"""Viewport IPR (macro ViewportIPR): interactive render of the current renderer drawn IN the
active viewport, not a frame buffer. Toggle — a second press stops it.

  Corona  — its own action "Start interactive rendering in active viewport" (572340868-9);
            running = CoronaFp.getRenderType() 2, stopped with CoronaFp.stopRender().
            Its docked "extended view" stays in the viewport after a stop (and a 2nd start
            then fails with a modal). Swapping layouts doesn't shift it; only
            viewport.ResetAllViews() does, so stop resets the views, puts back the view
            saved at start (other panes of a multi-view layout come back as defaults)
            and re-applies clean.look().
  V-Ray   — its own "Toggle V-Ray Viewport IPR" (-905641955-55), a toggle already.
  others  — Max's ActiveShade in the viewport (ActiveShadeFragmentManager), with the
            ActiveShade renderer made the production one's class when Max accepts it
            (Arnold, ART, Scanline, V-Ray GPU; Corona and V-Ray CPU refuse).
"""
from pymxs import runtime as rt

from . import hud

CORONA_START = (572340868, "9")
VRAY_TOGGLE = (-905641955, "55")


def _kind():
    c = str(rt.classOf(rt.renderers.production)).lower()
    if "corona" in c:
        return "corona"
    if c.startswith("v_ray") and not c.startswith("v_ray_gpu"):
        return "vray"
    return "activeshade"


_RESTORE_FN = """fn callisIprRestore s = (
    viewport.ResetAllViews()
    if s != undefined do (
    viewport.setLayout s[1]
    try (viewport.activeViewport = s[2]) catch ()
    if s[3] != undefined then viewport.setCamera s[3] else (
        viewport.setType s[4]
        viewport.setTM s[5]
        if s[4] == #view_persp_user do viewport.setFOV s[6]
    ))
    redrawViews()
)"""
_saved = None     # the active view when Corona's IR took it over


def _fragment():
    return rt.ActiveShadeFragmentManager


def _corona_docked():
    """Corona's extended view is in the panel: no active regular viewport."""
    return int(rt.viewport.activeViewport) == 0


def toggle():
    global _saved
    kind = _kind()
    if kind == "corona":
        fp = rt.CoronaRenderer.CoronaFp
        if int(fp.getRenderType()) == 2 or _corona_docked():
            fp.stopRender()
            rt.execute(_RESTORE_FN)
            rt.callisIprRestore(_saved)
            _saved = None
            from . import clean
            clean.look()
            return hud.show("Viewport IPR off", 800)
        v = rt.viewport
        _saved = [v.getLayout(), v.activeViewport, v.getCamera(), v.getType(),
                  v.getTM(), v.getFOV()]
        rt.actionMan.executeAction(*CORONA_START)
    elif kind == "vray":
        rt.actionMan.executeAction(*VRAY_TOGGLE)
    else:
        f = _fragment()
        if f.IsRunningInAtLeastOneViewport():
            f.RemoveActiveShadeFragmentFromAllViewports()
            rt.redrawViews()
            return hud.show("Viewport IPR off", 800)
        cls = rt.classOf(rt.renderers.production)
        if rt.classOf(rt.renderers.activeShade) != cls:
            try:
                rt.renderers.activeShade = rt.createInstance(cls)
            except Exception:
                pass
        f.ToggleInActiveViewport()
    hud.show("Viewport IPR", 800)
