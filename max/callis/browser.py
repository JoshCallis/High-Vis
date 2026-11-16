"""The Browser for Max: a Fusion-style tree of folders and objects, each object's
modifier stack inside it, drawn on the Mac by max_browser/ (port 8740).

MAX OWNS EVERYTHING — the tree, where you are (the entered folder), what is open, the
cursor. So the browser's keys are ordinary Max hotkeys (macroScripts "Callis Browser",
→ key()) that act at once inside Max, and the Mac page is only a renderer:
  Max → Mac  publish(): .state/browser.json, rewritten ~50 ms after any scene or
             selection change and after every key. The Mac server long-polls its mtime.
  Mac → Max  max_browser/server.py → bridge → act({...}) for clicks, renames, menus.

The Fusion browser, translated:
  component / folder   → folder: the Browser's OWN groups (callis/groups.py), never Max
                         layers — a scene's layers are left exactly as they came and never
                         shown. F or a click enters a folder (it becomes the top row) and
                         new objects land in it; D goes back out. Hiding a folder hides
                         what's in it. A click selects nothing; ⌘ / Space-click selects
                         everything in it, folders inside too (hidden and frozen left
                         out); ⇧ a range.
  body / sketch        → object (geometry / shape), coloured as Fusion colours them.
  body group           → a Max group (§ groups): amber; a click on any part selects the
                         whole group; Go In opens it so its parts pick one by one.
  (an object's own)    → an object with linked children: F or a click opens it.
                         Empty → "(Name)", as is an empty folder.
  Operations (features) → the object's settings: F or a click opens them inside the row,
                         top modifier first, base object last (always there). C/R step onto
                         one and make it current in the Modify panel; F on one
                         shows / hides the command panel to edit it.
  —                     → instances: one definition row per set of full instances, its
                         settings + an "Instances" group of numbered rows (§ Instances).
Viewport taps and clicks navigate as Fusion's Click Actions (§ the viewport's gestures).
Keys (hotkeys/Callis.hsx, Control Room ▸ 3ds Max ▸ Shortcuts): R up, C down, F in,
D out, ⇧F in deep, ⇧R / ⇧C top / bottom of the level, A deselect, ⌃E hide/show,
⌃R rename, ⌃G New Component (a folder), ⌘⇧G New Group, ⌃X cut, ⌃V paste, ⇧⌥F isolate.

root None = the scene's top: objects in no folder (everything in someone else's scene,
until it's sorted) sit there. maxstart.py gives a new scene the user's folder tree.
"""
import json
import os
import time

from pymxs import runtime as rt

from . import groups as G

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STATE = os.path.join(HERE, ".state", "browser.json")

# Where you are. Max-side, in memory: the page never holds any of it.
_v = {"root": None, "open": set(), "cursor": None, "doc": None,
      "shut": False,       # the entered folder's top row folded (a click on it)
      "cut": [],           # tokens waiting for a paste (⌘X)
      "picks": None,       # (row toks, selection count) — a ⌘ / ⇧ / Space pick (_picks)
      "anchor": None,      # where a ⇧-click measures from: the last row clicked without ⇧
      "rename": None,      # {"tok", "n"}: the page opens a name field on it (New Folder)
      "opened": [],        # handles of the Max groups Go In opened, outermost first
      "pending": None,     # row toks a nav key will select once the Browser has drawn (_sel_soon)
      "hide": None}        # KINDS left out of the tree (the row menu's ticks; _load_hidden)
_index = None          # groups.Index: handle → folder, folder → top-level nodes
_own_sel = [0.0]       # time of our own last selection change (its echo moves nothing)
_selecting = [False]   # inside _select: its own change doesn't cancel a pending pick


# ──────────────────────────────────────────────────────────────── the scene

def _undef(v):
    return v is None or str(v) == "undefined"


def _root():
    """The entered folder's id, "" at the top (and when it went away)."""
    gid = G.valid(G.load(), _v["root"] or "")
    if not gid:
        _v["root"] = None
    return gid


def _gtok(gid):
    return "G:" + gid


def _idx():
    global _index
    if _index is None:
        _index = G.Index(G.load())
    return _index


def _objects_on(gid):
    """The top-level objects in folder gid ("" = the top), by name."""
    out = []
    for _, h in _idx().tops.get(gid or "", []):
        n = rt.maxOps.getNodeByHandle(h)
        if not _undef(n):
            out.append(n)
    return out


def _gid(n):
    """n's folder ("" = the top)."""
    return _idx().gid.get(int(n.inode.handle), "")


def _layer_hidden(n):
    """n is hidden by its Max layer (someone else's layer system — never shown)."""
    lay = n.layer
    while not _undef(lay):
        if bool(lay.ishidden):
            return True
        lay = lay.getParent()
    return False


def _node(tok):
    if not tok or not tok.startswith("N:"):
        return None
    n = rt.maxOps.getNodeByHandle(int(tok[2:]))
    return None if _undef(n) else n


def _tok(n):
    return "N:%d" % int(n.inode.handle)


def _kind(n):
    if rt.isGroupHead(n):
        return "group"
    sc = rt.superClassOf(n)
    if rt.classOf(n) == rt.Targetobject:          # camera/light targets are "geometry" to Max
        return "aux"
    if sc == rt.GeometryClass:
        return "body"
    if sc == rt.shape:
        return "shape"
    if sc in (rt.light, rt.camera, rt.helper):
        return "aux"
    return "other"


# What the tree shows — Fusion's view filters (its menu's Sketches, Bodies…): a kind
# unticked in the row menu drops out of the TREE only, the viewport is untouched. What's
# linked under a dropped object moves up into its place. Kept per user, not per scene.
VIEW = os.path.join(HERE, ".state", "browser_view.json")
KINDS = ("targets", "helpers", "splines")
# Two more of the menu's ticks, kept in the same set: "empty" = Hide Empty Groups (a
# component or group with nothing in the tree, or only such ones, drops out); "root" =
# the entered folder's own top row is left off (its contents start at the top).
OPTS = KINDS + ("empty", "root")


def _load_hidden():
    try:
        with open(VIEW) as f:
            return set(json.load(f).get("hide", [])) & set(OPTS)
    except (OSError, ValueError):
        return set()


_v["hide"] = _load_hidden()


def toggle_kind(kind):
    if kind not in OPTS:
        return
    _v["hide"].symmetric_difference_update({kind})
    try:
        with open(VIEW, "w") as f:
            json.dump({"hide": sorted(_v["hide"])}, f)
    except OSError:
        pass


def _category(n):
    """Which of KINDS an object is, if any (a group head is a dummy, never a helper)."""
    if rt.classOf(n) == rt.Targetobject:
        return "targets"
    if rt.isGroupHead(n):
        return None
    sc = rt.superClassOf(n)
    if sc == rt.helper:
        return "helpers"
    if sc == rt.shape:
        return "splines"
    return None


def _shown(nodes):
    """`nodes` as the tree lists them: a hidden kind's object gives way to its children."""
    hide = _v["hide"]
    if not hide:
        return list(nodes)
    out = []
    for n in nodes:
        if _category(n) in hide:
            out.extend(_shown(n.children))
        else:
            out.append(n)
    return out


def _stack(n):
    """The object's settings: its modifier stack top-down, then the base object — Max's
    own order. The base row is there even with no modifiers, so a lone light or box opens
    to its settings; a group head (a dummy) has none."""
    out = []
    if rt.isGroupHead(n):
        return out
    mods = list(n.modifiers)
    for i, m in enumerate(mods):
        out.append({"tok": "M:%d:%d" % (int(n.inode.handle), i), "name": str(m.name),
                    "off": not bool(m.enabled), "kind": "mod"})
    out.append({"tok": "M:%d:base" % int(n.inode.handle), "kind": "base",
                "name": str(rt.classOf(n.baseObject)).replace("_", " "), "off": False})
    return out


def _stack_item(tok):
    """'M:<handle>:<i|base>' → (node, modifier or base object)."""
    _, h, i = tok.split(":")
    n = rt.maxOps.getNodeByHandle(int(h))
    if _undef(n):
        return None, None
    if i == "base":
        return n, n.baseObject
    mods = list(n.modifiers)
    return (n, mods[int(i)]) if int(i) < len(mods) else (n, None)


# Instances. Nodes that are full instances (the same base object AND the same modifiers)
# are one DEFINITION: one row ("D:<first handle>:<place>") holding the shared settings and
# an "Instances" group ("I:…") with a row per instance, numbered 1, 2, … in creation order
# (handle order) across the whole scene. A definition shows wherever it has instances —
# its place is "G<folder>" (top level of a folder) or "N<handle>" (children of a node) —
# and lists only the instances there; the numbers stay global.
_MS_INST = """
fn callisInstKeys = (
    for o in objects collect (
        local k = (getHandleByAnim o.baseObject) as string
        for m in o.modifiers do k += "," + (getHandleByAnim m) as string
        #(o.inode.handle, k)
    )
)
"""
_ms_inst = []
_inst = None           # (handle → key, key → [handles] in creation order), rebuilt with _index
_DEF_NAME = 0x43414C32       # base-object AppData: the definition's name
_INST_NAME = 0x43414C33                    # node AppData: the name the user gave an instance


def _instances():
    global _inst
    if _inst is None:
        if not _ms_inst:
            rt.execute(_MS_INST)
            _ms_inst.append(1)
        keyof, fam = {}, {}
        for h, k in rt.callisInstKeys():
            keyof[int(h)] = str(k)
            fam.setdefault(str(k), []).append(int(h))
        for hs in fam.values():
            hs.sort()
        _inst = (keyof, fam)
    return _inst


def _family(n):
    """Every instance of n (n alone when it has none), creation order."""
    keyof, fam = _instances()
    hs = fam.get(keyof.get(int(n.inode.handle)), [])
    if len(hs) < 2:
        return [n]
    out = [rt.maxOps.getNodeByHandle(h) for h in hs]
    return [x for x in out if not _undef(x)]


def _number(n):
    keyof, fam = _instances()
    hs = fam.get(keyof.get(int(n.inode.handle)), [])
    h = int(n.inode.handle)
    return hs.index(h) + 1 if len(hs) > 1 and h in hs else 0


def _def_name(rep):
    try:
        v = rt.getAppData(rep.baseObject, _DEF_NAME)
    except Exception:
        v = None
    if not _undef(v) and str(v):
        return str(v)
    base = str(rep.name).rstrip("0123456789").rstrip(" _-")
    return base or str(rep.name)


def _inst_name(n, num):
    """An instance shows its number until it's named. The given name is kept in AppData
    and only counts while the node still has it: a clone copies AppData but gets a new
    name, so it shows its own number."""
    v = rt.getAppData(n, _INST_NAME)
    if not _undef(v) and str(v) and str(v) == str(n.name):
        return str(n.name)
    return str(num)


def _place(n):
    p = n.parent
    return "G" + _gid(n) if _undef(p) else "N%d" % int(p.inode.handle)


def _def_tok(kind, n):
    """'D:…' / 'I:…' for the definition n belongs to, at n's place."""
    return "%s:%d:%s" % (kind, int(_family(n)[0].inode.handle), _place(n))


def _here(tok):
    """'D:<h>:<place>' / 'I:…' → (that definition's instances at that place, all of them)."""
    _, h, place = tok.split(":", 2)
    rep = rt.maxOps.getNodeByHandle(int(h))
    if _undef(rep):
        return [], []
    allof = _family(rep)
    return [x for x in allof if _place(x) == place], allof


def _nodes_of(tok):
    """The nodes a row stands for: an object, a definition's instances at its place."""
    if tok.startswith("N:"):
        n = _node(tok)
        return [n] if n is not None else []
    if tok[:2] in ("D:", "I:"):
        return _here(tok)[0]
    return []


# ──────────────────────────────────────────────────────────────── the rows

