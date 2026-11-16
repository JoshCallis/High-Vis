r"""Appearances — Fusion's Appearance panel, at the top of the Browser (ToggleAppearances).
Our own material libraries in place of Max's .mat libraries: nothing to save, ever.

  In This Model   every material this scene's objects wear, plus any put here by hand
                  (Duplicate, Paste into it — kept alive in the rootNode CA callisAppearHeld).
                  A row names the libraries it is stored in (dim, after the name).
  libraries       top-level groups of ../materials/tree.json, shared by EVERY scene. Groups
                  nest like the Browser's components; a material can be stored in several
                  libraries (row menu ▸ Stored In ticks). Copy + Paste makes an independent
                  copy; Cut + Paste / drag moves it.

Store (../materials, \\Mac\ClaudeMax\materials — in git):
  tree.json       {"groups": {gid: {name, parent}}, "mats": {mid: {name, in: [gid…], t}}}
  mats/<mid>.mat  the material alone (saveTempMaterialLibrary); thumbs/<mid>.png its swatch.
Every change is written at once. A scene's copy carries AppData MID (its library id) and MT
(the library `t` it matches).

Sync. A linked material edited in the scene (Slate, the Modify panel, undo — MAXScript
`when parameters`, which also fires for its maps) is written back ~1 s later. On scene open
and when Appearances is shown, a library copy newer than the scene's replaces it in place
(replaceInstances: every object keeps wearing it). Not live between running Maxes.

Keys (the Browser's, while Appearances has the focus — toggle, or a click in it):
R / C move (landing on a material makes it the one Apply Last Material uses), F / Enter go
into a library / group / In This Model, F on a material opens Slate with just it, D goes
out — at the top, D hands the focus back to the tree. ⌃R rename, ⌃G new group (picked
materials → into it), ⌘X / ⌘C / ⌘V cut / copy / paste. Dragging a material out of the
Browser onto Slate adds it there; onto an object, assigns it.
"""
import json
import os
import shutil
import struct
import tempfile
import time
import uuid
import zlib

import pymxs
from pymxs import runtime as rt

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STORE = os.path.join(HERE, "materials")
TREE = os.path.join(STORE, "tree.json")
MATS = os.path.join(STORE, "mats")
THUMBS = os.path.join(STORE, "thumbs")
LOCAL = os.path.join(HERE, ".state", "swatches")       # In This Model's unlinked materials
MID, MT = 0x43414C34, 0x43414C35                        # material AppData: library id, its t

_v = {"on": False, "focus": False,
      "root": None,        # None = the top (In This Model + libraries), "M", or a gid
      "cursor": None, "picks": [], "anchor": None,
      "cut": None,         # ("cut" | "copy", [toks])
      "rename": None, "n": 0}
_d = {"tree": None, "mtime": None}
_model = {"list": None}    # cached In This Model materials (None = stale)
_quiet = [0]
_sw = {"queue": [], "made": {}, "busy": False}

