"""Smart modelling commands: ONE Extrude (Bevel, Chamfer, …) that does the right thing
for what's current — Editable Poly or an Edit Poly modifier, Editable Mesh or Edit Mesh,
Editable Spline or Edit Spline, a plain shape (Rectangle, Circle…), or any other
geometry (a Box, an object whose current stack item is some other modifier) — at the
current sub-object level. Max's own versions are one macro per object type; these are
one macro per verb (startup.py SMART_VERBS, category "Callis Modeling"), for Control
Room to bind.

How a verb resolves (`run`):
  kind = what's current (`context`): poly / mesh / spline / shape / geo
  the verb's rule for that kind:
    level in the rule      → do it
    level not in the rule  → switch to the rule's `go` level and say what to select
                             (an empty sub-selection would do nothing anyway)
    no rule, kind shape/geo → add Edit Spline / Edit Poly on top and resolve again
Ops are Max's own, the ones its stock macros use (MacroScripts/Macro_EditablePolygon*.mcr,
Macro_EditableMesh.mcr, Macro_EditableSpline.mcr, Macro_Ribbon-Modeling.mcr): polygon ops
open the CADDY (in-viewport settings, live preview — Fusion's dialog); mesh/spline ops
start Max's drag mode. A verb that adds a modifier (Extrude on a shape, Shell, Revolve…)
opens its settings in the Browser's place (props._open → panel.py), as clean mode hides the Modify panel.
"""
import traceback

import pymxs
from pymxs import runtime as rt

from . import hud

# ──────────────────────────────────────────────────────────────── what's current

EDIT = {"Editable_Poly": "poly", "Edit_Poly": "poly",
        "Editable_mesh": "mesh", "Edit_Mesh": "mesh",
        "SplineShape": "spline", "line": "spline", "Edit_Spline": "spline"}
WRAP = {"geo": ("Edit_Poly", "poly"), "shape": ("Edit_Spline", "spline")}

# sub-object level number → letter, per kind (0 = object, "o")
LEVELS = {"poly": {1: "v", 2: "e", 3: "b", 4: "f", 5: "el"},
          "mesh": {1: "v", 2: "e", 3: "f", 4: "f", 5: "el"},
          "spline": {1: "v", 2: "s", 3: "sp"}}
GO = {"poly": {"v": 1, "e": 2, "b": 3, "f": 4, "el": 5},
      "mesh": {"v": 1, "e": 2, "f": 4, "el": 5},
      "spline": {"v": 1, "s": 2, "sp": 3}}
NAMES = {"v": "Vertices", "e": "Edges", "b": "Borders", "f": "Faces", "el": "Elements",
         "s": "Segments", "sp": "Splines"}


class Ctx:
    def __init__(self, kind, A, N, sel):
        self.kind, self.A, self.N, self.sel = kind, A, N, sel
        # an Edit Poly / Edit Mesh / Edit Spline modifier, rather than the base object
        self.mod = A is not None and str(rt.classOf(A)) in ("Edit_Poly", "Edit_Mesh", "Edit_Spline")

    def level(self):
        lv = rt.execute("subObjectLevel")
        lv = int(lv) if isinstance(lv, (int, float)) else 0
        return LEVELS.get(self.kind, {}).get(lv, "o")


def context():
    sel = list(rt.selection)
    if not sel:
        return None
    if rt.getCommandPanelTaskMode() != rt.Name("modify"):
        rt.execute("max modify mode")
    A = rt.modPanel.getCurrentObject()
    kind = EDIT.get(str(rt.classOf(A))) if A is not None else None
    if kind is None:
        supers = {str(rt.superClassOf(n)) for n in sel}
        kind = {"shape": "shape", "GeometryClass": "geo"}.get(supers.pop()) if len(supers) == 1 else None
    return Ctx(kind, A, sel[0], sel)


# ──────────────────────────────────────────────────────────────── the verbs

# A rule (per kind) maps a level letter ("*" = any level, "o" = object) to an op:
#   "MAXScript"            run with A = the current stack object, N = the node,
#                          T = N for a base object else A (what meshOps/splineOps take)
#   ("epoly", "modifier")  poly only: Editable Poly's op, Edit Poly modifier's op
#   Mod(...)               add a modifier on top, open its settings
#   callable               fn(ctx)
# and "go" = the level to switch to when the current one isn't in the rule.

