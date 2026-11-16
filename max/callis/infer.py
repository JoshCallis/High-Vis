"""SketchUp's inference engine for callis/movetool.py: where the point under the cursor
lands, given the base point, the points acquired by hovering, Rhino's ortho and the lock.
Pure Python (no pymxs), so it runs and is tested on the Mac: test_infer.py.

Priority (Engine.solve):
  1. lock      Space / arrows: the point slides on the locked line; a point / edge snap or
               an acquired point's alignment projects onto it (SketchUp: lock, then hover
               for length)
  2. ortho     F held: the axis through the base point whose screen direction best
               matches the cursor — always, not only near it (Rhino's ortho); a snap
               projects onto it, as with the lock
  3. point     Max's snap, point tier (vertex / endpoint / midpoint)
  4. axis      within AXIS_PX of an X/Y/Z line through the base point or an acquired
               point (SketchUp's "On Red Axis"; from another point = "From Point")
  5. edge, face  Max's snap, edge tier, then face tier (movetool asks Max tier by tier, so
               the more specific snap always wins)
  6. plane     the construction plane: XY through the base point, or the world plane
               facing the camera when the view is nearly edge-on to XY
On a line (4, 6) the point also stops where it lines up with another anchor ("From Point").

Screen coordinates are window px, y DOWN (MAXScript's viewPoint). gw's h-drawing is y up —
the conversion is movetool's.
"""
import math
import re

AXIS_PX = 10        # cursor this close (px) to an axis line → on it
STICK_PX = 16       # …and the line it was on keeps it this far (no flicker between two)
ALIGN_PX = 10       # a point on the line this close to lining up with an anchor → there
ACQUIRE_MS = 800    # a snap point hovered this long is acquired
ACQUIRE_PX = 4      # …while the cursor stays within this
ANCHORS = 4         # acquired points kept besides the base point (oldest dropped)
EDGE_ON = 0.15      # |view · Z| below this → the construction plane stands up

AXES = ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0))
AXIS_NAMES = ("Red", "Green", "Blue")
KEYS = ("x", "y", "z")
SNAP_LABELS = {"point": "Point", "edge": "On Edge", "face": "On Face"}


# ──────────────────────────────────────────────────────────────── vectors

def add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def mul(a, s):
    return (a[0] * s, a[1] * s, a[2] * s)


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def length(a):
    return math.sqrt(dot(a, a))


def norm(a):
    n = length(a)
    return (a[0] / n, a[1] / n, a[2] / n) if n > 1e-12 else None


def closest_on_line(o, e, ro, rd):
    """The point of line o + t·e (e unit) nearest the ray ro + s·rd (rd unit); None when
    they're parallel or the nearest point is behind the ray's start."""
    w = sub(o, ro)
    b = dot(e, rd)
    den = 1.0 - b * b
    if den < 1e-9:
        return None
    d, f = dot(e, w), dot(rd, w)
    t = (b * f - d) / den
    s = (f - b * d) / den
    if s <= 0:
        return None
    return add(o, mul(e, t))


def project_on_line(p, o, e):
    return add(o, mul(e, dot(sub(p, o), e)))


def ray_plane(ro, rd, p0, n):
    den = dot(rd, n)
    if abs(den) < 1e-9:
        return None
    t = dot(sub(p0, ro), n) / den
    return add(ro, mul(rd, t)) if t > 0 else None


def seg_dist(c, a, b):
    """Screen distance from c to the infinite 2D line through a, b."""
    dx, dy = b[0] - a[0], b[1] - a[1]
    n = math.hypot(dx, dy)
    if n < 1e-9:
        return math.hypot(c[0] - a[0], c[1] - a[1])
    return abs((c[0] - a[0]) * dy - (c[1] - a[1]) * dx) / n


# ──────────────────────────────────────────────────────────────── the camera