# ──────────────────────────────────────────────────────────────── MAXScript
_MS = r"""
global callisAppearDirty = #()
global callisAppearOpen = #()
global callisAppearCA = attributes callisAppearHeld attribID:#(0x43414c34, 0x48656c64) (
    parameters main ( ms type:#materialTab tabSizeVariable:true )
)
fn callisAppearHeld = (
    local ca = rootNode.custAttributes[#callisAppearHeld]
    if ca == undefined then #() else (for m in ca.ms where m != undefined collect m)
)
fn callisAppearHold m keep = (
    local ca = rootNode.custAttributes[#callisAppearHeld]
    if ca == undefined and keep do (
        custAttributes.add rootNode callisAppearCA
        ca = rootNode.custAttributes[#callisAppearHeld]
    )
    if ca != undefined do (
        local i = findItem ca.ms m
        if keep and i == 0 do append ca.ms m
        if not keep and i > 0 do deleteItem ca.ms i
    )
)
fn callisAppearWorn = (
    local r = #()
    for n in objects where (superClassOf n == GeometryClass or superClassOf n == shape) do (
        local m = if callisDimReal != undefined then callisDimReal n else n.material
        if m != undefined and m.name != "%s" do appendIfUnique r m
    )
    r
)
fn callisAppearWatch arr = (
    deleteAllChangeHandlers id:#callisAppear
    if arr.count > 0 do
        when parameters arr changes id:#callisAppear obj do appendIfUnique callisAppearDirty obj
)
fn callisAppearClean m = (
    local i = findItem callisAppearDirty m
    if i > 0 do deleteItem callisAppearDirty i
)
fn callisAppearStamp mtl path = (
    local g = (dotNetClass "Autodesk.Max.GlobalInterface").Instance
    local a = g.Animatable.GetAnimByHandle (dotNetObject "System.UIntPtr" (getHandleByAnim mtl))
    local ps = a.CreatePStamp (dotNetClass "Autodesk.Max.PostageStampSize").Large true
    (dotNetClass "System.IO.File").WriteAllBytes path ps.Image
    #(ps.Width, ps.Height)
)
fn callisAppearSlate m add = (
    if not (sme.IsOpen()) do sme.Open()
    local i = sme.GetViewByName "Callis"
    if i == 0 do i = sme.CreateView "Callis"
    sme.activeView = i
    local v = sme.GetView i
    if v == undefined do return false
    local n = v.GetNumNodes()
    if not add do (v.SelectAll(); v.DeleteSelection(); n = 0)
    v.CreateNode m [n * 40, n * 220]
    try (v.ZoomExtents type:#all) catch ()
    true
)
fn callisAppearSlateRect = (
    if not (sme.IsOpen()) do return undefined
    local h = sme.GetMainframe()
    if h == undefined or h == 0 do return undefined
    windows.getWindowPos h
)
"""


def _ms():
    from . import browser
    from .clean import DEFAULT_MTL
    browser._ms_load()                                  # callisDimReal (through the dim)
    if str(getattr(rt, "callisAppearWorn", "undefined")) == "undefined" or _d.get("ms") != _MS:
        rt.execute(_MS % DEFAULT_MTL)
        _d["ms"] = _MS


# ──────────────────────────────────────────────────────────────── the store
def _load():
    try:
        mt = os.path.getmtime(TREE)
    except OSError:
        mt = None
    if _d["tree"] is None or mt != _d["mtime"]:
        try:
            with open(TREE, encoding="utf-8") as f:
                t = json.load(f)
        except (OSError, ValueError):
            t = {}
        t.setdefault("groups", {})
        t.setdefault("mats", {})
        _d["tree"], _d["mtime"] = t, mt
    return _d["tree"]


def _save(t):
    os.makedirs(STORE, exist_ok=True)
    tmp = TREE + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(t, f, indent=1, sort_keys=True, ensure_ascii=False)
    os.replace(tmp, TREE)
    _d["tree"], _d["mtime"] = t, os.path.getmtime(TREE)


def _gid():
    return uuid.uuid4().hex[:12]


def _kids(t, parent):
    gs = [(g["name"].lower(), k) for k, g in t["groups"].items() if g.get("parent") == parent]
    return [k for _, k in sorted(gs)]


def _subtree(t, gid):
    out, todo = [], [gid]
    while todo:
        g = todo.pop()
        out.append(g)
        todo += _kids(t, g)
    return out


def _library(t, gid):
    while gid in t["groups"] and t["groups"][gid].get("parent"):
        gid = t["groups"][gid]["parent"]
    return gid


def _mats_in(t, gid):
    ms = [(m["name"].lower(), k) for k, m in t["mats"].items() if gid in m.get("in", [])]
    return [k for _, k in sorted(ms)]


def _libs_of(t, mid):
    m = t["mats"].get(mid)
    if not m:
        return []
    return sorted({_library(t, g) for g in m.get("in", []) if g in t["groups"]})


def _forget(t, mid):
    """A material in no group any more: gone from the store (scenes keep their copies,
    unlinked)."""
    if t["mats"].get(mid, {}).get("in"):
        return
    t["mats"].pop(mid, None)
    for p in (os.path.join(MATS, mid + ".mat"), os.path.join(THUMBS, mid + ".png")):
        try:
            os.remove(p)
        except OSError:
            pass


# ──────────────────────────────────────────────────────────────── materials
def _valid(m):
    try:
        return m is not None and bool(rt.isValidObj(m))
    except Exception:
        return False


def _mid(m):
    v = rt.getAppData(m, MID)
    return str(v) if v is not None and str(v) != "undefined" else None