def _rows():
    """What the tree draws right now, top to bottom: [{tok, name, kind, depth, kids,
    open, empty, hidden, frozen, …}]. Only open things are walked. As in Fusion's
    Browser, the entered folder is the top row (`root`) with its contents under it —
    its parents aren't drawn; at the scene's top, the top level is."""
    rows = []
    d = G.load()
    root = _root()
    # per row, not a set of the whole selection: a folder pick can select thousands
    picks = set(_picks() or [])
    cutset = set(_v["cut"])
    # a nav key's pick not made yet (_sel_soon): draw it, not Max's stale selection
    pend = None
    if _v["pending"] is not None:
        pend = {int(n.inode.handle) for n in _sel_nodes(_v["pending"])[0]}

    def is_sel(n):
        return int(n.inode.handle) in pend if pend is not None else bool(n.isSelected)

    # `dim`: inside something hidden as a whole (a hidden folder, an Instances group whose
    # instances are all hidden) — such rows are dimmed, not struck through, as in Fusion.

    def add_node(n, depth, dim, num=0):
        """An object row; `num` = it's instance number `num`, drawn inside its
        definition's Instances group (the definition holds the stack)."""
        tok = _tok(n)
        kids = _shown(n.children)
        grp = bool(rt.isGroupHead(n))
        if grp and drop_empty and not node_full(n):
            return
        stack = [] if num else _stack(n)
        is_open = tok in _v["open"] and bool(stack or kids)
        rows.append({"tok": tok, "name": _inst_name(n, num) if num else str(n.name),
                     "kind": "instance" if num else _kind(n), "depth": depth,
                     "kids": bool(stack or kids), "open": is_open, "cut": tok in cutset,
                     "empty": grp and not kids,
                     "hidden": (bool(n.isHidden) or _layer_hidden(n)) and not dim,
                     "dim": dim, "frozen": _frozen(n), "sel": is_sel(n),
                     "grp": grp, "num": num})
        if is_open:
            for it in stack:
                rows.append(dict(it, depth=depth + 1, kids=False, open=False,
                                 hidden=False, sel=False, dim=dim))
            add_many(kids, depth + 1, dim)

    def add_def(rep, here, depth, dim):
        tok, itok = _def_tok("D", rep), _def_tok("I", rep)
        allhid = all(bool(x.isHidden) for x in here)
        is_open = tok in _v["open"]
        rows.append({"tok": tok, "name": _def_name(_family(rep)[0]), "kind": "def", "depth": depth,
                     "kids": True, "open": is_open, "cut": tok in cutset, "empty": False,
                     "hidden": allhid and not dim, "dim": dim,
                     "frozen": all(_frozen(x) for x in here),
                     "sel": all(is_sel(x) for x in here), "count": len(here)})
        if not is_open:
            return
        for it in _stack(rep):
            rows.append(dict(it, depth=depth + 1, kids=False, open=False,
                             hidden=False, sel=False, dim=dim))
        i_open = itok in _v["open"]
        rows.append({"tok": itok, "name": "Instances", "kind": "inst", "depth": depth + 1,
                     "kids": True, "open": i_open, "cut": False, "empty": False,
                     "hidden": allhid and not dim, "dim": dim, "frozen": False, "sel": False})
        if i_open:
            for x in sorted(here, key=_number):
                add_node(x, depth + 2, dim or allhid, num=_number(x))

    def add_many(nodes, depth, dim):
        """Objects at one place, a definition's instances folded into one row, by name."""
        keyof, fam = _instances()
        items, defs = [], {}
        for n in _shown(nodes):
            hs = fam.get(keyof.get(int(n.inode.handle)), [])
            if len(hs) < 2:
                items.append((str(n.name).lower(), n, None))
                continue
            if hs[0] not in defs:
                defs[hs[0]] = []
                first = rt.maxOps.getNodeByHandle(hs[0])
                items.append((_def_name(first).lower(), n, defs[hs[0]]))
            defs[hs[0]].append(n)
        for _, n, here in sorted(items, key=lambda t: t[0]):
            if here is None:
                add_node(n, depth, dim)
            else:
                add_def(here[0], here, depth, dim)

    drop_empty = "empty" in _v["hide"]
    full = {}

    def node_full(n):
        """An object counts; a Max group only if something in it does."""
        return not rt.isGroupHead(n) or any(node_full(k) for k in _shown(n.children))

    def has_content(gid):
        """Hide Empty Groups: anything the tree would list in gid, its sub-folders' too."""
        if gid not in full:
            full[gid] = any(node_full(n) for n in _shown(_objects_on(gid))) or any(
                has_content(s) for s in G.children(d, gid))
        return full[gid]

    def add_folder(gid, depth, dim, is_root=False):
        if drop_empty and not is_root and not has_content(gid):
            return
        g = d["g"][gid]
        tok = _gtok(gid)
        subs, has = G.children(d, gid), bool(_idx().tops.get(gid))
        is_open = (not _v["shut"]) if is_root else tok in _v["open"]
        hid = bool(g.get("hidden"))
        rows.append({"tok": tok, "name": g["name"], "kind": "folder", "depth": depth,
                     "cut": tok in cutset,
                     "kids": bool(subs or has), "open": is_open and bool(subs or has),
                     "empty": not (subs or has), "root": is_root,
                     "hidden": hid and not dim, "dim": dim, "frozen": False,
                     "render": bool(g.get("render")), "sel": tok in picks})
        if is_open:
            walk(gid, depth + 1, dim or hid)

    def walk(gid, depth, dim):
        for s in G.children(d, gid):
            add_folder(s, depth, dim)
        add_many(_objects_on(gid), depth, dim)

    if root and "root" in _v["hide"]:
        walk(root, 0, bool(d["g"][root].get("hidden")))
    elif root:
        add_folder(root, 0, False, is_root=True)
    else:
        walk("", 0, False)
    return rows


def _path():
    """The crumbs from the scene's top (not drawn) to the entered folder."""
    d = G.load()
    return [d["g"][g]["name"] for g in G.chain(d, _root())]


def _one_lit(rows, cursor):
    """Fusion's rule: one highlight per branch. The row you're on lights alone — not the
    object, group or definition it sits inside (a modifier row selects its object; a
    closed group's pick selects its head) — and a lit row's contents don't light with it
    (a group's members, a definition's instances, a picked folder's objects)."""
    toks = [r["tok"] for r in rows]
    if cursor in toks:
        i = toks.index(cursor)
        d = rows[i]["depth"]
        for r in reversed(rows[:i]):
            if r["depth"] < d:
                r["sel"] = False
                d = r["depth"]
    lit = []                                      # depths of the lit rows above this one
    for r in rows:
        while lit and lit[-1] >= r["depth"]:
            lit.pop()
        if lit:
            r["sel"] = False
        elif r.get("sel") or r["tok"] == cursor:
            lit.append(r["depth"])


def snapshot():
    rows = _rows()
    toks = [r["tok"] for r in rows]
    if _v["cursor"] not in toks:
        sel = [r["tok"] for r in rows if r.get("sel")]
        _v["cursor"] = sel[0] if sel else None
    _one_lit(rows, _v["cursor"])
    return {"doc": str(rt.maxFilePath) + str(rt.maxFileName), "path": _path(),
            "rows": rows, "cursor": _v["cursor"], "iso": bool(_iso["on"]),
            "rename": _v["rename"], "hide": sorted(_v["hide"]), "away": _away(),
            "panel": _panel(), "appear": _appear(), "t": time.time()}


def _appear():
    """The Appearances section (appearance.py) when it's shown."""
    from . import appearance
    return appearance.snapshot()


def _away():
    """A panel's title while it has the Browser's place (side.py): the page draws nothing."""
    from . import side
    return side.title()


def _panel():
    """A settings panel for the page to draw in place of the tree (panel.py)."""
    from . import side
    p = side.page()
    if p is None:
        return None
    s = p.snapshot()
    s["parent"] = "root" not in _v["hide"]     # Show Parent tick → the title row (the camera's name)
    return s


# ──────────────────────────────────────────────────────────────── publishing

class _Pub:
    def __init__(self):
        from PySide6.QtCore import QTimer
        self.timer = QTimer()
        self.timer.setSingleShot(True)
        self.timer.timeout.connect(self.write)

    def write(self):
        try:
            s = snapshot()
        except Exception as e:
            s = {"error": str(e), "rows": [], "path": [], "t": time.time()}
        try:
            tmp = STATE + ".tmp"
            with open(tmp, "w") as f:
                json.dump(s, f)
            os.replace(tmp, STATE)
        except OSError:
            pass


def _pub():
    import builtins
    p = getattr(builtins, "_callis_browser_pub", None)
    if p is None:
        p = builtins._callis_browser_pub = _Pub()
    return p


def publish(now=False):
    p = _pub()
    if now:
        p.timer.stop()
        p.write()
    else:
        p.timer.start(50)


def _structure_changed(*_):
    global _index, _inst
    if _busy:
        return
    _index = _inst = None
    publish()


def _stack_changed(*_):
    global _inst
    _inst = None
    publish()


def _selection_changed(*_):
    if not _selecting[0]:
        _v["pending"] = None                      # anything else that selects beats a queued pick
    if _busy:
        return
    if time.time() - _own_sel[0] > 0.3:          # a pick in the viewport: follow it
        last = _last_selected()
        # a closed group's pick lands on its head, not the member Max listed last
        _v["cursor"] = _tok(_head(last)) if last is not None else None
        _v["picks"] = _v["pending"] = None
    if not _selecting[0] and int(rt.selection.count) == 0:
        _hide_cmd_panel()
    publish()


def _hide_cmd_panel():
    """Clean mode: the Modify panel a pick brought up goes when nothing is selected."""
    from . import clean
    try:
        if clean.is_on() and bool(rt.cui.commandPanelOpen):
            rt.cui.commandPanelOpen = False
    except Exception as e:
        print("[callis.browser] command panel:", e)


def _scene_changed(*_):
    global _index, _inst
    _index = _inst = None
    doc = str(rt.maxFilePath) + str(rt.maxFileName)
    if doc != _v["doc"]:
        _v.update(root=None, open=set(), cursor=None, doc=doc, shut=False, cut=[], picks=None,
                  anchor=None, rename=None, opened=[])
        _close_all_groups()            # a scene saved with a group gone into opens shut
        try:
            from . import maxstart
            maxstart.mark_render()     # the old " —" folders get Show When Rendering, once
        except Exception as e:
            print("[callis.browser] render ticks not marked:", e)
    _iso_load()
    publish()


def _stamp(*_):
    """nodeCreated: a new top-level object lands in the entered folder (as a new body
    lands in Fusion's active component). Clones already carry their original's folder."""
    try:
        root = _v["root"]
        if not root:
            return
        n = rt.callbacks.notificationParam()
        if _undef(n) or not _undef(n.parent):
            return
        v = rt.getUserProp(n, G.PROP)
        if _undef(v):
            G.stamp(n, root)
    except Exception as e:
        print("[callis.browser] new object not filed:", e)


STRUCTURE = ("nodeCreated", "nodePostDelete", "nodeNameSet", "nodeLinked", "nodeUnlinked",
             "nodeHide", "nodeUnhide", "nodeFreeze", "nodeUnfreeze", "postModifierAdded",
             "postModifierDeleted", "postNodesCloned", "sceneNodeAdded", "nodeLayerChanged",
             "layerParentChanged")
SCENE = ("filePostOpen", "systemPostReset", "systemPostNew", "filePostMerge")


def install():
    rt.callbacks.removeScripts(id=rt.Name("callisBrowser"))
    for ev, fn in [("nodeCreated", _stamp)] + \
                  [(e, _structure_changed) for e in STRUCTURE] + \
                  [(e, _scene_changed) for e in SCENE] + \
                  [("selectionSetChanged", _selection_changed),
                   ("sceneUndo", reiso_soon), ("sceneRedo", reiso_soon),
                   ("sceneUndo", _structure_changed), ("sceneRedo", _structure_changed),
                   ("modPanelObjPostChange", _stack_changed),
                   ("preRender", _pre_render), ("postRender", _post_render)]:     # Make Unique, instancing
        try:
            rt.callbacks.addScript(rt.Name(ev), fn, id=rt.Name("callisBrowser"))
        except Exception as e:
            print("[callis.browser] no callback", ev, e)
    _scene_changed()


