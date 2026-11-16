"""SketchUp's Move for 3ds Max, plus Rhino's ortho and direction lock (macro `Move`,
category "Callis Modeling"; the user binds S in Control Room ▸ 3ds Max).

  pick up    a selection: click anywhere — that point is the grab point, the selection
             moves whatever was clicked. Nothing selected: the click selects the object
             under it and picks that up. Nothing is highlighted on hover. Click–move–click,
             or press–drag–release. The tool stays on after a drop; the pivot is never
             touched.
  the point  infer.py: lock › ortho › point snap › X/Y/Z from the base or an acquired point
             (hover a snap point ~0.8 s) › edge snap › face snap › the construction plane.
             Snaps: Snapper asks Max tier by tier (points, then edges, then faces), so the
             more specific one always wins; Max draws nothing (display off) — our marker is
             a FILLED disc, white / red / green by tier, shown before a pick-up too (the
             click starts from it). Lines + markers are kept in world space and re-projected
             on every redraw (they follow orbit / pan / zoom); dotted, bold when locked. No
             text at the cursor, ever. Cursor: the four-way move arrow (IDC_SIZEALL).
  paste      start_placing(): a paste (callis/clip.py) rides the cursor as PlaceMover; a
             click places it (one undo step), Esc drops it.
  keys       (owned through rclick.claim — Max's hotkeys don't fire meanwhile)
             F held ortho (it reaches Max as Shift — Karabiner's cad_hover) · Space lock /
             unlock the line it's on · → ← ↑ lock X Y Z ·
             ⌥ tap Move → Copy → Instance · S snaps on/off · type a distance, x,y,z,
             [x,y,z], then ⌘ (Enter); after a copy 5x / /5 · Esc cancels, again exits ·
             right-click exits; the Move key again drops what's held, tool stays on.
             Finger / Space chords are aliased (infer.CHORDS).
  HUD        only the distance, whole millimetres — or what's being typed (a bare number
             is mm, shown "500 mm"); gone the moment the move drops or cancels.

Input: a MAXScript `tool` (Max's mouse events in the viewport) whose handlers call
Session.event; startTool blocks in a nested message loop, so start() defers it to a QTimer
(never run it inside a bridge job — the job would wait for the tool).

Movers (one per kind), each previewing without undo and committing ONE undo record:
  objects            positions = originals + delta; copies cloned at the drop. Frozen while
                     moving (showFrozenInGray off) so Max's snaps skip them.
  Edit Poly mod      MoveSelection (world space) / Cancel / Commit
  everything else    Editable Poly / Mesh / Spline, Edit Mesh / Edit Spline: the SDK's
  sub-object         BaseObject::Move (Max's own Move mode) in theHold: Restore per frame,
                     Accept on the drop. (The SDK route on an Edit Poly MODIFIER crashed Max,
                     2026-10-14 — that's why it has its own mover.)
"""
import math
import re
import time
import traceback

import pymxs
from pymxs import runtime as rt

from . import hud, rclick
from . import infer as I

CLICK_PX = 6           # a release this far from its press drops (drag-release)
DASH, GAP = 16, 10           # guest px (the VM runs at 2×)
DOT, DOT_GAP = 2, 4          # SketchUp-small: 1 pt dots, 2 pt apart
DISC_R = 5                   # the filled snap marker's radius, guest px
# Max's Standard snaps the tool asks for, by tier — most specific first (Snapper)
SNAP_TIERS = (("point", ("Vertex", "Endpoint", "Midpoint")), ("edge", ("Edge/Segment",)),
              ("face", ("Face",)))
HUD_MS = 1500
HOLD_MS = 600000       # the HUD while moving: held until the drop replaces it

# 0–255 colours on the black background: the axes pure red / green / blue, a free direction
# pure magenta; snap markers by tier — point white, edge red, face green
COLOURS = {"x": (255, 0, 0), "y": (0, 255, 0), "z": (0, 0, 255), "dir": (255, 0, 255),
           "from": (220, 220, 220), "point": (255, 255, 255), "edge": (255, 0, 0),
           "face": (0, 255, 0)}
COLOUR_IDX = {k: i + 1 for i, k in enumerate(COLOURS)}

_s = {"session": None, "errors": []}     # errors: the last few tracebacks, for the bridge


def _report():
    t = traceback.format_exc()
    print("[callis.movetool]", t)
    _s["errors"] = (_s["errors"] + [t])[-5:]

