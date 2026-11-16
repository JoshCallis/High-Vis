"""Render the ticked views at the chosen resolutions, into the project folder.

Per view × resolution, into  <output_root>/<view name>/<Low Res|High Res|…>/ :
  beauty.exr, passes.exr      — from the renderer adapter
  glass/beauty.exr, glass/passes.exr  — the glass pass, if any layer is "Glass (separate)"
  manifest.json               — everything the Photoshop step needs (passes, mattes, sizes)

Previous files (not .psb/.psd — those stay so compose updates their links) are moved to
_previous/ first and put back if the render is
cancelled (the old script's Backup behaviour).

Region only (Project.region): each view's saved region is re-rendered at full
size into <folder>/_region/ and queued as a patch — compose.patch pastes it into
the existing passes, so the PSB's linked files update in place.
"""
import json
import os
import re
import shutil
import time

from pymxs import runtime as rt

from . import project as P
from . import renderers
from . import scene as S

_RENDER_FN = """fn callisRender cam w h f fr rg = (
    local c = false
    local b = if rg == undefined then
        render camera:cam outputwidth:w outputheight:h outputfile:f frame:fr vfb:true cancelled:&c
    else
        render camera:cam outputwidth:w outputheight:h outputfile:f frame:fr vfb:true cancelled:&c \\
            renderType:#region region:rg
    if b != undefined do close b
    c
)"""
REGION_DIR = "_region"


class Cancelled(Exception):
    pass


def _safe(name):
    return "".join(ch for ch in name if ch not in '<>:"/\\|?*').strip() or "View"


def _kept(f):
    """The user's Photoshop files stay put through a re-render: compose then updates the
    PSB's links instead of building a new one (a re-render used to delete it with _previous)."""
    return f == "_previous" or os.path.splitext(f)[1].lower() in (".psb", ".psd")


def _backup(folder):
    prev = os.path.join(folder, "_previous")
    if os.path.isdir(prev):
        shutil.rmtree(prev)
    if os.path.isdir(folder) and any(not _kept(f) for f in os.listdir(folder)):
        os.makedirs(prev)
        for f in os.listdir(folder):
            if not _kept(f):
                shutil.move(os.path.join(folder, f), os.path.join(prev, f))
    os.makedirs(folder, exist_ok=True)
    return prev


def _restore(folder, prev):
    if not os.path.isdir(prev):
        return
    for f in os.listdir(folder):
        if not _kept(f):
            p = os.path.join(folder, f)
            shutil.rmtree(p) if os.path.isdir(p) else os.remove(p)
    for f in os.listdir(prev):
        shutil.move(os.path.join(prev, f), os.path.join(folder, f))
    os.rmdir(prev)


# ── Mattes ──────────────────────────────────────────────────────────────────

def _leaf_materials(mat, out):
    if mat is None:
        return
    if rt.classOf(mat) == rt.Shell_Material:    # the Browser's dim: render = original
        _leaf_materials(mat.originalMaterial if mat.renderMtlIndex == 0 else mat.bakedMaterial, out)
    elif rt.classOf(mat) == rt.Multimaterial:
        for sub in mat.materialList:
            _leaf_materials(sub, out)
    else:
        out.setdefault(str(mat.name), None)


# Max's layer tree — mattes still follow layers, though the Browser moved to its own
# folders (2026-10-13) and dropped these helpers.

def _zero():
    return rt.LayerManager.getLayer(0)


def _parent(lay):
    """The layer above, None at the top (a child of layer 0 is top-level)."""
    p = lay.getParent()
    return None if p is None or str(p.name) == str(_zero().name) else p


def _display(lay):
    """The layer's name without the " (Parent)" suffix Max's unique names forced on a clash."""
    name, p = str(lay.name), _parent(lay)
    if p is not None:
        suf = " (%s)" % _display(p)
        if name.endswith(suf) and len(name) > len(suf):
            return name[:-len(suf)]
    return name


# The 2017 L/M/B/N sublayers ("L (Cladding)" from maxstart, "Cladding (L)" older):
# no longer meaningful — their objects count as the parent layer's.
_MARKER = re.compile(r"^(?:[LMBN](?: \(.*\))?|.* \([LMBN]\))$")


def is_marker(layer):
    return bool(_MARKER.match(str(layer.name)))


