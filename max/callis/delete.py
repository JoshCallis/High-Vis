"""The ONE Delete (Fusion's Deleting.py / Delete Selection, for Max): macro `Delete`
(category "Callis Modeling", startup.py), whatever is current. One undo step "Delete".

What it does, first rule that applies:
  Browser-picked components (⌘ / ⇧ / Space on a folder row) → exploded: the component
      goes, what was in it moves up a level (browser.delete_folder). Groups and objects
      picked with them follow the rules below.
  a sub-object level (Editable / Edit Poly, Mesh, Spline) → the sub-selection:
      poly vertices / edges are REMOVED (dissolved, the surface stays — Backspace /
      Ctrl+Backspace, not Delete's hole), faces / elements deleted, borders refused;
      mesh and spline = Max's own sub-object Delete.
  a modifier made current from its Browser row → that modifier, off every instance.
  objects → closed groups among them are EXPLODED (ungrouped, the parts left selected,
      so Delete again deletes them); everything else is deleted. Inside an open group
      (Go In) its parts are the units, so a part that is a group explodes, not the group.
"""
import traceback

import pymxs
from pymxs import runtime as rt

from . import browser as B
from . import hud
from . import smart

# Editable Poly's edge Remove keeps the end vertices (every flag, measured 2026-10-14);
# Ctrl+Backspace's "and the vertices" = remove the ends left with 2 edges — inside the
# surface always (they shape nothing), on an open border only where it runs straight, so
# a corner of the outline is never cut off.
_EPOLY_EDGES = """(
    local vs = polyop.getVertsUsingEdge T (polyop.getEdgeSelection T)
    T.EditablePoly.Remove selLevel:#Edge flag:1
    local open = polyop.getOpenEdges T
    fn straight T v es = (
        local p = polyop.getVert T v, d = #()
        for e in es do (local ab = polyop.getEdgeVerts T e
                        append d (normalize ((polyop.getVert T (if ab[1] == v then ab[2] else ab[1])) - p)))
        dot d[1] d[2] < -0.9998
    )
    local loose = for v in vs where v <= (polyop.getNumVerts T) collect (
        local es = (polyop.getEdgesUsingVert T v) as array
        if es.count == 2 and ((open * (es as bitArray)).isEmpty or straight T v es) then v else dontCollect
    )
    if loose.count > 0 do (polyop.setVertSelection T (loose as bitArray)
                           T.EditablePoly.Remove selLevel:#Vertex)
    polyop.setEdgeSelection T #{}
)"""

SUB = {"poly": {"v": ("A.EditablePoly.Remove selLevel:#Vertex", "A.ButtonOp #RemoveVertex"),
                "e": (_EPOLY_EDGES, "A.ButtonOp #RemoveEdgeRemoveVertices"),
                "f": ("A.EditablePoly.delete #Face", "A.ButtonOp #DeleteFace"),
                "el": ("A.EditablePoly.delete #Face", "A.ButtonOp #DeleteFace")},
       "mesh": {"*": "max delete"},
       "spline": {"*": "max delete"}}


def run():
    try:
        _run()
    except Exception as e:
        traceback.print_exc()
        hud.show("Delete failed: %s" % e, 2000)
    finally:
        B.publish(now=True)


def _run():
    picks = B._picks() or []
    folders = [t[2:] for t in picks if t.startswith("G:")]
    if folders:
        nodes = [n for t in picks if t[:2] in ("N:", "D:", "I:") for n in B._nodes_of(t)]
        B._undoable("Delete", _explode_folders, folders, nodes)
        return
    lv = rt.execute("subObjectLevel")
    if isinstance(lv, (int, float)) and lv > 0 and rt.selection.count:
        _sub()
        return
    mod = _browser_modifier()
    if mod:
        B._undoable("Delete", _delete_modifier, *mod)
        return
    sel = list(rt.selection)
    if not sel:
        hud.show("Select something to delete")
        return
    B._undoable("Delete", _objects, sel)


def _explode_folders(gids, nodes):
    for g in gids:
        B.delete_folder(g)
    B._v["picks"] = None
    if nodes:
        _objects(nodes)
    else:
        rt.clearSelection()


def _sub():
    c = smart.context()
    rules = SUB.get(c.kind) if c else None
    if rules is None:
        pymxs.runtime.execute("max delete")         # some other modifier's sub-objects
        return
    lv = c.level()
    op = rules.get(lv, rules.get("*"))
    if op is None:
        hud.show("%s — nothing to delete" % smart.NAMES.get(lv, lv), 1400)
        return
    if isinstance(op, tuple):
        op = op[1] if c.mod else op[0]
    smart._undoable("Delete", lambda: smart._ms(op, c))


def _browser_modifier():
    """(node, modifier) when the Browser's cursor is a modifier row and that modifier is
    what the Modify panel shows for its object (a click on the row did that)."""
    tok = B._v.get("cursor") or ""
    if not tok.startswith("M:") or tok.endswith(":base"):
        return None
    n, m = B._stack_item(tok)
    if n is None or m is None or rt.getCommandPanelTaskMode() != rt.Name("modify"):
        return None
    if rt.modPanel.getCurrentObject() != m:
        return None
    hs = {int(x.inode.handle) for x in rt.selection}
    return (n, m) if int(n.inode.handle) in hs else None


def _delete_modifier(n, m):
    for x in B._family(n):                          # an instanced modifier: every instance
        rt.deleteModifier(x, m)


def _objects(nodes):
    units = B._units(nodes)
    heads = [u for u in units if rt.isGroupHead(u) and not rt.isOpenGroupHead(u)]
    hs = {int(h.inode.handle) for h in heads}
    rest = [n for n in nodes if rt.isValidNode(n) and not _in_heads(n, hs)]
    B._own_sel[0] = __import__("time").time()
    if rest:
        rt.delete(rest)
    kept = []
    for h in heads:
        if rt.isValidNode(h):
            kids = list(h.children)
            B.ungroup(B._tok(h))
            kept += [k for k in kids if rt.isValidNode(k)]
    rt.clearSelection()
    if kept:
        rt.select(kept)


def _in_heads(n, hs):
    """n is one of these closed groups, or a part of one."""
    while not B._undef(n):
        if int(n.inode.handle) in hs:
            return True
        n = n.parent
    return False
