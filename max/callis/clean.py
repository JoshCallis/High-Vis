"""Fusion-style 3ds Max: the look (always on) and clean mode (a toggle).

    import callis.clean as C
    C.toggle()        # clean mode: hide every bit of chrome / put it all back
    C.look()          # black background, plain shaded (fast in WARP), no grid / ViewCube /
                      # world axis / orbit ball — applied at startup and on every scene
    C.look(False)     # Max's own look back

The look is "never" settings, so it is on in both modes. Clean mode hides the rest:
menu bar, toolbars, command panel, ribbon, docks, time slider, track bar, status
bar, viewport labels, safe frame, helper/light/camera icons, window title (full
screen). What it changed is written to .state/clean.json, so toggling off after a
restart (or after a crash) still restores the original state.
"""
import json
import os

from pymxs import runtime as rt

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STATE = os.path.join(HERE, ".state", "clean.json")

BLACK = rt.Color(0, 0, 0)
# Plain Shaded, no antialiasing, no selection / hover outlines: the VM has no GPU, so
# Nitrous rasterises in software (D3D11 WARP, emulated x64) and every redraw is paid
# in CPU per pixel. Measured 2026-10-10 on a 3437x1437 viewport, AA off: a click-select
# (= full redraw) Shaded 0.73 s vs Acrylic 1.8 s; AA 4X adds ~0.6 s more; EACH outline
# adds a fixed ~0.3 s to every redraw, even with nothing selected. Selection shows as
# edged faces on the selected objects instead (free).
# With a real GPU, Acrylic is the Fusion "shaded with visible edges" look: smooth
# shading (Color Ink posterises), thin black feature/silhouette lines, none across
# smooth curved faces (normalEdgeMultiplier low), linear levels (dark/whiteControl 1 —
# its default 0.5 lifts the black background to grey). INK applies only to Acrylic.
STYLE = "Shaded"
AA = "4X"
OUTLINES = False               # selection + hover (preview) outlines
INK = {"normalEdgeMultiplier": 2.0, "depthEdgeMultiplier": 3.0, "EdgeDilateRadius": 0.0,
       "SilhouetteDilateRadius": 0.0, "darkControl": 1.0, "whiteControl": 1.0}
# Fusion's edges and selection. Nitrous has no edge colour of its own: edged faces draw in
# each node's WIRE colour, so every geometry node's wirecolor is black (set as nodes appear,
# undo off). A shaded node with no material shows its wire colour too (black on black), so
# those get one shared grey material — Fusion: every body has an appearance. Selected
# objects: edges in the Selection colour (UI colour 0 = clrx id 17320), faces tinted by
# Nitrous' selection highlight. Measured 2026-10-10: edged faces on everything and the
# highlight are both free in WARP (unlike outlines).
EDGE = rt.Color(0, 0, 0)
SELECT_EDGE = (20, 100, 235)                # selected edges
SELECT_TINT = (0, 80, 220)                # selected faces, blended in at HIGHLIGHT
HIGHLIGHT = 0.3                 # halved 2026-10-16; screen-space (no depth test): tints
                                # occluders in front too — no setting turns that off
# Snap markers: Max draws a different glyph per snap type (square, triangle, …) at
# markSize px. At a few px they all read as one small point, as in Fusion.
SNAP_MARK = 4
SNAP_COLOR = (1.0, 1.0, 1.0)            # UI colours 129/130 "Snap Point Active/Snapped" (clrx
SF_LIVE = 5                             # UI colour COLOR_SF_LIVE: the safe frame's live-area line
FROZEN = 2                              # UI colour COLOR_FREEZE: a frozen node's edges, even with
FROZEN_EDGE = (0.05, 0.05, 0.05)        # Show Frozen in Gray off (the Browser's dim, the move tool)
SNAP_UI = (129, 130)                   # 17449/17450); snapMode.hilite is reset from 129
DEFAULT_MTL = "Default (Callis)"
DEFAULT_GREY = 0.6
CATEGORIES = ("lights", "cameras", "helpers", "spacewarps", "Bones", "Particles")
OWN_DOCK_PREFIX = "Callis"     # our own docks (the browser) stay up in clean mode


