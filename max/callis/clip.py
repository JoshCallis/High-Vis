"""Copy / Paste for Max (macros `Copy`, `Paste`, category "Callis Modeling"; the Browser's
⌘C / ⌘V and its Cut / Paste keys come here too). One clipboard, the LAST action wins:

  copy   the selection (closed groups whole, linked children with their parents), or the
         folders the Browser picked (each with everything filed in it). Nothing is written:
         the copies are cloned at the paste (maxOps.cloneNodes — no file round trip, which
         the 2017 Copy / Paste did with saveNodes / mergeMaxFile). Only when the originals
         would go away — one is deleted, a file opens, New / Reset — are they saved to
         %TEMP%\\callis_clip.max first, and the paste merges that instead.
  paste  after a copy: the copies come in on the cursor, carried by the Move tool
         (snaps, F ortho, arrows, a typed distance all work); a click places them, Esc
         drops them. One undo step. Copied folders come back as new folders beside the
         originals (at the top in another scene).
         After a Browser cut: the Browser's own paste — the cut rows re-filed into the
         paste target, nothing moves in the viewport (Fusion's cut / paste).
"""
import os
import tempfile

import pymxs
from pymxs import runtime as rt

from . import hud

FILE = os.path.join(tempfile.gettempdir(), "callis_clip.max")
CB = "callisClip"

# kind: None / "copy" / "cut"; handles: what a copy clones; folders: {gid: (name, parent)}
# of copied folders, tops: the copied folders themselves; file: the saved snapshot
_c = {"kind": None, "handles": [], "folders": {}, "tops": [], "file": None}


def _undef(v):
    return v is None or str(v) == "undefined"


def _h(n):
    return int(n.inode.handle)


def _node(h):
    n = rt.maxOps.getNodeByHandle(h)
    return None if _undef(n) else n


def _with_children(nodes):
    out, todo = {}, list(nodes)
    while todo:
        n = todo.pop()
        if _h(n) in out:
            continue
        out[_h(n)] = n
        todo += list(n.children)
    return list(out.values())


# ──────────────────────────────────────────────────────────────── copy / cut

def copy():
    """Copy: the Browser's picked folders, else the selection."""
    from . import browser as B, groups as G
    d = G.load()
    picks = B._picks() or []
    gids = [t[2:] for t in picks if t.startswith("G:") and t[2:] in d["g"]]
    gids = [g for g in gids if not any(o != g and G.inside(d, g, o) for o in gids)]
    folders, nodes = {}, []
    if gids:
        sub = set()
        for g in gids:
            sub |= G.subtree(d, g)
        folders = {g: (d["g"][g]["name"], d["g"][g].get("parent", "")) for g in sub}
        nodes = [n for n in map(_node, B._idx().handles_in(sub)) if n is not None]
        nodes += [n for t in picks if not t.startswith("G:") for n in B._nodes_of(t)]
    else:
        nodes = list(rt.selection)
    nodes = _with_children(nodes)
    if not nodes and not folders:
        hud.show("Nothing selected to copy", 1200)
        return
    _c.update(kind="copy", handles=[_h(n) for n in nodes], folders=folders, tops=gids, file=None)
    _watch(True)
    if B._v["cut"]:
        B.uncut()
        B.publish(now=True)
    hud.show("Copied " + (("%d folder%s" % (len(gids), "s" * (len(gids) > 1))) if gids
                          else nodes[0].name if len(nodes) == 1 else "%d objects" % len(nodes)), 1000)


def cut_marked():
    """The Browser's cut (browser.cut) — the next paste re-files it."""
    _c.update(kind="cut", handles=[], folders={}, tops=[], file=None)
    _watch(False)


# ──────────────────────────────────────────────────────────────── keeping a copy alive

def _watch(on):
    rt.callbacks.removeScripts(id=rt.Name(CB))
    if not on:
        return
    for ev, fn in (("nodePreDelete", "_pre_delete()"), ("filePreOpen", "snapshot()"),
                   ("systemPreNew", "snapshot()"), ("systemPreReset", "snapshot()")):
        rt.callbacks.addScript(rt.Name(ev), 'python.Execute "import callis.clip; callis.clip.%s"' % fn,
                               id=rt.Name(CB))


def _pre_delete():
    try:
        n = rt.callbacks.notificationParam()
        if not _undef(n) and _h(n) in _c["handles"]:
            snapshot()
    except Exception as e:
        print("[callis.clip]", e)


def snapshot():
    """The copied objects to FILE, before they can go away (once per copy)."""
    if _c["kind"] != "copy" or _c["file"]:
        return
    nodes = [n for n in map(_node, _c["handles"]) if n is not None]
    if not nodes:
        return
    try:
        rt.saveNodes(nodes, FILE, quiet=True)
        _c["file"] = FILE
        _watch(False)            # the file has them now: nothing more to watch
    except Exception as e:
        print("[callis.clip] snapshot:", e)


# ──────────────────────────────────────────────────────────────── paste

def paste():
    """Paste: the last copy onto the cursor, or the Browser's cut re-filed."""
    from . import browser as B
    if _c["kind"] == "cut" or (_c["kind"] is None and B._v["cut"]):
        try:
            B._undoable("Browser Move", B.paste)
        except ValueError as e:
            hud.show(str(e), 1500)
        B.publish(now=True)
        return
    if _c["kind"] != "copy":
        hud.show("Nothing copied", 1200)
        return
    with pymxs.undo(False):
        nodes = _make(preview=True)
    if not nodes:
        hud.show("The copied objects are gone", 1500)
        _c["kind"] = None
        return
    from . import movetool
    movetool.start_placing(nodes, lambda: _make(preview=False))


def _make(preview):
    """The copies: clones of the originals, or the snapshot merged. preview: no folders
    made (the preview copies are deleted again; the real ones are made in the undo step)."""
    from . import movetool
    movetool._ms()                                   # callisMvClone
    src = [n for n in map(_node, _c["handles"]) if n is not None]
    if _c["file"] or len(src) < len(_c["handles"]):
        if not _c["file"] or not os.path.exists(_c["file"]):
            return list(rt.callisMvClone(src, rt.Name("copy"))) if src else []
        before = {_h(n) for n in rt.objects}
        rt.mergeMaxFile(_c["file"], rt.Name("neverReparent"), rt.Name("mergeDups"),
                        rt.Name("useSceneMtlDups"), quiet=True)
        new = [n for n in rt.objects if _h(n) not in before]
        same_scene = False
    else:
        new = list(rt.callisMvClone(src, rt.Name("copy")))
        same_scene = True
    if not preview and _c["folders"]:
        _refold(new, same_scene)
    return new


def _refold(new, same_scene):
    """Copied folders → new folders (beside the originals, or at the top in another scene);
    each copy filed in its folder's twin."""
    from . import browser as B, groups as G
    d = G.load()
    fmap = {}
    def twin(gid):
        if gid in fmap:
            return fmap[gid]
        name, parent = _c["folders"][gid]
        if gid in _c["tops"]:
            up = G.valid(d, parent) if same_scene else ""
        else:
            up = twin(parent)
        fmap[gid] = G.add(d, name, up)
        return fmap[gid]
    for g in _c["folders"]:
        twin(g)
    for n in new:
        g = rt.getUserProp(n, G.PROP)
        g = "" if _undef(g) else str(g)
        if g in fmap and _undef(n.parent):
            G.stamp(n, fmap[g])
    B._refile(d, set(fmap.values()) | {G.parent(d, g) for g in fmap.values()})
