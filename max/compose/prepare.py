"""Turn a render folder (manifest.json + EXRs from Max) into a Photoshop plan.

    .venv/bin/python -m compose.prepare "<render folder>"

Writes into <folder>/ps/:
  <Pass>.exr            one single-layer EXR per pass (Photoshop can't read multi-layer EXRs)
  mattes/layers/, mattes/materials/  8-bit greyscale coverage PNGs from Cryptomatte, cropped
                        to what they cover (offset in plan.json); Glass.png full-frame
  mattes/Facing *.png   six facing-direction masks from the normals pass
  plan.json             the resolved layer stack for compose/photoshop/build.jsx
"""
import glob
import json
import os
import shutil
import sys
import time

import numpy as np

from . import exr

HERE = os.path.dirname(os.path.abspath(__file__))
# Materials covering less than this share of the frame get no PNG (still listed in
# plan.json as skipped). config.json "matte_min_coverage" overrides. 0.0002 of a
# 1920×1080 frame ≈ 415 px, a 20×20 patch.
MIN_COVERAGE = 0.0002


def _config():
    try:
        with open(os.path.join(os.path.dirname(HERE), "config.json"), encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def _safe(name):
    return "".join(ch if ch not in '<>:"/\\|?*' else "_" for ch in name).strip() or "Matte"


def _load_render(folder, spec):
    """All layers of one render (main or glass): {canonical key: chans}, crypto layers, header."""
    passes, crypto, header = {}, {}, {}
    raw = None      # the passes file's own main image (Corona's VFB dump: unexposed radiance)
    if not spec:
        return passes, crypto, header
    beauty = os.path.join(folder, spec["beauty"])
    if os.path.exists(beauty):
        layers, _ = exr.read_layers(beauty)
        if "" in layers or "RGBA" in layers:
            passes["beauty"] = layers.get("", layers.get("RGBA"))
    for rel in spec["passes"]:
        path = os.path.join(folder, rel)
        if not os.path.exists(path):
            # V-Ray stamps a frame number on its raw file (passes.0000.exr).
            stem, ext = os.path.splitext(path)
            numbered = sorted(glob.glob(glob.escape(stem) + ".[0-9]*" + ext))
            if not numbered:
                print(f"  ! missing pass file {rel} — its passes are left out")
                continue
            path = numbered[-1]
        layers, hdr = exr.read_layers(path)
        header.update(hdr)
        for layer, chans in layers.items():
            key = spec["layers"].get(layer)
            if not layer and key is None:
                # V-Ray's raw file: the main image, with Z-Depth as its Z channel.
                if "Z" in chans and "z" in spec["layers"].values():
                    passes.setdefault("z", {"R": chans["Z"]})
                # Corona's dump: single-channel elements are bare channels of the main layer.
                for ch, a in chans.items():
                    if spec["layers"].get(ch):
                        passes[spec["layers"][ch]] = {"R": a}
                if "R" in chans:
                    raw = chans
                continue
            if "R" not in chans and "X" in chans:   # V-Ray Normals: X/Y/Z channels
                chans = {"R": chans["X"], "G": chans.get("Y", chans["X"]), "B": chans.get("Z", chans["X"])}
            if key:
                passes[key] = chans
            else:
                crypto[layer] = chans
    if spec.get("raw_passes") and raw is not None and "beauty" in passes:
        # Corona's elements sum to its unexposed beauty; the saved beauty is that times the
        # camera exposure (2^-EV). Measure the factor and bring the shading passes to it.
        b, r = passes["beauty"]["R"], raw["R"]
        ok = r > 1e-6
        if ok.any():
            scale = float(np.median(b[ok] / r[ok]))
            for k, chans in passes.items():
                if k not in ("beauty", "normals", "z"):
                    passes[k] = {c: a * scale if c in "RGB" else a for c, a in chans.items()}
    return passes, crypto, header


def prepare(folder):
    t0 = time.time()
    with open(os.path.join(folder, "manifest.json"), encoding="utf-8") as f:
        man = json.load(f)
    with open(os.path.join(HERE, "recipes.json"), encoding="utf-8") as f:
        recipes = json.load(f)
    labels = recipes["labels"]
    out = os.path.join(folder, "ps")
    mdir = os.path.join(out, "mattes")
    shutil.rmtree(mdir, ignore_errors=True)
    os.makedirs(mdir)

    main, main_crypto, main_hdr = _load_render(folder, man["render"])
    glass, glass_crypto, glass_hdr = _load_render(folder, man.get("glass"))

    files = {}
    for key, chans in main.items():
        name = labels.get(key, key)
        exr.write_rgb(os.path.join(out, name + ".exr"), chans, half=False)
        files[key] = name + ".exr"
    glass_files = {}
    for key, chans in glass.items():
        name = labels.get(key, key) + " (Glass)"
        exr.write_rgb(os.path.join(out, name + ".exr"), chans, half=False)
        glass_files[key] = name + ".exr"

    # Mattes from Cryptomatte: every layer that shows, every material above the size
    # threshold. Layer/material PNGs are cropped to what they cover (offset in plan.json);
    # Glass stays full-frame (build.jsx uses it as a mask as-is).
    min_cov = _config().get("matte_min_coverage", MIN_COVERAGE)
    cryptos = {}
    mattes, skipped = [], 0
    for m in man["mattes"]:
        is_glass = m.get("source") == "glass"
        spec = man["glass"] if is_glass else man["render"]
        if not spec:
            continue
        layer = spec["crypto"][m["kind"]]
        if (is_glass, layer) not in cryptos:
            cryptos[is_glass, layer] = exr.Crypto(glass_crypto if is_glass else main_crypto,
                                                  glass_hdr if is_glass else main_hdr, layer)
        crypto = cryptos[is_glass, layer]
        cut = crypto.cut(m["ids"]) if crypto.ok else None
        if cut is None:
            continue
        group = m.get("group", "glass" if is_glass else m["kind"])
        entry = {"name": m["name"], "kind": m["kind"], "group": group, "glass": is_glass,
                 "coverage": round(cut[2], 6)}
        if group == "material" and cut[2] < min_cov:
            entry["skipped"] = "tiny"
            mattes.append(entry)
            skipped += 1
            continue
        sub = {"layer": "layers/", "material": "materials/"}.get(group, "")
        os.makedirs(os.path.join(mdir, sub), exist_ok=True)
        fname = sub + _safe(m["name"].replace("/", " - ")) + ".png"
        if sub:
            exr.write_mask_png(os.path.join(mdir, fname), cut[0])
            entry["offset"] = list(cut[1])
        else:
            exr.write_mask_png(os.path.join(mdir, fname), crypto.full(cut))
        entry["file"] = "mattes/" + fname
        mattes.append(entry)

    # Id maps for ../bin/psmatte's hover/click picking: per pixel, the index in plan.json
    # `mattes` of the material / Max layer covering most of it (uint16 LE, W×H, 0xFFFF =
    # none). A layer pixel goes to the DEEPEST layer owning its object.
    idmaps = {}
    for kind, group in (("material", "material"), ("object", "layer")):
        crypto = cryptos.get((False, man["render"]["crypto"].get(kind))) if man["render"] else None
        if not crypto or not crypto.ok:
            continue
        owner, depth = {}, {}
        src = {m["name"]: m for m in man["mattes"] if m.get("source") != "glass"}
        for i, e in enumerate(mattes):
            if e["group"] != group or e.get("skipped") or e["name"] not in src:
                continue
            d = e["name"].count("/")
            for n in src[e["name"]]["ids"]:
                k = crypto.key(n)
                if k not in owner or d > depth[k]:
                    owner[k], depth[k] = i, d
        m = crypto.dominant(owner)
        if group == "material":
            g = next((i for i, e in enumerate(mattes) if e["glass"] and e.get("file")), None)
            if g is not None:
                gm = cryptos.get((True, man["glass"]["crypto"]["object"])) if man.get("glass") else None
                cut = gm.cut(next(x["ids"] for x in man["mattes"] if x["name"] == mattes[g]["name"])) if gm and gm.ok else None
                if cut is not None:
                    m[gm.full(cut) >= 0.5] = g
        fname = f"mattes/ids_{group}.u16"
        m.astype("<u2").tofile(os.path.join(out, fname))
        idmaps[group] = fname

    # Facing-direction mattes from the normals (the old "World Normals ± x/y/z" group).
    n = main.get("normals")
    if n is not None and all(c in n for c in "RGB"):
        for axis, c in (("X", "R"), ("Y", "G"), ("Z", "B")):
            for sign, s in (("+", 1.0), ("-", -1.0)):
                cov = np.clip(s * n[c], 0, 1)
                if cov.any():
                    fname = f"Facing {sign}{axis}.png"
                    exr.write_mask_png(os.path.join(mdir, fname), cov)
                    mattes.append({"name": f"Facing {sign}{axis}", "file": "mattes/" + fname,
                                   "kind": "facing", "group": "facing", "glass": False})

    def resolve(nodes):
        res = []
        for node in nodes:
            node = dict(node)
            if "pass" in node:
                if node["pass"] not in files:
                    continue
                node["file"] = files[node["pass"]]
                node["name"] = node.get("name", labels.get(node["pass"], node["pass"]))
            elif "glass" in node:
                if node["glass"] not in glass_files:
                    continue
                node["file"] = glass_files[node["glass"]]
                node["mask"] = next((m["file"] for m in mattes if m["glass"]), None)
            elif "group" in node:
                node["children"] = resolve(node.get("children", []))
                if not node["children"] and not node.get("keep"):
                    continue
            res.append(node)
        return res

    stack = resolve(recipes["common_top"] + recipes.get(man["recipe"], []) + recipes["common_bottom"])
    plan = {
        "name": f'{man["view"]}', "width": man["width"], "height": man["height"],
        "bit_depth": man.get("bit_depth", 32), "folder": out, "stack": stack, "mattes": mattes,
        "idmaps": idmaps,
        "psb": os.path.join(folder, f'{_safe(man["view"])}.psb'),
    }
    with open(os.path.join(out, "plan.json"), "w", encoding="utf-8") as f:
        json.dump(plan, f, indent=1)
    print(f"prepared {len(files)} passes, {len(glass_files)} glass, {len(mattes) - skipped} mattes "
          f"({skipped} tiny skipped) in {time.time() - t0:.1f} s → {out}")
    return plan


if __name__ == "__main__":
    prepare(sys.argv[1])