# ──────────────────────────────────────────────────────────────── isolate + dim

# Isolate = hide everything outside the entered folder; off, that outside is DIMMED:
# opaque, a darker version of what it is (Fusion's look). Each outside node's material is
# wrapped in a Shell Material — viewport = its dimmed look, render = the original — so a
# render or a save while dimmed is still right, and undimming is just unwrapping. Only the
# DIM_TOP most used materials outside get a real dimmed copy (a clone whose pixels are the
# original's × DIM_K, like a black layer over them — see TONE); every other one shows one
# shared dark grey (assigned directly, originals in a rootNode attribute), so a scene with
# thousands of materials costs a material swap each and nothing more. Shells / looks are cached per
# material for the session (MAXScript Dictionaries keyed by anim handle) and tagged with
# AppData, so a scene saved dimmed is still undone on open. Edges (drawn in the wire colour)
# fade toward the background; each dimmed node's own wire colour is kept in "wire".
# Node by node (folders aren't layers), diffed: only the nodes whose inside/outside
# status changed are touched, in one MAXScript call each way, our nodeHide callbacks
# muted (groups.quiet). Only what we changed is recorded, so switching off restores
# exactly what you had; the record lives in rootNode AppData (saved with the scene,
# re-read on open and on undo). A folder you hide adopts the isolate's hidden nodes in it.
# Scenes dimmed before 2026-10-15 used See-Through: a record without "v" is undone that way.
_iso = {"on": False, "dim": True, "v": 2,
        "hn": [],        # handles of nodes we hid
        "dn": [],        # handles of nodes we dimmed
        "nomat": [],     # dimmed nodes that had no material (given the grey)
        "fz": [],        # dimmed nodes we froze (unclickable; the user's own freezes left alone)
        "fzg": [],       # … of those, the ones that had Show Frozen in Gray on
        "pre": [],       # (old records) nodes that were See-Through before we dimmed
        "wire": {}}      # handle → [r, g, b]: the wire colour a dimmed node had
_APPDATA = 0x43414C31
DIM_BG = 0.9         # a dimmed edge: this much background, the rest mid grey
DIM_TOP = 5          # materials that get a real dimmed copy; the rest show DIM_GREY
DIM_K = 0.35         # dimmed copy = the original on screen × this (a black overlay at 65%)
# The viewport is tone-mapped (OCIO ACEScg + Physical Camera Exposure's filmic curve), so
# "pixels × k" needs a different light factor at each brightness. TONE = (light, 8-bit pixel)
# measured 2026-10-15 by sweeping a Physical material's emission (the shape is what matters:
# EV only rescales light, which the factor doesn't see). DIM_LIGHT = the light a white
# diffuse surface gets (Physical white, weight 1 → pixel 166 → 240); DIM_SPEC = a highlight.
TONE = [(2.56, 1), (4.1, 3), (6.55, 6), (10.49, 12), (16.78, 22), (26.84, 36), (42.95, 53),
        (68.72, 77), (109.95, 108), (175.92, 142), (281.47, 177), (450.36, 204), (720.58, 223),
        (1152.92, 235), (1844.67, 243), (2951.48, 249), (4722.37, 253), (7555.79, 255)]
DIM_LIGHT = 240.0
DIM_SPEC = 2000.0
DIM_CAP = 75         # no dimmed material brighter than this (0–255 on screen)
DIM_SHADE = 0.35     # share of a dimmed look that is real shading; the rest is flat emission
# A plain colour (callisDimFlat) is aimed at its look lit by DIM_REF × DIM_LIGHT — a face
# toward the sun, where colours look as you know them (brighter = less saturated on the
# curve's shoulder) — with DIM_FLAT_SHADE of it real shading, so a face in shade still
# darkens. Tuned 2026-10-15 on Render Test (Corona): brick (169,96,82) → (54,31,18), ground ×0.38.
DIM_REF = 2.5
DIM_FLAT_SHADE = 0.6
DIM_GREY = 40        # 0–255