class View:
    """World ↔ screen for one viewport. tm = Max's viewport.getTM() rows (world → view,
    p_view = p.x·r1 + p.y·r2 + p.z·r3 + r4, the camera looking down view −Z). Perspective:
    fov = horizontal degrees. Orthographic: upp = world units per pixel."""

    def __init__(self, rows, persp, w, h, fov=45.0, upp=1.0):
        self.r = [tuple(map(float, r)) for r in rows]
        self.persp, self.w, self.h = bool(persp), float(w), float(h)
        self.f = (self.w / 2.0) / math.tan(math.radians(fov) / 2.0) if persp else None
        self.upp = float(upp)
        r1, r2, r3, r4 = self.r
        self.back = (r1[2], r2[2], r3[2])          # view +Z in world: out of the screen
        self.forward = mul(self.back, -1.0)

    def to_view(self, p):
        r1, r2, r3, r4 = self.r
        return (p[0] * r1[0] + p[1] * r2[0] + p[2] * r3[0] + r4[0],
                p[0] * r1[1] + p[1] * r2[1] + p[2] * r3[1] + r4[1],
                p[0] * r1[2] + p[1] * r2[2] + p[2] * r3[2] + r4[2])

    def to_world(self, v):
        r1, r2, r3, r4 = self.r
        q = sub(v, r4)
        return (dot(r1, q), dot(r2, q), dot(r3, q))

    def project(self, p):
        """(x, y, depth) in window px, y down; None behind the camera."""
        x, y, z = self.to_view(p)
        if self.persp:
            d = -z
            if d < 1e-6:
                return None
            return (self.w / 2 + self.f * x / d, self.h / 2 - self.f * y / d, d)
        return (self.w / 2 + x / self.upp, self.h / 2 - y / self.upp, -z)

    def ray(self, sx, sy):
        if self.persp:
            d = norm((sx - self.w / 2, -(sy - self.h / 2), -self.f))
            o = self.to_world((0.0, 0.0, 0.0))
            return o, norm(sub(self.to_world(d), o))
        o = self.to_world(((sx - self.w / 2) * self.upp, -(sy - self.h / 2) * self.upp, 0.0))
        return o, self.forward

    def px(self, p):
        """World units per pixel at p (how far 1 px reaches there)."""
        if not self.persp:
            return self.upp
        q = self.project(p)
        return (q[2] if q else 1.0) / self.f

    def line_dist(self, c, o, e):
        """Screen px from cursor c to the projection of line o + t·e (only its part in
        front of the camera); None when it projects to a point."""
        if self.persp:
            d0 = -self.to_view(o)[2]                 # depth along the line: d0 + t·de
            de = -dot(self.back, e)
            near = 1e-3
            if d0 > near:
                t0 = 0.0
            elif abs(de) > 1e-12:
                t0 = (near * 2 - d0) / de           # a point just in front of the camera
            else:
                return None
            step = max(abs(d0), 1.0) * 0.5
            t1 = t0 + (step if de >= 0 else -step)
            a, b = self.project(add(o, mul(e, t0))), self.project(add(o, mul(e, t1)))
        else:
            a, b = self.project(o), self.project(add(o, mul(e, 100 * self.upp)))
        if a is None or b is None or math.hypot(b[0] - a[0], b[1] - a[1]) < 0.5:
            return None
        return seg_dist(c, a, b)

    def screen_dir(self, o, e):
        """Unit screen direction of e at o, None when it points at the eye."""
        a = self.project(o)
        b = self.project(add(o, mul(e, self.px(o) * 50)))
        if a is None or b is None:
            return None
        dx, dy = b[0] - a[0], b[1] - a[1]
        n = math.hypot(dx, dy)
        return (dx / n, dy / n) if n > 2.0 else None


# ──────────────────────────────────────────────────────────────── results

class Line:
    """o + t·e. axis: 0/1/2 for X/Y/Z, None for a free direction."""

    def __init__(self, o, e, axis=None):
        self.o, self.e, self.axis = o, e, axis

    def key(self):
        return (tuple(round(v, 6) for v in self.o), self.axis,
                None if self.axis is not None else tuple(round(v, 4) for v in self.e))


class Result:
    """point: where the grabbed point goes (None = nowhere sensible: keep the last).
    kind: lock / snap / axis / ortho / from / plane. label: the tooltip.
    lines: (a, b, colour, style) — colour x/y/z/dir/from/band, style dash/bold/dot/solid.
    marks: (p, kind) — base / anchor / point."""

    def __init__(self, point=None, kind=None, label="", axis=None, line=None):
        self.point, self.kind, self.label, self.axis, self.line = point, kind, label, axis, line
        self.lines, self.marks = [], []