def _mt(m):
    try:
        return float(str(rt.getAppData(m, MT)))
    except (TypeError, ValueError):
        return 0.0


def _h(m):
    return int(rt.getHandleByAnim(m))


def model():
    """In This Model: worn, then held by hand, each once. Re-read at most every 1.5 s
    (no #mtlRefAdded hook: the Browser's dim pass assigns thousands at a time)."""
    if _model["list"] is None or time.time() - _model.get("t", 0) > 1.5:
        _ms()
        seen, out = set(), []
        worn = list(rt.callisAppearWorn())
        for m in worn + list(rt.callisAppearHeld()):
            h = _h(m)
            if h not in seen:
                seen.add(h)
                out.append(m)
        was = _model.get("handles")
        _model.update(list=out, t=time.time(), worn={_h(m) for m in worn}, handles=seen)
        if was is not None and was != seen:
            _rewatch()
    return [m for m in _model["list"] if _valid(m)]


def _worn_handles():
    model()
    return _model["worn"]


def _stale(*_):
    _model["list"] = None


def scene_material(mid, load=True):
    """This scene's copy of library material `mid` (loaded from the store if it has none)."""
    _ms()
    for m in model() + list(rt.callisAppearOpen):
        if _valid(m) and _mid(m) == mid:
            return m
    if not load:
        return None
    m = _read(mid)
    if m is not None:
        rt.append(rt.callisAppearOpen, m)
        _rewatch()
    return m


def _read(mid):
    p = os.path.join(MATS, mid + ".mat")
    if not os.path.exists(p):
        return None
    tmp = os.path.join(tempfile.gettempdir(), "callis_%s.mat" % mid)
    shutil.copyfile(p, tmp)                # Max reads a local file faster than \\Mac
    lib = rt.loadTempMaterialLibrary(tmp)
    if lib is None or int(lib.count) < 1:
        return None
    m = lib[0]
    rt.setAppData(m, MID, mid)
    rt.setAppData(m, MT, repr(_load()["mats"].get(mid, {}).get("t", 0.0)))
    return m


def _write(t, mid, m):
    """The scene's material → the store (its .mat, name, t) and a new swatch."""
    os.makedirs(MATS, exist_ok=True)
    tmp = os.path.join(tempfile.gettempdir(), "callis_%s.mat" % mid)
    _quiet[0] += 1
    try:
        rt.setAppData(m, MID, mid)
        now = time.time()
        rt.setAppData(m, MT, repr(now))
        rt.saveTempMaterialLibrary(rt.materialLibrary(m), tmp)
    finally:
        _quiet[0] -= 1
    dst = os.path.join(MATS, mid + ".mat")
    shutil.copyfile(tmp, dst + ".tmp")
    os.replace(dst + ".tmp", dst)
    e = t["mats"].setdefault(mid, {"in": []})
    e["name"], e["t"] = str(m.name), now
    rt.callisAppearClean(m)                 # our own writing isn't an edit to write back
    _swatch(m, mid)


def _link(t, m):
    """Give a scene material a library id (stored, not yet in any group)."""
    mid = _mid(m)
    if mid is None or mid not in t["mats"]:
        mid = uuid.uuid4().hex
        t["mats"][mid] = {"in": [], "name": str(m.name), "t": 0.0}
        _write(t, mid, m)
        _rewatch()
    return mid


def _pull():
    """Library copies newer than the scene's replace them in place."""
    t = _load()
    done = False
    for m in model() + list(rt.callisAppearOpen):
        mid = _mid(m)
        e = t["mats"].get(mid) if mid else None
        if e and e.get("t", 0) > _mt(m) + 1e-3:
            new = _read(mid)
            if new is not None:
                _quiet[0] += 1
                try:
                    with pymxs.undo(False):
                        rt.replaceInstances(m, new)
                finally:
                    _quiet[0] -= 1
                done = True
    if done:
        _stale()
        _rewatch()
        rt.callisAppearDirty = rt.Array()


def _rewatch():
    _ms()
    ms = [m for m in model() + list(rt.callisAppearOpen) if _valid(m)]
    arr = rt.Array()
    for m in ms:
        rt.append(arr, m)
    rt.callisAppearWatch(arr)


