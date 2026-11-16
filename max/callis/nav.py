"""Fusion-style trackpad navigation for Max, driven from the Mac by bin/reanchor.m.

Max sits in a Parallels VM, so the Mac sees only "the Parallels window". Two files /
streams join the halves:

  Max → Mac   publish() keeps .state/nav.json current (polled every 250 ms, written only
              on change): Max's IP, the Windows desktop size, whether Max is the Windows
              foreground app, the viewport panel's rect, and the rects of Max's other
              windows (dialogs, floating panels, menus) that would cover it; rewritten
              every HEARTBEAT s regardless, so its age says Max is alive. reanchor maps
              the Mac pointer into Windows pixels with it and decides "over Max's viewport".

  Mac → Max   reanchor keeps one bridge socket open and streams {"lang": "nav", ...}
              frames down it (bridge_startup.py hands them to handle(), no reply):
                {"op": "zoom", "x", "y" (Windows screen px), "d" (scroll px, + = in),
                 "t" (Mac seconds), "begin" (first event of a gesture)}
              Everything that arrived since the last redraw is applied as ONE camera move.

              {"op": "drag", "x", "y", "dx", "dy", "shift", "begin"} … {"op": "end"}
              — a 3-finger drag: orbit, or pan while F is held (Karabiner F→Shift).

Orbit and pan are ours, not Max's middle-button navigation (2026-10-10): Max only orbits
the point under the cursor in one orbit mode, misses XRef scenes, and draws a marker. The
pivot is picked once per drag under the cursor (xref scenes included), orbit turns about
it, pan keeps it under the cursor; a camera view moves its camera (one undo step per drag).
setup() still makes a real mouse's MMB orbit and Shift+MMB pan.

The zoom is a dolly toward the point under the cursor, by a fraction of the distance to
it, so it slows by itself near the model and can never pass through it. The curve
constants below are the built-in curve; Control Room ▸ 3ds Max ▸ Scroll Curve shapes it
(scroll/curves.json, read live — see _User).
"""
import ctypes
import ctypes.wintypes as W
import json
import math
import os
import time

import pymxs
from pymxs import runtime as rt

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STATE = os.path.join(HERE, ".state", "nav.json")
HEARTBEAT = 2.0      # s — rewritten at least this often; reanchor ignores a file >5 s old
                     # (Max quit or crashed), so a stale "foreground" can't hijack drags

# ── zoom curve ───────────────────────────────────────────────────────────────
# The built-in curve. On top of it, Control Room ▸ 3ds Max ▸ Scroll Curve draws
# multipliers (velocity / proximity × in / out), the closest approach and a master
# gain → ../scroll/curves.json, read by _User below (flat / missing = this curve as is).
POWER = 1.3          # per-event |px|^POWER: small moves fine, big swipes coarser
GAIN = 0.0045        # fraction-of-distance (log) per curved px
BOOST_KNEE = 6000.0  # px/s — faster swipes than this zoom harder…
BOOST_MAX = 2.5      # …up to this multiple
MAX_STEP = 0.9       # cap on one coalesced move (log units: e^0.9 ≈ 2.5×)
NEAR_CM = 0.13       # never closer to the pivot than this (cm) unless curves.json says
CURVES = os.path.join(HERE, "scroll", "curves.json")
LIVE = os.path.join(HERE, "scroll", "live.json")   # the editor's "where am I" marker

# ── orbit ────────────────────────────────────────────────────────────────────
ORBIT_DEG = 0.12     # degrees of turn per Windows px of 3-finger drag

_u = ctypes.windll.user32


# ──────────────────────────────────────────────────────────────── Max → Mac

def _rect(hwnd):
    r = W.RECT()
    _u.GetWindowRect(W.HWND(hwnd), ctypes.byref(r))
    return [r.left, r.top, r.right - r.left, r.bottom - r.top]


def _main_hwnd():
    import qtmax
    return int(qtmax.GetQMaxMainWindow().winId())


def _panel_hwnd():
    h = int(rt.viewport.getHWnd())
    p = _u.GetParent(W.HWND(h))
    return p or h                # the ViewPanel: every viewport of the layout