_MS = """
global callisDimShells, callisDimLooks, callisDimGreyMtl
global callisToneL, callisToneY, callisToneLight, callisToneSpec, callisDimCap, callisDimShade, callisDimRef, callisDimFlatShade    -- set by _ms_load
if callisDimShells == undefined do callisDimShells = Dictionary #integer
if callisDimLooks == undefined do callisDimLooks = Dictionary #integer
fn callisIsDim m = m != undefined and classOf m == Shell_Material and (getAppData m 0x43414C32) == "1"
fn callisDimGrey g = (
    if callisDimGreyMtl == undefined or isDeleted callisDimGreyMtl do
        for m in sceneMaterials where m.name == "Callis Dim Grey" and (getAppData m 0x43414C32) == "1" do callisDimGreyMtl = m
    if callisDimGreyMtl == undefined or isDeleted callisDimGreyMtl do (
        callisDimGreyMtl = Standardmaterial name:"Callis Dim Grey" specularLevel:0 glossiness:0
        setAppData callisDimGreyMtl 0x43414C32 "1"
    )
    callisDimGreyMtl.diffuse = callisDimGreyMtl.ambient = color g g g
    callisDimGreyMtl
)
fn callisToneAt xs ys v = (    -- piecewise-linear in log x over a table (x ascending)
    if v <= xs[1] do return ys[1] * v / xs[1]
    for i = 2 to xs.count where v <= xs[i] do (
        local t = (log v - log xs[i-1]) / (log xs[i] - log xs[i-1])
        return ys[i-1] + t * (ys[i] - ys[i-1])
    )
    ys[ys.count]
)
fn callisToneInv xs ys y = (    -- display → light (ys ascending)
    if y <= ys[1] do return xs[1] * y / ys[1]
    for i = 2 to ys.count where y <= ys[i] do (
        local t = (y - ys[i-1]) / (ys[i] - ys[i-1])
        return exp (log xs[i-1] + t * (log xs[i] - log xs[i-1]))
    )
    xs[xs.count]
)
fn callisDimFactor L k = (    -- light × this = pixels × k, for light L through the viewport curve
    local y = callisToneAt callisToneL callisToneY L
    amax 0.005 (amin 1.0 ((callisToneInv callisToneL callisToneY (k * y)) / L))
)
fn callisLum c = (0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b) / 255.0
fn callisMtlBase m = (    -- #(colour, map or undefined, level, metal 0–1, roughness); undefined: unknown class
    local P = isProperty, col = undefined, tex = undefined, use = true, lvl = 1.0, mt = 0.0, ro = 0.5
    case of (
        (P m #base_color): (col = m.base_color; tex = m.base_color_map; use = m.base_color_map_on
                            lvl = m.base_weight; mt = m.metalness
                            ro = if m.roughness_inv then 1.0 - m.roughness else m.roughness)
        (P m #baseColor): (col = m.baseColor; tex = m.baseTexmap; use = m.baseTexmapOn; lvl = m.baseLevel
                           ro = m.baseRoughness; mt = if m.metalnessMode == 1 then 1.0 else 0.0)
        (P m #colorDiffuse): (col = m.colorDiffuse; tex = m.texmapDiffuse; use = m.texmapOnDiffuse; lvl = m.levelDiffuse)
        (P m #texmap_diffuse): (col = m.diffuse; tex = m.texmap_diffuse; use = m.texmap_diffuse_on)
        (P m #diffuseMap): (col = m.diffuse; tex = m.diffuseMap; use = m.diffuseMapEnable)
    )
    if col == undefined then undefined
    else #(col, (if use == true then tex else undefined), lvl, amax 0.0 (amin 1.0 mt), ro)
)
fn callisMul m p k = if isProperty m p do setProperty m p ((getProperty m p) * k)
fn callisSet m p v = if isProperty m p do setProperty m p v
global callisDimLights = Dictionary #string    -- callisDimKey → Point3 light, from dimlut (Python)
fn callisDimKey col light = (col as string) + " " + (light as string)
fn callisDimNeedsAdd m out seen depth = (
    if m == undefined or depth > 2 do return ok
    if classOf m == Multimaterial then
        for i = 1 to amin 5 m.numsubs do callisDimNeedsAdd m.materialList[i] out seen (depth + 1)
    else (
        local b = callisMtlBase m
        if b != undefined and b[2] == undefined do (
            local light = callisDimRef * callisToneLight * b[3], key = callisDimKey b[1] light
            if not hasDictValue seen key do (
                seen[key] = true
                append out #(key, b[1].r, b[1].g, b[1].b, light)
            )
        )
    )
)
fn callisDimNeeds hs = (    -- #(key, r, g, b, light) for every plain colour these nodes' looks need
    local out = #(), seen = Dictionary #string
    for h in hs do (
        local n = maxOps.getNodeByHandle h
        if n != undefined do callisDimNeedsAdd (callisDimRealH n h) out seen 0
    )
    out
)
fn callisDimSetLights keys pts = for i = 1 to keys.count do callisDimLights[keys[i]] = pts[i]
fn callisDimFlat b k = (    -- a plain colour's dimmed look: aimed per CHANNEL
    -- One light factor for all three channels lands the darker ones lower on the curve's
    -- toe, where they fall faster: a red went redder and darker (G, B × 0.2 vs R × 0.37).
    -- And the display transform mixes channels (pure red shows brighter than white), so
    -- the lights that show k × the pixel come from the measured viewport (dimlut.py,
    -- callisDimLights); never calibrated → the grey curve per channel. The cap scales all
    -- three alike; base / emission colours are built from those lights.
    local col = b[1], mt = b[4], light = callisDimRef * callisToneLight * b[3], Ls = #()
    local key = callisDimKey col light
    if hasDictValue callisDimLights key then (local e = callisDimLights[key]; Ls = #(e.x, e.y, e.z)) else (
        local ys = #()
        for v in #(col.r, col.g, col.b) do
            append ys (k * (callisToneAt callisToneL callisToneY (light * (amax 0.005 (v / 255.0)))))
        local s = amin 1.0 (callisDimCap / (amax ys[1] (amax ys[2] ys[3])))
        for y in ys do append Ls (callisToneInv callisToneL callisToneY (y * s))
    )
    local Lm = amax 0.001 (amax Ls[1] (amax Ls[2] Ls[3]))
    local ks = callisDimFactor callisToneSpec k
    local sh = callisDimFlatShade * 255.0 / (callisDimRef * callisToneLight)    -- shading: full lighting → share of Lt
    -- a metal's base colour is its reflection: the original's × the highlight factor
    local bc = for i = 1 to 3 collect amin 255 ((1 - mt) * sh * Ls[i] + mt * ks * #(col.r, col.g, col.b)[i])
    PhysicalMaterial base_color:(color bc[1] bc[2] bc[3]) \
        roughness:b[5] metalness:mt reflectivity:ks base_weight:1.0 emission:1.0 \
        emit_color:(color (255 * Ls[1] / Lm) (255 * Ls[2] / Lm) (255 * Ls[3] / Lm)) \
        emit_luminance:((1 - callisDimFlatShade) * Lm)
)
fn callisDimScaled m k = (    -- m's dimmed look (a new Physical); undefined: unknown class
    -- The viewport is tone-mapped (filmic): scaling light alone drops a bright surface off
    -- the curve's flat shoulder into its steep middle, so its shading spreads out (more
    -- contrast than the original). So the look is aimed at k × the original's brightness
    -- (capped: callisDimCap), and most of it is flat emission — only callisDimShade of it is
    -- real shading. Highlights / a metal's base get the near-white factor, so they go dark.
    local b = callisMtlBase m
    if b == undefined do return undefined
    local col = b[1], tex = b[2], mt = b[4]
    if tex == undefined do return callisDimFlat b k
    local ac = 0.4                                                            -- the map's own
    local L0 = callisToneLight * ac * b[3]                                    -- light, at full lighting
    local yt = amin callisDimCap (k * (callisToneAt callisToneL callisToneY L0))
    local Lt = callisToneInv callisToneL callisToneY yt
    local ks = callisDimFactor callisToneSpec k
    local w = callisDimShade * Lt / (callisToneLight * ac)
    local d = PhysicalMaterial base_color:col roughness:b[5] metalness:mt reflectivity:ks \
        base_weight:(w * (1 - mt) + ks * mt) emission:1.0 emit_color:col \
        emit_luminance:((1 - callisDimShade) * Lt / ac)
    if tex != undefined do (
        d.base_color_map = tex; d.base_color_map_on = true    -- shared, not copied
        d.emit_color_map = tex; d.emit_color_map_on = true
    )
    d
)
fn callisDimLookOf m k g = (    -- this material's dimmed viewport material (cached, refreshed)
    local h = getHandleByAnim m, d = callisDimLooks[h]
    if classOf m == Multimaterial then (
        if d == undefined or isDeleted d do (
            d = Multimaterial numsubs:m.numsubs name:(m.name + " (dim)")
            setAppData d 0x43414C32 "1"
        )
        if d.numsubs != m.numsubs do d.numsubs = m.numsubs
        for i = 1 to m.numsubs do (
            local s = m.materialList[i]
            d.materialIDList[i] = m.materialIDList[i]
            d.materialList[i] = if s != undefined and i <= 5 then callisDimLookOf s k g else callisDimGrey g
        )
    ) else (
        -- a clone with every light-producing term × k: same shading, so on screen
        -- it's the original × k^(1/2.2) — a black overlay, highlights included
        d = callisDimScaled m k
        if d == undefined do return callisDimGrey g
        d.name = m.name + " (dim)"
        setAppData d 0x43414C32 "1"
    )
    callisDimLooks[h] = d
    d
)
fn callisDimCmp a b = b[1] - a[1]
-- nodes showing the grey: handle → their own material. Session Dictionary, mirrored into a
-- rootNode attribute (it also keeps those materials alive through a save).
global callisDimGreyOf = Dictionary #integer
global callisDimStoreCA = attributes callisDimStore attribID:#(0x43414c33, 0x4d6c7431) (
    parameters main (
        hs type:#intTab tabSizeVariable:true
        ms type:#materialTab tabSizeVariable:true
    )
)
fn callisDimStoreLoad = (
    callisDimGreyOf = Dictionary #integer
    local ca = rootNode.custAttributes[#callisDimStore]
    if ca != undefined do
        for i = 1 to ca.hs.count where ca.ms[i] != undefined do callisDimGreyOf[ca.hs[i]] = ca.ms[i]
)
fn callisDimStoreSave = (
    local ca = rootNode.custAttributes[#callisDimStore]
    if callisDimGreyOf.count == 0 then (
        if ca != undefined do custAttributes.delete rootNode (custAttributes.getDef ca)
    ) else (
        if ca == undefined do (
            custAttributes.add rootNode callisDimStoreCA
            ca = rootNode.custAttributes[#callisDimStore]
        )
        ca.hs = for kv in callisDimGreyOf collect kv.key
        ca.ms = for kv in callisDimGreyOf collect kv.value
    )
)
fn callisDimRealH n h = (    -- the material a (maybe dimmed) node really has (h = its handle)
    local m = n.material
    if callisIsDim m then m.originalMaterial
    else if m != undefined and m == callisDimGreyMtl and hasDictValue callisDimGreyOf h then callisDimGreyOf[h]
    else m
)
fn callisDimReal n = callisDimRealH n n.inode.handle    -- (n.inode.handle: ~65 µs — not in loops)
global callisDimTop = #()    -- anim handles of the materials getting a real dimmed copy
fn callisDim hs top k g wire recount = (    -- -> #(no-material handles, #(handle, wirecolor)…)
    local nodes = #(), mats = #(), hh = #(), counts = Dictionary #integer
    local grey = callisDimGrey g
    for h in hs do (
        local n = maxOps.getNodeByHandle h
        if n != undefined do (
            local m = callisDimRealH n h
            append nodes n; append mats m; append hh h
            if recount and m != undefined and m != grey do (
                local mh = getHandleByAnim m
                counts[mh] = (if hasDictValue counts mh then counts[mh] else 0) + 1
            )
        )
    )
    if recount do (    -- a fresh dim: pick the most used; a diff keeps that pick
        local ranked = for kv in counts collect #(kv.value, kv.key)
        qsort ranked callisDimCmp
        callisDimTop = for i = 1 to amin top ranked.count collect ranked[i][2]
    )
    local best = callisDimTop
    local nomat = #(), cols = #(), fz = #(), fzg = #(), looks = Dictionary #integer
    for i = 1 to nodes.count do (
        local n = nodes[i], m = mats[i], h = hh[i]
        append cols #(h, n.wirecolor)
        if m == undefined then (
            if superClassOf n == GeometryClass and classOf n != Targetobject and n.material == undefined do (
                n.material = grey
                append nomat h
            )
        ) else if m != grey do (
            local mh = getHandleByAnim m
            if (finditem best mh) > 0 then (    -- a real dimmed copy, in a viewport-only shell
                local s = callisDimShells[mh]
                if s == undefined or isDeleted s do (
                    s = if callisIsDim n.material then n.material \
                        else Shell_Material originalMaterial:m viewportMtlIndex:1 renderMtlIndex:0 name:(m.name + " (dim)")
                    setAppData s 0x43414C32 "1"
                    callisDimShells[mh] = s
                )
                if not hasDictValue looks mh do looks[mh] = callisDimLookOf m k g
                local look = looks[mh]
                if s.bakedMaterial != look do s.bakedMaterial = look
                if n.material != s do n.material = s
                removeDictValue callisDimGreyOf h
            ) else (                             -- the rest: the shared grey, theirs recorded
                callisDimGreyOf[h] = m
                if n.material != grey do n.material = grey
            )
        )
    )
    -- unclickable: frozen, but drawn in its own colours (Show Frozen in Gray off)
    for i = 1 to nodes.count where not nodes[i].isFrozen do (
        local n = nodes[i]
        if n.showFrozenInGray do (append fzg hh[i]; n.showFrozenInGray = false)
        n.isFrozen = true
        append fz hh[i]
    )
    -- every colour read before any is set: a camera and its target share one
    for c in cols do (
        local n = maxOps.getNodeByHandle c[1]
        if n.wirecolor != wire do n.wirecolor = wire
    )
    #(nomat, cols, fz, fzg)
)
fn callisUnfreeze hs greys = (
    for h in hs do (local n = maxOps.getNodeByHandle h; if n != undefined do n.isFrozen = false)
    for h in greys do (local n = maxOps.getNodeByHandle h; if n != undefined do n.showFrozenInGray = true)
)
fn callisUndim hs nomat legacy pre = (
    for h in hs do (
        local n = maxOps.getNodeByHandle h
        if n != undefined do (
            local m = n.material
            if callisIsDim m then n.material = m.originalMaterial
            else if m != undefined and m == callisDimGreyMtl do (
                if hasDictValue callisDimGreyOf h then n.material = callisDimGreyOf[h]
                else if (finditem nomat h) > 0 do n.material = undefined
            )
            if legacy do n.xray = (finditem pre h) > 0
        )
        removeDictValue callisDimGreyOf h
    )
)
fn callisUnwire hs cs = (
    for i = 1 to hs.count do (
        local n = maxOps.getNodeByHandle hs[i]
        if n != undefined do n.wirecolor = cs[i]
    )
)
fn callisXrayLayers lays pre = (    -- undoing a dim recorded by layer (scenes before 2026-10-13)
    for l in lays do (
        local a = #()
        l.nodes &a
        for n in a do n.xray = (finditem pre n.inode.handle) > 0
    )
)
"""


_ms_ready = []
_busy = []


def _iso_load(*_):
    try:
        raw = str(rt.getAppData(rt.rootNode, _APPDATA) or "")
        d = json.loads(raw) if raw else {}
    except Exception:
        d = {}
    _iso.update({"on": False, "dim": True, "v": 2 if not d else 1, "hn": [], "dn": [],
                 "nomat": [], "fz": [], "fzg": [], "pre": [], "wire": {}})
    old = {k: d.pop(k) for k in ("hl", "dl") if k in d}
    _iso.update(d)
    try:
        _ms_load()
        rt.callisDimStoreLoad()          # this scene's grey-dimmed nodes → their materials
    except Exception as e:
        print("[callis.browser] dim record not read:", e)
    if old:
        _legacy_undo(old)


def _ms_load():
    if not _ms_ready:
        rt.execute(_MS)
        rt.execute("global callisToneL = #(%s)\nglobal callisToneY = #(%s)\n"
                   "global callisToneLight = %r\nglobal callisToneSpec = %r\n"
                   "global callisDimCap = %r\nglobal callisDimShade = %r\nglobal callisDimRef = %r\n"
                   "global callisDimFlatShade = %r" % (",".join("%r" % float(l) for l, _ in TONE),
                                            ",".join("%r" % float(y) for _, y in TONE),
                                            DIM_LIGHT, DIM_SPEC, float(DIM_CAP), DIM_SHADE, DIM_REF, DIM_FLAT_SHADE))
        _ms_ready.append(1)


def real_material(n):
    """n's own material, through the dim (a shell or the shared grey)."""
    _ms_load()
    return rt.callisDimReal(n)


def _legacy_undo(old):
    """A scene whose isolate / dim was recorded by LAYER (before folders): put those
    layers back once — shown, See-Through as it was — and drop that record."""
    try:
        _ms_load()
        def lay(name):
            l = rt.LayerManager.getLayerFromName(name)
            return None if _undef(l) else l
        for l in filter(None, map(lay, old.get("hl", []))):
            l.ishidden = False
        dl = list(filter(None, map(lay, old.get("dl", []))))
        if dl:
            rt.callisXrayLayers(dl, list(_iso["pre"]))
        _unwire([int(h) for h in list(_iso["wire"])])
        _iso["pre"] = []
        _iso_save()
    except Exception as e:
        print("[callis.browser] old layer isolate not undone:", e)


def _iso_save():
    try:
        rt.setAppData(rt.rootNode, _APPDATA, json.dumps(_iso))
    except Exception as e:
        print("[callis.browser] isolate record not saved:", e)


def _want():
    """(handles to hide, handles to dim) for the entered folder: everything outside it."""
    root = _root()
    if not root:                                  # at the top nothing is outside
        return set(), set()
    d = G.load()
    inside = G.subtree(d, root)
    outside = {h for h, g in _idx().gid.items() if g not in inside}
    if _iso["on"]:
        return outside, set()
    if not _iso["dim"] or _rendering:
        return set(), set()
    return set(), outside


def _group_hid():
    """Handles a hidden folder is holding hidden — the isolate leaves those alone."""
    out = set()
    for g in G.load()["g"].values():
        out.update(int(h) for h in g.get("hid", []))
    return out


def reiso():
    """Make the viewport match: diff the wanted hide / dim sets against what we did."""
    _busy.append(1)                  # our own hides aren't scene changes to publish
    rt.disableSceneRedraw()          # one redraw at the end, not one per layer
    try:
        with __import__("pymxs").undo(False):
            _reiso()
    except Exception as e:
        print("[callis.browser] isolate:", e)
    finally:
        rt.enableSceneRedraw()
        rt.redrawViews()             # else the viewport shows it only at the next click
        _busy.pop()
        publish()