def _tick():
    """Every second: write back edited linked materials; names changed in Max follow."""
    try:
        if str(getattr(rt, "callisAppearDirty", "undefined")) == "undefined":
            return
        ms = list(rt.callisAppearDirty)
        if not ms:
            return
        rt.callisAppearDirty = rt.Array()
        if _quiet[0]:
            return
        t, changed = _load(), False
        for m in ms:
            if not _valid(m):
                continue
            mid = _mid(m)
            if mid and mid in t["mats"]:
                _write(t, mid, m)
                changed = True
            else:
                _swatch(m, None)
        if changed:
            _save(t)
        _publish()
    except Exception as e:
        print("[callis.appearance] tick:", e)


# ──────────────────────────────────────────────────────────────── swatches
def _sw_path(mid, m):
    return os.path.join(THUMBS, mid + ".png") if mid else os.path.join(LOCAL, "h%d.png" % _h(m))


def _swatch(m, mid):
    """Queue a new swatch for m (one per timer tick: ~0.3 s each, so never in a burst)."""
    key = mid or "h%d" % _h(m)
    if all(k != key for k, _, _ in _sw["queue"]):
        _sw["queue"].append((key, m, _sw_path(mid, m)))     # where, decided now
    _sw_next()


def _sw_next():
    if _sw["busy"] or not _sw["queue"]:
        return
    from PySide6.QtCore import QTimer
    _sw["busy"] = True
    QTimer.singleShot(300, _sw_make)          # Max stays responsive between them


def _sw_make():
    try:
        key, m, p = _sw["queue"].pop(0)
        if _valid(m):
            os.makedirs(os.path.dirname(p), exist_ok=True)
            raw = os.path.join(tempfile.gettempdir(), "callis_swatch.raw")
            wh = rt.callisAppearStamp(m, raw)
            rt.callisAppearClean(m)
            w, h = int(wh[0]), int(wh[1])
            with open(raw, "rb") as f:
                _png(f.read(), w, h, p)
            _sw["made"][key] = time.time()
            _publish()
    except Exception as e:
        print("[callis.appearance] swatch:", e)
    finally:
        _sw["busy"] = False
        _sw_next()


def _png(raw, w, h, path):
    """The postage stamp (BGR rows, top down) → PNG."""
    out = bytearray()
    for y in range(h):
        r = raw[y * w * 3:(y + 1) * w * 3]
        row = bytearray(r)
        row[0::3], row[2::3] = r[2::3], r[0::3]
        out.append(0)
        out += row

    def chunk(k, d):
        return struct.pack(">I", len(d)) + k + d + struct.pack(">I", zlib.crc32(k + d) & 0xffffffff)
    data = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(bytes(out), 6)) + chunk(b"IEND", b""))
    with open(path + ".tmp", "wb") as f:
        f.write(data)
    os.replace(path + ".tmp", path)


def _sw_url(mid, m):
    """The page's swatch URL (served by max_browser/server.py), or None while it's made."""
    p = _sw_path(mid, m) if (mid or m is not None) else None
    if p is None:
        return None
    if not os.path.exists(p) or (not mid and ("h%d" % _h(m)) not in _sw["made"]):
        if m is not None and _valid(m):
            _swatch(m, mid)
        elif mid and os.path.exists(os.path.join(MATS, mid + ".mat")):
            pass                                  # made when first loaded
        if not os.path.exists(p):
            return None
    rel = os.path.relpath(p, HERE).replace(os.sep, "/")
    return "/swatch/%s?%d" % (rel, int(os.path.getmtime(p)))


# ──────────────────────────────────────────────────────────────── rows
def _grow(t, gid, depth):
    empty = not _kids(t, gid) and not _mats_in(t, gid)
    return {"tok": "A:g:" + gid, "kind": "agroup", "name": t["groups"][gid]["name"],
            "depth": depth, "empty": empty, "lib": not t["groups"][gid].get("parent")}


def _mrow(t, gid, mid, depth):
    m = scene_material(mid, load=False)
    return {"tok": "A:m:%s:%s" % (gid, mid), "kind": "amat", "name": t["mats"][mid]["name"],
            "depth": depth, "sw": _sw_url(mid, m), "inmodel": m is not None,
            "libgids": _libs_of(t, mid)}