def layer_rows(project):
    """Every layer but 0 and the L/M/B/N markers, parents first:
    [{"layer", "path", "depth", "mode", "own"}] — mode is the effective setting
    (own, else the parent's), own the layer's explicit one or None."""
    kids = {}
    for lay in S.layers():
        if str(lay.name) == str(_zero().name) or is_marker(lay):
            continue
        p = _parent(lay)
        while p is not None and is_marker(p):
            p = _parent(p)
        kids.setdefault(None if p is None else str(p.name), []).append(lay)
    rows = []

    def walk(parent, path, depth, mode):
        for lay in sorted(kids.get(parent, []), key=lambda l: _display(l).lower()):
            name = str(lay.name)
            m = project.matte_mode(name, mode)
            p = path + [_display(lay)]
            rows.append({"layer": lay, "parent": parent, "path": "/".join(p), "depth": depth,
                         "mode": m, "own": project.own_matte_mode(name)})
            walk(name, p, depth + 1, m)

    walk(None, [], 0, "normal")
    return rows


def owner_layer(lay):
    """The layer an object counts towards: itself, or the parent of an L/M/B/N marker."""
    while lay is not None and is_marker(lay):
        lay = _parent(lay)
    return lay


def matte_plan(project, adapter):
    """Mattes for Photoshop, cut from Cryptomatte by the compose step:
      - one per layer whose subtree holds geometry (its path, "Geometry/Building/Walls"),
      - one per material on that geometry (compose drops the tiny ones),
      - one "Glass" for glass layers (added by render_view after the glass pass).
    Names are written as the renderer hashes them. Returns (plan, glass nodes, warnings)."""
    rows = layer_rows(project)
    by_name = {str(r["layer"].name): r for r in rows}
    direct = {}                       # layer name → geometry nodes that count towards it
    for lay in S.layers():
        own = owner_layer(lay)
        if own is None or str(own.name) not in by_name:
            continue
        nodes = [n for n in S.layer_nodes(lay) if rt.superClassOf(n) == rt.GeometryClass]
        direct.setdefault(str(own.name), []).extend(nodes)

    from .browser import real_material      # through the Browser's dim
    mats, glass, seen, warnings = {}, [], {}, []
    layer_ids = {}                    # layer name → crypto names in its subtree (normal only)
    for r in rows:
        nodes = direct.get(str(r["layer"].name), [])
        if r["mode"] == "glass":
            glass.extend(nodes)
        elif r["mode"] == "normal":
            ids = layer_ids[str(r["layer"].name)] = set()
            for n in nodes:
                nn = str(n.name)
                seen.setdefault(nn, set()).add(r["path"])
                ids.add(adapter.crypto_name(nn))
                _leaf_materials(real_material(n), mats)
    for r in reversed(rows):          # children first: roll each layer up into its parent
        name = str(r["layer"].name)
        if name in layer_ids and r["parent"] in layer_ids:
            layer_ids[r["parent"]] |= layer_ids[name]
    plan = [{"name": r["path"], "kind": "object", "group": "layer",
             "ids": sorted(layer_ids[str(r["layer"].name)])}
            for r in rows if layer_ids.get(str(r["layer"].name))]
    plan += [{"name": m, "kind": "material", "group": "material", "ids": [adapter.crypto_name(m)]}
             for m in sorted(mats)]
    dup = sorted(n for n, paths in seen.items() if len(paths) > 1)
    if dup:
        warnings.append("Same object name on more than one layer — those layer mattes overlap: "
                        + ", ".join(dup[:12]) + (" …" if len(dup) > 12 else ""))
    return plan, glass, warnings


# ── Rendering ───────────────────────────────────────────────────────────────

def _render(adapter, cam, w, h, path, frame, rect=None):
    """frame: a legacy view's keyed frame, or None for the current time (shots carry
    their poses, not a frame). rect: [left, top, right, bottom] in pixels, right/bottom
    exclusive (Max's own region convention). Arnold writes beauty full-frame (black
    outside) and the passes with a data window of just the rect — compose.patch handles both."""
    if adapter.own_render:
        cancelled = adapter.render(cam, w, h, path, frame, rect)
    else:
        rt.execute(_RENDER_FN)
        rg = rt.Array(*rect) if rect else None
        cancelled = rt.callisRender(cam, w, h, path, rt.currentTime if frame is None else frame, rg)
    adapter.finish()
    if cancelled:
        err = adapter.render_error()
        if err:
            raise RuntimeError(err)
        raise Cancelled()


