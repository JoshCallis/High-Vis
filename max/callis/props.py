"""Camera and sun settings in the Browser's place, drawn by the Browser page (panel.py),
instead of the Modify panel. Rows are bound to node (or Sun & Sky environment) properties;
each edit is one undo record. D at the top level, Esc, or the same command again, closes it.

A row lists candidate property names — the first one the object has is used, so
Physical / V-Ray Physical / Free / Target cameras and Sun Positioner / VRaySun / CoronaSun
share one spec. Rows: (section, label, names, target[, opts]) — target "node" or "env";
a name may be (name, opts) for that property alone; opts as in form.py, plus
"inv": shown as 1/value (Physical's shutter in seconds → V-Ray's 1/s).
The rows are form.Fields (shared with the Render window, which draws them with form.Form).
"""
import pymxs
from pymxs import runtime as rt

from . import form, hud, panel, scene as S, side

# Basics only for now; V-Ray Physical names checked against V-Ray 7 (2026-10-14).
CAMERA = [
    ("Lens", "Focal length", ["focal_length_mm", "focal_length"], "node", {"suffix": " mm", "decimals": 1, "step": 1}),
    ("Lens", "Film width", ["film_width_mm", "film_width"], "node", {"suffix": " mm", "decimals": 1}),
    ("Lens", "Field of view", ["fov"], "node", {"suffix": "°", "decimals": 1, "step": 1}),
    ("Exposure", "Exposure", [("exposure_gain_type", {"choices": [(0, "Manual (ISO)"), (1, "Target EV")]}),
                              ("exposure", {"choices": [(0, "Off"), (1, "Physical (ISO)"), (2, "EV")]})], "node"),
    ("Exposure", "EV", ["exposure_value"], "node", {"decimals": 2, "step": 0.5}),
    ("Exposure", "ISO", ["iso", "ISO"], "node", {"decimals": 0, "step": 100, "min": 1}),
    ("Exposure", "f-number", ["f_number"], "node", {"decimals": 1, "step": 0.5, "min": 0.1}),
    ("Exposure", "Shutter", [("shutter_length_seconds", {"inv": True}), "shutter_speed"], "node",
     {"suffix": "  1/s", "decimals": 0, "step": 10, "min": 0.01}),
    ("Exposure", "White balance", [("white_balance_type", {"choices": [(0, "Illuminant"), (1, "Temperature"),
                                                                      (2, "Custom")]})], "node"),
    ("Exposure", "Temperature", ["white_balance_kelvin", "temperature"], "node",
     {"suffix": " K", "decimals": 0, "step": 100, "min": 1000, "max": 20000}),
    ("Exposure", "Vignetting", ["vignetting_enabled", "vignetting"], "node"),
    ("Exposure", "Vignetting amount", ["vignetting_amount"], "node", {"decimals": 2}),
    ("Perspective", "Auto vertical tilt", ["auto_vertical_tilt_correction", "lens_tilt_auto"], "node"),
    ("Perspective", "Vertical tilt", ["vertical_tilt_correction", "lens_tilt"], "node", {"decimals": 2}),
    ("Perspective", "Vertical shift", ["vertical_shift", "lens_shift"], "node", {"decimals": 3, "step": 0.01}),
    ("Perspective", "Horizontal shift", ["horizontal_shift"], "node", {"decimals": 3, "step": 0.01}),
    ("Focus", "Depth of field", ["use_dof", "mpassEnabled"], "node"),
    ("Focus", "Focus distance", ["focus_distance", "targetDistance", "target_distance"], "node", {"decimals": 1, "min": 0}),
    ("Clipping", "Clip", ["clip_on", "clipManually"], "node"),
    ("Clipping", "Near", ["clip_near", "nearclip"], "node", {"decimals": 1, "min": 0}),
    ("Clipping", "Far", ["clip_far", "farclip"], "node", {"decimals": 1, "min": 0}),
]
CAMERA_KIND = {"Physical": "Physical camera", "VRayPhysicalCamera": "V-Ray Physical camera",
               "Targetcamera": "Target camera", "Freecamera": "Free camera"}