def _srow(t, m, depth, worn):
    mid = _mid(m)
    if mid not in t["mats"]:
        mid = None
    elif str(m.name) != t["mats"][mid].get("name"):      # renamed in Max: the library follows
        _write(t, mid, m)
        _save(t)
    gids = _libs_of(t, mid) if mid else []
    return {"tok": "A:s:%d" % _h(m), "kind": "amat", "name": str(m.name), "depth": depth,
            "sw": _sw_url(mid, m), "libs": [t["groups"][g]["name"] for g in gids],
            "libgids": gids, "unused": _h(m) not in worn}


def _rows():
    t = _load()
    root = _v["root"]
    if root not in (None, "M") and root not in t["groups"]:
        root = _v["root"] = None
    rows = []
    if root is None:
        rows.append({"tok": "A:M", "kind": "amodel", "name": "In This Model", "depth": 0,
                     "empty": not model()})
        rows += [_grow(t, g, 0) for g in _kids(t, None)]
    elif root == "M":
        rows.append({"tok": "A:M", "kind": "amodel", "name": "In This Model", "depth": 0, "root": True})
        ms = sorted(model(), key=lambda m: str(m.name).lower())
        worn = _worn_handles()
        rows += [_srow(t, m, 1, worn) for m in ms]
    else:
        rows.append(dict(_grow(t, root, 0), root=True))
        rows += [_grow(t, g, 1) for g in _kids(t, root)]
        rows += [_mrow(t, root, mid, 1) for mid in _mats_in(t, root)]
    cut = set(_v["cut"][1]) if _v["cut"] and _v["cut"][0] == "cut" else set()
    for r in rows:
        r["sel"] = r["tok"] in _v["picks"]
        r["cut"] = r["tok"] in cut
    return rows


def snapshot():
    if not _v["on"]:
        return None
    try:
        _ms()
        rows = _rows()
    except Exception as e:
        return {"error": str(e), "rows": [], "focus": _v["focus"]}
    toks = [r["tok"] for r in rows]
    if _v["cursor"] not in toks:
        _v["cursor"] = toks[1] if len(toks) > 1 and rows[0].get("root") else (toks[0] if toks else None)
    t = _load()
    return {"rows": rows, "cursor": _v["cursor"], "focus": _v["focus"], "rename": _v["rename"],
            "libs": [{"gid": g, "name": t["groups"][g]["name"]} for g in _kids(t, None)],
            "pastable": bool(_v["cut"])}


def _publish():
    from . import browser
    browser.publish()


# ──────────────────────────────────────────────────────────────── acting
def _row(tok):
    return next((r for r in _rows() if r["tok"] == tok), None)


def _mat_of(tok, load=True):
    """The scene material a row stands for (a library one loaded if need be)."""
    if tok.startswith("A:s:"):
        m = rt.getAnimByHandle(int(tok[4:]))
        return m if _valid(m) else None
    if tok.startswith("A:m:"):
        return scene_material(tok.split(":")[3], load=load)
    return None


def _mid_of(tok):
    if tok.startswith("A:m:"):
        return tok.split(":")[3]
    m = _mat_of(tok)
    return _mid(m) if m is not None else None


def _gid_of(tok):
    return tok.split(":")[2] if tok.startswith(("A:g:", "A:m:")) else None


def toggle():
    """ToggleAppearances: shown → (focused → hidden; else focused); hidden → shown + focused."""
    if _v["on"] and _v["focus"]:
        _v["on"] = _v["focus"] = False
    else:
        if not _v["on"]:
            _ms()
            _stale()
            _pull()
            _rewatch()
        _v["on"] = _v["focus"] = True
    _publish()


def focused():
    return _v["on"] and _v["focus"]


def blur():
    _v["focus"] = False


def _land(tok):
    _v["cursor"] = tok
    _v["anchor"] = tok
    if tok and tok.startswith(("A:m:", "A:s:")):
        from . import material
        if tok.startswith("A:m:"):
            material.take_ref(tok.split(":")[3])
        else:
            m = _mat_of(tok)
            if m is not None:
                material._take(m)


def _enter(root, cursor=None):
    _v["root"], _v["picks"] = root, []
    rows = _rows()
    _v["cursor"] = cursor or (rows[1]["tok"] if len(rows) > 1 else rows[0]["tok"])