def _load():
    try:
        with open(STATE) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def _save(state):
    try:
        os.makedirs(os.path.dirname(STATE), exist_ok=True)
        with open(STATE, "w") as f:
            json.dump(state, f, indent=1)
    except OSError as e:          # share not mounted: still works, just not restart-proof
        print("[callis.clean] state not saved:", e)


def _core16():
    """Interface16 (SDK) — the only way to the world-axis tripod."""
    return rt.dotNetClass("Autodesk.Max.GlobalInterface").Instance.COREInterface16


def _main():
    import qtmax
    return qtmax.GetQMaxMainWindow()


def _rgb(c):
    return [float(c.x), float(c.y), float(c.z)] if hasattr(c, "x") else [c.r / 255, c.g / 255, c.b / 255]


# ──────────────────────────────────────────────────────────────── the look

def _viewports():
    return range(1, int(rt.viewport.numViews) + 1)


def _look_snapshot():
    vps = []
    for i in _viewports():
        s = rt.NitrousGraphicsManager.GetViewportSetting(i)
        vps.append({"grid": bool(rt.viewport.GetGridVisibility(i)), "style": str(s.VisualStyleMode),
                    "envbg": bool(s.UseEnvironmentBackgroundColorEnabled),
                    "seledges": bool(s.SelectedEdgedFacesEnabled),
                    "edges": bool(s.ShowEdgedFacesEnabled),
                    "ink": {k: float(s.GetNPRFloat(k)) for k in INK}})
    g = rt.NitrousGraphicsManager
    sel = g.GetSelectionSetting()
    return {"aa": str(g.AntialiasingQuality), "sel_outline": bool(sel.SelectionOutlineEnabled),
            "hover_outline": bool(sel.PreviewOutlineEnabled),
            "sel_highlight": bool(sel.SelectionHighlightEnabled),
            "highlight": float(sel.HighlightFactor),
            "highlight_color": _rgb(rt.colorMan.getColor(rt.Name("selectionHighlights"))),
            "sel_color": _rgb(rt.GetUIColor(0)), "sf_live": _rgb(rt.GetUIColor(SF_LIVE)),
            "frozen": _rgb(rt.GetUIColor(FROZEN)),
            "darker_edges": str(g.DarkerEdgeOption),
            "snap_mark": int(rt.snapMode.markSize), "snap_colors": [_rgb(rt.GetUIColor(i)) for i in SNAP_UI],
            "viewcube": bool(rt.ViewCubeOps.Visibility), "axis": bool(_core16().ShowWorldAxis),
            "ball_rotate": bool(rt.IAutoCamMax.showPivotBallOnRotate),
            "ball_zoom": bool(rt.IAutoCamMax.showPivotBallOnZoom),
            "solid_bg": bool(rt.viewport.IsSolidBackgroundColorMode()),
            "bg": _rgb(rt.colorMan.getColor("ViewportBackground")), "viewports": vps}