SUN = [
    ("Date & time", "Year", ["year"], "node"),
    ("Date & time", "Month", ["month"], "node"),
    ("Date & time", "Day", ["day"], "node"),
    ("Date & time", "Hours", ["hours"], "node"),
    ("Date & time", "Minutes", ["minutes"], "node"),
    ("Location", "North direction", ["north_direction_deg"], "node"),
    ("Location", "Latitude", ["latitude_deg"], "node"),
    ("Location", "Longitude", ["longitude_deg"], "node"),
    ("Sun", "Intensity", ["intensity_multiplier", "intensityMultiplier"], "node"),
    ("Sun", "Size", ["size_multiplier", "sizeMultiplier"], "node"),
    ("Sun", "Turbidity", ["turbidity"], "node"),
    ("Sun", "Ozone", ["ozone"], "node"),
    ("Sun & Sky", "Global intensity", ["global_intensity"], "env"),
    ("Sun & Sky", "Sun disc intensity", ["sun_disc_intensity"], "env"),
    ("Sun & Sky", "Sky intensity", ["sky_intensity"], "env"),
    ("Sun & Sky", "Haze", ["haze"], "env"),
]
SUN_CLASSES = {"Sun_Positioner", "VRaySun", "CoronaSun", "Daylight", "SunLight"}


def _has(obj, name):
    return obj is not None and bool(rt.isProperty(obj, name))


def _env_for(sun):
    env = rt.environmentMap
    if env is not None and _has(env, "sun_position_object") and env.sun_position_object == sun:
        return env
    return None


def is_sun(n):
    return rt.isValidNode(n) and str(rt.classOf(n)) in SUN_CLASSES


def shot_sun(view):
    from . import scene
    for h in view.only_objects:
        n = scene.node(h)
        if n is not None and is_sun(n):
            return n
    suns = [n for n in rt.objects if is_sun(n)]
    return suns[0] if len(suns) == 1 else None


def fields(node, spec, env=None, undo=None):
    """form.Fields for a spec on `node` (env rows on `env`): the first candidate name the
    object has; edits are one undo record each (titled `undo`), or none if undo is None."""
    out = []
    for row in spec:
        section, label, names, target = row[:4]
        obj = env if target == "env" else node
        for n in names:
            name, own = (n, {}) if isinstance(n, str) else n
            if _has(obj, name):
                break
        else:
            continue
        opts = {**(row[4] if len(row) > 4 else {}), **own}
        inv = opts.get("inv")

        def get(obj=obj, name=name, inv=inv):
            v = rt.getProperty(obj, name)
            if not isinstance(v, (bool, int, float)):
                raise TypeError(name)
            return round(1.0 / v, 3) if inv and v else v

        def put(v, obj=obj, name=name, inv=inv, label=label, record=True):
            v = 1.0 / v if inv and v else v
            if undo is None or not record:          # (record False: a choice tried on)
                rt.setProperty(obj, name, v)
            else:
                with pymxs.undo(True, f"{undo}: {label}"):
                    rt.setProperty(obj, name, v)
            rt.redrawViews()
        out.append(form.Field(section, label, get, put, opts))
    return out


def _open(kind, node, spec):
    """Drawn by the Browser page in its place (panel.py, side.take_page); the same command
    again closes it."""
    p = side.page()
    if p is not None and p.kind == kind and p.node == node:
        side.close()
        return
    sub = CAMERA_KIND.get(str(rt.classOf(node)), "") if kind == "camera" else ""
    side.take_page(panel.PagePanel(kind, node, str(node.name), sub,
                                   fields(node, spec, _env_for(node) if kind == "sun" else None,
                                          undo=str(node.name))))


def camera():
    from . import cameras, ui
    view = cameras.current_shot(ui.project())
    cam = S.node(view.camera) if view else None
    if cam is None:
        hud.show("No shots" if view is None else f"{view.name} has no camera")
        return
    _open("camera", cam, CAMERA)


def sun():
    from . import cameras, ui
    view = cameras.current_shot(ui.project())
    n = shot_sun(view) if view else None
    if n is None:
        hud.show("No sun")
        return
    _open("sun", n, SUN)
