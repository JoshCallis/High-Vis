"""The viewport's colour response, measured, for the Browser's dim (browser.py).

The viewport's display transform (OCIO ACEScg + the camera's filmic curve) isn't per
channel: pure red at a light shows brighter than white at it, and a pink loses its weak
channels faster than its strong one as it darkens. So "this colour × k on screen" can't
come from the grey curve alone. Two steps:

  1. in Max:  calibrate() — an emission-only plane in front of the view, emission colour
     (light per channel) → 8-bit pixel on a LEVELS³ grid → .state/dim_lut.json "px".
         maxctl eval 'import callis.dimlut as d; _result = d.calibrate()'   (~90 s)
  2. on the Mac:  max/.venv/bin/python max/callis/dimlut.py — fits
         pixel = sRGB( N · grey( M · light ) )
     (M, N: 3×3, rows sum to 1; grey = the measured grey curve, per channel) → "fit".
     rmse ~9 levels over the whole grid, 2026-10-15 (Max 2027, ACEScg, Physical camera).

screen() / light_for() use the fit (light_for is its exact inverse). No fit → None, and
the dim falls back to the grey curve per channel. Re-run both after changing the view
transform or the camera's exposure model.
"""
import json
import math
import os

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LUT = os.path.join(HERE, ".state", "dim_lut.json")
LEVELS = [0.0, 2.0, 5.0, 12.0, 28.0, 65.0, 150.0, 350.0, 800.0, 1900.0, 4500.0]

_fit = []       # [M, N, N⁻¹, M⁻¹, log levels, grey (linear display), mtime]