def key(name):
    """A Browser key while Appearances has the focus; True if taken."""
    rows = _rows()
    toks = [r["tok"] for r in rows]
    cur = _v["cursor"] if _v["cursor"] in toks else (toks[0] if toks else None)
    i = toks.index(cur) if cur in toks else 0
    if name in ("up", "down", "top", "bottom"):
        if toks:
            j = {"up": max(0, i - 1), "down": min(len(toks) - 1, i + 1),
                 "top": 0, "bottom": len(toks) - 1}[name]
            _land(toks[j])
        return True
    if name in ("in", "deep"):
        r = rows[i] if rows else None
        if r is None or r.get("root"):
            return True
        if r["kind"] == "amodel":
            _enter("M")
        elif r["kind"] == "agroup":
            _enter(_gid_of(r["tok"]))
        else:
            slate(r["tok"])
        return True
    if name == "out":
        root, t = _v["root"], _load()
        if root is None:
            _v["focus"] = False
        elif root == "M":
            _enter(None, "A:M")
        else:
            _enter(t["groups"].get(root, {}).get("parent"), "A:g:" + root)
        return True
    if name == "rename":
        if cur and cur != "A:M":
            _ask_name(cur)
        return True
    if name == "deselect":
        _v["picks"] = []
        return True
    if name in ("cut", "copy"):
        _v["cut"] = (name, list(_v["picks"]) or ([cur] if cur else []))
        return True
    if name == "paste":
        paste()
        return True
    if name in ("newfolder", "newlayer", "newgroup"):
        new_group()
        return True
    return name in ("hide", "isolate", "ungroup")


def _ask_name(tok):
    _v["n"] += 1
    _v["rename"] = {"tok": tok, "n": _v["n"]}


def new_group(at=None):
    """⌃G / New Group: at the top a new library; else a group in the entered one (or the
    clicked group row), taking the picked materials of the entered group with it."""
    t = _load()
    root = _v["root"]
    parent = _gid_of(at) if at and at.startswith("A:g:") and at != "A:g:%s" % root else \
        (root if root not in (None, "M") else None)
    gid = _gid()
    t["groups"][gid] = {"name": "Group" if parent else "Library", "parent": parent}
    for tok in _v["picks"]:
        if tok.startswith("A:m:") and _gid_of(tok) == parent:
            e = t["mats"][tok.split(":")[3]]
            e["in"] = [g for g in e["in"] if g != parent] + [gid]
    _v["picks"] = []
    _save(t)
    _v["cursor"] = "A:g:" + gid
    _ask_name("A:g:" + gid)


def rename(tok, name):
    name = (name or "").strip()
    if not name:
        return
    t = _load()
    if tok.startswith("A:g:"):
        t["groups"][tok[4:]]["name"] = name
    else:
        m = _mat_of(tok)
        if m is None:
            return
        with pymxs.undo(True, "Rename Material"):
            m.name = name
        mid = _mid(m)
        if mid in t["mats"]:
            _write(t, mid, m)
    _v["rename"] = None
    _save(t)


def duplicate(tok):
    """A copy in In This Model only — stored in no library."""
    src = _mat_of(tok)
    if src is None:
        return
    with pymxs.undo(True, "Duplicate Material"):
        m = rt.copy(src)
        m.name = str(src.name) + " copy"
        rt.deleteAppData(m, MID)
        rt.deleteAppData(m, MT)
        rt.callisAppearHold(m, True)
    _stale()
    _rewatch()
    if _v["root"] == "M":
        _v["cursor"] = "A:s:%d" % _h(m)


def stored_in(tok, lib):
    """Row menu ▸ Stored In ▸ <library>: tick = store it there (at the library's top),
    untick = out of that library and every group in it."""
    t = _load()
    m = _mat_of(tok) if not tok.startswith("A:m:") else None
    mid = _mid_of(tok) if tok.startswith("A:m:") else (_link(t, m) if m is not None else None)
    if mid is None or lib not in t["groups"]:
        return
    e = t["mats"][mid]
    inside = set(_subtree(t, lib))
    if any(g in inside for g in e["in"]):
        e["in"] = [g for g in e["in"] if g not in inside]
        _forget(t, mid)
    else:
        e["in"].append(lib)
    _save(t)