def colour(line):
    return KEYS[line.axis] if line.axis is not None else "dir"


# ──────────────────────────────────────────────────────────────── the engine

class Engine:
    def __init__(self):
        self.ortho = False             # F held (movetool sets it from Shift each frame)
        self.reset(None)

    def reset(self, base):
        self.base = base
        self.anchors = []              # acquired points, oldest first
        self.lock = None               # a Line
        self.prev = None               # key of the line the last solve sat on
        self.hover = None              # (point, sx, sy, t0) — a snap waiting to be acquired

    # acquiring ──────────────────────────────────────────────────────────────────

    def watch(self, snap, sx, sy, t):
        """Track the hovered snap point; True once it is acquired."""
        if snap is None:
            self.hover = None
            return False
        h = self.hover
        if h is None or math.hypot(sx - h[1], sy - h[2]) > ACQUIRE_PX or \
                length(sub(snap, h[0])) > 1e-6 * max(1.0, length(snap)):
            self.hover = (snap, sx, sy, t)
            return False
        return self.tick(t)

    def tick(self, t):
        h = self.hover
        if h is None or t - h[3] < ACQUIRE_MS:
            return False
        self.hover = None
        return self.acquire(h[0])

    def acquire(self, p):
        if self.base is not None and length(sub(p, self.base)) < 1e-9:
            return False
        self.anchors = [a for a in self.anchors if length(sub(a, p)) > 1e-9] + [p]
        del self.anchors[:-ANCHORS]
        return True

    def all_anchors(self):
        return ([self.base] if self.base is not None else []) + self.anchors

    # locking ────────────────────────────────────────────────────────────────────

    def lock_axis(self, k):
        """Arrow keys: lock to axis k through the base point; the same arrow again unlocks."""
        if self.base is None:
            return
        if self.lock is not None and self.lock.axis == k and self.lock.o == self.base:
            self.lock = None
        else:
            self.lock = Line(self.base, AXES[k], k)

    def toggle_lock(self, last):
        """Space: lock the line the point is on (an axis, or the free direction from the
        base point — Rhino's direction lock); again unlocks."""
        if self.lock is not None:
            self.lock = None
            return
        if last is None or self.base is None or last.point is None:
            return
        if last.line is not None:
            self.lock = last.line
            return
        e = norm(sub(last.point, self.base))
        if e is not None:
            self.lock = Line(self.base, e, _axis_of(e))

    # solving ────────────────────────────────────────────────────────────────────

    def solve(self, view, sx, sy, snap=None, snap_kind="point"):
        """snap_kind: point / edge / face — the tier of Max's snap that hit."""
        c = (sx, sy)
        ro, rd = view.ray(sx, sy)
        B = self.base
        if B is None:                                       # no base point yet
            r = Result(snap, "snap" if snap is not None else None)
            return r
        r = None
        on_line = snap if snap_kind != "face" else None     # a face is everywhere: not on lines
        if self.lock is not None:
            r = self._on_line(view, c, ro, rd, self.lock, on_line, "lock")
        elif self.ortho:
            k = self._ortho_axis(view, c)
            if k is not None:
                r = self._on_line(view, c, ro, rd, Line(B, AXES[k], k), on_line, "ortho")
                if r.point is None:
                    r = None
        if r is None and snap is not None and snap_kind == "point":
            r = Result(snap, "snap", SNAP_LABELS["point"])
        elif r is None:
            ln = self._near_line(view, c)
            if ln is not None:
                r = self._on_line(view, c, ro, rd, ln, None, "axis")
                if r.point is None:
                    r = None
            if r is None and snap is not None:
                r = Result(snap, "snap", SNAP_LABELS.get(snap_kind, ""))
            elif r is None:
                r = Result(self._plane(view, ro, rd), "plane")
        self.prev = r.line.key() if r.line is not None else None
        r.marks.append((B, "base"))
        r.marks.extend((a, "anchor") for a in self.anchors)
        return r

    def _on_line(self, view, c, ro, rd, ln, snap, kind):
        if snap is not None:
            p = project_on_line(snap, ln.o, ln.e)
        else:
            p = closest_on_line(ln.o, ln.e, ro, rd)
        if p is None:
            return Result(None, kind, line=ln)
        style = "bolddot" if kind == "lock" else "dot"
        r = Result(p, kind, "", ln.axis, ln)
        # lining up with another anchor along this line ("From Point")
        if snap is None:
            best = None
            for a in self.all_anchors():
                if a == ln.o:
                    continue
                q = project_on_line(a, ln.o, ln.e)
                sq, sp = view.project(q), view.project(p)
                if sq is None or sp is None:
                    continue
                d = math.hypot(sq[0] - c[0], sq[1] - c[1])
                if d <= ALIGN_PX and (best is None or d < best[0]):
                    best = (d, q, a)
            if best is not None:
                r.point, p = best[1], best[1]
                r.kind = "from" if kind != "lock" else kind
                r.lines.append((best[2], p, "from", "dot"))
        if snap is not None:
            r.lines.append((snap, p, "from", "dot"))
        r.lines.append((ln.o, p, colour(ln), style))
        r.label = _label(ln, kind, r.kind == "from" or snap is not None, ln.o != self.base)
        return r

    def _near_line(self, view, c):
        best = None
        for a in self.all_anchors():
            for k, e in enumerate(AXES):
                ln = Line(a, e, k)
                d = view.line_dist(c, a, e)
                if d is None:
                    continue
                lim = STICK_PX if ln.key() == self.prev else AXIS_PX
                if d <= lim and (best is None or d - (lim - AXIS_PX) < best[0]):
                    best = (d - (lim - AXIS_PX), ln)
        return best[1] if best else None

    def _ortho_axis(self, view, c):
        sb = view.project(self.base)
        if sb is None:
            return None
        dx, dy = c[0] - sb[0], c[1] - sb[1]
        n = math.hypot(dx, dy)
        if n < 2.0:
            return None
        best = None
        for k, e in enumerate(AXES):
            u = view.screen_dir(self.base, e)
            if u is None:
                continue
            s = abs(u[0] * dx + u[1] * dy) / n
            if best is None or s > best[0]:
                best = (s, k)
        return best[1] if best else None

    def _plane(self, view, ro, rd):
        n = plane_normal(view)
        p = ray_plane(ro, rd, self.base, n)
        if p is None:
            return None
        # a point nearly at the horizon runs off to infinity: keep it within reach
        far = view.px(self.base) * max(view.w, view.h) * 20
        if length(sub(p, self.base)) > far:
            return None
        return p