_ENUM = ctypes.WINFUNCTYPE(ctypes.c_bool, W.HWND, W.LPARAM)


def _covers(main):
    """Rects of Max's own visible top-level windows other than the main one."""
    pid = os.getpid()
    out = []

    def cb(h, _):
        p = W.DWORD()
        _u.GetWindowThreadProcessId(h, ctypes.byref(p))
        if p.value == pid and _u.IsWindowVisible(h) and int(h or 0) != main:
            r = _rect(h)
            if r[2] > 4 and r[3] > 4:
                out.append(r)
        return True
    _u.EnumWindows(_ENUM(cb), 0)
    return out


def _ip():
    import builtins
    b = getattr(builtins, "_claude_bridge", None)
    return b.server.serverAddress().toString() if b else ""


def snapshot():
    main = _main_hwnd()
    fg = _u.GetForegroundWindow()
    p = W.DWORD()
    _u.GetWindowThreadProcessId(W.HWND(fg), ctypes.byref(p))
    return {"ip": _ip(), "port": 27120, "pid": os.getpid(),
            "desk": [_u.GetSystemMetrics(0), _u.GetSystemMetrics(1)],
            "fg": p.value == os.getpid() and not _u.IsIconic(W.HWND(main)),
            "panel": _rect(_panel_hwnd()), "covers": _covers(main)}


class _Publisher:
    def __init__(self):
        from PySide6.QtCore import QTimer
        self.last, self.written = None, 0.0
        self.timer = QTimer()
        self.timer.timeout.connect(self.tick)
        self.timer.start(250)

    def tick(self):
        try:
            s = snapshot()
        except Exception as e:          # mid-reset etc.: try again next tick
            s = {"error": str(e)}
        now = time.time()
        if s == self.last and now - self.written < HEARTBEAT:
            return
        self.last, self.written = s, now
        try:
            tmp = STATE + ".tmp"
            with open(tmp, "w") as f:
                json.dump(dict(s, t=time.time()), f)
            os.replace(tmp, STATE)
        except OSError:
            pass


def publish():
    import builtins
    old = getattr(builtins, "_callis_nav_pub", None)
    if old is not None:
        old.timer.stop()
    builtins._callis_nav_pub = _Publisher()


def setup():
    """Plain MMB orbits, Shift+MMB pans (Max's default is MMB pan, Alt+MMB orbit —
    Alt can't be held from the trackpad, Shift can: F)."""
    rt.MouseConfigManager.UserMode = rt.Name("Customized")
    rt.MouseConfigManager.SetRotateShortcut(rt.Name("Null"), rt.Name("MiddleButton"))
    rt.MouseConfigManager.SetPanShortcut(rt.Name("Shift"), rt.Name("MiddleButton"))
    publish()


# ──────────────────────────────────────────────────────────────── Mac → Max

_g = {"pivot": None, "vel": 0.0, "t": None, "dist_cm": None, "live_t": 0.0}


class _User:
    """curves.json, re-read when its mtime moves (stat'd at most every CHECK s — it is
    on the Mac share). A curve is {xmin, xmax, scale (1 = log x), samples}: evenly
    spaced multipliers, linearly interpolated, clamped at the ends — the same LUT
    FusionScrollFilter.c reads. Anything unreadable → 1.0 (the built-in curve)."""
    CHECK = 0.5

    def __init__(self):
        self.mtime, self.checked, self.d = None, 0.0, {}

    def refresh(self):
        now = time.time()
        if now - self.checked < self.CHECK:
            return
        self.checked = now
        try:
            m = os.stat(CURVES).st_mtime
        except OSError:
            self.mtime, self.d = None, {}
            return
        if m == self.mtime:
            return
        try:
            with open(CURVES) as f:
                self.d = json.load(f)
            self.mtime = m
        except (OSError, ValueError):
            pass                         # half-written: keep the last good, retry next check

    def mult(self, name, x):
        c = self.d.get(name)
        try:
            s, lo, hi = c["samples"], float(c["xmin"]), float(c["xmax"])
            v = min(max(x, lo), hi)
            if c.get("scale"):
                lo, v, hi = math.log(max(lo, 1e-9)), math.log(max(v, 1e-9)), math.log(hi)
            fi = (v - lo) / (hi - lo) * (len(s) - 1)
            i = min(int(fi), len(s) - 2)
            return float(s[i] + (s[i + 1] - s[i]) * (fi - i))
        except (TypeError, KeyError, ValueError, IndexError, ZeroDivisionError):
            return 1.0

    def num(self, name, default, lo, hi):
        try:
            return min(max(float(self.d[name]), lo), hi)
        except (KeyError, TypeError, ValueError):
            return default