def _reiso():
    _ms_load()
    G.ms()
    hn, dn = _want()
    # nodes hidden (a hidden folder's own are its business, not ours)
    held = _group_hid()
    have = {int(h) for h in _iso["hn"]} - held
    show = [h for h in have - hn]
    add = list(hn - have - held)
    vis = [int(h) for h in rt.callisVisibleOf(add)] if add else []
    with G.quiet():
        if show:
            rt.callisSetHidden(show, False)
        if vis:
            rt.callisSetHidden(vis, True)
    _iso["hn"] = sorted((have & hn) | set(vis))
    # nodes dimmed — material swaps mustn't count as "the last material" (material.py)
    from . import material as M
    with M.paused(), G.quiet(("nodeFreeze", "nodeUnfreeze")):
        _redim(dn)
    _iso["dn"] = sorted(dn)
    _iso_save()


def _redim(dn):
    had = {int(h) for h in _iso["dn"]}
    legacy = _iso.get("v", 1) < 2
    gone = list(had - dn) if not legacy else list(had)    # an old See-Through dim: all of it
    if gone:
        rt.callisUndim(gone, list(_iso["nomat"]), legacy, list(_iso["pre"]))
        _unwire(gone)
        g = set(gone)
        _iso["nomat"] = [h for h in _iso["nomat"] if h not in g]
        rt.callisUnfreeze([h for h in _iso["fz"] if h in g], [h for h in _iso["fzg"] if h in g])
        _iso["fz"] = [h for h in _iso["fz"] if h not in g]
        _iso["fzg"] = [h for h in _iso["fzg"] if h not in g]
        if legacy:
            had, _iso["pre"], _iso["v"] = set(), [], 2
    new = dn - had
    if new:
        # always the whole outside set, re-picking the most used materials: a diff against
        # an older pick (e.g. one made when only cameras were outside) left everything grey.
        # Nodes already showing the right look aren't reassigned.
        _dim_lights(dn)
        nomat, cols, fz, fzg = rt.callisDim(sorted(dn), DIM_TOP, DIM_K, DIM_GREY, _dim_wire(), True)
        _iso["nomat"] = sorted(set(_iso["nomat"]) | {int(h) for h in nomat})
        _iso["fz"] = sorted(set(_iso["fz"]) | {int(h) for h in fz})
        _iso["fzg"] = sorted(set(_iso["fzg"]) | {int(h) for h in fzg})
        for h, c in cols:
            _iso["wire"].setdefault(str(int(h)), [float(c.r), float(c.g), float(c.b)])
    if gone or new:
        rt.callisDimStoreSave()
    if not dn and _iso["wire"]:                   # nothing dimmed: no colour left behind
        _unwire([int(h) for h in _iso["wire"]])


def _dim_lights(dn):
    """The measured lights for the plain colours the dim will need (dimlut.py) → MAXScript
    callisDimLights. No LUT → nothing set; callisDimFlat falls back to the grey curve."""
    from . import dimlut
    keys, pts = [], []
    for key, r, g, b, light in rt.callisDimNeeds(sorted(dn)):
        e = dimlut.dim(float(r), float(g), float(b), float(light), DIM_K, float(DIM_CAP))
        if e is not None:
            keys.append(key)
            pts.append(rt.Point3(*e))
    if keys:
        rt.callisDimSetLights(keys, pts)


def _dim_wire():
    """The edge colour of a dimmed node: nearly the background (the solid colour, or a
    light sky grey when the view shows the environment), so See-Through's ghost isn't
    drawn over by a full-strength wireframe."""
    s = rt.NitrousGraphicsManager.GetActiveViewportSetting()
    if bool(rt.viewport.IsSolidBackgroundColorMode()) and not bool(s.UseEnvironmentBackgroundColorEnabled):
        bg = [float(c) * 255 for c in rt.colorMan.getColor(rt.Name("ViewportBackground"))]
    else:
        bg = [245.0] * 3
    return rt.Color(*[DIM_BG * c + (1 - DIM_BG) * 128.0 for c in bg])


def _unwire(handles):
    """Give these nodes back the wire colours they had before we dimmed them."""
    hs = [h for h in handles if str(h) in _iso["wire"]]
    if hs:
        rt.callisUnwire(hs, [rt.Color(*_iso["wire"].pop(str(h))) for h in hs])


def _frozen(n):
    """Frozen by the user — the dim's own freeze (unclickable outside) doesn't count."""
    return bool(n.isFrozen) and int(n.inode.handle) not in _dim_frozen()


_dimfz = [None, frozenset()]


def _dim_frozen():
    if _dimfz[0] is not _iso["fz"]:
        _dimfz[:] = [_iso["fz"], frozenset(_iso["fz"])]
    return _dimfz[1]


def dimmed(n):
    """n's wire colour is ours (dimmed) — clean.paint() leaves it alone."""
    return str(int(n.inode.handle)) in _iso["wire"]


_reiso_timer = []


def reiso_soon(*_):
    """After scene changes made elsewhere (merges, undo): once, off the callback."""
    from PySide6.QtCore import QTimer
    if not _reiso_timer:
        t = QTimer()
        t.setSingleShot(True)
        t.timeout.connect(reiso)
        _reiso_timer.append(t)
    _reiso_timer[0].start(80)


def _reiso_after():
    """Navigation: the Browser first, the viewport after. key() / act() publish the new
    tree on the way out; the hide / dim pass (and its redraw, up to ~1 s) runs once
    Max's event loop is back. Quick presses coalesce — reiso diffs against what we did."""
    reiso_soon()
    _reiso_timer[0].start(0)


_rendering = []


def _pre_render(*_):
    """A render sees every node's own material (the grey isn't a shell)."""
    _rendering.append(1)
    reiso()


def _post_render(*_):
    del _rendering[:]
    reiso_soon()


def toggle_isolate():
    _iso["on"] = not _iso["on"]
    reiso()


# ──────────────────────────────────────────────────────────────── acting

_BIG = 200    # a folder pick this big selects with the Create panel up (Modify: 2× slower)
_renames = [0]


def _top(n):
    """The top node above n (group members and linked children are filed with it)."""
    while not _undef(n.parent):
        n = n.parent
    return n


def _folder_nodes(toks):
    """Everything in these folders and the folders inside them, hidden and frozen left
    out — one MAXScript call (8000 nodes: ~0.2 s to select)."""
    d = G.load()
    gids = set()
    for t in toks:
        if t.startswith("G:") and t[2:] in d["g"]:
            gids |= G.subtree(d, t[2:])
    if not gids:
        return []
    G.ms()
    return list(rt.callisNodesOf(_idx().handles_in(gids)))


def _picks():
    """The rows the Browser itself picked (⌘ / ⇧ / Space clicks), while what they selected
    is still Max's whole selection; else None. Folder rows draw `sel` off this, and the
    browser keys act on a picked folder rather than its thousands of objects."""
    p = _v["picks"]
    return p[0] if p and p[1] == int(rt.selection.count) else None


def _picked_folder():
    return next((t for t in (_picks() or []) if t.startswith("G:")), None)


def _last_selected():
    c = int(rt.selection.count)
    return rt.selection[c - 1] if c else None


def _sel_nodes(toks, whole=False):
    """The nodes these rows select (_select), and the modifier a modifier row makes current."""
    nodes = [n for n in (_node(t) for t in toks) if n is not None]
    for t in toks:
        if t[:2] in ("D:", "I:"):
            nodes += _here(t)[1]
    folders = [t for t in toks if t.startswith("G:")] if whole else []
    if folders:
        nodes += _folder_nodes(folders)
    m = None
    mods = [t for t in toks if t.startswith("M:")]
    if mods:
        n, m = _stack_item(mods[-1])
        if n is not None:
            nodes += _family(n)
    return nodes, m


def _select(toks, whole=False):
    """Make these rows Max's selection. A folder row selects nothing (it IS where you
    are) unless `whole` — a ⌘ / ⇧ / Space click — which selects everything inside it,
    as a Fusion component pick does: folders inside too, hidden and frozen left out.
    Plain selection, not a hidden group: a group's members are selected with it, and a
    move's cost is the redraw either way (max_browser/CLAUDE.md). A modifier row
    selects its object and makes the modifier current.
    A definition (or its Instances group, or one of its settings) selects every instance,
    so the Modify panel shows what they share."""
    _own_sel[0] = time.time()
    _v["picks"] = _v["pending"] = None
    nodes, m = _sel_nodes(toks, whole)
    if len(nodes) > _BIG and rt.getCommandPanelTaskMode() == rt.Name("modify"):
        rt.execute("max create mode")
    _selecting[0] = True
    try:
        rt.clearSelection()
        if nodes:
            rt.select(nodes)
    finally:
        _selecting[0] = False
    if whole and nodes:
        _v["picks"] = (list(toks), int(rt.selection.count))
    if m is not None and nodes:
        rt.execute("max modify mode")
        rt.modPanel.setCurrentObject(m)


# Navigation draws first: a nav key's selection (70–400 ms with the Modify panel up, then
# the redraw) runs on a 0 ms QTimer AFTER key() / act() publish, and the rows draw the
# pending pick meanwhile (_rows). Quick presses coalesce — only the last one selects.
_sel_timer = []


def _sel_soon(toks):
    from PySide6.QtCore import QTimer
    _v["pending"], _v["picks"] = list(toks), None
    _own_sel[0] = time.time()
    if not _sel_timer:
        t = QTimer()
        t.setSingleShot(True)
        t.timeout.connect(_sel_now)
        _sel_timer.append(t)
    _sel_timer[0].start(0)


def _sel_now():
    """Run a pending nav selection now (the timer, or anything that reads the selection)."""
    p = _v["pending"]
    if p is None:
        return
    if _sel_timer:
        _sel_timer[0].stop()
    try:
        _select(p)
    except Exception as e:
        _v["pending"] = None
        print("[callis.browser] pending selection failed:", e)
    publish()


def _land(tok, select=True):
    _v["cursor"] = _v["anchor"] = tok
    if select:
        _sel_soon([tok] if tok else [])


def _siblings(rows, i):
    """Indices of row i's siblings (same depth, same parent run)."""
    d = rows[i]["depth"]
    lo = i
    while lo > 0 and rows[lo - 1]["depth"] >= d:
        lo -= 1
    hi = i
    while hi + 1 < len(rows) and rows[hi + 1]["depth"] >= d:
        hi += 1
    return [j for j in range(lo, hi + 1) if rows[j]["depth"] == d]


def _enter(gid, land=True, select=True):
    """Root the tree at this folder (its top row); new objects land in it (_stamp).
    `land` puts the cursor on the first thing in it (F); a click leaves it on the
    folder's own row. `select` False (a viewport click) leaves Max's selection alone."""
    gid = G.valid(G.load(), gid)
    _close_groups()
    _v["root"] = gid or None
    _v["shut"] = False
    _reiso_after()
    rows = _rows()
    if land and len(rows) > 1:
        _land(rows[1]["tok"])
    else:
        _v["cursor"] = rows[0]["tok"] if rows else None
        if select:
            _sel_soon([])


def _children(rows, i):
    """The rows one level inside row i."""
    out = []
    for r in rows[i + 1:]:
        if r["depth"] <= rows[i]["depth"]:
            break
        if r["depth"] == rows[i]["depth"] + 1:
            out.append(r)
    return out


def step(delta):
    rows = _rows()
    if not rows:
        return
    toks = [r["tok"] for r in rows]
    i = toks.index(_v["cursor"]) if _v["cursor"] in toks else (-1 if delta > 0 else 0)
    _land(toks[(i + delta) % len(toks)])


def jump(dir):
    rows = _rows()
    toks = [r["tok"] for r in rows]
    if _v["cursor"] not in toks:
        return step(dir)
    sibs = _siblings(rows, toks.index(_v["cursor"]))
    _land(toks[sibs[-1] if dir > 0 else sibs[0]])


