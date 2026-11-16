"""Paste a region re-render into the full render it belongs to.

    .venv/bin/python -m compose.patch "<render folder>"

Max's "Region only" writes <folder>/_region/ — the same files as a full render
(beauty.exr, passes.exr, glass/…) plus region.json {rect: [l, t, r, b]} with
right/bottom exclusive. Every EXR there is pasted into its namesake in <folder>
over exactly that rect: Arnold writes beauty full-frame (black outside the
region) but the passes with a data window of just the region, so the source
offset comes from each file's own data window, never from assuming either.

The files replaced are kept in _previous_region/ (one level of undo); the patch
is logged into manifest.json["patches"].
"""
import json
import os
import shutil
import sys
import time

import OpenEXR

REGION_DIR = "_region"
PREVIOUS = "_previous_region"


def _paste(src_path, dst_path, rect):
    """Paste rect from src into dst, every channel of every part. Returns the
    channels that couldn't be matched (missing in dst) — reported, not fatal."""
    l, t, r, b = rect
    src = OpenEXR.File(src_path, separate_channels=True)
    dst = OpenEXR.File(dst_path, separate_channels=True)
    dst_parts = {p.name: p for p in dst.parts}
    missing = []
    for sp in src.parts:
        dp = dst_parts.get(sp.name) or (dst.parts[0] if len(dst.parts) == 1 else None)
        if dp is None:
            missing.append(f"part {sp.name}")
            continue
        (sx0, sy0), (sx1, sy1) = sp.header["dataWindow"]
        (dx0, dy0), _ = dp.header["dataWindow"]
        # The rect clipped to what the source actually holds.
        cl, ct = max(l, int(sx0)), max(t, int(sy0))
        cr, cb = min(r, int(sx1) + 1), min(b, int(sy1) + 1)
        if cr <= cl or cb <= ct:
            continue
        for name, ch in sp.channels.items():
            target = dp.channels.get(name)
            if target is None:
                missing.append(name)
                continue
            target.pixels[ct - dy0:cb - dy0, cl - dx0:cr - dx0] = \
                ch.pixels[ct - sy0:cb - sy0, cl - sx0:cr - sx0].astype(target.pixels.dtype)
    tmp = dst_path + ".patching.exr"
    dst.write(tmp)
    os.replace(tmp, dst_path)
    return missing


def patch(folder):
    """Apply <folder>/_region to <folder>. Returns a one-line summary; raises if
    there's nothing to patch or the sizes don't match."""
    t0 = time.time()
    rdir = os.path.join(folder, REGION_DIR)
    with open(os.path.join(rdir, "region.json"), encoding="utf-8") as f:
        region = json.load(f)
    man_path = os.path.join(folder, "manifest.json")
    with open(man_path, encoding="utf-8") as f:
        man = json.load(f)
    if (man["width"], man["height"]) != (region["width"], region["height"]):
        raise RuntimeError(f'region is {region["width"]}×{region["height"]} but the render is '
                           f'{man["width"]}×{man["height"]} — re-render the full view')
    rect = region["rect"]

    pairs = []
    for dirpath, _, names in os.walk(rdir):
        for n in names:
            if n.lower().endswith(".exr"):
                src = os.path.join(dirpath, n)
                rel = os.path.relpath(src, rdir)
                pairs.append((src, rel, os.path.join(folder, rel)))
    prev = os.path.join(folder, PREVIOUS)
    if os.path.isdir(prev):
        shutil.rmtree(prev)
    warnings, patched = [], []
    for src, rel, dst in pairs:
        if not os.path.exists(dst):
            warnings.append(f"{rel}: not in the full render — skipped")
            continue
        os.makedirs(os.path.dirname(os.path.join(prev, rel)), exist_ok=True)
        shutil.copy2(dst, os.path.join(prev, rel))
        missing = _paste(src, dst, rect)
        if missing:
            warnings.append(f"{rel}: {len(missing)} channel(s) not in the full render: {', '.join(missing[:5])}")
        patched.append(rel)

    man.setdefault("patches", []).append({"rect": rect, "files": patched, "rendered": region.get("rendered"),
                                          "patched": time.strftime("%Y-%m-%d %H:%M:%S"), "warnings": warnings})
    with open(man_path, "w", encoding="utf-8") as f:
        json.dump(man, f, indent=1)
    shutil.rmtree(rdir)
    summary = (f"patched {len(patched)} file(s) at {rect} in {time.time() - t0:.1f} s"
               + "".join("\n  ! " + w for w in warnings))
    print(summary)
    return summary


def undo(folder):
    """Put the files from before the last patch back."""
    prev = os.path.join(folder, PREVIOUS)
    for dirpath, _, names in os.walk(prev):
        for n in names:
            src = os.path.join(dirpath, n)
            shutil.move(src, os.path.join(folder, os.path.relpath(src, prev)))
    shutil.rmtree(prev, ignore_errors=True)
    man_path = os.path.join(folder, "manifest.json")
    with open(man_path, encoding="utf-8") as f:
        man = json.load(f)
    if man.get("patches"):
        man["patches"].pop()
    with open(man_path, "w", encoding="utf-8") as f:
        json.dump(man, f, indent=1)


if __name__ == "__main__":
    (undo if "--undo" in sys.argv else patch)(sys.argv[1])