_user = _User()


def _cm():
    """World units per cm (the scene's system unit), asked once per gesture."""
    try:
        return float(rt.units.decodeValue("1cm"))
    except Exception:
        return 1.0
_d = {}             # the current 3-finger drag (see _drag_start); empty = none


def handle(frames):
    """One batch = everything that arrived since the last redraw. Runs of the same op
    (and, for drags, the same Shift state) are applied as one move each, in order."""
    runs = []
    for f in frames:
        key = (f.get("op"), bool(f.get("shift")))
        if runs and runs[-1][0] == key and not f.get("begin"):
            runs[-1][1].append(f)
        else:
            runs.append((key, [f]))
    moved = False
    for (op, shift), fs in runs:
        if op == "zoom":
            moved |= _zoom(fs)
        elif op == "drag":
            moved |= _drag(fs, shift)
        elif op == "end":
            _drag_end()
        elif op in ("tap2", "tap3", "click"):
            _gesture(fs[-1])
    if moved:
        rt.redrawViews()


# ── taps and clicks: the Browser's Click Actions ─────────────────────────────
# {"op": "tap3"} three-finger tap (reanchor) → the top; {"op": "tap2"} up a level;
# {"op": "click", "x", "y", "mods"} a stationary left click (callis/rclick.py, from inside
# Windows — Max has had it too and made its own pick). A click is Max's select, nothing
# more (empty space deselects); Space+click also goes all the way down to what was clicked
# (Go to Bottom); ⌘-click (Ctrl here) adds / removes. Right-clicks never come here —
# rclick.py eats them and goes up itself. See callis/browser.py § the viewport's gestures.
CLICK_DEFER_MS = 80      # Max's own pick lands first
# A 3-finger tap is also a left click to Windows (Parallels has the OS's click before
# reanchor can swallow it): a click this close to a tap3 is the tap's own — it only
# puts the selection back.
TAP3_CLICK_S = 0.5
_tap3 = [0.0]


def _gesture(f):
    import callis.browser as browser
    op = f.get("op")
    if op == "tap3":
        _tap3[0] = time.time()
    if op == "click":
        from PySide6.QtCore import QTimer
        QTimer.singleShot(CLICK_DEFER_MS, lambda: _click(f))
        return
    browser.key("navup" if op == "tap2" else "navtop")


def _click(f):
    import callis.browser as browser
    mods = str(f.get("mods") or "")
    try:
        if time.time() - _tap3[0] < TAP3_CLICK_S:
            with pymxs.undo(False):
                browser.unclick()
        elif "ctrl" in mods or "cmd" in mods:
            n = _clicked(f)
            if n is not None:
                browser.ctrl_click(n)
        elif "space" in mods and "alt" not in mods:
            n = _clicked(f)
            if n is not None:
                with pymxs.undo(False):
                    browser.toward(n, True, select=False)
        else:
            return
        browser.publish(now=True)
    except Exception as e:
        print("[callis.nav] click:", e)


def _clicked(f):
    """What the click was on: the object under the point, else what Max's click selected
    when that is one new object (a light, a shape — the ray only hits geometry)."""
    pt = _viewport_at(f)
    if pt is not None:
        _ms()
        try:
            n = rt.callisPickNode(rt.mapScreenToWorldRay(pt))
        except Exception:
            n = None
        if n is not None and str(n) != "undefined":
            return n
    try:
        n = rt.callisClicked()
    except Exception:
        return None
    return None if n is None or str(n) == "undefined" else n