def region_pixels(region, w, h):
    """A view's 0–1 region → pixel rect at w×h, at least 1 px, clamped to the frame."""
    x0, y0, x1, y1 = region
    l, t = min(w - 1, max(0, int(x0 * w))), min(h - 1, max(0, int(y0 * h)))
    r, b = max(l + 1, min(w, round(x1 * w))), max(t + 1, min(h, round(y1 * h)))
    return [l, t, r, b]


def _passes(adapter, cam, w, h, folder, view, glass_nodes, log, label, rect=None):
    """Pass 1 (everything but the separate glass) and pass 2 (the glass alone).
    Returns (main outputs, glass outputs or None)."""
    was_hidden = [bool(n.isHidden) for n in glass_nodes]
    glass_nodes = [n for n, hid in zip(glass_nodes, was_hidden) if not hid]  # already-hidden glass stays out
    for n in glass_nodes:
        n.isHidden = True
    try:
        out = adapter.configure(folder)
        log(f"{label} — rendering")
        _render(adapter, cam, w, h, out["beauty"], view.frame, rect)
    finally:
        for n in glass_nodes:
            n.isHidden = False
    glass_out = None
    if glass_nodes:
        gdir = os.path.join(folder, "glass")
        os.makedirs(gdir, exist_ok=True)
        glass_out = adapter.configure(gdir, glass=True)
        log(f"{view.name} · glass pass")
        _render(adapter, cam, w, h, glass_out["beauty"], view.frame, rect)
    return out, glass_out, glass_nodes