def calibrate():
    """Measure the grid in Max. Leaves the scene as it was (a temp plane, deleted after)."""
    from pymxs import runtime as rt
    from PySide6 import QtGui
    tm = rt.inverse(rt.viewport.getTM())                # view → world
    z = rt.normalize(tm.row3)                           # the view looks down -z
    p = rt.Plane(length=1e5, width=1e5, lengthsegs=1, widthsegs=1, name="callis dim lut")
    p.transform = rt.Matrix3(tm.row1, tm.row2, tm.row3, tm.row4 - z * 10.0)
    p.wirecolor = rt.Color(0, 0, 0)
    m = rt.PhysicalMaterial(base_weight=0, reflectivity=0, emission=1.0, emit_luminance=1.0)
    p.material = m
    hwnd = int(rt.viewport.getHWnd())
    scr = QtGui.QGuiApplication.primaryScreen()
    top, px = max(LEVELS), []
    try:
        for r in LEVELS:
            for g in LEVELS:
                for b in LEVELS:
                    # emit_color is a 0–255 multiplier of emit_luminance (linear, measured)
                    m.emit_luminance = top
                    m.emit_color = rt.Color(255 * r / top, 255 * g / top, 255 * b / top)
                    rt.redrawViews()
                    im = scr.grabWindow(hwnd).toImage()
                    c = QtGui.QColor(im.pixel(im.width() // 2, im.height() // 2))
                    px.append([c.red(), c.green(), c.blue()])
    finally:
        rt.delete(p)
        rt.redrawViews()
    with open(LUT, "w") as f:
        json.dump({"levels": LEVELS, "px": px}, f)
    return "%d samples — now fit on the Mac: max/.venv/bin/python max/callis/dimlut.py" % len(px)


# ──────────────────────────────────────────────────────────────── the model

def _dec(v):
    return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4


def _enc(v):
    v = min(1.0, max(0.0, v))
    return v * 12.92 if v <= 0.0031308 else 1.055 * v ** (1 / 2.4) - 0.055


def _mat(p):
    return [[1 - p[0] - p[1], p[0], p[1]], [p[2], 1 - p[2] - p[3], p[3]], [p[4], p[5], 1 - p[4] - p[5]]]


def _inv3(a):
    (a0, a1, a2), (b0, b1, b2), (c0, c1, c2) = a
    d = a0 * (b1 * c2 - b2 * c1) - a1 * (b0 * c2 - b2 * c0) + a2 * (b0 * c1 - b1 * c0)
    return [[(b1 * c2 - b2 * c1) / d, (a2 * c1 - a1 * c2) / d, (a1 * b2 - a2 * b1) / d],
            [(b2 * c0 - b0 * c2) / d, (a0 * c2 - a2 * c0) / d, (a2 * b0 - a0 * b2) / d],
            [(b0 * c1 - b1 * c0) / d, (a1 * c0 - a0 * c1) / d, (a0 * b1 - a1 * b0) / d]]


def _mul(m, v):
    return [sum(m[i][j] * v[j] for j in range(3)) for i in range(3)]


def _load():
    try:
        t = os.path.getmtime(LUT)
    except OSError:
        return None
    if not _fit or _fit[6] != t:
        with open(LUT) as f:
            d = json.load(f)
        if "fit" not in d:
            return None
        lv, n = d["levels"], len(d["levels"])
        grey = [_dec(d["px"][(i * n + i) * n + i][1] / 255.0) for i in range(n)]
        M, N = _mat(d["fit"][:6]), _mat(d["fit"][6:12])
        _fit[:] = [M, N, _inv3(N), _inv3(M), lv, grey, t]
    return _fit


def _curve(x, lv, grey):
    """Light → linear display along grey: linear below the first step, log-linear above."""
    if x <= lv[1]:
        return grey[1] * max(0.0, x) / lv[1]
    for i in range(2, len(lv)):
        if x <= lv[i]:
            t = (math.log(x) - math.log(lv[i - 1])) / (math.log(lv[i]) - math.log(lv[i - 1]))
            return grey[i - 1] + t * (grey[i] - grey[i - 1])
    return grey[-1]


def _uncurve(y, lv, grey):
    if y <= grey[1]:
        return lv[1] * max(0.0, y) / grey[1]
    for i in range(2, len(lv)):
        if y <= grey[i]:
            t = (y - grey[i - 1]) / max(1e-9, grey[i] - grey[i - 1])
            return math.exp(math.log(lv[i - 1]) + t * (math.log(lv[i]) - math.log(lv[i - 1])))
    return lv[-1]


def screen(e):
    """Light colour (per channel) → the 8-bit pixel the viewport shows. None: no fit."""
    f = _load()
    if f is None:
        return None
    M, N, _, _, lv, grey, _ = f
    a = [_curve(v, lv, grey) for v in _mul(M, e)]
    return [255 * _enc(v) for v in _mul(N, a)]


def light_for(px):
    """The light colour whose pixel is `px` (8-bit floats). None: no fit."""
    f = _load()
    if f is None:
        return None
    _, _, Ni, Mi, lv, grey, _ = f
    a = _mul(Ni, [_dec(min(255.0, max(0.0, v)) / 255.0) for v in px])
    return [max(0.0, v) for v in _mul(Mi, [_uncurve(v, lv, grey) for v in a])]


def dim(r, g, b, light, k, cap):
    """Swatch (0–255) lit by `light` → the light colour that shows k × its pixel (the
    brightest channel capped at `cap`), as a list; None: no fit."""
    y = screen([light * v / 255.0 for v in (r, g, b)])
    if y is None:
        return None
    t = [k * v for v in y]
    s = min(1.0, cap / max(1e-6, max(t)))
    return light_for([v * s for v in t])


def fit():
    """Fit M, N to the measured grid (numpy: run with max/.venv/bin/python)."""
    import numpy as np
    with open(LUT) as f:
        d = json.load(f)
    lv, n = d["levels"], len(d["levels"])
    px = np.array(d["px"], float)
    E = np.array([[lv[i], lv[j], lv[k]] for i in range(n) for j in range(n) for k in range(n)])
    grey = [_dec(px[(i * n + i) * n + i][1] / 255.0) for i in range(n)]
    curve = np.vectorize(lambda x: _curve(x, lv, grey))
    enc = np.vectorize(_enc)
    w = ((px > 2) & (px < 253)).astype(float)       # clipped channels say nothing

    def loss(p):
        a = curve(E @ np.array(_mat(p[:6])).T)
        return float(np.sum(w * (255 * enc(a @ np.array(_mat(p[6:])).T) - px) ** 2) / w.sum())

    rng = np.random.default_rng(0)
    p, best, step = np.zeros(12), loss(np.zeros(12)), 0.1
    for it in range(9000):
        q = p + rng.normal(0, step, 12)
        l = loss(q)
        if l < best:
            p, best = q, l
        if it % 1500 == 1499:
            step *= 0.5
    d["fit"] = [float(v) for v in p]
    with open(LUT, "w") as f:
        json.dump(d, f)
    return "rmse %.1f levels" % best ** 0.5


if __name__ == "__main__":
    print(fit())