def go_in(deep=False):
    """F: a folder is entered (cursor onto its first row); an object or group with
    something inside (modifiers, members, linked children) opens; a bare object does
    nothing; a modifier shows / hides the command panel. ⇧F keeps going while there is
    exactly one thing inside that opens — or, when the selection (a viewport pick) is
    below the entered folder, goes all the way to it."""
    if deep:
        _sel_now()
    last = None if _picked_folder() else _last_selected()
    if deep and last is not None and _below_root(last):
        return toward(last, deep=True)
    tok = _v["cursor"]
    for _ in range(64):
        if not tok:
            return
        if tok.startswith("G:"):
            _enter(tok[2:])
        elif tok.startswith("N:") and _shut_group(_node(tok)) is not None:
            return _open_group(_shut_group(_node(tok)))     # Go In: its parts pick now
        elif tok[:2] in ("N:", "D:", "I:"):
            rows = _rows()
            row = next((r for r in rows if r["tok"] == tok), None)
            if row is None or not row["kids"]:
                return
            _v["open"].add(tok)
        else:                                     # a modifier: edit it in the panel
            rt.cui.commandPanelOpen = not bool(rt.cui.commandPanelOpen)
            return
        if not deep:
            return
        rows = _rows()
        toks = [r["tok"] for r in rows]
        here = toks.index(tok) if tok in toks else -1
        kids = _children(rows, here) if here >= 0 else []
        if len(kids) != 1 or not kids[0]["kids"]:
            if kids:
                _land(kids[0]["tok"])
            return
        tok = kids[0]["tok"]
        _land(tok)


def go_out():
    if _close_last_group():
        return
    rows = _rows()
    toks = [r["tok"] for r in rows]
    # Close what is open at the deepest level first, the way Fusion's D folds up. The
    # entered folder's own row isn't one of these: D on it leaves the folder.
    open_rows = [r for r in rows if r["open"] and not r.get("root")]
    if open_rows:
        deepest = max(r["depth"] for r in open_rows)
        cur = _v["cursor"]
        for r in open_rows:
            if r["depth"] == deepest:
                _v["open"].discard(r["tok"])
                if cur and cur in toks and toks.index(cur) > toks.index(r["tok"]):
                    # the cursor was inside it: it comes back to the row that closed
                    after = toks[toks.index(r["tok"]) + 1:toks.index(cur) + 1]
                    if all(rows[toks.index(a)]["depth"] > deepest for a in after):
                        _land(r["tok"])
        return
    left = _leave()
    if left:
        _land(_gtok(left))


def _leave():
    """Out of the entered folder into its parent; the folder left, or None at the top."""
    left = _root()
    if not left:
        return None
    _close_groups()
    _v["root"] = G.parent(G.load(), left) or None
    _v["shut"] = False
    _reiso_after()
    return left


# ── the viewport's gestures (callis/nav.py ← reanchor), Fusion's Click Actions ──────
# Right-click (callis/rclick.py) = up a level, three-finger tap = the top. A click is
# Max's own select (2026-10-14: it no longer steps toward the pick, and empty space
# deselects); ⌘-click (Ctrl in Windows) adds / removes (ctrl_click). Space+click / ⇧F go
# all the way down to the pick (Go to Bottom), keeping Max's selection. Only a pick
# strictly BELOW the entered folder moves anything. The selection is kept through the
# taps (unclick undoes the tap's own click), as Fusion's nav commands keep it.

def nav_up():
    if _close_last_group():
        return
    left = _leave()
    if left:
        _v["cursor"] = _gtok(left)


def nav_top():
    _close_groups()
    root = _root()
    if not root:
        return
    top = G.chain(G.load(), root)[0]
    _v["root"] = None
    _v["shut"] = False
    _reiso_after()
    _v["cursor"] = _gtok(top)


def nav_down(deep=False):
    """Go Down / Go to Bottom (Fusion's nav commands): one folder toward the selection, or
    all the way; the selection is kept."""
    sel = list(rt.selection)
    if sel:
        toward(sel[0], deep=deep, select=False)


def _head(n):
    """A group member clicked in the viewport is its outermost CLOSED group — a group's
    selection priority. Inside groups that are open (Go In), it is itself."""
    pick, m = n, n
    while rt.isGroupMember(m) and not _undef(m.parent):
        m = m.parent
        if not rt.isOpenGroupHead(m):
            pick = m
    return pick


def _below_root(n):
    """n's folder is strictly inside the entered folder (any folder, at the top)."""
    g, root = _gid(n), _root()
    if not root:
        return bool(g)
    return g != root and G.inside(G.load(), g, root)


def _reveal(n):
    """Open what n's row sits inside — linked parents, its definition and the Instances
    group — so the cursor can land on it."""
    p = n.parent
    if not _undef(p):
        _reveal(p)
        _v["open"].add(_tok(p))
    if len(_family(n)) > 1:
        _v["open"].update({_def_tok("D", n), _def_tok("I", n)})


def _next_down(chain, root):
    """The folder one step below root on the way down chain (top … n's folder)."""
    return chain[chain.index(root) + 1] if root else chain[0]


def landing(n, deep=False):
    """What the move tool (callis/movetool.py) picks up when it hovers n — SketchUp's
    "the thing in the current context", touching nothing: the folder one step inside the
    entered one on the way down to n (the folder a click enters), else n itself (its
    outermost group); deep (Space held, as Space+click) — n itself. Returns
    (name, top-level nodes to move)."""
    n = _head(n)
    if not deep and _below_root(n):
        d = G.load()
        gid = _next_down(G.chain(d, _gid(n)), _root())
        nodes = _folder_nodes([_gtok(gid)])
        handles = {int(m.inode.handle) for m in nodes}
        tops = [m for m in nodes if not _ancestor_in(m, handles)]
        return d["g"][gid]["name"], tops
    return str(n.name), [n]


def _ancestor_in(n, handles):
    p = n.parent
    while not _undef(p):
        if int(p.inode.handle) in handles:
            return True
        p = p.parent
    return False


def toward(n, deep=False, select=True):
    n = _head(n)
    d = G.load()
    if _below_root(n):
        chain = G.chain(d, _gid(n))
        _enter(chain[-1] if deep else _next_down(chain, _root()), land=False, select=select)
    if _gid(n) == _root():                        # got there
        _reveal(n)
    elif not select:              # not there yet: the cursor on the folder it is inside
        chain, root = G.chain(d, _gid(n)), _root()
        if not root or root in chain:
            return _land(_gtok(_next_down(chain, root)), select=False)
    _land(_tok(n), select=select)


def unclick():
    """Put back the selection from before a viewport click (rclick.py took it on the down)."""
    _own_sel[0] = time.time()
    try:
        rt.callisRestoreSel()
    except Exception as e:
        print("[callis.browser] selection not restored:", e)


def ctrl_click(n):
    """⌘-click (Ctrl in Windows): Max adds what was clicked; one that was already selected
    comes off — whether or not Max's own Ctrl+click toggled it."""
    h = _head(n)
    hid = int(h.inode.handle)
    pre = [p for p in rt.callisPreClick if rt.isValidNode(p)]
    if not h.isSelected or hid not in {int(p.inode.handle) for p in pre}:
        return
    off = [h]
    if rt.isGroupHead(h):
        k = 0
        while k < len(off):
            off += list(off[k].children)
            k += 1
    _own_sel[0] = time.time()
    rt.deselect(off)


def deselect():
    _own_sel[0] = time.time()
    rt.clearSelection()
    _v["cursor"] = None


def escape_or_deselect():
    """Escape / Deselect (macro EscapeOrDeselect) — one key. Something to escape gets
    it: a panel in the Browser's place closes, the Move tool stops, any other command
    mode (creating, a pick, an Edit Poly drag mode — rclick.IDLE says which aren't) gets
    a real Esc. Nothing to escape: Deselect Everything, the Browser's own key."""
    from . import side, movetool, rclick
    if side.close():
        return
    if movetool._s["session"] is not None:
        movetool.stop()
        return
    try:
        idle = str(rt.toolMode.commandMode) in rclick.IDLE
    except Exception:
        idle = True
    if not idle:
        # After the hotkey's own chord has let go, so the Esc goes out bare.
        from PySide6.QtCore import QTimer
        QTimer.singleShot(60, _send_escape)
        return
    key("deselect")


def super_escape():
    """Super Escape (macro SuperEscape) — everything open, out, in one press: the
    panel in the Browser's place, the Move tool, then a real Esc every 120 ms while
    any command mode is still up (a create, a pick, a drag mode inside one…), at most
    8. Nothing open: nothing happens (no Deselect — that is Escape / Deselect's)."""
    from . import side, movetool
    side.close()
    if movetool._s["session"] is not None:
        movetool.stop()
    _super_esc_step(8, 60)              # after the hotkey's chord lets go: a bare Esc


def _super_esc_step(left, wait):
    from . import rclick
    from PySide6.QtCore import QTimer

    def step():
        try:
            idle = str(rt.toolMode.commandMode) in rclick.IDLE
        except Exception:
            idle = True
        if idle or left <= 0:
            return
        _send_escape()
        _super_esc_step(left - 1, 120)
    QTimer.singleShot(wait, step)


def _send_escape():
    import ctypes
    u = ctypes.windll.user32
    u.keybd_event(0x1B, 0, 0, 0)          # VK_ESCAPE down
    u.keybd_event(0x1B, 0, 2, 0)          # KEYEVENTF_KEYUP


# ── groups: real Max groups, inside components ─────────────────────────────────
# A Browser folder is a COMPONENT: organisation only, nothing about it changes a pick. A
# GROUP is Max's own (a group head + members), drawn amber: a click on any part of a
# closed group selects the whole group (Max does that, and _head says so for our own
# picks); Go In opens it (setGroupOpen) so its parts and the groups inside it pick one by
# one; Go Out / right-click / leaving the component closes what Go In opened, innermost
# first. Only groups opened here are tracked — a scene opens with every group shut.
# Grouping re-parents, so per-shot poses are rebased around it (scene.reparenting).

def _shut_group(n):
    """The closed group a pick on n selects (n itself if it's a closed head), or None."""
    if n is None:
        return None
    h = _head(n)
    return h if rt.isGroupHead(h) and not rt.isOpenGroupHead(h) else None


def _set_open(head, on):
    with __import__("pymxs").undo(False):         # where you are isn't an undo step
        rt.setGroupOpen(head, on)


def _open_group(head):
    _set_open(head, True)
    h = int(head.inode.handle)
    if h not in _v["opened"]:
        _v["opened"].append(h)
    _reveal(head)
    _v["open"].add(_tok(head))
    _sel_soon([])
    _v["cursor"] = _v["anchor"] = _tok(head)


def _close_last_group():
    """The innermost group Go In opened shuts, the cursor on it. False when none is."""
    while _v["opened"]:
        n = rt.maxOps.getNodeByHandle(_v["opened"].pop())
        if _undef(n) or not rt.isGroupHead(n):
            continue
        if rt.isOpenGroupHead(n):
            _set_open(n, False)
        _v["open"].discard(_tok(n))
        _v["cursor"] = _tok(n)
        return True
    return False


def _close_groups():
    while _close_last_group():
        pass


def _close_all_groups():
    try:
        heads = [n for n in rt.helpers if rt.isGroupHead(n) and rt.isOpenGroupHead(n)]
    except Exception:
        return
    for n in reversed(sorted(heads, key=lambda x: _depth(x))):
        _set_open(n, False)


def _depth(n):
    d = 0
    while not _undef(n.parent):
        n, d = n.parent, d + 1
    return d


def _unit(n):
    """What moves / groups as one at the level you're at: n's top node, stopping at an
    open group (its members are separate things while it's open)."""
    while True:
        p = n.parent
        if _undef(p) or (rt.isGroupHead(p) and rt.isOpenGroupHead(p)):
            return n
        n = p


def _units(nodes):
    out = {}
    for n in nodes:
        u = _unit(n)
        out.setdefault(int(u.inode.handle), u)
    return list(out.values())


