"""Quick Render (macro QuickRender): the current shot at its own (Low Res) size, with the
Preview render settings, shown in the frame buffer only — no passes, nothing saved.

A region drawn in the frame buffer is rendered alone:
  V-Ray — the VFB's region (vfbControl #getregion — V-Ray 7 returns a list of regions; the first is used);
  others — Max's frame window "Area to Render: Region" (setRenderType #region), whose
  frame lives on the active viewport in output pixels.
No region → the whole frame, and your viewport is left as it is. A region renders only
through the active view, so then the viewport goes to the shot's camera.
Renders with whatever renderer is current; ones with own_render (Corona) go through
Max's production render instead of MAXScript's render().
"""
import time

from pymxs import runtime as rt

from . import cameras, hud, renderers, rsettings, scene as S

_FN = """fn callisQuickRender cam w h rg = (
    local c = false
    local b = if rg == undefined then
        render camera:cam outputwidth:w outputheight:h vfb:true cancelled:&c
    else
        render camera:cam outputwidth:w outputheight:h vfb:true cancelled:&c renderType:#region region:rg
    if b != undefined do close b
    c
)"""


def _fractions(l, t, r, b, w, h):
    """A pixel rect at w×h → 0–1, or None if it's empty or the whole frame."""
    if w <= 0 or h <= 0 or r <= l or b <= t:
        return None
    f = [max(0.0, l / w), max(0.0, t / h), min(1.0, r / w), min(1.0, b / h)]
    return None if f == [0.0, 0.0, 1.0, 1.0] else f


def drawn_region(adapter):
    """The region drawn in the frame buffer as 0–1 of the frame, or None."""
    w, h = int(rt.renderWidth), int(rt.renderHeight)
    if adapter is not None and adapter.key == "vray":
        try:
            rg = rt.execute("vfbControl #getregion")
            if rg is not None and len(rg) and not isinstance(rg[0], (int, float)):
                rg = rg[0]   # V-Ray 6+: #(#(l, t, r, b), ...) — one per region; all 0 = none
            if rg is not None and len(rg) >= 4 and any(int(v) for v in list(rg)[:4]):
                return _fractions(*[int(v) for v in list(rg)[:4]], w, h)
        except Exception as e:
            print("[callis] quick: V-Ray region:", e)
        return None
    if str(rt.getRenderType()) != "region":
        return None
    box = rt.viewport.getRegionRect(rt.viewport.activeViewport)
    x, y, bw, bh = int(box.x), int(box.y), int(box.w), int(box.h)
    return _fractions(x, y, x + bw, y + bh, w, h)


def _production(cam, w, h, rect):
    """Start Max's production render of the active view, for renderers MAXScript's
    render() can't drive (Corona: "Unable to open renderer", and its VFB stays empty).
    It returns at once while Corona renders on, so this hands back a restore() to call
    when it's done. The view goes to the shot camera, and back after unless a region
    needs it."""
    vp = rt.viewport.activeViewport
    keep = (rt.renderWidth, rt.renderHeight, rt.getRenderType())
    view = (rt.viewport.getCamera(), rt.viewport.getType(), rt.viewport.getTM(), rt.viewport.getFOV())

    def restore():
        rt.renderWidth, rt.renderHeight = keep[:2]
        rt.setRenderType(keep[2])
        if not rect and view[0] != cam:
            if view[0] is not None:
                rt.viewport.setCamera(view[0])
            else:
                rt.viewport.setType(view[1])
                rt.viewport.setTM(view[2])
                rt.viewport.setFOV(view[3])

    try:
        rt.renderWidth, rt.renderHeight = w, h
        if view[0] != cam:
            rt.viewport.setCamera(cam)
        if rect:
            l, t, r, b = rect
            rt.setRenderType(rt.Name("region"))
            rt.viewport.setRegionRect(vp, rt.Box2(l, t, r - l, b - t))
        else:
            rt.setRenderType(rt.Name("view"))
        rt.execute("max quick render")
    except Exception:
        restore()
        raise
    return restore


def _when_done(adapter, then, started=None):
    """then() once the adapter's renderer has stopped rendering — polled on a Qt timer,
    so Max stays responsive and its frame buffer keeps updating."""
    from PySide6 import QtCore
    started = started or time.time()
    try:
        busy = adapter.rendering()
    except Exception as e:
        print("[callis] quick: rendering():", e)
        busy = False
    if busy and time.time() - started < 6 * 3600:
        QtCore.QTimer.singleShot(250, lambda: _when_done(adapter, then, started))
    else:
        then()


def run():
    from contextlib import ExitStack
    from . import render as R, ui
    p = ui.project()
    view = cameras.current_shot(p)
    if view is None:
        hud.show("No shots")
        return
    adapter = renderers.for_current()
    region = drawn_region(adapter)          # read at the size it was drawn at
    if p.active == view.id:
        cam = S.node(view.camera)
        rt.renderWidth, rt.renderHeight = view.width, view.height
    else:
        cam = S.apply_view(p, view, look=False)
    if cam is None:
        hud.show(f"{view.name} has no camera")
        return
    w, h = view.width, view.height
    rect = R.region_pixels(region, w, h) if region else None
    if rect and rt.viewport.getCamera() != cam:
        rt.viewport.setCamera(cam)      # Max renders a region only through the active view
    hud.show(f"Quick render — {view.name}" + (" (region)" if rect else ""))
    rt.execute(_FN)
    started = time.time()
    stack = ExitStack()
    with stack:
        stack.enter_context(rsettings.applied(p, "preview"))
        if adapter is not None:
            stack.enter_context(adapter.quiet())
        if adapter is not None and adapter.own_render:
            stack.callback(_production(cam, w, h, rect))
            later = stack.pop_all()     # settings stay on until the render ends

            def done():
                later.close()
                print(f"[callis] quick render {view.name} {w}x{h} region={rect} "
                      f"{time.time() - started:.1f}s")
            _when_done(adapter, done)
            return
        rt.callisQuickRender(cam, w, h, rt.Array(*rect) if rect else None)
    print(f"[callis] quick render {view.name} {w}x{h} region={rect} {time.time() - started:.1f}s")