class Mod:
    def __init__(self, cls, spec=(), set=None):
        self.cls, self.spec, self.set = cls, spec, set or {}


def _rows(title, *rows):
    """props spec rows: (label, [candidate property names])."""
    return [(title, label, names, "node") for label, names in rows]


EXTRUDE_MOD = Mod("Extrude", _rows("Extrude", ("Distance", ["amount"]), ("Segments", ["segs"]),
                                   ("Cap start", ["capStart"]), ("Cap end", ["capEnd"])))
BEVEL_MOD = Mod("Bevel", _rows("Bevel", ("Start outline", ["Starting_Outline"]),
                               ("Height", ["Level_1_Height"]), ("Outline", ["Level_1_Outline"]),
                               ("Level 2", ["Use_Level_2"]), ("Height 2", ["Level_2_Height"]),
                               ("Outline 2", ["Level_2_Outline"])))
CHAMFER_ROWS = _rows("Chamfer", ("Amount", ["amount"]), ("Segments", ["segments"]),
                     ("Tension", ["tension"]))
SHELL_MOD = Mod("Shell", _rows("Shell", ("Inner", ["innerAmount"]), ("Outer", ["outerAmount"]),
                               ("Segments", ["segments", "Segments"])))
LATHE_MOD = Mod("Lathe", _rows("Revolve", ("Degrees", ["degrees"]), ("Segments", ["segs"]),
                               ("Weld core", ["weldCore"]), ("Flip normals", ["flipNormals"])))
FILLET_SEGS = 4


def _combine(c):
    """Fusion's Combine: everything selected joins the FIRST selected object. A target
    that isn't editable geometry gets an Edit Poly on top (its stack stays live)."""
    if len(c.sel) < 2:
        hud.show("Combine — select two or more objects")
        return
    target, tools = c.sel[0], c.sel[1:]
    top = target.modifiers[0] if len(target.modifiers) else target.baseObject
    cls = str(rt.classOf(top))
    sup = str(rt.superClassOf(target))
    if not (cls in ("Edit_Poly", "Editable_Poly", "Editable_mesh", "SplineShape", "line")
            or sup == "GeometryClass" or (sup == "shape" and not len(target.modifiers))):
        hud.show("Combine — %s isn't an editable spline" % target.name, 1600)
        return

    def work():
        nonlocal top, cls
        # Edit_Poly.attach only works on the modifier CURRENT in the Modify panel —
        # otherwise an access violation (2026-10-12)
        rt.select(target)
        rt.execute("max modify mode")
        if cls == "Edit_Poly":
            rt.modPanel.setCurrentObject(top)
        elif cls not in ("Editable_Poly", "Editable_mesh", "SplineShape", "line"):
            if str(rt.superClassOf(target)) == "shape":
                rt.convertToSplineShape(target)      # a Rectangle / Circle has no attach
                cls = "SplineShape"
            else:
                top = rt.Edit_Poly()                 # its stack stays live underneath
                rt.modPanel.addModToSelection(top)
                cls = "Edit_Poly"
        for n in tools:
            if cls == "Edit_Poly":
                top.attach(n, editPolyNode=target)
            elif cls == "Editable_Poly":
                rt.polyop.attach(target, n)
            elif cls == "Editable_mesh":
                rt.meshop.attach(target, n)
            else:
                rt.convertToSplineShape(n)
                rt.addAndWeld(target, n, -1.0)       # < 0: no welding

    _undoable("Combine", work)
    left = sum(1 for n in tools if rt.isValidNode(n))
    hud.show("Combined %d into %s" % (len(tools) - left, target.name)
             + (" — %d didn't join" % left if left else ""))