def _curve(f, dist_cm):
    d = float(f.get("d", 0))
    t = float(f.get("t", 0))
    if f.get("begin") or _g["t"] is None or t - _g["t"] > 0.15:
        _g["vel"] = 0.0
    elif t > _g["t"]:
        _g["vel"] = 0.7 * _g["vel"] + 0.3 * abs(d) / (t - _g["t"])
    _g["t"] = t
    way = "in" if d > 0 else "out"
    boost = 1.0 + (BOOST_MAX - 1.0) * max(0.0, min(1.0, (_g["vel"] - BOOST_KNEE) / BOOST_KNEE))
    boost *= _user.mult("vel_" + way, _g["vel"])
    if dist_cm is not None:
        boost *= _user.mult("prox_" + way, dist_cm)
    return math.copysign(abs(d) ** POWER, d) * GAIN * boost


def _zoom(frames):
    last = frames[-1]
    pt = _viewport_at(last)
    if pt is None:
        return False
    begin = any(f.get("begin") for f in frames)
    _user.refresh()
    if begin or "cm" not in _g:
        _g["cm"] = _cm()
    kind = str(rt.viewport.getType())
    persp = kind in ("view_persp_user", "view_camera", "view_spot")
    # Proximity is the distance to the point under the cursor — only a perspective
    # view has one; an ortho zoom gets the velocity curve and the gain only.
    dist_cm = _pivot_dist(pt, begin) / _g["cm"] if persp else None
    amount = sum(_curve(f, dist_cm) for f in frames) * _user.num("gain", 1.0, 0.05, 10.0)
    amount = max(-MAX_STEP, min(MAX_STEP, amount))
    if persp:
        _dolly(pt, amount, kind != "view_persp_user")
    else:
        _ortho(pt, amount)
    _publish_live(dist_cm)
    return True


def _publish_live(dist_cm):
    """The editor's marker: where this scroll sits on each axis. Throttled — it is a
    write across the share."""
    now = time.time()
    if now - _g["live_t"] < 0.2:
        return
    _g["live_t"] = now
    try:
        with open(LIVE, "w") as f:
            json.dump({"vel": round(_g["vel"]), "dist": dist_cm and round(dist_cm, 1)}, f)
    except OSError:
        pass


def _viewport_at(f):
    """Make the viewport under Windows screen point f["x"], f["y"] active; its local
    point, or None when the point isn't over a viewport."""
    info = rt.viewport.getViewportFromScreenCoord(rt.Point2(f["x"], f["y"]))
    if info is None or str(info) == "undefined":
        return None
    idx, pt = int(info[1]), info[4]
    if idx != int(rt.viewport.activeViewport):
        rt.viewport.activeViewport = idx
        _g["pivot"] = None
    return pt


# The pick, in MAXScript: one call instead of a pymxs round trip per node. intersectRayScene
# skips XRef SCENE nodes (they aren't in the scene's node list — tested 2026-10-10; XRef
# OBJECTS are hit), so those trees are walked here, AABB-tested before the mesh test.
_MS = r"""
fn callisRayHitsBox r a b = (
    local t0 = -1e30, t1 = 1e30, ok = true
    for i = 1 to 3 while ok do (
        local o = r.pos[i], d = r.dir[i]
        if abs d < 1e-12 then (if o < a[i] or o > b[i] do ok = false)
        else (
            local ta = (a[i] - o) / d, tb = (b[i] - o) / d
            if ta > tb do swap ta tb
            if ta > t0 do t0 = ta
            if tb < t1 do t1 = tb
            if t0 > t1 or t1 < 0 do ok = false
        )
    )
    ok
)
fn callisAddTree n acc = (append acc n; for c in n.children do callisAddTree c acc)
fn callisXRefNodes root acc = (     -- root: undefined = the scene, else an XRefScene
    local cnt = if root == undefined then xrefs.getXRefFileCount() else xrefs.getXRefFileCount root:root
    for i = 1 to cnt do (
        local f = if root == undefined then xrefs.getXRefFile i else xrefs.getXRefFile i root:root
        if not f.hidden and not f.disabled do (
            for c in f.tree.children do callisAddTree c acc
            callisXRefNodes f acc           -- nested: root: takes the XRefScene
        )
    )
    acc
)
fn callisPick r = (
    local best = undefined, bd = 1e30
    for h in (intersectRayScene r) do (
        local n = h[1]
        if not n.isNodeHidden and superClassOf n == GeometryClass do (
            local d = dot (h[2].pos - r.pos) r.dir
            if d > 0 and d < bd do (bd = d; best = h[2].pos)
        )
    )
    for n in (callisXRefNodes undefined #()) do (
        if not n.isNodeHidden and superClassOf n == GeometryClass and callisRayHitsBox r n.min n.max do (
            local h = intersectRay n r
            if h != undefined do (
                local d = dot (h.pos - r.pos) r.dir
                if d > 0 and d < bd do (bd = d; best = h.pos)
            )
        )
    )
    best
)
fn callisPickNode r = (
    local best = undefined, bd = 1e30
    for h in (intersectRayScene r) do (
        local d = dot (h[2].pos - r.pos) r.dir
        if not h[1].isNodeHidden and d > 0 and d < bd do (bd = d; best = h[1])
    )
    best
)
fn callisOrbitTM cam piv yaw pitch = (
    local rot = matrix3 cam.row1 cam.row2 cam.row3 [0,0,0]
    local m = (transMatrix -piv) * (inverse rot) * (rotateXMatrix pitch) * rot * (rotateZMatrix yaw) * (transMatrix piv)
    cam * m
)
"""