_MS = r"""
global callisMvSegs = #(), callisMvMarks = #(), callisMvDiscs = #()
global callisMvCols = #(%s)
global callisMvProject = undefined  -- Python: re-project the world-space lines for this view
-- Python sets it in Session.setup; undeclared here, the tool's handlers bind a tool-local
-- (undefined) in a fresh Max: "Call needs function or class, got undefined"
global callisMoveEvent
global callisMvR = %d
fn callisMvDisc x y c = (           -- a filled circle (hMarker has none): scanlines + a dark rim
    local r = callisMvR
    gw.setColor #line c
    for dy = -r to r do (
        local w = sqrt (r * r - dy * dy)
        gw.hPolyline #([x - w, y + dy, 0], [x + w, y + dy, 0]) false
    )
    gw.setColor #line black
    gw.hPolyline (for k = 0 to 23 collect [x + (r + 1) * cos (k * 15), y + (r + 1) * sin (k * 15), 0]) true
)
fn callisMvDraw = (
    if callisMvProject != undefined do callisMvProject()
    if callisMvSegs.count + callisMvMarks.count + callisMvDiscs.count > 0 do (
        gw.setTransform (matrix3 1)
        local a = callisMvSegs
        for i = 1 to a.count by 5 do (
            gw.setColor #line callisMvCols[a[i + 4]]
            gw.hPolyline #([a[i], a[i + 1], 0], [a[i + 2], a[i + 3], 0]) false
        )
        local m = callisMvMarks
        for i = 1 to m.count by 4 do
            gw.hMarker [m[i], m[i + 1], 0] m[i + 2] color:callisMvCols[m[i + 3]]
        local d = callisMvDiscs
        for i = 1 to d.count by 3 do callisMvDisc d[i] d[i + 1] callisMvCols[d[i + 2]]
        gw.enlargeUpdateRect #whole
        gw.updateScreen()
    )
)
fn callisMvView = (                 -- the active viewport, flat: rows, persp, fov, w, h, upp
    local tm = viewport.getTM(), r = #()
    for v in #(tm.row1, tm.row2, tm.row3, tm.row4) do (append r v.x; append r v.y; append r v.z)
    local a = (mapScreenToWorldRay [0, 0]).pos, b = (mapScreenToWorldRay [100, 0]).pos
    join r #(viewport.IsPerspView(), viewport.GetFOV(), gw.getWinSizeX(), gw.getWinSizeY(), (distance a b) / 100.0)
    r
)
fn callisMvSet nodes origs d = (for i = 1 to nodes.count do nodes[i].pos = origs[i] + d; ok)
fn callisMvClone src typ = (        -- in src's order (cloneNodes keeps it)
    local nn = #()
    maxOps.cloneNodes (for n in src collect n) cloneType:typ newNodes:&nn
    nn
)
fn callisMvLocked nodes = (for n in nodes where (
    local f = getTransformLockFlags n; f[1] or f[2] or f[3]) collect n)
-- world points of the selected sub-objects (what Max's snaps must not land on while moving)
fn callisMvSubPts n A lvl = (
    local pts = #()
    try (
        local c = classOf A
        if c == Editable_Poly then (
            local vs = case lvl of (
                1: polyop.getVertSelection n
                2: polyop.getVertsUsingEdge n (polyop.getEdgeSelection n)
                3: polyop.getVertsUsingEdge n (polyop.getEdgeSelection n)
                default: polyop.getVertsUsingFace n (polyop.getFaceSelection n))
            pts = for v in vs collect polyop.getVert n v node:n
        ) else if c == Edit_Poly then (
            local lv = A.GetEPolySelLevel(), vs = #{}
            if lv == #Vertex then vs = A.GetSelection #Vertex
            else if lv == #Edge or lv == #Border then (
                for e in (A.GetSelection #Edge) do (vs[A.GetEdgeVertex e 1] = true; vs[A.GetEdgeVertex e 2] = true))
            else for f in (A.GetSelection #Face) do
                for k = 1 to (A.GetFaceDegree f) do vs[A.GetFaceVertex f k] = true
            pts = for v in vs collect A.GetVertex v node:n
        ) else if c == Editable_mesh or c == Edit_Mesh then (
            local m = n.mesh
            local vs = case lvl of (
                1: (if c == Edit_Mesh then getVertSelection n A else getVertSelection n)
                2: meshop.getVertsUsingEdge m (if c == Edit_Mesh then getEdgeSelection n A else getEdgeSelection n)
                default: meshop.getVertsUsingFace m (if c == Edit_Mesh then getFaceSelection n A else getFaceSelection n))
            pts = for v in vs collect (getVert m v) * n.objectTransform
        ) else if c == SplineShape or c == line then (
            for s = 1 to numSplines n do (
                local ks = #()
                if lvl == 1 then ks = getKnotSelection n s
                else if lvl == 2 then (for g in (getSegSelection n s) do (
                    append ks g; append ks (if g == numKnots n s then 1 else g + 1)))
                else if findItem (getSplineSelection n) s > 0 then ks = #{1..(numKnots n s)} as array
                for k in ks do append pts (getKnotPoint n s k)
            )
        )
    ) catch ()
    pts
)
global callisMvG = undefined
fn callisMvSdkMove A node d = (     -- BaseObject::Move: what Max's Move mode calls
    if callisMvG == undefined do callisMvG = (dotNetClass "Autodesk.Max.GlobalInterface").Instance
    local g = callisMvG, t = node.objectTransform
    local pm = g.Matrix3.Create()
    pm.SetRow 0 (g.Point3.Create t.row1.x t.row1.y t.row1.z)
    pm.SetRow 1 (g.Point3.Create t.row2.x t.row2.y t.row2.z)
    pm.SetRow 2 (g.Point3.Create t.row3.x t.row3.y t.row3.z)
    pm.SetRow 3 (g.Point3.Create t.row4.x t.row4.y t.row4.z)
    local ax = g.Matrix3.Create()
    ax.IdentityMatrix()
    local a = g.Animatable.GetAnimByHandle (dotNetObject "System.UIntPtr" (getHandleByAnim A))
    a.Move currentTime.ticks pm ax (g.Point3.Create d.x d.y d.z) false
    ok
)
tool callisMoveTool (
    on freeMove do callisMoveEvent #free 0 viewPoint lbutton snapMode.hit snapMode.worldHitpoint
    on mouseMove clickno do callisMoveEvent #move clickno viewPoint lbutton snapMode.hit snapMode.worldHitpoint
    on mousePoint clickno do callisMoveEvent #point clickno viewPoint lbutton snapMode.hit snapMode.worldHitpoint
    on mouseAbort clickno do callisMoveEvent #abort clickno viewPoint false false [0,0,0]
)
""" % (", ".join("(color %d %d %d)" % c for c in COLOURS.values()), DISC_R)

_ms_done = [None]


def _ms():
    if _ms_done[0] != _MS:
        rt.execute(_MS)
        _ms_done[0] = _MS


def _p3(v):
    return (float(v.x), float(v.y), float(v.z))


def _P(p):
    return rt.Point3(p[0], p[1], p[2])


def _undef(v):
    return v is None or str(v) == "undefined"


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


# ──────────────────────────────────────────────────────────────── movers