def render_view(project, view, res_key, log=print):
    adapter = renderers.for_current()
    if adapter is None:
        raise RuntimeError(f"No adapter for renderer {rt.classOf(rt.renderers.current)} — "
                           "switch to Arnold, V-Ray or Corona.")
    res = P.RESOLUTIONS[res_key]
    w, h = max(1, round(view.width * res["scale"])), max(1, round(view.height * res["scale"]))
    folder = os.path.join(project.output_root, _safe(view.name), res["folder"])
    cam = S.apply_view(project, view)
    if cam is None:
        raise RuntimeError(f'View "{view.name}" has no camera.')

    mattes, glass_nodes, matte_warnings = matte_plan(project, adapter)
    adapter.warnings.extend(matte_warnings)
    prev = _backup(folder)
    started = time.time()
    try:
        out, glass_out, glass_nodes = _passes(adapter, cam, w, h, folder, view, glass_nodes, log,
                                              f"{view.name} · {res['label']} · {w}×{h}")
        if glass_out:
            mattes.append({"name": "Glass", "kind": "object", "group": "glass", "source": "glass",
                           "ids": [adapter.crypto_name(str(n.name)) for n in glass_nodes]})
    except Cancelled:
        _restore(folder, prev)
        log(f"{view.name} · cancelled — previous files restored")
        raise
    except Exception:
        _restore(folder, prev)
        raise
    if os.path.isdir(prev):
        shutil.rmtree(prev)

    manifest = {
        "schema": 1,
        "view": view.name, "resolution": res_key, "width": w, "height": h,
        "renderer": adapter.key, "recipe": adapter.recipe,
        "scene": os.path.join(str(rt.maxFilePath), str(rt.maxFileName)),
        "rendered": time.strftime("%Y-%m-%d %H:%M:%S"), "seconds": round(time.time() - started, 1),
        "render": _rel(out, folder), "glass": _rel(glass_out, folder) if glass_out else None,
        "mattes": mattes, "bit_depth": project.bit_depth, "photoshop": project.photoshop,
        "warnings": adapter.warnings,
    }
    with open(os.path.join(folder, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=1)
    for w_ in adapter.warnings:
        log("  ! " + w_)
    log(f"{view.name} · {res['label']} done in {manifest['seconds']} s")
    if project.photoshop:
        _queue_compose(folder, {"photoshop": True}, log)
    return folder


def render_region(project, view, res_key, log=print):
    """Re-render just the view's region at full size into <folder>/_region/ and queue
    a patch. Needs an earlier full render at the same size — that's what gets patched."""
    if not view.region:
        log(f"{view.name} · no region set — skipped (Region only is ticked)")
        return None
    adapter = renderers.for_current()
    if adapter is None:
        raise RuntimeError(f"No adapter for renderer {rt.classOf(rt.renderers.current)} — "
                           "switch to Arnold, V-Ray or Corona.")
    res = P.RESOLUTIONS[res_key]
    w, h = max(1, round(view.width * res["scale"])), max(1, round(view.height * res["scale"]))
    folder = os.path.join(project.output_root, _safe(view.name), res["folder"])
    try:
        with open(os.path.join(folder, "manifest.json"), encoding="utf-8") as f:
            man = json.load(f)
    except (OSError, ValueError):
        man = None
    if not man or (man["width"], man["height"]) != (w, h):
        log(f"{view.name} · {res['label']} — no full {w}×{h} render to patch yet; render it without Region only first")
        return None
    cam = S.apply_view(project, view)
    if cam is None:
        raise RuntimeError(f'View "{view.name}" has no camera.')
    rect = region_pixels(view.region, w, h)
    rdir = os.path.join(folder, REGION_DIR)
    if os.path.isdir(rdir):
        shutil.rmtree(rdir)
    os.makedirs(rdir)
    _, glass_nodes, _ = matte_plan(project, adapter)
    started = time.time()
    try:
        _passes(adapter, cam, w, h, rdir, view, glass_nodes, log,
                f"{view.name} · {res['label']} · region {rect[2] - rect[0]}×{rect[3] - rect[1]}", rect)
    except Cancelled:
        shutil.rmtree(rdir, ignore_errors=True)
        log(f"{view.name} · region cancelled — nothing changed")
        raise
    except Exception:
        shutil.rmtree(rdir, ignore_errors=True)
        raise
    with open(os.path.join(rdir, "region.json"), "w", encoding="utf-8") as f:
        json.dump({"rect": rect, "width": w, "height": h, "rendered": time.strftime("%Y-%m-%d %H:%M:%S"),
                   "seconds": round(time.time() - started, 1)}, f, indent=1)
    for w_ in adapter.warnings:
        log("  ! " + w_)
    log(f"{view.name} · region done in {round(time.time() - started, 1)} s")
    # Always queued: the patch is what makes the passes whole again, PSB or not.
    _queue_compose(folder, {"patch": REGION_DIR, "photoshop": project.photoshop}, log)
    return folder


def _queue_compose(folder, job, log):
    """Hand the render to the compose step (patch → passes → PNG mattes → PSB) via
    the shared queue folder in max/config.json."""
    cfg_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "config.json")
    try:
        with open(cfg_path, encoding="utf-8") as f:
            queue = json.load(f)["queue_windows"]
        os.makedirs(queue, exist_ok=True)
        name = time.strftime("%Y%m%d-%H%M%S-") + _safe(os.path.basename(os.path.dirname(folder)))
        with open(os.path.join(queue, name + ".job"), "w", encoding="utf-8") as f:
            json.dump({"folder": folder, **job}, f)
        log("  → queued for " + ("patching" if job.get("patch") else "Photoshop"))
    except (OSError, KeyError, ValueError) as e:
        log(f"  ! couldn't queue for Photoshop: {e}")


def _rel(out, folder):
    """Adapter paths → relative to the view folder, so the manifest works from any OS."""
    def rel(p):
        return os.path.relpath(p, folder).replace("\\", "/")
    return {"beauty": rel(out["beauty"]), "passes": [rel(p) for p in out["passes"]],
            "layers": out["layers"], "crypto": out["crypto"], "raw_passes": out.get("raw_passes", False)}


def render_batch(project, log=print):
    """Every ticked view at every chosen resolution. Stops at the first cancel."""
    from . import rsettings
    done = []
    if not project.output_root:
        raise RuntimeError("Set the project's output folder first.")
    if project.save_scene:
        if str(rt.maxFileName):
            rt.saveMaxFile(os.path.join(str(rt.maxFilePath), str(rt.maxFileName)), quiet=True)
            log("Scene saved.")
        else:
            log("  ! scene not saved — it has no file yet")
    one = render_region if project.region else render_view
    from .browser import render_shown
    with rsettings.applied(project, "final", log), render_shown(log):
        for view in [v for v in project.views if v.render]:
            for res in project.resolutions:
                try:
                    folder = one(project, view, res, log)
                except Cancelled:
                    return done
                if folder:
                    done.append(folder)
    return done