def look(on=True):
    state = _load()
    if on:
        if "look" not in state:              # first time only: what Max had before us
            state["look"] = _look_snapshot()
            _save(state)
        rt.ViewCubeOps.Visibility = False
        _core16().ShowWorldAxis = False
        rt.execute('(dotNetClass "Autodesk.Max.GlobalInterface").Instance.COREInterface.UseTransformGizmo = false')
        rt.IAutoCamMax.showPivotBallOnRotate = False
        rt.IAutoCamMax.showPivotBallOnZoom = False
        rt.viewport.EnableSolidBackgroundColorMode(not state.get("env_bg"))
        rt.viewport.DispBkgImage = bool(state.get("env_bg"))
        rt.colorMan.setColor("ViewportBackground", rt.Point3(0, 0, 0))
        rt.SetUIColor(41, BLACK)
        rt.SetUIColor(SF_LIVE, BLACK)        # camera view: the safe frame crops, no outline
        rt.SetUIColor(FROZEN, rt.Point3(*FROZEN_EDGE))
        g = rt.NitrousGraphicsManager
        g.AntialiasingQuality = rt.Name(AA)
        sel = g.GetSelectionSetting()
        sel.SelectionOutlineEnabled = OUTLINES
        sel.PreviewOutlineEnabled = OUTLINES
        sel.SelectionHighlightEnabled = True
        sel.HighlightFactor = HIGHLIGHT
        rt.colorMan.setColor(rt.Name("selectionHighlights"), rt.Point3(*[c / 255 for c in SELECT_TINT]))
        rt.SetUIColor(0, rt.Point3(*[c / 255 for c in SELECT_EDGE]))   # 0–1: a Color wraps
        g.DarkerEdgeOption = rt.Name("Off")
        rt.snapMode.markSize = SNAP_MARK
        for i in SNAP_UI:
            rt.SetUIColor(i, rt.Point3(*SNAP_COLOR))
        for i in _viewports():
            rt.viewport.SetGridVisibility(i, False)
            s = rt.NitrousGraphicsManager.GetViewportSetting(i)
            s.UseEnvironmentBackgroundColorEnabled = bool(state.get("env_bg"))
            s.VisualStyleMode = rt.Name(STYLE)
            s.ShowEdgedFacesEnabled = True
            s.SelectedEdgedFacesEnabled = not OUTLINES
            for k, v in INK.items():
                s.SetNPRFloat(k, v)
        paint(rt.geometry)
        _install_paint()
    else:
        old = state.pop("look", None)
        if old is None:
            return
        rt.ViewCubeOps.Visibility = old["viewcube"]
        _core16().ShowWorldAxis = old["axis"]
        rt.IAutoCamMax.showPivotBallOnRotate = old["ball_rotate"]
        rt.IAutoCamMax.showPivotBallOnZoom = old["ball_zoom"]
        rt.viewport.EnableSolidBackgroundColorMode(old["solid_bg"])
        rt.colorMan.setColor("ViewportBackground", rt.Point3(*old["bg"]))
        rt.SetUIColor(41, rt.Color(*[255 * c for c in old["bg"]]))
        g = rt.NitrousGraphicsManager      # snapshots before 2026-10-10 lack these: Max defaults
        g.AntialiasingQuality = rt.Name(old.get("aa", "4X").lstrip("#"))
        sel = g.GetSelectionSetting()
        sel.SelectionOutlineEnabled = old.get("sel_outline", True)
        sel.PreviewOutlineEnabled = old.get("hover_outline", True)
        sel.SelectionHighlightEnabled = old.get("sel_highlight", False)
        sel.HighlightFactor = old.get("highlight", 0.15)
        rt.colorMan.setColor(rt.Name("selectionHighlights"), rt.Point3(*old.get("highlight_color", [0, 0.698, 1])))
        rt.SetUIColor(0, rt.Point3(*old.get("sel_color", [1, 1, 1])))
        rt.SetUIColor(SF_LIVE, rt.Point3(*old.get("sf_live", [0.753, 0.753, 0])))
        rt.SetUIColor(FROZEN, rt.Point3(*old.get("frozen", [0.471, 0.471, 0.471])))
        g.DarkerEdgeOption = rt.Name(old.get("darker_edges", "SubLevelOnly").lstrip("#"))
        rt.snapMode.markSize = old.get("snap_mark", 20)
        for i, c in zip(SNAP_UI, old.get("snap_colors", [[1, 1, 0], [0, 1, 0]])):
            rt.SetUIColor(i, rt.Point3(*c))
        rt.callbacks.removeScripts(id=rt.Name("callisPaint"))   # wire colours stay black
        for i, vp in zip(_viewports(), old["viewports"]):
            rt.viewport.SetGridVisibility(i, vp["grid"])
            s = rt.NitrousGraphicsManager.GetViewportSetting(i)
            s.UseEnvironmentBackgroundColorEnabled = vp["envbg"]
            s.VisualStyleMode = rt.Name(vp["style"].lstrip("#"))
            s.SelectedEdgedFacesEnabled = vp.get("seledges", False)
            s.ShowEdgedFacesEnabled = vp.get("edges", False)
            for k, v in vp["ink"].items():
                s.SetNPRFloat(k, v)
        _save(state)
    rt.colorMan.repaintUI(rt.Name("repaintAll"))
    rt.completeRedraw()


