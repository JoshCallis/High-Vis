"""The Browser's own groups (Fusion's folders) — Max layers are never used or shown.

Other people's scenes keep their layer system untouched; the Browser draws only these.
Measured 2026-10-13 (8000 boxes): hiding them node by node costs ~90 ms against ~35 ms
for a layer, lost under the redraw (0.5–1.4 s) — so no layers. The real cost was our
own per-node nodeHide callbacks (~0.8 s), which every bulk change here mutes (quiet()).

  the tree        rootNode custom attribute callisGroups (a JSON string, so it is part of
                  the undo record of whatever changes it):
                  {"g": {id: {"name", "parent" (id, "" = the top), "hidden",
                               "hid": [handles this group hid],
                               "render": shown while rendering (render_shown)}},
                   "rv": the maxstart defaults were applied (maxstart.mark_render)}
  membership      user property "callis_group" = id on a top-level node (undoable, copied
                  with clones and merges). Group members and linked children belong where
                  their top node does. No property, or an id that isn't in the tree = the top.
  hiding          a hidden group hides every node in it that was showing and lists it in
                  the INNERMOST hidden group around that node (its "hid"), so showing a
                  group puts back exactly what it hid, a node you hid yourself stays
                  hidden, and nested hidden groups hand their nodes on (refit()).
"""
import json
import random
import time

from pymxs import runtime as rt

PROP = "callis_group"
_CA_NAME = "callisGroups"
_CA_DEF = """
attributes %s attribID:#(0x3c1a5e11, 0x6b2d9f12)
(
    parameters main ( groupsJson type:#string default:"" )
)
""" % _CA_NAME

_MS = r"""
fn callisGid n = (
    local r = n
    while r.parent != undefined do r = r.parent
    local v = getUserProp r "callis_group"
    if v == undefined then "" else v as string
)
fn callisGroupIndex = for o in objects collect #(o.inode.handle, callisGid o, o.parent == undefined, o.name)
fn callisVisibleOf hs = for h in hs where (local n = maxOps.getNodeByHandle h; n != undefined and not n.isHidden) collect h
fn callisHiddenOf hs = for h in hs where (local n = maxOps.getNodeByHandle h; n != undefined and n.isHidden) collect h
fn callisSetHidden hs state = (
    local a = for h in hs where (local n = maxOps.getNodeByHandle h; n != undefined) collect n
    if state then hide a else unhide a
    a.count
)
fn callisNodesOf hs = for h in hs where (local n = maxOps.getNodeByHandle h; n != undefined and not n.isHidden and not n.isFrozen) collect n
"""
_ms_done = []
_cache = ["", {"g": {}}]


def ms():
    if not _ms_done:
        rt.execute(_MS)
        _ms_done.append(1)


# ──────────────────────────────────────────────────────────────── the tree

def _ca():
    for i in range(1, rt.custAttributes.count(rt.rootNode) + 1):
        ca = rt.custAttributes.get(rt.rootNode, i)
        if str(rt.custAttributes.getDef(ca).name) == _CA_NAME:
            return ca
    return None


def load():
    """The scene's tree (cached while the stored string is unchanged — undo changes it)."""
    ca = _ca()
    raw = str(ca.groupsJson) if ca is not None else ""
    if raw != _cache[0]:
        try:
            d = json.loads(raw) if raw else {}
        except ValueError:
            d = {}
        d.setdefault("g", {})
        _cache[:] = [raw, d]
    return _cache[1]


def save(d):
    """Part of the caller's undo record, if one is open."""
    ca = _ca()
    if ca is None:
        rt.custAttributes.add(rt.rootNode, rt.execute(_CA_DEF))
        ca = _ca()
    raw = json.dumps(d)
    ca.groupsJson = raw
    _cache[:] = [raw, d]


def exists():
    return _ca() is not None and bool(load()["g"])


def new_id():
    return "g%s%s" % (format(int(time.time() * 1000), "x")[-7:],
                      "".join(random.choice("abcdefghijklmnopqrstuvwxyz") for _ in range(3)))


def add(d, name, parent="", render=False):
    gid = new_id()
    d["g"][gid] = {"name": name, "parent": parent or "", "hidden": False, "hid": []}
    if render:
        d["g"][gid]["render"] = True
    return gid


def valid(d, gid):
    return gid if gid and gid in d["g"] else ""


def parent(d, gid):
    g = d["g"].get(gid)
    return valid(d, g["parent"]) if g else ""


def children(d, pid):
    """The groups directly inside pid ("" = the top), by name."""
    pid = pid or ""
    kids = [k for k, g in d["g"].items() if valid(d, g.get("parent", "")) == pid]
    return sorted(kids, key=lambda k: d["g"][k]["name"].lower())


def chain(d, gid):
    """Top-level group … gid (empty for the top)."""
    out = []
    while gid and gid not in out:
        out.insert(0, gid)
        gid = parent(d, gid)
    return out