def plane_normal(view):
    f = view.forward
    if abs(f[2]) >= EDGE_ON:
        return AXES[2]
    return AXES[0] if abs(f[0]) >= abs(f[1]) else AXES[1]


def _axis_of(e):
    for k, a in enumerate(AXES):
        if abs(abs(dot(e, a)) - 1.0) < 1e-6:
            return k
    return None


def _label(ln, kind, aligned, other):
    if kind == "lock":
        base = "Locked " + (AXIS_NAMES[ln.axis] if ln.axis is not None else "Direction")
        return base + (" · From Point" if aligned else "")
    if aligned:
        return "From Point"
    if ln.axis is None:
        return ""
    return ("Ortho " if kind == "ortho" else "On ") + AXIS_NAMES[ln.axis] + " Axis" + \
        (" from Point" if other else "")


# ──────────────────────────────────────────────────────────────── typing

def parse_typed(text, decode):
    """The Measurements box. decode(str) → a float in system units, or None (MAXScript's
    units.decodeValue in Max). Returns one of
        ("dist", d)              this far along the current direction
        ("rel", (x, y, z))       x,y,z — this far from the base point
        ("abs", (x, y, z))       [x,y,z] — the grabbed point lands exactly there
        ("array", n, "x"|"/")    5x / x5 / *5 — n copies at the spacing; /5 — divided
    or None when it doesn't parse."""
    t = (text or "").strip()
    if not t:
        return None
    m = re.fullmatch(r"(\d+)\s*[x*]|[x*]\s*(\d+)", t, re.I)
    if m:
        n = int(m.group(1) or m.group(2))
        return ("array", n, "x") if n >= 1 else None
    m = re.fullmatch(r"/\s*(\d+)|(\d+)\s*/", t)
    if m:
        n = int(m.group(1) or m.group(2))
        return ("array", n, "/") if n >= 1 else None
    absolute = t.startswith("[") and t.endswith("]")
    if absolute:
        t = t[1:-1]
    parts = [p.strip() for p in t.split(",")]
    if len(parts) == 3 or absolute:
        if len(parts) != 3:
            return None
        vals = [_num(p, decode) if p else 0.0 for p in parts]
        if any(v is None for v in vals):
            return None
        return ("abs" if absolute else "rel", tuple(vals))
    if len(parts) != 1:
        return None
    v = _num(t, decode)
    return ("dist", v) if v is not None else None


