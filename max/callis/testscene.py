"""A minimal scene for testing the render → Photoshop pipeline end to end.

Ground, a block with a glass pane, a chrome teapot and a shrub — five materials on
five layers in four subtrees (so layer AND material mattes have something to split),
a sun + sky, two shots (Front, Corner). Glass layer = "Glass (separate)", so the
glass pass runs too. Physical cameras + Physical materials + Sun Positioner (V-Ray: VRaySun +
VRaySky — it can't light with the Sun Positioner) are
understood by Arnold, V-Ray and Corona alike; `build()` sets the renderer.

    maxctl eval 'import callis.testscene as T; _result = T.build()'
    maxctl eval 'import callis.testscene as T; _result = T.build("vray")'
"""
import os

import pymxs
from pymxs import runtime as rt

from . import project as P
from . import scene as S

NAME = "Render Test"
OUTPUT = r"\\Mac\Home\Documents\3ds Max 2027\renders\Render Test"
# RendererClass names to try, first found wins (V-Ray: the CPU renderer, newest first)
RENDERERS = {"arnold": ("Arnold",),
             "vray": ("V_Ray_7", "V_Ray_6", "V_Ray_Adv", "V_Ray"),
             "corona": ("Corona", "CoronaRenderer")}


def _layer(name):
    lay = rt.LayerManager.getLayerFromName(name)
    if lay is None:
        lay = rt.LayerManager.newLayerFromName(name)
    return lay


def _put(node, layer, mat=None):
    _layer(layer).addNode(node)
    if mat is not None:
        node.material = mat
    return node


def _mat(name, color, rough=0.5, metal=0.0, transparency=0.0):
    m = rt.PhysicalMaterial(name=name)
    m.base_color = rt.Color(*(c * 255 for c in color), 255)
    m.roughness = rough
    m.metalness = metal
    m.transparency = transparency
    if transparency:
        m.trans_color = rt.Color(255, 255, 255)
        m.thin_walled = True
    return m


def _renderer(key):
    names = RENDERERS[key]
    have = {str(c) for c in rt.RendererClass.classes}
    for n in names:   # prefix: V-Ray's class name carries its build ("V_Ray_7__update_4_hotfix_2_DR2")
        hit = sorted(c for c in have if c == n or c.startswith(n + "_"))
        if hit:
            rt.renderers.current = getattr(rt, hit[0])()
            return hit[0]
    raise RuntimeError(f"{key} isn't installed in Max (renderers: {sorted(have)})")


def _camera(name, pos, target):
    t = rt.TargetObject(name=name + ".Target", pos=rt.Point3(*target))
    c = rt.Physical(name=name, pos=rt.Point3(*pos), target=t)   # Physical camera
    c.exposure_gain_type = 1          # EV
    c.exposure_value = 15.0           # sunny day
    _put(c, "Cameras")
    _put(t, "Cameras")
    return c


def build(renderer="arnold", save=True):
    """Reset to maxstart, build the scene, save it as scenes/Render Test.max."""
    if rt.getSaveRequired() and rt.maxFileName == "":
        rt.holdMaxFile()
    rt.resetMaxFile(rt.Name("noPrompt"))
    used = _renderer(renderer)

    with pymxs.undo(False):
        mats = {
            "Concrete": _mat("Concrete", (0.45, 0.44, 0.42), rough=0.8),
            "Brick":    _mat("Brick", (0.42, 0.16, 0.10), rough=0.7),
            "Glass":    _mat("Glass", (1, 1, 1), rough=0.0, transparency=1.0),
            "Chrome":   _mat("Chrome", (0.9, 0.9, 0.9), rough=0.12, metal=1.0),
            "Foliage":  _mat("Foliage", (0.10, 0.28, 0.06), rough=0.6),
        }
        _put(rt.Plane(name="Ground", length=60000, width=60000, lengthsegs=1, widthsegs=1),
             "Paving (Context)", mats["Concrete"])
        _put(rt.Box(name="Block", length=300, width=400, height=500, pos=rt.Point3(0, 150, 0)),
             "External Walls", mats["Brick"])
        _put(rt.Box(name="Window", length=4, width=220, height=260, pos=rt.Point3(0, -4, 120)),
             "Glass", mats["Glass"])
        _put(rt.Teapot(name="Teapot", radius=60, pos=rt.Point3(-280, -260, 0)),
             "Furniture", mats["Chrome"])
        _put(rt.GeoSphere(name="Shrub", radius=70, pos=rt.Point3(300, -220, 55)),
             "Plants", mats["Foliage"])

        sun = rt.SunPositioner(name="Sun", pos=rt.Point3(0, 0, 0))
        sun.north_direction = 0
        sun.mode = 0                                   # date & time
        sun.year, sun.month, sun.day = 2026, 6, 21
        sun.hours, sun.minutes = 15, 30
        _put(sun, "Sun")
        rt.environmentMap = rt.PhysicalSunSkyEnv(sun_position_object=sun)
        if renderer == "vray":
            # V-Ray 7 can't light with the Sun Positioner ("Unable to create light from
            # node Sun") — a VRaySun at the same date & time + VRaySky instead.
            d = rt.normalize(sun.manual_sun_position)
            rt.delete(sun)
            sun = rt.VRaySun(name="Sun", pos=d * 20000,
                             target=rt.Targetobject(name="Sun.Target", pos=rt.Point3(0, 0, 0)))
            _put(sun, "Sun")
            _put(sun.target, "Sun")
            rt.environmentMap = rt.VRaySky(manual_sun_node=True, sun_node=sun)
        rt.useEnvironmentMap = True
        rt.SceneExposureControl.exposureControl = rt.Physical_Camera_Exposure_Control()

        front = _camera("Cam Front", (0, -1800, 180), (0, 0, 200))
        corner = _camera("Cam Corner", (1300, -1300, 450), (0, 50, 150))

        p = P.Project(output_root=OUTPUT, resolutions=["low"], photoshop=True)
        p.views = [P.View(name="Front", camera=S.handle(front), width=1280, height=720),
                   P.View(name="Corner", camera=S.handle(corner), width=1280, height=720)]
        p.layer_mattes["Glass"] = "glass"
        p.active = p.views[0].id
        P.save(p)

    rt.viewport.setCamera(front)
    rt.redrawViews()
    path = os.path.join(str(rt.getDir(rt.Name("scene"))), NAME + ".max")
    if save:
        rt.saveMaxFile(path, quiet=True)
    return {"renderer": used, "scene": path, "output": OUTPUT, "materials": list(mats)}
