"""Jump to Name for Max — the rows the Mac's jump box (jump/, port 8741) ranks, and the
jump itself, made the way the Browser's own navigation makes it (callis/browser.py).

  rows()     every Browser folder and object: {id, name, group, kind, shot}
  go(tok)    G:<gid> → entered (browser._enter, F on a folder: isolate follows);
             N:<handle> → browser.toward (the Browser's Go to Bottom onto it)

`shot` lets the box pick the current shot's one of several near-identical objects (a
camera / light per shot): 1 = the current shot's camera or one of its only-in-shot
objects, -1 = another shot's, 0 = every shot's.

Called over the bridge by jump/server.py:
    import callis.jump as J; _result = J.rows()
"""
from pymxs import runtime as rt

from . import browser as B
from . import groups as G


def _shots():
    """{handle: 1 | -1} — the current shot's objects, and the other shots'."""
    from . import cameras, ui
    try:
        p = ui.project()
    except Exception:
        return {}
    cur = cameras.current_shot(p)
    out = {}
    for v in p.views:
        mark = 1 if cur is not None and v.id == cur.id else -1
        for h in ([v.camera] if v.camera else []) + list(v.only_objects or []):
            if out.get(int(h)) != 1:
                out[int(h)] = mark
    return out


def rows():
    d = G.load()
    path = {}

    def where(gid):
        if gid not in path:
            path[gid] = " / ".join(d["g"][g]["name"] for g in G.chain(d, gid) if g in d["g"])
        return path[gid]

    out = []
    for gid, g in d["g"].items():
        parent = G.parent(d, gid)
        out.append({"id": B._gtok(gid), "name": g["name"], "kind": "folder",
                    "group": where(parent) if parent else ""})
    shots = _shots()
    idx = B._idx()
    for n in rt.objects:
        if rt.classOf(n) == rt.Targetobject:
            continue
        h = int(n.inode.handle)
        gid = idx.gid.get(h, "")
        out.append({"id": "N:%d" % h, "name": str(n.name), "kind": B._kind(n),
                    "group": where(gid) if gid else "", "shot": shots.get(h, 0)})
    return out


def go(tok):
    try:
        B._sel_now()
        if tok.startswith("G:"):
            B._enter(tok[2:])
        else:
            n = B._node(tok)
            if n is None:
                return False
            B.toward(n, deep=True)
    finally:
        B.publish(now=True)
    return True