def subtree(d, gid):
    out = {gid}
    for k in children(d, gid):
        out |= subtree(d, k)
    return out


def inside(d, gid, anc):
    """gid is anc or somewhere inside it ("" anc = everything)."""
    return not anc or anc in chain(d, gid)


# ──────────────────────────────────────────────────────────────── membership

class Index:
    """One MAXScript call: every node's handle → its group, and each group's top-level
    nodes as (name, handle)."""

    def __init__(self, d):
        ms()
        self.gid, self.tops = {}, {}
        for h, g, top, name in rt.callisGroupIndex():
            g = valid(d, str(g))
            self.gid[int(h)] = g
            if top:
                self.tops.setdefault(g, []).append((str(name).lower(), int(h)))
        for v in self.tops.values():
            v.sort()

    def handles_in(self, gids):
        """Every node (children too) in these groups."""
        return [h for h, g in self.gid.items() if g in gids]


def stamp(n, gid):
    rt.setUserProp(n, PROP, gid or "")


# ──────────────────────────────────────────────────────────────── hiding

class quiet:
    """Bulk hides without the Browser's per-node nodeHide/nodeUnhide callbacks (~0.1 ms
    each — 0.8 s for 8000 nodes); the caller publishes once afterwards. events: other
    Browser structure callbacks to mute instead (the move tool's nodeFreeze/nodeUnfreeze)."""
    EVENTS = ("nodeHide", "nodeUnhide")

    def __init__(self, events=None):
        if events:
            self.EVENTS = tuple(events)

    def __enter__(self):
        for ev in self.EVENTS:
            rt.callbacks.removeScripts(rt.Name(ev), id=rt.Name("callisBrowser"))
        return self

    def __exit__(self, *exc):
        from . import browser
        for ev in self.EVENTS:
            rt.callbacks.addScript(rt.Name(ev), browser._structure_changed, id=rt.Name("callisBrowser"))
        return False


def _innermost_hidden(d, gid):
    for g in reversed(chain(d, gid)):
        if d["g"][g].get("hidden"):
            return g
    return ""


def refit(d, idx, handles, take=()):
    """Bring these nodes in line with their groups' hidden flags: hidden by the innermost
    hidden group around them (listed in its "hid"), or shown again if a group hid them
    and none does now. `take`: handles hidden by something else of ours (isolate) that a
    hiding group may adopt. Returns (handles now hidden, handles now shown)."""
    ms()
    owner = {}
    for k, g in d["g"].items():
        for h in g.get("hid", []):
            owner[int(h)] = k
    take = set(take)
    hide_cand, unhide, moved = [], [], {}
    for h in handles:
        want = _innermost_hidden(d, idx.gid.get(h, ""))
        have = owner.get(h, "")
        if want == have:
            continue
        if have:
            d["g"][have]["hid"] = [x for x in d["g"][have]["hid"] if int(x) != h]
        if want:
            if have:
                moved.setdefault(want, []).append(h)       # already hidden: hand it on
            else:
                hide_cand.append((h, want))
        else:
            unhide.append(h)
    for want, hs in moved.items():
        d["g"][want]["hid"] += hs
    hidden = []
    if hide_cand:
        vis = {int(h) for h in rt.callisVisibleOf([h for h, _ in hide_cand])}
        for h, want in hide_cand:
            if h in vis or h in take:
                d["g"][want]["hid"].append(h)
                hidden.append(h)
    shown = [int(h) for h in rt.callisHiddenOf(unhide)] if unhide else []
    with quiet():
        if hidden:
            rt.callisSetHidden(hidden, True)
        if shown:
            rt.callisSetHidden(shown, False)
    return hidden, shown


def set_hidden(d, idx, gid, hide, take=()):
    g = d["g"].get(gid)
    if g is None or bool(g.get("hidden")) == hide:
        return [], []
    g["hidden"] = hide
    return refit(d, idx, idx.handles_in(subtree(d, gid)), take)


def remove(d, idx, gid):
    """Delete a group; what was in it (groups and objects) goes to its parent."""
    if gid not in d["g"]:
        return
    up = parent(d, gid)
    for k in children(d, gid):
        d["g"][k]["parent"] = up
    for _, h in idx.tops.get(gid, []):
        n = rt.maxOps.getNodeByHandle(h)
        if n is not None and str(n) != "undefined":
            stamp(n, up)
    hs = idx.handles_in(subtree(d, gid))
    del d["g"][gid]
    for h in hs:
        if idx.gid.get(h) == gid:
            idx.gid[h] = up
    refit(d, idx, hs)


def build(tree, d=None, top=""):
    """[{"name", "render", "kids": [...]}] → groups (maxstart's tree)."""
    d = d if d is not None else load()
    for n in tree:
        gid = add(d, n["name"], top, n.get("render", False))
        build(n.get("kids", []), d, gid)
    return d