def _num(s, decode):
    try:
        v = decode(s)
    except Exception:
        return None
    if v is None:
        return None
    try:
        v = float(v)
    except (TypeError, ValueError):
        return None
    return v if math.isfinite(v) else None


# ──────────────────────────────────────────────────────────────── keys

# What reaches Windows when the Mac key is pressed with Karabiner's Max layers active
# (../../remap/bindings.json: max-finger1/2 = fingers resting on the trackpad, max-space =
# Space held; Escape is "opens" = ⌘O = Ctrl+O in the VM). test_infer.py checks these
# against bindings.json. (vk, ctrl, alt, shift) → action.
VK = {"back": 0x08, "tab": 0x09, "enter": 0x0D, "esc": 0x1B, "space": 0x20, "left": 0x25,
      "up": 0x26, "right": 0x27, "down": 0x28, "delete": 0x2E, "alt": 0x12, "f20": 0x83}
CAS = (True, True, True)
CHORDS = {
    # F: ortho is F HELD — over Max Karabiner makes a held F Shift (cad_hover), and
    # movetool reads Shift. A quick tap still types f: eaten, so Max's F (Front view)
    # doesn't fire mid-move.
    (0x46, False, False, False): "nop",            # F
    (0x78,) + CAS: "nop",                          # max.finger1.f → ctrl+alt+shift+f9
    (0x42,) + CAS: "nop",                          # max.finger2.f → ctrl+alt+shift+b
    (0x73,) + CAS: "nop",                          # max.space.f   → ctrl+alt+shift+f4
    (0x53, False, False, False): "snaps",          # S
    (0x48,) + CAS: "rearm",                        # max.finger1.s → ctrl+alt+shift+h = Move itself
    (0x43,) + CAS: "snaps",                        # max.space.s   → ctrl+alt+shift+c
    (0x20, False, False, False): "lock",           # Space (Karabiner sends it on release)
    (0x49,) + CAS: "lock",                         # max.finger2.space → ctrl+alt+shift+i
    (0x1B, False, False, False): "esc",
    (0x4F, True, False, False): "esc",             # opens: Escape → cmd+o → Ctrl+O
    (0x0D, False, False, False): "enter",          # ⌘ tap (always.right_command → return)
    (0x08, False, False, False): "back",
    (0x2E, False, False, False): "back",
    (0x27, False, False, False): "axis0",          # → X (SketchUp: right = red)
    (0x25, False, False, False): "axis1",          # ← Y (left = green)
    (0x26, False, False, False): "axis2",          # ↑ Z (up = blue)
}
# the chords' bindings.json rows, for the test
CHORD_ROWS = {"max.finger1.f": "ctrl+alt+shift+f9", "max.finger2.f": "ctrl+alt+shift+b",
              "max.space.f": "ctrl+alt+shift+f4", "max.finger1.s": "ctrl+alt+shift+h",
              "max.space.s": "ctrl+alt+shift+c", "max.finger2.space": "ctrl+alt+shift+i",
              "opens": "cmd+o", "always.right_command": "return"}
TYPED = set("0123456789.,-[]x*/'\"mc")


def action(vk, ctrl, alt, shift, char=""):
    """What a key does in the move tool: an action name, ("type", char), or None (not
    ours — Max gets it)."""
    a = CHORDS.get((vk, bool(ctrl), bool(alt), bool(shift)))
    if a:
        return a
    if not ctrl and not alt and char and char.lower() in TYPED:
        return ("type", char.lower())
    return None