def _default_mtl():
    for m in rt.sceneMaterials:
        if str(m.name) == DEFAULT_MTL:
            return m
    m = rt.PhysicalMaterial(name=DEFAULT_MTL)
    m.base_color = rt.Color(*[255 * DEFAULT_GREY] * 3)
    return m


def paint(nodes):
    """Black edges (wire colour) and, where there's no material, the default grey one.
    Undo off: it's display, not an edit — Ctrl+Z never steps through it."""
    import pymxs
    nodes = [n for n in nodes if rt.isValidNode(n) and rt.superClassOf(n) == rt.GeometryClass
             and rt.classOf(n) != rt.TargetObject]
    if not nodes:
        return
    from . import browser
    with pymxs.undo(False):
        mtl = None
        for n in nodes:
            if n.wirecolor != EDGE and not browser.dimmed(n):     # a dimmed node's is the Browser's
                n.wirecolor = EDGE
            if n.material is None:
                mtl = mtl or _default_mtl()
                n.material = mtl


def _paint_param(*_):
    p = rt.callbacks.notificationParam()
    try:
        paint(list(p) if hasattr(p, "__iter__") else [p])
    except Exception as e:
        print("[callis.clean] paint:", e)


def _install_paint():
    rt.callbacks.removeScripts(id=rt.Name("callisPaint"))
    for ev in ("nodeCreated", "sceneNodeAdded"):
        rt.callbacks.addScript(rt.Name(ev), _paint_param, id=rt.Name("callisPaint"))
    rt.callbacks.addScript(rt.Name("postImport"), lambda *_: paint(rt.geometry), id=rt.Name("callisPaint"))


# ──────────────────────────────────────────────────────────────── clean mode

def is_on():
    return bool(_load().get("clean"))


def on(reapply=False):
    """Hide the chrome. reapply=True (startup, when it was on at quit): hide it
    again but keep the first snapshot — Max saved its dock layout hidden on exit,
    so only the snapshot still knows what to bring back."""
    state = _load()
    saved = state.get("clean")
    if saved and not reapply:
        return
    w = _main()
    if not saved:
        saved = state["clean"] = _snapshot(w)
        _save(state)              # before touching anything: a crash mid-way stays undoable
    _hide(w, saved)
    _save(state)
    w.showFullScreen()
    from PySide6 import QtCore
    for ms in (1500, 6000):                    # Max restores its frame late at startup
        QtCore.QTimer.singleShot(ms, lambda: _fill(w))
    look()


def respace():
    """Re-enter full screen so Parallels gives Max its own Mac Space again (run by
    max/coherence_fullscreen.sh, with Max's stub frontmost on the Mac — from behind
    it Parallels leaves the window where it is). Also when Max has dropped out of
    full screen altogether (seen 2026-10-13, clean mode on but window state normal):
    then the old early return left only the AX fallback, which rarely took, and
    every jump to Max sat through ~20 s of failed retries."""
    w = _main()
    if w.isFullScreen():
        w.showNormal()
    w.setGeometry(w.screen().geometry())
    w.showFullScreen()
    return True


def _fill(w):
    """Full screen that doesn't cover the screen. At startup Max's restored frame
    can survive showFullScreen — it came up at 7,13 (a gap top-left, overhanging
    bottom-right; 2026-10-10). That matters on the Mac too: Parallels gives a
    Coherence window its own full-screen Space only while it covers the screen
    exactly, so an offset Max lands on top of whatever desktop is shown.
    setGeometry, not showNormal: leaving full screen drops the Mac Space as well."""
    if w.isFullScreen() and w.screen() and w.geometry() != w.screen().geometry():
        w.setGeometry(w.screen().geometry())     # clears Qt's full-screen state…
        w.showFullScreen()                       # …so put it back


