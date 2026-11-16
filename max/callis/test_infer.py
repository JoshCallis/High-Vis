"""infer — run on the Mac: python3 max/callis/test_infer.py"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
from callis import infer as I  # noqa: E402


def camera(eye, target, w=1600, h=900, fov=60.0, persp=True, upp=0.2):
    """A View looking from eye at target, Z up."""
    za = I.norm(I.sub(eye, target))                       # out of the screen
    xa = I.norm((-za[1], za[0], 0.0)) if abs(za[2]) < 0.999 else (1.0, 0.0, 0.0)
    ya = (za[1] * xa[2] - za[2] * xa[1], za[2] * xa[0] - za[0] * xa[2], za[0] * xa[1] - za[1] * xa[0])
    rows = [(xa[j], ya[j], za[j]) for j in range(3)] + [(-I.dot(eye, xa), -I.dot(eye, ya), -I.dot(eye, za))]
    return I.View(rows, persp, w, h, fov, upp)


def near(a, b, eps=1e-3):
    return a is not None and b is not None and all(abs(x - y) <= eps for x, y in zip(a, b))


def check(label, ok, extra=""):
    print(("ok  " if ok else "FAIL"), label, "" if ok else extra)
    return ok


def screen(v, p, dx=0.0, dy=0.0):
    s = v.project(p)
    return s[0] + dx, s[1] + dy


V = camera((120.0, -200.0, 150.0), (0.0, 0.0, 0.0))
results = []

# camera round trip: the ray through a projected point passes through it
p = (30.0, 40.0, 10.0)
o, d = V.ray(*screen(V, p))
t = I.dot(I.sub(p, o), d)
results.append(check("ray(project(p)) hits p", near(I.add(o, I.mul(d, t)), p, 1e-6)))
Vo = camera((0.0, -100.0, 0.0), (0.0, 0.0, 0.0), persp=False, upp=0.25)
o, d = Vo.ray(*screen(Vo, p))
t = I.dot(I.sub(p, o), d)
results.append(check("ortho ray(project(p)) hits p", near(I.add(o, I.mul(d, t)), p, 1e-6)))

# on an axis: cursor 5 px off the projected X axis
E = I.Engine()
E.reset((0.0, 0.0, 0.0))
sx, sy = screen(V, (40.0, 0.0, 0.0), 0, 5)
r = E.solve(V, sx, sy)
results.append(check("near X → on X", r.kind == "axis" and r.axis == 0 and abs(r.point[1]) < 1e-6
                     and abs(r.point[2]) < 1e-6 and r.label == "On Red Axis", (r.kind, r.point, r.label)))
# sticky: 13 px off keeps it on X, a fresh engine doesn't take it
sx, sy = screen(V, (40.0, 0.0, 0.0), 0, 13)
r = E.solve(V, sx, sy)
results.append(check("13 px off stays on X", r.kind == "axis" and r.axis == 0, (r.kind, r.axis)))
E2 = I.Engine()
E2.reset((0.0, 0.0, 0.0))
r = E2.solve(V, sx, sy)
results.append(check("…but isn't taken at 13 px", r.kind == "plane", r.kind))

# off every axis: the construction plane (XY through the base point)
E.reset((0.0, 0.0, 5.0))
sx, sy = screen(V, (30.0, 30.0, 5.0))
r = E.solve(V, sx, sy)
results.append(check("free → XY plane at the base", r.kind == "plane" and near(r.point, (30.0, 30.0, 5.0), 1e-4),
                     (r.kind, r.point)))

# edge-on view: the plane stands up
Vs = camera((0.0, -200.0, 1.0), (0.0, 0.0, 0.0))
results.append(check("edge-on view → XZ plane", I.plane_normal(Vs) == I.AXES[1], I.plane_normal(Vs)))

# lock: Z through the base point; a snap projects onto it
E.reset((0.0, 0.0, 0.0))
E.lock_axis(2)
sx, sy = screen(V, (50.0, -20.0, 30.0))
r = E.solve(V, sx, sy)
results.append(check("locked Z → x = y = 0", r.kind == "lock" and abs(r.point[0]) < 1e-6 and abs(r.point[1]) < 1e-6
                     and r.label.startswith("Locked Blue"), (r.point, r.label)))
r = E.solve(V, sx, sy, snap=(10.0, 10.0, 42.0))
results.append(check("locked + snap → projected", near(r.point, (0.0, 0.0, 42.0)), r.point))
r = E.solve(V, sx, sy, snap=(10.0, 10.0, 42.0), snap_kind="face")
results.append(check("locked + face snap → not projected", r.kind == "lock" and not near(r.point, (0.0, 0.0, 42.0)), r.point))
E.lock_axis(2)
results.append(check("same arrow unlocks", E.lock is None))

# snap tiers: a point beats the axis, the axis beats an edge / face, an edge / face beats the plane
E.reset((0.0, 0.0, 0.0))
sx, sy = screen(V, (40.0, 0.0, 0.0))
r = E.solve(V, sx, sy, snap=(40.0, 0.5, 0.0), snap_kind="point")
results.append(check("point snap beats the axis", r.kind == "snap" and near(r.point, (40.0, 0.5, 0.0)), (r.kind, r.point)))
r = E.solve(V, sx, sy, snap=(40.0, 0.5, 0.0), snap_kind="edge")
results.append(check("axis beats an edge snap", r.kind == "axis" and r.axis == 0, (r.kind, r.point)))
sx, sy = screen(V, (40.0, 40.0, 0.0))
r = E.solve(V, sx, sy, snap=(40.0, 40.0, 3.0), snap_kind="face")
results.append(check("face snap beats the plane", r.kind == "snap" and r.label == "On Face", (r.kind, r.label)))

# Space locks the free direction
E.reset((0.0, 0.0, 0.0))
r = E.solve(V, *screen(V, (30.0, 30.0, 0.0)))
E.toggle_lock(r)
r2 = E.solve(V, *screen(V, (0.0, 60.0, 0.0)))
results.append(check("Space locks the free direction", E.lock is not None and E.lock.axis is None
                     and abs(r2.point[0] - r2.point[1]) < 1e-6 and r2.label == "Locked Direction",
                     (r2.point, r2.label)))
E.toggle_lock(r2)
results.append(check("Space again unlocks", E.lock is None))

# ortho: well off any axis, still on the axis whose screen direction matches
E.reset((0.0, 0.0, 0.0))
E.ortho = True
sx, sy = screen(V, (60.0, 25.0, 0.0))
r = E.solve(V, sx, sy)
results.append(check("ortho → X", r.kind == "ortho" and r.axis == 0 and abs(r.point[1]) < 1e-6
                     and r.label == "Ortho Red Axis", (r.kind, r.axis, r.label)))
r = E.solve(V, sx, sy, snap=(7.0, 8.0, 9.0))
results.append(check("ortho: a snap projects onto the axis", r.kind == "ortho" and r.axis == 0
                     and near(r.point, (7.0, 0.0, 0.0), 1e-6), (r.kind, r.point)))
E.ortho = False

# acquiring: held still ACQUIRE_MS, not when it moves
E.reset((0.0, 0.0, 0.0))
A = (50.0, 30.0, 0.0)
E.watch(A, 500, 400, 0)
results.append(check("not acquired early", not E.watch(A, 501, 401, 500) and not E.anchors))
results.append(check("acquired after ACQUIRE_MS", E.watch(A, 502, 400, I.ACQUIRE_MS + 1) and E.anchors == [A]))
E.watch((1.0, 2.0, 3.0), 100, 100, 0)
results.append(check("moving resets the wait", not E.watch((1.0, 2.0, 3.0), 120, 100, 2000)))
for i in range(6):
    E.acquire((float(i), 0.0, 99.0))
results.append(check("anchors capped, oldest dropped", len(E.anchors) == I.ANCHORS
                     and E.anchors[-1] == (5.0, 0.0, 99.0)))

# From Point: on X from the base, lining up with an acquired point
E.reset((0.0, 0.0, 0.0))
E.acquire(A)
sx, sy = screen(V, (50.6, 0.0, 0.0), 0, 3)
r = E.solve(V, sx, sy)
results.append(check("lines up with an anchor → From Point", r.kind == "from" and near(r.point, (50.0, 0.0, 0.0))
                     and r.label == "From Point", (r.kind, r.point, r.label)))
# an axis through the acquired point
sx, sy = screen(V, (50.0, 30.0, 40.0), 4, 0)
r = E.solve(V, sx, sy)
results.append(check("Z through an anchor", r.kind == "axis" and r.axis == 2 and near(r.point[:2], (50.0, 30.0), 1e-6)
                     and r.label == "On Blue Axis from Point", (r.kind, r.point, r.label)))

# typing
dec = lambda s: float(s[:-1]) * 1000 if s.endswith("m") and s[:-1].replace(".", "").isdigit() else float(s)
results += [
    check("dist", I.parse_typed("1200", dec) == ("dist", 1200.0)),
    check("dist with units", I.parse_typed("1.5m", dec) == ("dist", 1500.0)),
    check("negative dist", I.parse_typed("-20", dec) == ("dist", -20.0)),
    check("relative", I.parse_typed("10,0,-5", dec) == ("rel", (10.0, 0.0, -5.0))),
    check("absolute", I.parse_typed("[1,2,3]", dec) == ("abs", (1.0, 2.0, 3.0))),
    check("array 5x", I.parse_typed("5x", dec) == ("array", 5, "x")),
    check("array x5", I.parse_typed("x5", dec) == ("array", 5, "x")),
    check("array *3", I.parse_typed("*3", dec) == ("array", 3, "x")),
    check("divide /4", I.parse_typed("/4", dec) == ("array", 4, "/")),
    check("junk", I.parse_typed("1,2", dec) is None and I.parse_typed("abc", dec) is None),
]

# keys
results += [
    check("F tap eaten (ortho = F held = Shift)", I.action(0x46, 0, 0, 0, "f") == "nop"),
    check("one finger + S (Move again) → rearm", I.action(0x48, 1, 1, 1) == "rearm"),
    check("Ctrl+O → esc", I.action(0x4F, 1, 0, 0, "o") == "esc"),
    check("digit typed", I.action(0x35, 0, 0, 0, "5") == ("type", "5")),
    check("shift+8 → *", I.action(0x38, 0, 0, 1, "*") == ("type", "*")),
    check("Q isn't ours", I.action(0x51, 0, 0, 0, "q") is None),
]
bindings = json.load(open(os.path.join(HERE, "..", "..", "remap", "bindings.json")))
rows = bindings["bindings"]
got = {r.get("id"): r.get("to") for r in rows if isinstance(r, dict)}
stale = {k: (v, got.get(k)) for k, v in I.CHORD_ROWS.items() if got.get(k) != v}
results.append(check("chords match remap/bindings.json", not stale, stale))

sys.exit(0 if all(results) else 1)