def new_group(at=None):
    """⌘⇧G / New Group: the selection (or a ⌘-picked set of objects) becomes one Max group,
    filed where its first part was. Inside an open group it nests (Max does). Its name
    field opens, like New Folder's."""
    from . import scene
    picks = _picks()
    nodes = [n for t in (picks or []) if not t.startswith("G:") for n in _nodes_of(t)] \
        if picks else list(rt.selection)
    units = _units(nodes)
    if not units:
        raise ValueError("Select what to group")
    gid = _gid(_top(units[0]))
    with scene.reparenting():
        head = rt.group(units, name=str(rt.uniqueName("Group")))
    if _undef(head.parent):
        G.stamp(head, gid)
    _refile(G.load(), {gid})
    _reveal(head)
    if not _undef(head.parent):
        _v["open"].add(_tok(head.parent))
    _own_sel[0] = time.time()
    rt.clearSelection()
    rt.select(head)
    tok = _tok(head)
    _v["cursor"] = _v["anchor"] = tok
    _renames[0] += 1
    _v["rename"] = {"tok": tok, "n": _renames[0]}


def ungroup(tok=None):
    """The group's parts are loose again, where the group was (its component, or the group
    around it)."""
    from . import scene
    n = _node(tok or _v["cursor"] or "")
    if n is None or not rt.isGroupHead(n):
        heads = [x for x in rt.selection if rt.isGroupHead(x)]
        n = min(heads, key=_depth) if heads else None      # the outermost one selected
    if n is None:
        raise ValueError("Not a group")
    gid = _gid(_top(n))
    kids = list(n.children)
    h = int(n.inode.handle)
    with scene.reparenting():
        rt.ungroup(n)
    _v["opened"] = [x for x in _v["opened"] if x != h]
    for k in kids:
        if not _undef(k) and rt.isValidNode(k) and _undef(k.parent):
            G.stamp(k, gid)
    _refile(G.load(), {gid})
    _own_sel[0] = time.time()
    rt.clearSelection()
    live = [k for k in kids if rt.isValidNode(k)]
    if live:
        rt.select(live)
        _v["cursor"] = _tok(live[0])


def _detach(n):
    """n out of its group (Max detaches only from an open group): loose at the top."""
    head = n.parent
    was = bool(rt.isOpenGroupHead(head))
    if not was:
        _set_open(head, True)
    rt.detachNodesFromGroup(n)
    if not was:
        _set_open(head, False)


def _into_group(nodes, head):
    """Attach these (their units) to a group, out of any group they were in."""
    for u in _units(nodes):
        h = int(u.inode.handle)
        p = head
        while not _undef(p):                        # never into itself / its own parts
            if int(p.inode.handle) == h:
                raise ValueError("Can't move a group into itself")
            p = p.parent
        if not _undef(u.parent) and int(u.parent.inode.handle) == int(head.inode.handle):
            continue
        if rt.isGroupMember(u):
            _detach(u)
        rt.attachNodesToGroup(u, head)


# ── hiding ─────────────────────────────────────────────────────────────────────

def _hide_folders(gids, hide):
    """Folders hidden / shown (groups.py § hiding). A folder hiding a node the isolate
    had hidden takes it over; afterwards the isolate is re-applied, so what a shown
    folder brings back outside an isolated folder goes hidden again."""
    d, idx = G.load(), _idx()
    take = {int(h) for h in _iso["hn"]}
    got = set()
    for g in gids:
        got |= set(G.set_hidden(d, idx, g, hide, take)[0])
    G.save(d)
    if got & take:
        _iso["hn"] = [h for h in _iso["hn"] if int(h) not in got]
        _iso_save()
    reiso()


def _set_render(gid, on):
    d = G.load()
    if on:
        d["g"][gid]["render"] = True
    else:
        d["g"][gid].pop("render", None)
    G.save(d)


class render_shown:
    """A production render (render.render_batch — not Quick Render): hidden folders
    ticked Show When Rendering show for it and hide again when it ends, however it
    ends. The old maxstart's " —" layers. Undo off — the scene ends as it began."""

    def __init__(self, log=print):
        self.log, self.gids = log, []

    def __enter__(self):
        d = G.load()
        self.gids = [k for k, g in d["g"].items() if g.get("render") and g.get("hidden")]
        if self.gids:
            with __import__("pymxs").undo(False):
                _hide_folders(self.gids, False)
            self.log("Shown for the render: " + ", ".join(sorted(d["g"][k]["name"] for k in self.gids)))
            publish(now=True)
        return self

    def __exit__(self, *exc):
        d = G.load()
        back = [k for k in self.gids if k in d["g"] and not d["g"][k].get("hidden")]
        if back:
            with __import__("pymxs").undo(False):
                _hide_folders(back, True)
            publish(now=True)
        return False


def _set_nodes_hidden(ns, hide):
    """Objects hidden / shown themselves. Shown: no folder holds them hidden any more,
    and a hidden Max layer (someone else's) under them is shown too."""
    for n in ns:
        n.isHidden = hide
    if hide:
        return
    d = G.load()
    hs = {int(n.inode.handle) for n in ns}
    changed = False
    for g in d["g"].values():
        keep = [h for h in g.get("hid", []) if int(h) not in hs]
        if len(keep) != len(g.get("hid", [])):
            g["hid"], changed = keep, True
    if changed:
        G.save(d)
    for n in ns:
        lay = n.layer
        while not _undef(lay):
            if bool(lay.ishidden):
                lay.ishidden = False
            lay = lay.getParent()


def toggle_hidden():
    d = G.load()
    if _picked_folder():                          # a ⌘/Space pick holding folders: hide them
        picks = _picks()
        gids = [t[2:] for t in picks if t.startswith("G:") and t[2:] in d["g"]]
        ns = [n for t in picks if not t.startswith("G:") for n in _nodes_of(t)]
        hide = not all([bool(d["g"][g]["hidden"]) for g in gids] + [bool(n.isHidden) for n in ns])
        _set_nodes_hidden(ns, hide)
        _hide_folders(gids, hide)
        return
    sel = list(rt.selection)
    if sel:
        _set_nodes_hidden(sel, not all(bool(n.isHidden) for n in sel))
    elif _v["cursor"] and _v["cursor"].startswith("G:") and _v["cursor"][2:] in d["g"]:
        g = _v["cursor"][2:]
        _hide_folders([g], not d["g"][g]["hidden"])


def rename(tok=None, name=None):
    tok = tok or _v["cursor"]
    if not tok:
        return
    d = G.load()
    if name is None:                              # from a Max hotkey: ask in Max
        from PySide6.QtWidgets import QInputDialog
        import qtmax
        old = ""
        if tok.startswith("G:") and tok[2:] in d["g"]:
            old = d["g"][tok[2:]]["name"]
        elif tok.startswith("N:") and _node(tok):
            n = _node(tok)
            num = _number(n)
            old = _inst_name(n, num) if num else str(n.name)
        elif tok.startswith("D:") and _here(tok)[1]:
            old = _def_name(_here(tok)[1][0])
        name, ok = QInputDialog.getText(qtmax.GetQMaxMainWindow(), "Rename", "Name", text=old)
        if not ok:
            return
    name = name.strip()
    if not name:
        return
    if tok.startswith("G:"):
        if tok[2:] in d["g"]:
            d["g"][tok[2:]]["name"] = name
            G.save(d)
    elif tok.startswith("M:"):
        n, m = _stack_item(tok)
        if m is not None and not tok.endswith(":base"):
            m.name = name
    elif tok.startswith("D:"):                    # the definition: on the shared base object
        allof = _here(tok)[1]
        if allof:
            rt.setAppData(allof[0].baseObject, _DEF_NAME, name)
    elif tok.startswith("N:"):
        n = _node(tok)
        if n is not None:
            n.name = name
            if _number(n):                        # an instance: named, not numbered now
                rt.setAppData(n, _INST_NAME, str(n.name))


# ── folders: new, move, delete ─────────────────────────────────────────────────

def _refile(d, gids):
    """After membership / folder parents changed: a fresh index, and every node in these
    folders brought in line with their hidden flags; then the isolate."""
    global _index, _inst
    G.save(d)
    _index = _inst = None
    G.refit(d, _idx(), _idx().handles_in(gids))
    G.save(d)
    reiso()


def new_folder(at=None):
    """⌘G / New Folder — Fusion's addFolder: what's picked (folders, objects) or selected
    goes into a new folder made where the first of them was; nothing selected → an empty
    one in the menu's row (a folder, or the folder an object is in), else the entered
    folder. It opens, the cursor lands on it and the page starts its name field."""
    d = G.load()
    picks = _picks()
    if picks:
        wrap_g = [t[2:] for t in picks if t.startswith("G:") and t[2:] in d["g"]]
        nodes = [n for t in picks if not t.startswith("G:") for n in _nodes_of(t)]
    else:
        wrap_g, nodes = [], list(rt.selection)
    # what travels inside a wrapped folder isn't wrapped again
    wrap_g = [g for g in wrap_g if not any(o != g and G.inside(d, g, o) for o in wrap_g)]
    tops = list({int(t.inode.handle): t for t in map(_top, nodes)}.values())
    tops = [n for n in tops if not any(G.inside(d, _gid(n), o) for o in wrap_g)]
    if wrap_g:
        container = G.parent(d, wrap_g[0])
    elif tops:
        container = _gid(tops[0])
    elif at and at.startswith("G:"):
        container = G.valid(d, at[2:])
    elif at and at[:2] in ("N:", "D:", "I:", "M:"):
        n = _stack_item(at)[0] if at.startswith("M:") else next(iter(_nodes_of(at)), None)
        container = _gid(n) if n is not None else _root()
    else:
        container = _root()
    gid = G.add(d, "Folder", container)
    old = set()
    for g in wrap_g:
        old.add(G.parent(d, g))
        d["g"][g]["parent"] = gid
    for n in tops:
        old.add(_gid(n))
        G.stamp(n, gid)
    _refile(d, G.subtree(d, gid) | old)
    tok = _gtok(gid)
    _v["open"].add(tok)
    if container and container != _root():
        _v["open"].add(_gtok(container))
    _select([])
    _v["cursor"] = _v["anchor"] = tok
    _renames[0] += 1
    _v["rename"] = {"tok": tok, "n": _renames[0]}


def _members(n):
    """A group head moves with its members."""
    out = [n]
    if rt.isGroupHead(n):
        for c in n.children:
            out += _members(c)
    return out


def cut():
    """⌘X: the selected objects, else the cursor row (a folder or an object). Nothing
    moves until the paste; the rows draw faded meanwhile. It's the clipboard's last action
    now (callis/clip.py), so the next Paste re-files it."""
    from . import clip
    clip.cut_marked()
    if _picked_folder():                          # a pick holding folders: the rows themselves
        _v["cut"] = [t for t in _picks() if t[:2] in ("G:", "N:", "D:", "I:")]
        return
    toks = [_tok(n) for n in _units(rt.selection)]      # a selected group, not its parts
    c = _v["cursor"]
    if not toks and c and c[:2] in ("G:", "N:", "D:", "I:"):
        toks = [c]
    _v["cut"] = toks


def uncut():
    _v["cut"] = []


def _paste_target():
    """Fusion's pasteTarget: on a folder → into it; on a group → into the group; on an
    object → its folder (or the group it's in); nothing → the entered folder (or the top).
    A folder id, or "N:<head>" for a group."""
    d = G.load()
    c = _v["cursor"]
    if c and c.startswith("G:") and c[2:] in d["g"]:
        return c[2:]
    if c and c[:2] in ("N:", "M:", "D:", "I:"):
        n = _stack_item(c)[0] if c.startswith("M:") else next(iter(_nodes_of(c)), None)
        if n is not None:
            if c.startswith("N:") and rt.isGroupHead(n):
                return c
            if rt.isGroupMember(n):
                return _tok(n.parent)
            return _gid(_top(n))
    return _root()