def _ms():
    if _g.get("ms") != _MS:              # (re)defined after an edit + reload too
        rt.execute(_MS)
        _g["ms"] = _MS


def _pick(ray):
    _ms()
    try:
        p = rt.callisPick(ray)
    except Exception:
        return None
    return None if p is None or str(p) == "undefined" else p


def _pivot(ray, eye):
    """Nearest visible surface under the cursor (xref scenes included), else the point
    on the ray as deep as the last pivot was, else the viewport's focal point."""
    hit = _pick(ray)
    if hit is not None:
        return hit
    last = _g.get("last_depth")
    d = last if last else float(rt.viewport.GetFocalDistance())
    return ray.pos + rt.normalize(ray.dir) * d


def _pivot_dist(pt, begin):
    """Distance (world units) from the eye to the zoom's pivot — picked under the
    cursor at the gesture's start, then kept."""
    ray = rt.mapScreenToWorldRay(pt)
    eye = rt.inverse(rt.viewport.getTM()).row4
    if begin or _g["pivot"] is None:
        _g["pivot"] = _pivot(ray, eye)
    return float(rt.distance(eye, _g["pivot"]))


def _dolly(pt, amount, camera):
    ray = rt.mapScreenToWorldRay(pt)
    cam = rt.inverse(rt.viewport.getTM())
    eye = cam.row4
    near = _user.num("near", NEAR_CM, 0.01, 1000.0) * _g["cm"]
    d = max(float(rt.distance(eye, _g["pivot"])), near)
    step = d - max(d * math.exp(-amount), near)
    move = rt.normalize(ray.dir) * step
    if camera:
        node = rt.viewport.getCamera()
        if node is None or str(node) == "undefined":
            return
        from . import cameras
        if cameras.is_locked(node):
            return
        node.pos = node.pos + move
        tgt = getattr(node, "target", None)
        if tgt is not None and str(tgt) != "undefined":
            tgt.pos = tgt.pos + move
    else:
        cam.row4 = eye + move
        rt.viewport.setTM(rt.inverse(cam))


def _ortho(pt, amount):
    """Zoom an orthographic view about the cursor: scale, then shift so the world
    point under the cursor stays put."""
    before = rt.mapScreenToWorldRay(pt).pos
    rt.viewport.zoom(math.exp(-amount))
    after = rt.mapScreenToWorldRay(pt).pos
    cam = rt.inverse(rt.viewport.getTM())
    cam.row4 = cam.row4 + (before - after)
    rt.viewport.setTM(rt.inverse(cam))