VERBS = {
    "extrude": ("Extrude", {
        "poly": {"go": "f", "v": ("A.popupDialog #Extrude", "A.popupDialog #ExtrudeVertex"),
                 "e": ("A.popupDialog #Extrude", "A.popupDialog #ExtrudeEdge"),
                 "b": ("A.popupDialog #Extrude", "A.popupDialog #ExtrudeEdge"),
                 "f": ("A.popupDialog #Extrude", "A.popupDialog #ExtrudeFace")},
        "mesh": {"go": "f", "e": "meshOps.startExtrude T", "f": "meshOps.startExtrude T"},
        "spline": {"*": EXTRUDE_MOD},
        "shape": {"*": EXTRUDE_MOD}}),
    "bevel": ("Bevel", {
        # faces bevel; edges / vertices = a flat (1-segment) chamfer, Fillet's square twin
        "poly": {"go": "f", "f": "A.popupDialog #Bevel",
                 "v": ("(A.vertexChamferSegments = 1; A.popupDialog #Chamfer)",
                       "(A.vertexChamferSegments = 1; A.popupDialog #ChamferVertex)"),
                 "e": ("(A.edgeChamferSegments = 1; A.popupDialog #Chamfer)",
                       "(A.edgeChamferSegments = 1; A.popupDialog #ChamferEdge)"),
                 "b": ("(A.edgeChamferSegments = 1; A.popupDialog #Chamfer)",
                       "(A.edgeChamferSegments = 1; A.popupDialog #ChamferEdge)")},
        "mesh": {"go": "f", "f": "meshOps.startBevel T", "v": "meshOps.startChamfer T",
                 "e": "meshOps.startChamfer T"},
        "geo": {"*": Mod("Chamfer", CHAMFER_ROWS, {"segments": 1})},
        "spline": {"*": BEVEL_MOD},
        "shape": {"*": BEVEL_MOD}}),
    "inset": ("Inset", {
        "poly": {"go": "f", "f": "A.popupDialog #Inset"}}),
    "offset": ("Offset", {
        "poly": {"go": "f", "f": "A.popupDialog #Outline"},
        "spline": {"go": "sp", "sp": "splineOps.startOutline T"}}),
    "chamfer": ("Chamfer", {
        "poly": {"go": "e", "v": ("A.popupDialog #Chamfer", "A.popupDialog #ChamferVertex"),
                 "e": ("A.popupDialog #Chamfer", "A.popupDialog #ChamferEdge"),
                 "b": ("A.popupDialog #Chamfer", "A.popupDialog #ChamferEdge")},
        "mesh": {"go": "e", "v": "meshOps.startChamfer T", "e": "meshOps.startChamfer T"},
        "spline": {"go": "v", "v": "splineOps.startChamfer T"},
        "geo": {"*": Mod("Chamfer", CHAMFER_ROWS)}}),
    "fillet": ("Fillet", {
        # a poly fillet = a chamfer with segments: set some if it has none, then the caddy
        "poly": {"go": "e", "e": ("(if A.edgeChamferSegments < 2 do A.edgeChamferSegments = %d;"
                                  " A.popupDialog #Chamfer)" % FILLET_SEGS,
                                  "(if A.edgeChamferSegments < 2 do A.edgeChamferSegments = %d;"
                                  " A.popupDialog #ChamferEdge)" % FILLET_SEGS)},
        "spline": {"go": "v", "v": "splineOps.startFillet T"},
        "geo": {"*": Mod("Chamfer", CHAMFER_ROWS, {"segments": FILLET_SEGS})}}),
    "weld": ("Weld", {
        "poly": {"go": "v", "v": ("A.popupDialog #WeldSelected", "A.popupDialog #WeldVertex"),
                 "e": ("A.popupDialog #WeldSelected", "A.popupDialog #WeldEdge"),
                 "b": ("A.popupDialog #WeldSelected", "A.popupDialog #WeldEdge")},
        "mesh": {"go": "v", "v": "meshOps.weld T"},
        "spline": {"go": "v", "v": "splineOps.weld T"}}),
    "connect": ("Connect", {
        "poly": {"go": "e", "v": "A.buttonOp #ConnectVertices",
                 "e": "A.popupDialog #ConnectEdges", "b": "A.popupDialog #ConnectEdges"},
        "spline": {"go": "v", "v": "splineOps.startConnect T"}}),
    "bridge": ("Bridge", {
        "poly": {"go": "b", "e": "A.popupDialog #BridgeEdge", "b": "A.popupDialog #BridgeBorder",
                 "f": "A.popupDialog #BridgePolygon"}}),
    "cap": ("Cap", {
        "poly": {"go": "b", "b": "A.buttonOp #Cap"},
        "geo": {"*": Mod("Cap_Holes")}}),
    "cut": ("Cut", {
        "poly": {"*": ("A.toggleCommandMode #CutVertex", "A.toggleCommandMode #Cut")},
        "mesh": {"go": "e", "v": "meshOps.startCut T", "e": "meshOps.startCut T",
                 "f": "meshOps.startCut T"},
        "spline": {"go": "v", "v": "splineOps.startBreak T"}}),
    "slice": ("Slice", {
        "poly": {"*": "A.toggleCommandMode #QuickSlice"},
        "mesh": {"go": "f", "f": "meshOps.startSlicePlane T"}}),
    "detach": ("Detach", {
        "poly": {"go": "f", "v": ("A.buttonOp #Detach", "A.popupDialog #DetachVertex"),
                 "f": ("A.buttonOp #Detach", "A.popupDialog #DetachFace"),
                 "el": ("A.buttonOp #Detach", "A.popupDialog #DetachFace")},
        "mesh": {"go": "f", "f": "meshOps.detach T", "el": "meshOps.detach T"},
        "spline": {"go": "sp", "s": "splineOps.detach T", "sp": "splineOps.detach T"}}),
    "combine": ("Combine", {k: {"*": _combine} for k in ("poly", "mesh", "spline", "shape", "geo")}),
    "shell": ("Shell", {k: {"*": SHELL_MOD} for k in ("poly", "mesh", "geo")}),
    "revolve": ("Revolve", {k: {"*": LATHE_MOD} for k in ("spline", "shape")}),
}