def move(toks, into):
    """Into a folder: folders re-parent, objects are filed there (a group's members and
    linked children with their top node; a group's member comes out of its group).
    Into a group ("N:<head>"): objects and groups are attached to it. A folder can't go
    into itself or what's inside it, nor into a group; a group not into itself."""
    from . import scene
    d = G.load()
    head = _node(into) if into and into.startswith("N:") else None
    nodes = [n for t in toks if t[:2] in ("N:", "D:", "I:") for n in _nodes_of(t)]
    hs = {int(n.inode.handle) for n in nodes}
    nodes = [n for n in nodes if not _ancestor_in(n, hs)]    # a group's parts go with it
    if head is not None:
        if not rt.isGroupHead(head):
            raise ValueError("Not a group")
        if any(t.startswith("G:") for t in toks):
            raise ValueError("A component can't go into a group")
        gid = _gid(_top(head))
        touched = {gid} | {_gid(_top(n)) for n in nodes}
        with scene.reparenting():
            _into_group(nodes, head)
        _v["cut"] = []
        _v["open"].add(_tok(head))
        _refile(d, touched)
        return
    into = G.valid(d, into or "")
    touched = {into}
    for t in toks:
        if t.startswith("G:"):
            gid = t[2:]
            if gid not in d["g"]:
                continue
            if G.inside(d, into, gid):
                raise ValueError("Can't move a folder into itself")
            touched.add(G.parent(d, gid))
            d["g"][gid]["parent"] = into
            touched |= G.subtree(d, gid)
    out = [n for n in nodes if rt.isGroupMember(n)]   # out of their groups, then filed
    if out:
        touched |= {_gid(_top(n)) for n in out}
        with scene.reparenting():
            for n in out:
                _detach(n)
    for n in nodes:
        if _undef(n.parent):
            touched.add(_gid(n))
            G.stamp(n, into)
    _v["cut"] = []
    _refile(d, touched)


def paste():
    d = G.load()
    toks = [t for t in _v["cut"] if (t.startswith("G:") and t[2:] in d["g"]) or _nodes_of(t)]
    if not toks:
        _v["cut"] = []
        return
    into = _paste_target()
    if into:
        _v["open"].add(into if into.startswith("N:") else _gtok(into))
    move(toks, into)


def delete_folder(gid):
    """A folder goes; what was in it moves up into its parent, nothing is deleted."""
    global _index, _inst
    d = G.load()
    if gid not in d["g"]:
        return
    if _v["root"] == gid:
        _v["root"] = G.parent(d, gid) or None
    G.remove(d, _idx(), gid)
    G.save(d)
    _index = _inst = None
    reiso()


KEYS = {"down": lambda: step(1), "up": lambda: step(-1), "top": lambda: jump(-1),
        "bottom": lambda: jump(1), "in": go_in, "deep": lambda: go_in(True), "out": go_out,
        "deselect": deselect, "hide": toggle_hidden, "rename": rename,
        "newfolder": new_folder, "newlayer": new_folder,     # (the old key's name)
        "newgroup": new_group, "ungroup": ungroup,
        "cut": cut, "paste": paste, "isolate": toggle_isolate,
        "navup": nav_up, "navtop": nav_top,
        "navdown": nav_down, "navbottom": lambda: nav_down(True)}
_UNDO = {"hide": "Hide", "rename": "Rename", "newfolder": "New Component", "newlayer": "New Component",
         "newgroup": "Group", "ungroup": "Ungroup"}


_NAV = {"down", "up", "top", "bottom", "in", "out", "navup", "navtop"}   # never read the selection


def key(name):
    """A browser key pressed in Max (macroScript) or in the Mac window."""
    from . import side
    p = side.page()                              # a settings panel the page draws (panel.py)
    if p is not None and p.key(name):
        publish(now=True)
        return
    from . import appearance                     # Appearances has the focus (appearance.py)
    if appearance.focused():
        try:
            if appearance.key(name):
                return
        except ValueError as e:
            print("[callis.appearance]", e)
            return
        finally:
            publish(now=True)
    if name == "out" and side.close():          # D: a panel in the Browser's place → the Browser
        return
    if name == "rename" and side.edit():         # a picked number field in that panel
        return
    try:
        if name not in _NAV:
            _sel_now()                            # a key that reads the selection: settle it
        if name in ("paste", "copy"):              # the clipboard decides (callis/clip.py)
            from . import clip
            (clip.paste if name == "paste" else clip.copy)()
        elif name in _UNDO:
            _undoable(_UNDO[name], KEYS[name])
        else:
            with __import__("pymxs").undo(False):
                KEYS[name]()
    except ValueError as e:                       # a refused move
        print("[callis.browser]", e)
    finally:
        publish(now=True)


def _pick_click(tok, a):
    """⌘ / ⇧ / Space clicks, as in Fusion's Browser: they only select — nothing enters,
    opens or folds — and a folder selects everything inside it (_select whole).
    Space: this row alone (again, while it is the whole selection: deselect).
    ⌘: add it to / take it out of the selection.  ⇧: every row from the anchor (the
    last row clicked without ⇧) to here, replacing the selection."""
    rows = _rows()
    toks = [r["tok"] for r in rows]
    row = next((r for r in rows if r["tok"] == tok), None)
    cur = _picks()
    if cur is None:                               # a viewport selection to build on
        cur = [_tok(n) for n in rt.selection]
    mine = {_tok(n) for n in _nodes_of(tok)}      # the objects the row stands for
    _v["cursor"] = tok
    if a.get("shift"):
        anchor = _v["anchor"] if _v["anchor"] in toks else _v["cursor"]
        if anchor in toks and tok in toks:
            i, j = sorted((toks.index(anchor), toks.index(tok)))
            _select([t for t in toks[i:j + 1] if not t.startswith("M:")], whole=True)
        return
    _v["anchor"] = tok
    if a.get("meta"):
        if tok in cur or (row and row["sel"]):
            new = [t for t in cur if t != tok and t not in mine]
        else:
            new = cur + [tok]
        if new:
            _select(new, whole=True)
        else:
            deselect()
        return
    if cur == [tok] or (mine and set(cur) == mine):
        deselect()
    else:
        _select([tok], whole=True)


def _undoable(name, fn, *args):
    """fn as one undo record. pymxs's undo context swallows exceptions, so a refusal
    (ValueError) is carried out of it and raised here, for the page to flash."""
    err = []

    def run():
        try:
            fn(*args)
        except ValueError as e:
            err.append(e)
    with __import__("pymxs").undo(True, name):
        run()
    if err:
        raise err[0]


def act(a):
    """A click / menu pick from the Mac page."""
    op, tok = a.get("op"), a.get("tok")
    if op == "frame":                              # the page's size → the strip (side.py)
        from . import side
        side.set_frame(a)
        return True
    if op in ("panel", "closepanel"):              # the page-drawn settings panel (panel.py)
        from . import side
        p = side.page()
        try:
            if op == "closepanel":
                side.close()
            elif p is not None:
                p.act(a)
        finally:
            publish(now=True)
        return True
    if (tok or "").startswith("A:") or op in ("newlib", "hideappear"):   # Appearances rows
        from . import appearance
        try:
            appearance.act(a)
        finally:
            publish(now=True)
        return True
    if op == "click":                              # a tree click: the keys are the tree's again
        from . import appearance
        appearance.blur()
    try:
        if op not in ("key", "click") or a.get("meta") or a.get("shift") or a.get("alt"):
            _sel_now()
        if op == "key":
            key(a["key"])
        elif op == "click":
            # Fusion's Browser clicks: a folder goes in (its own top row folds and
            # unfolds instead), selecting nothing; an object or group is picked and
            # opens / shuts what's in it — its modifier stack, members, linked children;
            # a row with nothing in it that is already the whole selection deselects.
            # ⌘ / ⇧ / Space (Option, from remapd) only select: _pick_click.
            if a.get("meta") or a.get("shift") or a.get("alt"):
                _pick_click(tok, a)
            elif tok.startswith("G:"):
                _v["anchor"] = tok
                if tok == _gtok(_root()):
                    _v["shut"] = not _v["shut"]
                    _v["cursor"] = tok
                    _sel_soon([])
                else:
                    _enter(tok[2:], land=False)
            elif tok[:2] in ("D:", "I:"):          # a definition / its Instances: open + pick all
                _v["open"].symmetric_difference_update({tok})
                _land(tok)
            elif tok.startswith("N:"):
                n = _node(tok)
                if n is None:
                    return True
                row = next((r for r in _rows() if r["tok"] == tok), None)
                if rt.superClassOf(n) == rt.camera:   # a camera: its settings (props.camera's panel)
                    from . import props
                    _land(tok)
                    _sel_now()
                    _hide_cmd_panel()
                    props._open("camera", n, props.CAMERA)
                elif row and row["kids"]:
                    _v["open"].symmetric_difference_update({tok})
                    _land(tok)
                elif (_v["pending"] == [tok] if _v["pending"] is not None
                      else n.isSelected and int(rt.selection.count) == 1):
                    deselect()
                else:
                    _land(tok)
            else:
                _land(tok)
        elif op == "enter":                        # the menu's Go In
            if tok.startswith("G:"):
                _enter(tok[2:])
            elif tok.startswith("N:"):                 # a group: open it
                _v["cursor"] = tok
                go_in()
        elif op == "rename":
            _undoable("Rename", rename, tok, a.get("name", ""))
        elif op == "vis":
            _v["cursor"] = tok
            if tok[:2] in ("N:", "D:", "I:"):      # a definition: its instances here
                ns = _nodes_of(tok)
                _undoable("Hide", _set_nodes_hidden, ns, not all(bool(n.isHidden) for n in ns))
            elif tok.startswith("G:"):
                g = G.load()["g"].get(tok[2:])
                if g is not None:
                    _undoable("Hide", _hide_folders, [tok[2:]], not g["hidden"])
            elif tok.startswith("M:"):
                n, m = _stack_item(tok)
                if m is not None and not tok.endswith(":base"):
                    m.enabled = not bool(m.enabled)
        elif op == "isolate":
            if tok.startswith("G:"):                  # a folder: go in and isolate it
                _enter(tok[2:], land=False)
                _iso["on"] = True
                reiso()
            else:
                _select([tok])
                rt.IsolateSelection.EnterIsolateSelectionMode()
        elif op == "toggleiso":
            toggle_isolate()
        elif op == "cut":
            cut()
        elif op == "uncut":
            uncut()
        elif op in ("paste", "copy"):              # the clipboard decides (callis/clip.py)
            from . import clip
            (clip.paste if op == "paste" else clip.copy)()
        elif op == "move":
            into = a.get("into") or ""
            _undoable("Browser Move", move, a.get("toks", []),
                      into[2:] if into.startswith("G:") else into if into.startswith("N:") else "")
        elif op == "delete":
            if tok.startswith("G:"):
                _undoable("Delete Folder", delete_folder, tok[2:])
            elif tok.startswith("M:"):
                n, m = _stack_item(tok)
                if m is not None and not tok.endswith(":base"):
                    for x in _family(n):              # an instanced modifier: off every instance
                        rt.deleteModifier(x, m)
            else:
                ns = _nodes_of(tok)                  # a definition: its instances here
                if ns:
                    _own_sel[0] = time.time()
                    rt.clearSelection()
                    rt.select(ns)                    # (a closed group selects its members)
                    rt.delete(rt.selection)
        elif op in ("newfolder", "newlayer"):
            _undoable("New Component", new_folder, tok)
        elif op == "newgroup":
            _undoable("Group", new_group, tok)
        elif op == "ungroup":
            _undoable("Ungroup", ungroup, tok)
        elif op == "renderon":                     # the menu's Show When Rendering tick
            g = G.load()["g"].get((tok or "")[2:]) if (tok or "").startswith("G:") else None
            if g is not None:
                _undoable("Show When Rendering", _set_render, tok[2:], not g.get("render"))
        elif op == "showkind":                     # the menu's Targets / Helpers / Splines ticks
            toggle_kind(a.get("kind"))
    finally:
        publish(now=True)
    return True