# ── 3-finger drag: orbit / pan ───────────────────────────────────────────────
# Max's own MMB orbit only uses the point of interest in its "Orbit Point of Interest"
# mode, misses XRef scenes, and draws a pivot marker. So the drag is ours too:
# {"op": "drag", "x", "y" (Windows px at the drag's first frame), "dx", "dy" (Windows
# px), "shift" (F held → pan), "begin"} … {"op": "end"}. The pivot is picked ONCE, at
# the begin: the surface under the cursor (_pivot). Orbit turns the view about it
# (turntable: yaw about world Z, pitch about the view's right axis; the model follows
# the fingers); pan keeps that point under the cursor.

def _camera():
    if str(rt.viewport.getType()) not in ("view_camera", "view_spot"):
        return None
    n = rt.viewport.getCamera()
    return None if n is None or str(n) == "undefined" else n


def _target(n):
    t = getattr(n, "target", None) if n is not None else None
    return None if t is None or str(t) == "undefined" else t


def _drag_start(f):
    _d.clear()
    pt = _viewport_at(f)
    if pt is None:
        return False
    from . import cameras
    if cameras.is_locked(_camera()):
        return False
    kind = str(rt.viewport.getType())
    if kind not in ("view_persp_user", "view_iso_user", "view_camera", "view_spot"):
        rt.viewport.setType(rt.Name("view_iso_user"))    # Top/Front/… → the same view, orbitable
    ray = rt.mapScreenToWorldRay(pt)
    piv = _pivot(ray, ray.pos)
    _g["last_depth"] = float(rt.dot(piv - ray.pos, rt.normalize(ray.dir)))
    cam = _camera()
    _d.update(pivot=piv, cam=cam, pt=pt,
              before=(rt.copy(cam.transform), rt.copy(_target(cam).pos) if _target(cam) else None)
              if cam else None)
    return True


def _drag(frames, shift):
    if frames[0].get("begin") or not _d:
        if not _drag_start(frames[0]):
            return False
    dx = sum(float(f.get("dx", 0)) for f in frames)
    dy = sum(float(f.get("dy", 0)) for f in frames)
    if not dx and not dy:
        return False
    with pymxs.undo(False):
        if shift:
            _pan(dx, dy)
        else:
            _orbit(dx, dy)
    return True


def _apply(m):
    """Move the view (or its camera) by the world-space transform m."""
    cam = _d.get("cam")
    if cam is None:
        view = rt.inverse(rt.viewport.getTM()) * m
        rt.viewport.setTM(rt.inverse(view))
        return
    tgt = _target(cam)
    if tgt is not None:
        tgt.pos = tgt.pos * m
        cam.pos = cam.pos * m              # the look-at controller re-aims it
    else:
        cam.transform = cam.transform * m


def _orbit(dx, dy):
    _ms()
    view = rt.inverse(rt.viewport.getTM())
    m = rt.inverse(view) * rt.callisOrbitTM(view, _d["pivot"], -dx * ORBIT_DEG, -dy * ORBIT_DEG)
    _apply(m)


def _pan(dx, dy):
    """Grab the pivot's depth plane: two rays dx,dy apart meet it that far apart."""
    pt = _d["pt"]
    view = rt.inverse(rt.viewport.getTM())
    n = rt.normalize(view.row3)
    piv = _d["pivot"]

    def on_plane(p):
        r = rt.mapScreenToWorldRay(p)
        dn = float(rt.dot(r.dir, n))
        if abs(dn) < 1e-9:
            return None
        return r.pos + r.dir * (float(rt.dot(piv - r.pos, n)) / dn)
    a, b = on_plane(pt), on_plane(rt.Point2(pt.x + dx, pt.y + dy))
    if a is None or b is None:
        return
    _apply(rt.transMatrix(a - b))


def _drag_end():
    """A camera that was orbited/panned gets ONE undo record for the whole drag (view
    moves aren't scene undo, as with Max's own navigation)."""
    cam, before = _d.get("cam"), _d.get("before")
    _d.clear()
    if cam is None or before is None or rt.isDeleted(cam):
        return
    tgt = _target(cam)
    after = (rt.copy(cam.transform), rt.copy(tgt.pos) if tgt else None)
    with pymxs.undo(False):
        cam.transform = before[0]
        if tgt is not None:
            tgt.pos = before[1]
    with pymxs.undo(True, "Orbit Camera"):
        cam.transform = after[0]
        if tgt is not None:
            tgt.pos = after[1]