# ──────────────────────────────────────────────────────────────── doing it

def _undoable(title, fn):
    """fn() as one undo record. pymxs.undo swallows exceptions — carry them out."""
    err = []
    with pymxs.undo(True, title):
        try:
            fn()
        except Exception as e:
            err.append(e)
    if err:
        raise err[0]


def _ms(code, c):
    rt.callisSmartA, rt.callisSmartN = c.A, c.N
    rt.execute("(local A = callisSmartA, N = callisSmartN\n"
               " local T = if A == N.baseObject then N else A\n %s\n)" % code)


def _add_mod(m, c, title):
    if rt.execute("subObjectLevel") not in (0, None):
        rt.execute("subObjectLevel = 0")     # else the modifier takes the sub-selection
    mod = getattr(rt, m.cls)()
    for k, v in m.set.items():
        if rt.isProperty(mod, k):
            rt.setProperty(mod, k, v)
    _undoable(title, lambda: rt.modPanel.addModToSelection(mod))
    if m.spec:
        from . import props
        props._open("mod", mod, m.spec)


def run(verb, _wrapped=False):
    try:
        title, rules = VERBS[verb]
        c = context()
        if c is None:
            hud.show("Select something to %s" % title)
            return
        rule = rules.get(c.kind)
        if rule is None:
            cls, kind = WRAP.get(c.kind, (None, None))
            if kind in rules and not _wrapped:
                _undoable(title, lambda: rt.modPanel.addModToSelection(getattr(rt, cls)()))
                return run(verb, _wrapped=True)
            hud.show("%s — not for %s" % (title, _what(c)), 1400)
            return
        lv = c.level()
        op = rule.get(lv, rule.get("*"))
        if op is None:
            go = rule["go"]
            rt.execute("subObjectLevel = %d" % GO[c.kind][go])
            hud.show("%s — select, then %s" % (NAMES[go], title), 1400)
            return
        if isinstance(op, tuple):
            op = op[1] if c.mod else op[0]
        if isinstance(op, str):
            _ms(op, c)
        elif isinstance(op, Mod):
            _add_mod(op, c, title)
        else:
            op(c)
    except Exception as e:
        traceback.print_exc()
        hud.show("%s failed: %s" % (VERBS.get(verb, (verb,))[0], e), 2000)


def _what(c):
    if c.kind is None:
        return "a mixed selection"
    return str(rt.classOf(c.A)).replace("_", " ") if c.A is not None else c.kind