def _snapshot(w):
    return {
        "expert": bool(rt.cui.getExpertMode()),
        "menubar": w.menuBar().isVisible(),
        "labels": bool(rt.ViewportButtonMgr.EnableButtons),
        "timeslider": bool(rt.timeSlider.isVisible()),
        "trackbar": bool(rt.trackbar.visible),
        "status": bool(rt.statusPanel.visible),
        "safeframe": bool(rt.displaySafeFrames),
        "categories": {c: bool(getattr(rt.hideByCategory, c)) for c in CATEGORIES},
        "borders": {n: _rgb(rt.colorMan.getColor(n)) for n in ("ViewportBorder", "ActiveViewportBorder")},
        "maximized": False,
        "window": int(w.windowState().value),
        "docks": [],
    }


def _hide(w, saved):
    if not rt.cui.getExpertMode():
        rt.cui.expertModeOn()
    from PySide6 import QtWidgets
    for d in w.findChildren(QtWidgets.QDockWidget) + w.findChildren(QtWidgets.QToolBar):
        name = d.objectName()
        if d.isVisible() and not name.startswith(OWN_DOCK_PREFIX):
            entry = [type(d).__name__, name, d.windowTitle()]
            if entry not in saved["docks"]:
                saved["docks"].append(entry)
            d.hide()
    w.menuBar().hide()
    rt.ViewportButtonMgr.EnableButtons = False
    rt.timeSlider.setVisible(False)
    rt.trackbar.visible = False
    rt.statusPanel.visible = False
    rt.displaySafeFrames = False
    for c in CATEGORIES:
        setattr(rt.hideByCategory, c, True)
    for n in saved["borders"]:
        rt.colorMan.setColor(n, rt.Point3(0, 0, 0))
    if int(rt.viewport.numViews) > 1:
        rt.actionMan.executeAction(0, "50026")     # Maximize Viewport Toggle
        saved["maximized"] = True


def off():
    state = _load()
    saved = state.get("clean")
    if not saved:
        return
    w = _main()
    from PySide6 import QtCore, QtWidgets
    w.setWindowState(QtCore.Qt.WindowState(saved["window"]))
    if saved["maximized"]:
        rt.actionMan.executeAction(0, "50026")
    for n, c in saved["borders"].items():
        rt.colorMan.setColor(n, rt.Point3(*c))
    for c, v in saved["categories"].items():
        setattr(rt.hideByCategory, c, v)
    rt.displaySafeFrames = saved["safeframe"]
    rt.statusPanel.visible = saved["status"]
    rt.trackbar.visible = saved["trackbar"]
    rt.timeSlider.setVisible(saved["timeslider"])
    rt.ViewportButtonMgr.EnableButtons = saved["labels"]
    w.menuBar().setVisible(saved["menubar"])
    if not saved["expert"]:
        rt.cui.expertModeOff()
    kinds = {"QDockWidget": QtWidgets.QDockWidget, "QToolBar": QtWidgets.QToolBar}
    for kind, name, title in saved["docks"]:
        for d in w.findChildren(kinds[kind], name):
            if d.windowTitle() == title:
                d.show()
    del state["clean"]
    _save(state)
    rt.colorMan.repaintUI(rt.Name("repaintAll"))
    rt.completeRedraw()


def toggle():
    off() if is_on() else on()


def toggle_background():
    """Macro ToggleViewportBackground: the viewport behind the model black ↔ the scene's
    environment (its map / colour). Kept in .state/clean.json, so look() on the next scene
    keeps the choice."""
    from . import hud
    state = _load()
    env = not state.get("env_bg")
    state["env_bg"] = env
    _save(state)
    rt.viewport.EnableSolidBackgroundColorMode(not env)
    rt.viewport.DispBkgImage = env           # left on, it draws the env map over the black
    for i in _viewports():
        rt.NitrousGraphicsManager.GetViewportSetting(i).UseEnvironmentBackgroundColorEnabled = env
    rt.completeRedraw()
    hud.show("Background: " + ("environment" if env else "black"), 1200)


def on_scene():
    """Scene opened / reset / new: the look again (viewport settings live in the
    scene), and clean mode's per-scene bits (categories, safe frame)."""
    look()
    if is_on():
        rt.displaySafeFrames = False
        for c in CATEGORIES:
            setattr(rt.hideByCategory, c, True)