# ── Snap View to Nearest Axis (Fusion's "Snap View" add-in) ──────────────────
# Turns the view to whichever of ±X/±Y/±Z it already looks closest along and STAYS in
# perspective (Max's Front/Top/… are orthographic): an orbit about the point in the
# middle of the view (the surface there, else the focal point) at the same distance. Up
# = the world axis nearest the screen's up, square to the new direction. An ortho /
# iso view becomes perspective; a locked camera is left alone, an unlocked one moves
# (one undo record). The scene a few px on screen or off it → Zoom Extents after.

_AXES = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
FAR_FRACTION = 0.01      # the scene's on-screen box at most this share of the view = lost

_SNAP_MS = r"""
fn callisSceneBox = (
    local lo = undefined, hi = undefined
    for n in geometry where not n.isNodeHidden and classOf n != Targetobject do (
        if lo == undefined then (lo = copy n.min; hi = copy n.max)
        else (lo = [amin lo.x n.min.x, amin lo.y n.min.y, amin lo.z n.min.z]
              hi = [amax hi.x n.max.x, amax hi.y n.max.y, amax hi.z n.max.z])
    )
    if lo == undefined then undefined else #(lo, hi)
)
fn callisLost box eye look frac = (
    gw.setTransform (matrix3 1)
    local xs = #(), ys = #()
    for x in #(box[1].x, box[2].x) do for y in #(box[1].y, box[2].y) do for z in #(box[1].z, box[2].z) do (
        local p = [x, y, z]
        if dot (p - eye) look > 0 do (local s = gw.wTransPoint p; append xs s.x; append ys s.y)
    )
    if xs.count == 0 then true else (
        local w = gw.getWinSizeX(), h = gw.getWinSizeY()
        local x0 = amin xs, x1 = amax xs, y0 = amin ys, y1 = amax ys
        if x1 < 0 or x0 > w or y1 < 0 or y0 > h then true
        else (amax (x1 - x0) (y1 - y0)) <= frac * (amin w h)
    )
)
"""


def _near(v, cands):
    return max(cands, key=lambda c: v[0] * c[0] + v[1] * c[1] + v[2] * c[2])


def snap_view():
    try:
        _snap_view()
    except Exception as e:
        print("[callis.nav] snap view:", e)


def _snap_view():
    from . import cameras
    _ms()
    if _g.get("snap_ms") != _SNAP_MS:
        rt.execute(_SNAP_MS)
        _g["snap_ms"] = _SNAP_MS
    cam = _camera()
    if cam is not None and cameras.is_locked(cam):
        return
    if cam is None and str(rt.viewport.getType()) != "view_persp_user":
        rt.viewport.setType(rt.Name("view_persp_user"))
    view = rt.inverse(rt.viewport.getTM())
    eye = view.row4
    look = rt.normalize(-view.row3)
    up = rt.normalize(view.row2)
    size = rt.getViewSize()
    piv = _pick(rt.mapScreenToWorldRay(rt.Point2(size.x / 2, size.y / 2)))
    if piv is None:
        piv = eye + look * float(rt.viewport.GetFocalDistance())
    dist = float(rt.distance(eye, piv))
    if dist < 1e-6:
        return
    box = rt.callisSceneBox()
    fit = box is not None and str(box) != "undefined" and \
        bool(rt.callisLost(box, eye, look, FAR_FRACTION))

    d = _near((look.x, look.y, look.z), _AXES)
    u = _near((up.x, up.y, up.z), [a for a in _AXES if sum(p * q for p, q in zip(a, d)) == 0])
    d3, u3 = rt.Point3(*d), rt.Point3(*u)
    back = -d3
    new = rt.Matrix3(rt.cross(u3, back), u3, back, piv - d3 * dist)
    if cam is None:
        rt.viewport.setTM(rt.inverse(new))
    else:
        tgt = _target(cam)
        with pymxs.undo(True, "Snap View"):
            cam.transform = new
            if tgt is not None:
                tgt.pos = piv
    if fit:
        rt.viewport.ZoomToBounds(False, box[0], box[1])
    rt.redrawViews()