class ObjMover:
    """Whole objects (top-moving ones only: a child moves with its parent)."""
    copyable = True

    def __init__(self, nodes):
        locked = {int(n.inode.handle) for n in rt.callisMvLocked(nodes)}
        self.skipped = [n for n in nodes if int(n.inode.handle) in locked]
        self.all = [n for n in nodes if int(n.inode.handle) not in locked]   # what a copy clones
        hs = {int(n.inode.handle) for n in self.all}
        self.top = [i for i, n in enumerate(self.all) if not _ancestor_in(n, hs)]
        self.nodes = [self.all[i] for i in self.top]                       # what moves
        self.orig = [n.pos for n in self.nodes]
        self.cloned, self.clones = [], []   # preview clones (copy / instance), undo off
        self.frozen = []           # (node, wasFrozen, showFrozenInGray)
        self.mode = "move"

    def label(self):
        return self.nodes[0].name if len(self.nodes) == 1 else "%d objects" % len(self.nodes)

    def begin(self):
        self._freeze(self.nodes)

    def _freeze(self, nodes):
        from . import groups as G
        with pymxs.undo(False), G.quiet(("nodeFreeze", "nodeUnfreeze")):
            for n in nodes:
                self.frozen.append((n, bool(n.isFrozen), bool(n.showFrozenInGray)))
                n.showFrozenInGray = False
                n.isFrozen = True

    def _thaw(self):
        from . import groups as G
        with pymxs.undo(False), G.quiet(("nodeFreeze", "nodeUnfreeze")):
            for n, was, grey in reversed(self.frozen):
                if rt.isValidNode(n):
                    n.isFrozen = was
                    n.showFrozenInGray = grey
        self.frozen = []

    def set_mode(self, mode):
        with pymxs.undo(False):
            if mode == "move" or (self.clones and mode != self.mode):
                self._drop_clones()
            if mode != "move" and not self.clones:
                rt.callisMvSet(self.nodes, self.orig, rt.Point3(0, 0, 0))
                self.cloned, self.clones = self.clone(mode)
                self._freeze(self.cloned)
        self.mode = mode

    def clone(self, mode):
        """(every clone, the clones of the top nodes — in self.nodes order)."""
        new = _clone(self.all, mode)
        return new, [new[i] for i in self.top]

    def _drop_clones(self):
        live = [c for c in getattr(self, "cloned", []) if rt.isValidNode(c)]
        self.frozen = [f for f in self.frozen if f[0] not in live]
        if live:
            rt.delete(live)
        self.cloned, self.clones = [], []

    def preview(self, d):
        with pymxs.undo(False):
            rt.callisMvSet(self.clones or self.nodes, self.orig, _P(d))

    def cancel(self):
        with pymxs.undo(False):
            self._drop_clones()
            rt.callisMvSet(self.nodes, self.orig, rt.Point3(0, 0, 0))
        self._thaw()

    def commit(self, d):
        self.cancel()
        last = Last(self, d)
        _undoable("Move" if self.mode == "move" else "Copy", lambda: last.place(d))
        return last


def _ancestor_in(n, handles):
    p = n.parent
    while not _undef(p):
        if int(p.inode.handle) in handles:
            return True
        p = p.parent
    return False


def _clone(nodes, mode):
    return list(rt.callisMvClone(nodes, rt.Name("instance" if mode == "instance" else "copy")))


class Last:
    """The move just dropped: a distance typed now changes it, 5x / /5 arrays its copies."""

    def __init__(self, mover, d):
        self.m, self.d, self.mode = mover, d, mover.mode
        self.copies, self.extra, self.array = [], [], None

    def place(self, d):
        m = self.m
        if self.mode == "move":
            rt.callisMvSet(m.nodes, m.orig, _P(d))
        else:
            if not self.copies:
                self.copies = m.clone(self.mode)[1]
            rt.callisMvSet(self.copies, m.orig, _P(d))
        self.d = d

    def adjust(self, d):
        def go():
            self.place(d)
            if self.array:
                self._array(*self.array)
        _undoable("Move", go)

    def arrayed(self, n, how):
        if self.mode == "move":
            hud.show("Arrays need a copy — ⌥ before the move", HUD_MS)
            return
        _undoable("Array", lambda: self._array(n, how))

    def _array(self, n, how):
        live = [c for c in self.extra if rt.isValidNode(c)]
        if live:
            rt.delete(live)
        self.extra = []
        ks = range(2, n + 1) if how == "x" else range(1, n)
        for k in ks:
            f = float(k) if how == "x" else float(k) / n
            new, tops = self.m.clone(self.mode)
            rt.callisMvSet(tops, self.m.orig, _P(I.mul(self.d, f)))
            self.extra += new
        self.array = (n, how)


class PlaceMover(ObjMover):
    """A paste being placed (callis/clip.py): preview copies made with undo off ride the
    cursor; the drop deletes them and make()s the real ones, placed, as ONE undo step;
    a cancel just deletes them."""
    copyable = False

    def __init__(self, nodes, make):
        super().__init__(nodes)
        self.preview_nodes, self.make = list(nodes), make

    def label(self):
        return "Paste"

    def _gone(self):
        self._thaw()
        live = [n for n in self.preview_nodes if rt.isValidNode(n)]
        if live:
            with pymxs.undo(False):
                rt.delete(live)

    def cancel(self):
        self._gone()

    def commit(self, d):
        self._gone()
        def go():
            new = self.make()
            hs = {int(n.inode.handle) for n in new}
            top = [n for n in new if not _ancestor_in(n, hs)]
            rt.callisMvSet(top, [n.pos for n in top], _P(d))
            rt.select(new)
        _undoable("Paste", go)
        return None