def apply(tok, nodes=None):
    """Onto the selection (or `nodes`): it shows in In This Model, still stored where it was."""
    from . import material
    m = _mat_of(tok)
    if m is None:
        return
    nodes = [n for n in (nodes if nodes is not None else rt.selection) if material._capable(n)]
    if not nodes:
        return
    with pymxs.undo(True, "Apply Material"):
        for n in nodes:
            try:
                n.material = m
            except Exception:
                pass
    material._take(m)
    _stale()
    _rewatch()


def slate(tok, add=False):
    """F / Enter on a material: Slate with just it (add: beside what's there)."""
    m = _mat_of(tok)
    if m is not None:
        _ms()
        rt.callisAppearSlate(m, add)


def _target(into):
    """Where a paste / drop lands: a group, or "M" (In This Model)."""
    if into == "A:M":
        return "M"
    if into and into.startswith("A:g:"):
        return into[4:]
    r = _row(_v["cursor"]) if _v["cursor"] else None
    if r and r["kind"] == "agroup" and not r.get("root"):
        return _gid_of(r["tok"])
    return _v["root"]


def move(toks, into, copy=False):
    """Cut / copy + paste, or a drag: materials (and groups) into a group or the model.
    Copy makes an independent copy; a move between groups re-files the same material."""
    t = _load()
    dest = _target(into)
    if dest is None:
        raise ValueError("Paste into a library")
    for tok in toks:
        if tok.startswith("A:g:"):
            g = tok[4:]
            if dest == "M" or g == dest or dest in _subtree(t, g):
                raise ValueError("Can't move a group there")
            if copy:
                continue
            t["groups"][g]["parent"] = dest
        elif dest == "M":
            m = _mat_of(tok)
            if m is not None:
                rt.callisAppearHold(m, True)
                _stale()
        elif copy or tok.startswith("A:s:"):
            m = _mat_of(tok)
            if m is None:
                continue
            if copy:
                m = rt.copy(m)
                rt.deleteAppData(m, MID)
                rt.append(rt.callisAppearOpen, m)
            mid = _link(t, m)
            if dest not in t["mats"][mid]["in"]:
                t["mats"][mid]["in"].append(dest)
        else:
            src, mid = _gid_of(tok), tok.split(":")[3]
            e = t["mats"].get(mid)
            if e is not None:
                e["in"] = [g for g in e["in"] if g != src]
                if dest not in e["in"]:
                    e["in"].append(dest)
    _save(t)
    _rewatch()


def paste():
    if not _v["cut"]:
        return
    kind, toks = _v["cut"]
    move(toks, None, copy=kind == "copy")
    if kind == "cut":
        _v["cut"] = None


def delete(tok):
    """A material: out of this group (gone from the store when in none); In This Model:
    dropped if nothing wears it. A group: its contents move up a level (a library's are
    forgotten)."""
    t = _load()
    if tok.startswith("A:m:"):
        gid, mid = tok.split(":")[2:4]
        e = t["mats"].get(mid)
        if e:
            e["in"] = [g for g in e["in"] if g != gid]
            _forget(t, mid)
    elif tok.startswith("A:s:"):
        m = _mat_of(tok)
        if m is None:
            return
        _stale()
        if _h(m) in _worn_handles():
            raise ValueError("In use — objects wear it")
        rt.callisAppearHold(m, False)
        _stale()
    elif tok.startswith("A:g:"):
        gid = tok[4:]
        up = t["groups"][gid].get("parent")
        if up:                                    # a group: its contents up a level
            for k in _kids(t, gid):
                t["groups"][k]["parent"] = up
            for e in t["mats"].values():
                if gid in e["in"]:
                    e["in"] = [g for g in e["in"] if g != gid] + ([] if up in e["in"] else [up])
            t["groups"].pop(gid, None)
        else:                                     # a library: all of it
            gone = set(_subtree(t, gid))
            for g in gone:
                t["groups"].pop(g, None)
            for mid, e in list(t["mats"].items()):
                if gone & set(e["in"]):
                    e["in"] = [g for g in e["in"] if g not in gone]
                    _forget(t, mid)
        if _v["root"] == gid:
            _v["root"] = up
    _save(t)


