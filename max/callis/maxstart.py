"""The folder tree every new scene starts with: max/maxstart/layers.json, built as the
Browser's own folders (callis/groups.py) — no Max layers. `ensure()` runs at startup and
on File ▸ New / Reset (startup.py) and fills an EMPTY scene that has no folders yet; a
scene that already has objects (someone else's) is left as it came.

layers.json is a hand-editable nested list: [{"name": "Geometry", "render": true,
"kids": [...]}]. Folder names needn't be unique. "render": the folder's Show When
Rendering tick (browser.render_shown) — the old maxstart's " —" layers.
`mark_render()` ticks those once in a scene built before the tick existed.

There is no maxstart.max any more (it carried the tree as layers); `retire_file()`
renames an old one aside so Max stops loading it.
"""
import json
import os

import pymxs
from pymxs import runtime as rt

from . import groups

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TREE = os.path.join(HERE, "maxstart", "layers.json")


def load():
    with open(TREE, encoding="utf-8") as f:
        return json.load(f)


def build():
    """The tree as folders (whatever else is in the scene stays)."""
    d = groups.load()
    groups.build(load(), d)
    d["rv"] = 1
    with pymxs.undo(False):
        groups.save(d)


def ensure(*_):
    """An empty scene with no folders gets the tree."""
    try:
        if int(rt.objects.count) == 0 and not groups.exists():
            build()
            rt.setSaveRequired(False)
    except Exception as e:
        print("[callis.maxstart] tree not built:", e)


def _ticked(tree, at=()):
    for n in tree:
        p = at + (n["name"],)
        if n.get("render"):
            yield p
        yield from _ticked(n.get("kids", []), p)


def mark_render():
    """Once per scene: folders at a ticked layers.json path get Show When Rendering.
    Scenes built from this tree before the tick existed; a scene that has had it is
    left alone (your own unticks stay). True if anything was written."""
    d = groups.load()
    if not d["g"] or d.get("rv"):
        return False
    want = set(_ticked(load()))
    for gid, g in d["g"].items():
        if tuple(d["g"][k]["name"] for k in groups.chain(d, gid)) in want:
            g["render"] = True
    d["rv"] = 1
    with pymxs.undo(False):
        groups.save(d)
    return True


def path():
    return os.path.join(str(rt.getDir(rt.Name("scene"))), "maxstart.max")


def retire_file():
    """maxstart.max (the layer tree, from before folders) → maxstart.max.layers."""
    f = path()
    if os.path.exists(f):
        os.replace(f, f + ".layers")
        return f + ".layers"
    return None