def _base_of(nodes):
    """Where a paste is held: one object's pivot, else the bottom centre of them all."""
    if len(nodes) == 1:
        return _p3(nodes[0].pos)
    lo = [min(float(getattr(n.min, k)) for n in nodes) for k in "xyz"]
    hi = [max(float(getattr(n.max, k)) for n in nodes) for k in "xyz"]
    return ((lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2, lo[2])


class EPolyMover:
    """Edit Poly modifier sub-objects: its own MoveSelection (world space), Cancel, Commit."""
    copyable = False

    def __init__(self, ctx, lvl):
        self.A, self.N, self.lvl, self.skipped = ctx.A, ctx.N, lvl, []
        self.pts = [_p3(p) for p in rt.callisMvSubPts(ctx.N, ctx.A, lvl)]

    def label(self):
        return "%d vertices" % len(self.pts) if self.pts else "selection"

    def begin(self):
        pass

    def preview(self, d):
        with pymxs.undo(False):
            self.A.Cancel()
            self.A.MoveSelection(_P(d))

    def cancel(self):
        with pymxs.undo(False):
            self.A.Cancel()

    def commit(self, d):
        self.cancel()
        last = SubLast(self, d)
        _undoable("Move", lambda: last.apply(d))
        return last

    def move_by(self, d):
        self.A.MoveSelection(_P(d))
        self.A.Commit()


class SdkMover:
    """Editable Poly / Mesh / Spline and Edit Mesh / Edit Spline sub-objects: Max's own
    BaseObject::Move inside theHold (Restore each frame, Accept on the drop)."""
    copyable = False

    def __init__(self, ctx, lvl):
        self.A, self.N, self.lvl, self.skipped = ctx.A, ctx.N, lvl, []
        self.pts = [_p3(p) for p in rt.callisMvSubPts(ctx.N, ctx.A, lvl)]
        self.held = False
        rt.callisMvA, rt.callisMvN = ctx.A, ctx.N

    def label(self):
        return "%d points" % len(self.pts) if self.pts else "selection"

    def begin(self):
        rt.theHold.Begin()
        self.held = True

    def preview(self, d):
        rt.theHold.Restore()
        rt.callisMvSdkMove(self.A, self.N, _P(d))

    def cancel(self):
        if self.held:
            self.held = False
            rt.theHold.Cancel()

    def commit(self, d):
        rt.theHold.Restore()
        rt.callisMvSdkMove(self.A, self.N, _P(d))
        self.held = False
        rt.theHold.Accept("Move")
        return SubLast(self, d)

    def move_by(self, d):
        rt.callisMvSdkMove(self.A, self.N, _P(d))


class SubLast:
    mode = "move"

    def __init__(self, mover, d):
        self.m, self.d = mover, d

    def apply(self, d):
        self.m.move_by(d)

    def adjust(self, d):
        step = I.sub(d, self.d)
        if isinstance(self.m, SdkMover):
            rt.theHold.Begin()
            try:
                self.m.move_by(step)
            except Exception:
                rt.theHold.Cancel()
                raise
            rt.theHold.Accept("Move")
        else:
            _undoable("Move", lambda: self.m.move_by(step))
        self.d = d

    def arrayed(self, n, how):
        hud.show("Arrays work on objects", HUD_MS)


def _mover():
    """What a press with a selection picks up — None when nothing usable is selected."""
    from . import smart
    sel = list(rt.selection)
    if not sel:
        return None
    lvl = rt.execute("subObjectLevel")
    lvl = int(lvl) if isinstance(lvl, (int, float)) else 0
    if lvl == 0:
        return ObjMover(sel)
    ctx = smart.context()
    if ctx is None or ctx.kind not in ("poly", "mesh", "spline"):
        hud.show("Move: this sub-object level isn't supported", HUD_MS)
        return None
    if str(rt.classOf(ctx.A)) == "Edit_Poly":
        return EPolyMover(ctx, lvl)
    return SdkMover(ctx, lvl)


# ──────────────────────────────────────────────────────────────── snapping

class Snapper:
    """Max's own snap engine, asked tier by tier (ViewExp.SnapPoint with only that tier's
    Standard items on): with everything on at once Max returns whichever hit it likes — an
    Edge point beside an Endpoint, a Face under both. Between asks every item is off, so the
    tool's own snapping finds nothing and Max draws no marker or highlight (display off too).
    ~5–15 ms an ask (2026-10-14): one ask with every tier first — a miss or a point ends
    there; an edge / face asks the tiers above it together, and so on. (A hit on what's
    moving is rejected: then tier by tier.)"""

    LABELS = {0: "Vertex", 1: "Endpoint", 3: "Midpoint"}   # by OsnapHit.Subsnap

    def __init__(self):
        self.g = rt.dotNetClass("Autodesk.Max.GlobalInterface").Instance
        self.flags = rt.dotNetClass("Autodesk.Max.SnapFlags").In3d
        self.items = {}                   # Standard item name → (group, item)
        for i in range(1, int(rt.snapmode.numOSnaps) + 1):
            if str(rt.snapmode.getOSnapName(i)) != "Standard":
                continue
            for j in range(1, int(rt.snapmode.getOSnapNumItems(i)) + 1):
                self.items.setdefault(str(rt.snapmode.getOSnapItemName(i, j)), (i, j))
        self.on = None
        # OsnapHit.Subsnap = the item's index − 1 in its group (Vertex 0, Endpoint 1, Edge 2…)
        self.subs = {t: {self.items[n][1] - 1 for n in names if n in self.items} for t, names in SNAP_TIERS}
        self.names = dict(SNAP_TIERS)
        self.all = [n for _, names in SNAP_TIERS for n in names]
        self.subs["all"] = set().union(*self.subs.values())

    def _set(self, names):
        for n, (i, j) in self.items.items():
            want = n in names
            if self.on is None or (n in self.on) != want:
                rt.snapmode.setOSnapItemActive(i, j, want)
        self.on = set(names)

    def off(self):
        self._set(())

    def at(self, x, y, reject=None):
        """(point, tier, label) at window px x, y (y down), or None. reject(p) → skip a hit
        (the geometry being moved) and try the next tier."""
        if not rt.snapMode.active:
            return None
        g = self.g
        vx, om = g.COREInterface.ActiveViewExp, g.COREInterface.OsnapManager
        ip, op = g.IPoint2NS.Create(int(x), int(y)), g.IPoint2NS.Create(0, 0)
        def ask(names, subs):
            self._set(names)
            r = _p3(vx.SnapPoint(ip, op, None, self.flags))
            # A miss returns the construction-plane point and leaves the LAST hit in
            # snapMode / the manager (Reset doesn't clear it): a real hit returns its point.
            h = om.Hit
            if h is None or not rt.snapMode.hit or int(h.Subsnap) not in subs:
                return None
            p = _p3(rt.snapMode.worldHitpoint)
            if I.length(I.sub(p, r)) > 1e-4 * max(1.0, I.length(p)):
                return None
            n = rt.snapMode.node
            if _undef(n) or n == rt.rootNode:
                return None
            if reject is not None and reject(p, n):
                return "rejected"              # on what's moving: a lower tier may still hit
            return p, int(h.Subsnap)
        try:
            # everything at once first: most frames hit nothing, or a point (done in one ask)
            tiers = [t for t, _ in SNAP_TIERS]
            hit = ask(self.all, self.subs["all"])
            if hit == "rejected":                  # tier by tier, then
                for t in tiers:
                    hit = ask(self.names[t], self.subs[t])
                    if hit is not None and hit != "rejected":
                        break
                else:
                    return None
            while hit is not None:
                tier = next(t for t in tiers if hit[1] in self.subs[t])
                above = tiers[:tiers.index(tier)]  # the more specific tiers, asked together
                better = ask([n for t in above for n in self.names[t]],
                             set().union(*(self.subs[t] for t in above))) if above else None
                if better is None or better == "rejected":
                    return hit[0], tier, self.LABELS.get(hit[1], I.SNAP_LABELS[tier])
                hit, tiers = better, above
            return None
        finally:
            self.off()


# ──────────────────────────────────────────────────────────────── the session

def _view():
    v = list(rt.callisMvView())
    rows = [tuple(v[i:i + 3]) for i in range(0, 12, 3)]
    persp, fov, w, h, upp = v[12:17]
    return I.View(rows, bool(persp), int(w), int(h), float(fov), float(upp) or 1.0)


def _ms_now():
    return time.monotonic() * 1000.0


_cur = {}


def _cursor(on):
    """SketchUp's Move cursor: the four-way arrow — Windows' SizeAll, which cursors/install.ps1
    makes the Mac's move cursor. Set on every tool event; the arrow again at the end."""
    try:
        import ctypes
        u = ctypes.windll.user32
        if not _cur:
            u.LoadCursorW.restype = ctypes.c_void_p
            u.SetCursor.argtypes = [ctypes.c_void_p]
            _cur[True] = u.LoadCursorW(None, ctypes.c_void_p(32646))     # IDC_SIZEALL
            _cur[False] = u.LoadCursorW(None, ctypes.c_void_p(32512))    # IDC_ARROW
        u.SetCursor(_cur[on])
    except Exception:
        pass


class Session:
    def __init__(self):
        self.E = I.Engine()
        self.mover = None
        self.press = None              # where the pick-up happened, till its release
        self.held = False              # the button is down (a drag)
        self.prev = None               # (cursor, Max's hit) of the last event
        self.typed = ""
        self.mode = "move"
        self.last = None
        self.view = None
        self.cursor = (0.0, 0.0)
        self.hit = None                # Max's own tool snap (tests; Snapper off)
        self.snap = None               # (point, tier, label) used this frame
        self.snapper = None
        self.result = None
        self.point = None              # where the grabbed point is now
        self.prims = ([], [])          # world lines (a, b, colour, style), marks (p, marker, colour)
        self.hud = None
        self.snaps0 = None
        self.timer = None
        self.esc0 = None
        self.placing = False           # a paste the tool runs just for: ends with it
        self.mm = float(rt.units.decodeValue("1mm")) or 1.0    # system units per mm

    # set up / tear down ─────────────────────────────────────────────────────────

    def setup(self):
        rt.callisMoveEvent = self.event
        # A MAXScript call that sees Esc down is "interrupted" — it left a cancel half done
        # (the mover kept, the next press did nothing). Esc is ours while the tool runs.
        self.esc0 = bool(rt.escapeEnable)
        rt.escapeEnable = False
        self._snaps(True)
        rclick.claim(self)
        rt.callisMvProject = self._project
        rt.unregisterRedrawViewsCallback(rt.callisMvDraw)
        rt.registerRedrawViewsCallback(rt.callisMvDraw)

    def teardown(self):
        try:
            if self.mover is not None:
                self.mover.cancel()
                self.mover = None
        except Exception:
            _report()
        rclick.release(self)
        try:
            rt.unregisterRedrawViewsCallback(rt.callisMvDraw)
            rt.callisMvProject = None
            self._clear()
        except Exception:
            pass
        self._snaps(False)
        if self.esc0 is not None:
            rt.escapeEnable = self.esc0
        self._hide()
        _cursor(False)
        rt.redrawViews()

    def _snaps(self, on):
        """While the tool runs every snap item is off (Snapper turns a tier on just for its
        ask), Max's markers / highlights / rubber band are off; all restored after."""
        try:
            if on:
                saved = {}
                for i in range(1, int(rt.snapmode.numOSnaps) + 1):
                    for j in range(1, int(rt.snapmode.getOSnapNumItems(i)) + 1):
                        saved[(i, j)] = bool(rt.snapmode.getOSnapItemActive(i, j))
                        rt.snapmode.setOSnapItemActive(i, j, False)
                self.snaps0 = (saved, bool(rt.snapMode.active), str(rt.snapMode.type),
                               bool(rt.snapMode.displayRubberBand), bool(rt.snapMode.display))
                rt.snapMode.active = True
                rt.snapMode.displayRubberBand = False    # Max's own solid line from the base
                rt.snapMode.display = False              # Max's markers + edge / face highlight
                rt.snapMode.type = rt.Name("3D")
                self.snapper = Snapper()
                self.snapper.off()
            elif self.snaps0:
                saved, active, typ, band, display = self.snaps0
                for (i, j), a in saved.items():
                    rt.snapmode.setOSnapItemActive(i, j, a)
                rt.snapMode.active = active
                rt.snapMode.type = rt.Name(typ)
                rt.snapMode.displayRubberBand = band
                rt.snapMode.display = display
                self.snaps0 = None
        except Exception:
            _report()

    # events ─────────────────────────────────────────────────────────────────────

    def event(self, ev, clickno, vp, lbutton, hit, hitpt):
        try:
            ev = str(ev).lower()          # a pymxs Name prints capitalised
            _cursor(True)                 # Max puts its own back on every WM_SETCURSOR
            self.cursor = (float(vp.x), float(vp.y))
            self.hit = _p3(hitpt) if hit else None
            if ev == "abort":
                self._cancel()
                return False
            # Max's tool: the FIRST mousePoint comes on the press (clickno 1), every later
            # one on a release; later presses are seen only as moves with lbutton set.
            if ev == "point":
                if int(clickno) == 1:
                    self.held = False
                    if self.mover is None:
                        self._pick_up()
                else:
                    self._release()
            elif ev == "move" and lbutton and not self.held:
                self.held = True                       # a drag began where the last event was
                if self.mover is None and self.prev is not None:
                    now = self.cursor, self.hit
                    self.cursor, self.hit = self.prev
                    self._pick_up()
                    self.cursor, self.hit = now
            self._update()
            self.prev = self.cursor, self.hit
        except Exception:
            _report()
        return False

    def _snap_now(self):
        """(point, tier, label) under the cursor — Snapper's, or Max's own hit without one."""
        reject = self._on_moving if self.mover is not None else None
        if self.snapper is not None:
            return self.snapper.at(self.cursor[0], self.cursor[1], reject)
        if self.hit is None or (reject is not None and reject(self.hit, None)):
            return None
        return self.hit, "point", I.SNAP_LABELS["point"]

    def _release(self):
        """A release: the end of a drag-from-pick-up drops; a click picks up or drops."""
        if self.mover is not None:
            if self.press is None:                     # a later click
                self._drop(self.point)
            elif math.hypot(self.cursor[0] - self.press[0], self.cursor[1] - self.press[1]) > CLICK_PX:
                self._drop(self.point)                 # press–drag–release
        elif not self.held:
            self._pick_up()
        self.press = None
        self.held = False

    def _pick_up(self):
        """A selection moves whatever is clicked; nothing selected selects the clicked object."""
        if not rt.selection.count:
            n = self._picked()
            if n is None:
                return
            with pymxs.undo(True, "Select"):
                rt.select(n)
        mover = _mover()
        if mover is None:
            return
        if not getattr(mover, "nodes", True):
            hud.show("Locked — " + ", ".join(str(n.name) for n in mover.skipped[:3]), HUD_MS)
            return
        sn = self._snap_now()
        base = (sn[0] if sn else None) or self._surface() or self._ground()
        if base is None:
            return
        self.last = None
        self.typed = ""
        self.E.reset(base)
        self.point = base
        self.press = self.cursor
        mover.begin()
        self.mover = mover
        try:
            if self.mode != "move":
                self._set_mode(self.mode)
        except Exception:
            self._cancel()
            raise
        if getattr(mover, "skipped", None):
            hud.show("Skipped locked: " + ", ".join(str(n.name) for n in mover.skipped[:3]), HUD_MS)

    def _place(self, nodes, make, exit):
        """Hold a paste on the cursor (start_placing): no press, the next click drops."""
        mover = PlaceMover(nodes, make)
        base = _base_of(mover.nodes or nodes)
        self.last, self.typed, self.mode = None, "", "move"
        self.E.reset(base)
        self.point = base
        self.press = None
        mover.begin()
        self.mover = mover
        self.placing = exit

    def _placed(self):
        """A paste the tool ran just for is done (dropped or cancelled): the tool ends."""
        if self.placing:
            self.placing = False
            from PySide6.QtCore import QTimer
            QTimer.singleShot(0, stop)

    def _drop(self, p):
        m = self.mover
        if m is None:
            return
        d = I.sub(p, self.E.base) if p is not None else (0.0, 0.0, 0.0)
        self.mover = None
        self.press = None
        self._hide()
        try:
            self.last = m.commit(d)
        except Exception:
            _report()
            self.last = None
        self.E.reset(None)
        self.result = None
        self._placed()

    def _cancel(self):
        m, self.mover = self.mover, None
        self.press = None
        self.typed = ""
        self._hide()
        if m is not None:
            self.E.reset(None)
            self.result = None
            m.cancel()
            # now, not at the next mouse move: lines off + the objects back on screen
            self.prims = ([], [])
            rt.redrawViews()
        self._placed()

    # the frame ──────────────────────────────────────────────────────────────────

    def _update(self):
        self.E.ortho = rclick._down(rclick.VK_SHIFT)       # F held
        self.view = v = _view()
        if self.mover is None:
            # nothing held: just the snap, so a click picks up from the point shown
            self.snap = sn = self._snap_now()
            self._publish([], [(sn[0], "disc", sn[1])] if sn else [])
            return
        self.snap = sn = self._snap_now()
        snap, tier = (sn[0], sn[1]) if sn else (None, None)
        if self.E.watch(snap if tier == "point" else None, self.cursor[0], self.cursor[1], _ms_now()):
            pass
        elif self.E.hover is not None:
            self._tick_later()
        r = self.E.solve(v, self.cursor[0], self.cursor[1], snap, tier or "point")
        self.result = r
        if r.point is not None:
            self.point = r.point
        d = I.sub(self.point, self.E.base)
        self.mover.preview(d)
        marks = [(p, {"base": "smallCircle", "anchor": "plusSign"}[kind], "from") for p, kind in r.marks]
        if r.kind in ("axis", "ortho", "from", "lock") and r.point is not None:
            marks.append((r.point, "circle", I.KEYS[r.axis] if r.axis is not None else "dir"))
        if sn and (r.kind == "snap" or (r.kind in ("lock", "ortho") and tier != "face")):
            marks.append((snap, "disc", tier))                 # the snap: a filled circle
        self._publish(list(r.lines), marks)
        self._show(self._summary(d), HOLD_MS)

    def _on_moving(self, snap, node=None):
        """A snap on the geometry being moved — it follows the cursor, so it would hold
        the point where it is. Moving objects are frozen, so Max's snaps skip them already:
        rejecting a snap at the grabbed point there threw away every other frame's real
        edge / face snap (it sits where the last frame put the point) — the face ↔ edge
        flicker (2026-10-14). So only sub-objects, and only hits on their own object."""
        if isinstance(self.mover, ObjMover):
            return False
        N = getattr(self.mover, "N", None)
        if node is not None and N is not None and node != N:
            return False
        tol = (self.view.px(snap) if self.view else 1.0) * 1.5
        if self.point is not None and I.length(I.sub(snap, self.point)) <= tol:
            return True
        pts = getattr(self.mover, "pts", None)
        if pts:
            d = I.sub(self.point, self.E.base)
            for p in pts:
                if I.length(I.sub(snap, I.add(p, d))) <= tol:
                    return True
        return False

    def _tick_later(self):
        if self.timer is not None:
            return
        from PySide6.QtCore import QTimer
        self.timer = QTimer()
        self.timer.setSingleShot(True)
        self.timer.timeout.connect(self._tick)
        self.timer.start(I.ACQUIRE_MS + 30)

    def _tick(self):
        self.timer = None
        if self.mover is not None and _s["session"] is self and self.E.tick(_ms_now()):
            try:
                self._update()
            except Exception:
                _report()

    def _publish(self, lines, marks):
        if not (lines or marks or self.prims[0] or self.prims[1]):
            return                     # nothing drawn, nothing to draw: no redraw
        self.prims = (lines, marks)
        rt.redrawViews()               # → callisMvDraw → _project

    def _project(self):
        """The redraw callback: the world-space lines / markers projected through the view as
        it is NOW, so they follow an orbit / pan / zoom (nav.py moves the view with no tool
        event). No text at the cursor, ever (the user's rule)."""
        try:
            lines, marks = self.prims
            if not (lines or marks):
                self._clear()
                return
            v = _view()
            segs, mk, discs = [], [], []
            for a, b, col, style in lines:
                _segs(v, a, b, col, style, segs)
            for p, marker, col in marks:
                s = v.project(p)
                if not s:
                    continue
                if marker == "disc":
                    discs += [s[0], v.h - s[1], COLOUR_IDX[col]]
                else:
                    mk += [s[0], v.h - s[1], rt.Name(marker), COLOUR_IDX[col]]
            rt.callisMvSegs, rt.callisMvMarks, rt.callisMvDiscs = segs, mk, discs
        except Exception:
            self._clear()
            _report()

    def _clear(self):
        rt.callisMvSegs, rt.callisMvMarks, rt.callisMvDiscs = [], [], []

    # what's under the cursor ────────────────────────────────────────────────────

    def _picked(self):
        """The object under the cursor (not frozen), or None."""
        from . import nav
        nav._ms()
        try:
            n = rt.callisPickNode(rt.mapScreenToWorldRay(rt.Point2(*self.cursor)))
        except Exception:
            return None
        return None if _undef(n) or bool(n.isFrozen) else n

    def _surface(self):
        from . import nav
        p = nav._pick(rt.mapScreenToWorldRay(rt.Point2(*self.cursor)))
        return None if p is None else _p3(p)

    def _ground(self):
        v = self.view or _view()
        ro, rd = v.ray(*self.cursor)
        return I.ray_plane(ro, rd, (0.0, 0.0, 0.0), I.plane_normal(v))

    # keys (rclick.claim) ────────────────────────────────────────────────────────

    def want(self, vk, ctrl, alt, shift, char):
        if vk == I.VK["alt"] and alt and not ctrl and not shift:
            tok = "mode"
        else:
            tok = I.action(vk, ctrl, alt, shift, char)
        _s["keys"] = (_s.get("keys", []) + [(hex(vk), ctrl, alt, shift, char, tok)])[-30:]
        return tok

    def shift(self):
        """Shift (F held) went down or up: ortho on / off now, not at the next move."""
        if _s["session"] is self and self.mover is not None:
            try:
                self._update()
            except Exception:
                _report()

    def key(self, tok):
        if _s["session"] is not self:
            return
        try:
            self._key(tok)
        except Exception:
            _report()

    def _key(self, tok):
        E = self.E
        if isinstance(tok, tuple):                     # ("type", ch)
            self.typed += tok[1]
            self._show(self._summary(), HOLD_MS)
            return
        if tok == "nop":
            return
        if tok == "rearm":                             # the Move key while it's on
            self._cancel()
            self.last = None
        elif tok == "snaps":
            toggle_snaps()
        elif tok == "lock":
            E.toggle_lock(self.result)
        elif tok.startswith("axis"):
            E.lock_axis(int(tok[4:]))
        elif tok == "mode":
            self._set_mode({"move": "copy", "copy": "instance", "instance": "move"}[self.mode])
            hud.show({"move": "Move", "copy": "Copy", "instance": "Instance"}[self.mode], HUD_MS)
        elif tok == "back":
            self.typed = self.typed[:-1]
            self._show(self._summary(), HOLD_MS)
        elif tok == "enter":
            self._typed()
        elif tok == "esc":
            if self.typed:
                self.typed = ""
                self._show(self._summary(), HOLD_MS if self.mover is not None else 1)
            elif self.mover is not None:
                self._cancel()
            else:
                rt.execute("stopTool callisMoveTool")
                return
        if self.mover is not None or tok != "esc":
            self._update()

    def _set_mode(self, mode):
        m = self.mover
        if m is not None and not m.copyable and mode != "move":
            hud.show("Copy works on objects", HUD_MS)
            return
        self.mode = mode
        if m is not None:
            m.set_mode(mode)

    def _typed(self):
        t, self.typed = self.typed, ""
        self._hide()
        def dec(s):
            if re.fullmatch(r"\s*-?(\d+\.?\d*|\.\d+)\s*", s):     # a bare number is mm
                s = s.strip() + "mm"
            return float(rt.units.decodeValue(s))
        q = I.parse_typed(t, dec)
        if q is None:
            hud.show("Can't read “%s”" % t, HUD_MS)
            return
        if self.mover is not None:
            B = self.E.base
            if q[0] == "dist":
                lk = self.E.lock
                e = I.norm(I.sub(self.point, B)) if self.point is not None else None
                if lk is not None:
                    e = lk.e if e is None or I.dot(e, lk.e) >= 0 else I.mul(lk.e, -1.0)
                if e is None:
                    hud.show("Move the mouse to show the direction first", HUD_MS)
                    return
                self._drop(I.add(B, I.mul(e, q[1])))
            elif q[0] == "rel":
                self._drop(I.add(B, q[1]))
            elif q[0] == "abs":
                self._drop(q[1])
            else:
                hud.show("Drop the copy first, then type %s" % t, HUD_MS)
            return
        L = self.last
        if L is None:
            return
        if q[0] == "dist":
            e = I.norm(L.d)
            if e is None:
                return
            L.adjust(I.mul(e, q[1]))
        elif q[0] == "rel":
            L.adjust(q[1])
        elif q[0] == "abs":
            hud.show("[x,y,z] works while moving", HUD_MS)
            return
        else:
            L.arrayed(q[1], q[2])
        rt.redrawViews()

    # the HUD ────────────────────────────────────────────────────────────────────

    def _summary(self, d=None):
        """The distance in whole millimetres, or what's being typed."""
        if self.typed:                                   # a bare number is mm: say so
            if re.fullmatch(r"-?(\d+\.?\d*|\.\d+)", self.typed.strip()):
                return self.typed.strip() + " mm"
            return self.typed
        if d is None:
            return ""
        return "%d mm" % int(round(I.length(d) / self.mm))

    def _show(self, text, ms=HUD_MS):
        if not text:
            self._hide()
            return
        if text != self.hud or ms != HOLD_MS:
            hud.show(text, ms)
        self.hud = text

    def _hide(self):
        """The held HUD off now (a drop / cancel / Enter) — not left to time out."""
        if self.hud is not None:
            hud.show(self.hud, 1)
        self.hud = None


# ──────────────────────────────────────────────────────────────── drawing

def _clip(v, a, b):
    """The part of segment a–b in front of the camera (perspective), else None."""
    if not v.persp:
        return a, b
    near = 1e-3
    da, db = -v.to_view(a)[2], -v.to_view(b)[2]
    if da < near and db < near:
        return None
    if da < near:
        a = I.add(a, I.mul(I.sub(b, a), (near - da) / (db - da)))
    elif db < near:
        b = I.add(b, I.mul(I.sub(a, b), (near - db) / (da - db)))
    return a, b


def _segs(v, a, b, col, style, out):
    """Screen segments for a world line, dashed / dotted, 2 px (bold 4), h-coords (y up)."""
    ab = _clip(v, a, b)
    if ab is None:
        return
    pa, pb = v.project(ab[0]), v.project(ab[1])
    if pa is None or pb is None:
        return
    x0, y0, x1, y1 = pa[0], v.h - pa[1], pb[0], v.h - pb[1]
    L = math.hypot(x1 - x0, y1 - y0)
    if L < 0.5:
        return
    ux, uy = (x1 - x0) / L, (y1 - y0) / L
    on, off = {"dash": (DASH, GAP), "dot": (DOT, DOT_GAP)}.get(style, (L, 0))
    t = 0.0
    if style == "bolddot":         # the dots grow round the same centres: the pitch stays
        on, off, t = 2 * DOT, DOT_GAP - DOT, -DOT / 2.0
    offs = (-1.0, 0.0, 1.0, 2.0) if style in ("bold", "bolddot") else (0.0, 1.0)
    c = COLOUR_IDX[col]
    while t < L:
        t, e = max(t, 0.0), min(t + on, L)
        for o in offs:
            out += [x0 + ux * t - uy * o, y0 + uy * t + ux * o, x0 + ux * e - uy * o, y0 + uy * e + ux * o, c]
        t = e + off


# ──────────────────────────────────────────────────────────────── start

def start():
    """The macro: the tool runs on a QTimer — startTool blocks until it ends."""
    if _s["session"] is not None:
        return
    from PySide6.QtCore import QTimer
    QTimer.singleShot(0, _run)


def start_placing(nodes, make):
    """A paste (callis/clip.py): `nodes` (preview copies) ride the cursor until a click
    places them — make() builds the real ones in the undo step. In a running Move tool it
    takes over and the tool stays on; else the tool runs just for it."""
    s = _s["session"]
    if s is not None:
        s._cancel()
        s._place(nodes, make, exit=False)
        return
    from PySide6.QtCore import QTimer
    QTimer.singleShot(0, lambda: _run((nodes, make)))


def _run(place=None):
    if _s["session"] is not None:
        if place:
            PlaceMover(*place).cancel()
        return
    _ms()
    s = Session()
    _s["session"] = s
    try:
        s.setup()
        if place:
            s._place(place[0], place[1], exit=True)
        rt.execute("startTool callisMoveTool snap:#3D")
    except Exception:
        _report()
    finally:
        _s["session"] = None
        s.teardown()


def stop():
    if _s["session"] is not None:
        rt.execute("stopTool callisMoveTool")


def toggle_snaps():
    """S, in the tool or out of it (macro SnapsToggle): Max's snaps on / off + the HUD."""
    rt.snapMode.active = not bool(rt.snapMode.active)
    hud.show("Snaps " + ("on" if rt.snapMode.active else "off"), HUD_MS)