def _pick_click(tok, a):
    """⌘ / ⇧ / Space clicks only pick (as the tree's): for Group, cut / copy, drag."""
    rows = [r for r in _rows() if not r.get("root")]
    toks = [r["tok"] for r in rows]
    _v["cursor"] = tok
    if a.get("shift") and _v["anchor"] in toks and tok in toks:
        i, j = sorted((toks.index(_v["anchor"]), toks.index(tok)))
        _v["picks"] = toks[i:j + 1]
        return
    _v["anchor"] = tok
    if a.get("meta"):
        _v["picks"] = [x for x in _v["picks"] if x != tok] if tok in _v["picks"] else _v["picks"] + [tok]
    else:
        _v["picks"] = [] if _v["picks"] == [tok] else [tok]


def drop(tok, sx, sy):
    """A material dragged out of the Browser, let go over Max at Mac screen point (sx, sy):
    onto Slate → added there; onto an object → it wears it."""
    from . import nav, side
    try:
        with open(os.path.join(HERE, ".state", "nav.json")) as f:
            desk = json.load(f)["desk"]
        fr = side._frame()
        x, y = sx * desk[0] / fr["sw"], sy * desk[1] / fr["sh"]
    except (OSError, ValueError, KeyError):
        return
    _ms()
    r = rt.callisAppearSlateRect()
    if r is not None and str(r) != "undefined":
        if r.x <= x <= r.x + r.w and r.y <= y <= r.y + r.h:
            slate(tok, add=True)
            return
    pt = nav._viewport_at({"x": x, "y": y})
    if pt is None:
        return
    nav._ms()
    n = rt.callisPickNode(rt.mapScreenToWorldRay(pt))
    if n is not None and str(n) != "undefined":
        apply(tok, [n])


def act(a):
    """The page's clicks and menu picks on Appearances rows (browser.act routes them)."""
    op, tok = a.get("op"), a.get("tok") or ""
    _v["focus"] = True
    if op == "click":
        if a.get("meta") or a.get("shift") or a.get("alt"):
            _pick_click(tok, a)
            return
        _v["picks"] = []
        r = _row(tok)
        if r is None:
            return
        if r.get("root"):
            key("out")
        elif r["kind"] == "amodel":
            _enter("M")
        elif r["kind"] == "agroup":
            _enter(_gid_of(tok))
        else:
            _land(tok)
    elif op == "enter":
        _v["cursor"] = tok
        key("in")
    elif op == "rename":
        rename(tok, a.get("name", ""))
    elif op == "askname":
        _ask_name(tok)
    elif op in ("newfolder", "newgroup"):
        new_group(tok)
    elif op == "newlib":
        _v["root"] = None
        new_group()
    elif op == "duplicate":
        duplicate(tok)
    elif op == "storedin":
        stored_in(tok, a.get("lib"))
    elif op == "apply":
        apply(tok)
    elif op == "slate":
        slate(tok)
    elif op in ("cut", "copy"):
        _v["cut"] = (op, list(_v["picks"]) if tok in _v["picks"] else [tok])
    elif op == "paste":
        if tok:
            _v["cursor"] = tok
        paste()
    elif op == "uncut":
        _v["cut"] = None
    elif op == "delete":
        delete(tok)
    elif op == "move":
        move(a.get("toks", []), a.get("into"), copy=bool(a.get("copy")))
    elif op == "dropmat":
        drop(tok, float(a.get("sx", 0)), float(a.get("sy", 0)))
    elif op == "hideappear":
        _v["on"] = _v["focus"] = False


# ──────────────────────────────────────────────────────────────── install
def _opened(*_):
    _stale()
    _sw["made"].clear()
    try:
        _ms()
        rt.callisAppearOpen = rt.Array()
        _pull()
        _rewatch()
    except Exception as e:
        print("[callis.appearance] open:", e)


def _flush(*_):
    _tick()


class _Timer:
    def __init__(self):
        from PySide6.QtCore import QTimer
        self.timer = QTimer()
        self.timer.timeout.connect(lambda: _tick())
        self.timer.start(1000)


def install():
    import builtins
    rt.callbacks.removeScripts(id=rt.Name("callisAppear"))
    for ev in ("filePostOpen", "systemPostNew", "systemPostReset", "filePostMerge"):
        rt.callbacks.addScript(rt.Name(ev), _opened, id=rt.Name("callisAppear"))
    rt.callbacks.addScript(rt.Name("filePreSave"), _flush, id=rt.Name("callisAppear"))
    if getattr(builtins, "_callis_appear_timer", None) is None:
        builtins._callis_appear_timer = _Timer()
    _opened()
