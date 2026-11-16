"""Camera lock, the current shot, and the shot-camera / perspective view toggle
(the 2017 toggleAutokeyAndCameraLock / toggleCameraPerspectiveView)."""
import pymxs
from pymxs import runtime as rt

from . import hud

_locked = True      # for the session (the old callisScriptsCamerasLocked global)


def _is_cam(n):
    return rt.isValidNode(n) and rt.superClassOf(n) == rt.camera


def _targets(c):
    t = getattr(c, "target", None)
    return None if t is None or str(t) == "undefined" else t


def _set(n, locked):
    rt.setTransformLockFlags(n, rt.Name("all") if locked else rt.Name("none"))


def apply():
    """Lock / unlock every camera and its target to match the flag (undo off)."""
    with pymxs.undo(False):
        for c in rt.cameras:
            if rt.superClassOf(c) == rt.camera:
                _set(c, _locked)
                t = _targets(c)
                if t is not None:
                    _set(t, _locked)


def toggle():
    global _locked
    _locked = not _locked
    apply()
    hud.show("Cameras locked" if _locked else "Cameras unlocked")


def on_node(n):
    if _locked and rt.isValidNode(n):
        with pymxs.undo(False):
            if rt.superClassOf(n) == rt.camera or (rt.classOf(n) == rt.Targetobject and _owner_is_cam(n)):
                _set(n, True)


def _owner_is_cam(t):
    return any(_is_cam(d) and _targets(d) is not None and _targets(d) == t
               for d in rt.refs.dependents(t) if rt.isValidNode(d))


def is_locked(n):
    """The node's real flags: all axes locked (a bit array of 9)."""
    if n is None or str(n) == "undefined":
        return False
    return all(bool(b) for b in rt.getTransformLockFlags(n))


def current_shot(p):
    return p.view(p.active) or (p.views[0] if p.views else None)


def toggle_view():
    from . import project as P, scene as S, ui
    p = ui.project()
    if str(rt.viewport.getType()) in ("view_camera", "view_spot"):
        if p.persp:
            rt.viewport.setType(rt.Name("view_persp_user"))
            rt.viewport.setTM(rt.Matrix3(*[rt.Point3(*p.persp["tm"][i:i + 3]) for i in range(0, 12, 3)]))
            rt.viewport.setFOV(p.persp["fov"])
            rt.displaySafeFrames = False
        else:
            rt.actionMan.executeAction(0, "40182")     # Perspective User View
            rt.displaySafeFrames = False
        rt.redrawViews()
        return
    view = current_shot(p)
    if view is None:
        hud.show("No shots")
        return
    if str(rt.viewport.getType()) == "view_persp_user":
        m = rt.viewport.getTM()
        p.persp = {"tm": [c for row in (m.row1, m.row2, m.row3, m.row4) for c in (row.x, row.y, row.z)],
                   "fov": float(rt.viewport.getFOV())}
        P.save(p)
    cam = S.node(view.camera)
    if cam is None:
        hud.show(f"{view.name} has no camera")
        return
    if view.id != p.active:
        _apply(p, view, True)
    else:
        rt.viewport.setCamera(cam)
        rt.displaySafeFrames = True
        rt.redrawViews()


def _apply(p, view, look):
    from . import scene as S, ui
    if ui._panel is not None:
        ui._panel.go(view, look)
    else:
        S.apply_view(p, view, look)
