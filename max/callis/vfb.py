"""The current renderer's frame buffer: show / hide it, and its interface on / off (macros
ToggleFrameBuffer, ToggleFrameBufferUI).

The interface setting is sticky: `.state/vfb.json` {"ui": bool}, applied by a 300 ms watch to
whichever frame buffer is showing — one our toggle showed, a render opened, or one shown
again after a hide — so it holds through hide/show, renders and renderer switches.

  V-Ray   — `vfbControl #show true|false` (bare `#show` reads → #(1)). Max's Qt, so the
            interface = every widget beside the chain down to `vray_vfb_renderview`
            (menu bar, toolbars, status bar, both side panels), hidden; the image grows.
  Arnold  — MAXtoA's RenderView: a QDockWidget "Arnold RenderView" in Max's Qt (created by
            action 695602995-20 the first time). Same sibling hiding, kept = the biggest
            widget in `m_optionsSplitter`.
  Corona  — `CoronaFp.showVfb`. Its VFB runs on Corona's OWN Qt (class Qt672Legion…), out of
            PySide's reach: the side panel is closed with its own toggle button (top right,
            a posted click), the title bar + toolbar are clipped off with SetWindowRgn.
  others  — Max's Rendered Frame Window (Win32 #32770 with a BitmapWindow child; action 0-348
            toggles it): clipped to the BitmapWindow.
Clipping never moves the window, so the image stays where it was on screen.
"""
import ctypes
import json
import os
from ctypes import wintypes

from pymxs import runtime as rt

STATE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".state", "vfb.json")

_u = ctypes.windll.user32
_g = ctypes.windll.gdi32
_u.GetParent.restype = wintypes.HWND
_u.GetWindow.restype = wintypes.HWND
_u.FindWindowExW.restype = wintypes.HWND
_g.CreateRectRgn.restype = wintypes.HRGN
_u.SetWindowRgn.argtypes = (wintypes.HWND, wintypes.HRGN, wintypes.BOOL)
_ENUM = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)

CORONA_BAR = 44        # Corona's toolbar height at 96 dpi
_ui = None             # cached setting
_applied = {}          # hwnd → the ui state last applied to it
_hidden = {}           # hwnd → Qt widgets we hid (restored by ui on)
_corona_panel = False  # we closed Corona's side panel (its window is new each show)
_timer = None


# ── setting ─────────────────────────────────────────────────────────────────

def ui_on():
    global _ui
    if _ui is None:
        try:
            with open(STATE, encoding="utf-8") as f:
                _ui = bool(json.load(f).get("ui", True))
        except (OSError, ValueError):
            _ui = True
    return _ui


def _save(on):
    global _ui
    _ui = on
    os.makedirs(os.path.dirname(STATE), exist_ok=True)
    with open(STATE, "w", encoding="utf-8") as f:
        json.dump({"ui": on}, f)


# ── which frame buffer ──────────────────────────────────────────────────────

def kind():
    c = str(rt.classOf(rt.renderers.current)).lower()
    if c.startswith("corona"):
        return "corona"
    if c.startswith("v_ray"):
        return "vray"
    if c == "arnold":
        return "arnold"
    return "max"


def _windows():
    """Top-level windows of this process: (hwnd, class, title)."""
    pid = os.getpid()
    out = []

    def cb(h, _):
        p = wintypes.DWORD()
        _u.GetWindowThreadProcessId(h, ctypes.byref(p))
        if p.value == pid:
            c = ctypes.create_unicode_buffer(96)
            t = ctypes.create_unicode_buffer(160)
            _u.GetClassNameW(h, c, 96)
            # Never GetWindowTextW: on another thread's window it SENDS WM_GETTEXT and
            # waits. Max's .NET SystemEvents thread hangs while it marshals a display
            # change to this (main) thread → deadlock, Max frozen for good (2026-10-16).
            _u.InternalGetWindowText(h, t, 160)
            out.append((h, c.value, t.value))
        return True
    _u.EnumWindows(_ENUM(cb), 0)
    return out


def _qt_top(title):
    from PySide6 import QtWidgets
    for w in QtWidgets.QApplication.topLevelWidgets():
        if w.windowTitle() == title:
            return w
    return None


def _hwnd(k):
    """The frame buffer's top-level window (shown or not), or None."""
    if k in ("vray", "arnold"):
        w = _qt_top("V-Ray Frame Buffer" if k == "vray" else "Arnold RenderView")
        return int(w.winId()) if w is not None else None
    for h, c, t in _windows():
        if k == "corona" and "Legion" in c and t.startswith("Corona"):
            return h
        if k == "max" and c == "#32770" and _u.FindWindowExW(h, None, "BitmapWindow", None):
            return h
    return None


def visible(k=None):
    h = _hwnd(k or kind())
    return bool(h and _u.IsWindowVisible(h))


# ── show / hide ─────────────────────────────────────────────────────────────

def toggle():
    k = kind()
    show = not visible(k)
    if k == "vray":
        rt.vfbControl(rt.Name("show"), show)
    elif k == "corona":
        rt.CoronaRenderer.CoronaFp.showVfb(show)
    elif k == "arnold":
        w = _qt_top("Arnold RenderView")
        if w is None:
            rt.actionMan.executeAction(695602995, "20")
        else:
            w.setVisible(show)
            if show:
                w.raise_()
    else:
        rt.actionMan.executeAction(0, "348")
    if show:
        _apply(k)


def toggle_ui():
    _save(not ui_on())
    _apply(kind())
    from . import hud
    hud.show("Frame buffer interface " + ("on" if ui_on() else "off"), 900)


# ── interface ───────────────────────────────────────────────────────────────

def _apply(k):
    h = _hwnd(k)
    if not h or not _u.IsWindowVisible(h):
        return
    want = ui_on()
    if _applied.get(h) == want and _still(h, want):
        return
    if k in ("vray", "arnold"):
        _qt_ui(h, k, want)
    elif k == "corona":
        _corona_ui(h, want)
    else:
        _clip(h, None if want else _max_image(h))
    _applied[h] = want


def _still(h, want):
    """Re-check a Qt frame buffer: V-Ray / MAXtoA may show their own widgets again."""
    return want or all(not w.isVisible() for w in _hidden.get(h, []))


def _keep(top, k):
    from PySide6 import QtWidgets
    if k == "vray":
        return top.findChild(QtWidgets.QWidget, "vray_vfb_renderview")
    sp = top.findChild(QtWidgets.QSplitter, "m_optionsSplitter")
    if sp is None:
        return None
    kids = [sp.widget(i) for i in range(sp.count())]
    kids = [w for w in kids if w is not None]
    return max(kids, key=lambda w: w.width() * w.height(), default=None)


def _qt_ui(h, k, want):
    from PySide6 import QtWidgets
    top = _qt_top("V-Ray Frame Buffer" if k == "vray" else "Arnold RenderView")
    if want:
        for w in _hidden.pop(h, []):
            try:
                w.setVisible(True)
            except RuntimeError:      # deleted meanwhile
                pass
        return
    keep = _keep(top, k)
    if keep is None:
        return
    hid = _hidden.setdefault(h, [])
    w = keep
    while w is not None and w is not top:
        p = w.parentWidget()
        if p is None:
            break
        for s in p.children():
            if isinstance(s, QtWidgets.QWidget) and s is not w and s.isVisible() and not s.isWindow():
                s.setVisible(False)
                if s not in hid:
                    hid.append(s)
        w = p


def _rect_in(h, child):
    """child's client rect in h's window coordinates (what SetWindowRgn takes)."""
    wr = wintypes.RECT()
    cr = wintypes.RECT()
    _u.GetWindowRect(h, ctypes.byref(wr))
    _u.GetWindowRect(child, ctypes.byref(cr))
    return (cr.left - wr.left, cr.top - wr.top, cr.right - wr.left, cr.bottom - wr.top)


def _max_image(h):
    """The Rendered Frame Window's image: its BitmapWindow below that window's own toolbar."""
    bw = _u.FindWindowExW(h, None, "BitmapWindow", None)
    l, t, r, b = _rect_in(h, bw)
    bar = _u.FindWindowExW(bw, None, "CustToolbar", None)
    if bar and _u.IsWindowVisible(bar):
        t = max(t, _rect_in(h, bar)[3])
    return (l, t, r, b)


def _client_in(h):
    wr = wintypes.RECT()
    cr = wintypes.RECT()
    pt = wintypes.POINT(0, 0)
    _u.GetWindowRect(h, ctypes.byref(wr))
    _u.GetClientRect(h, ctypes.byref(cr))
    _u.ClientToScreen(h, ctypes.byref(pt))
    x, y = pt.x - wr.left, pt.y - wr.top
    return (x, y, x + cr.right, y + cr.bottom)


def _clip(h, rect):
    rgn = _g.CreateRectRgn(*rect) if rect else None
    _u.SetWindowRgn(h, rgn, True)       # the system owns rgn from here


def _corona_panel_open(h):
    """Corona's right panel is a flat mid grey; the viewer behind an image is darker."""
    from PySide6 import QtWidgets
    cr = wintypes.RECT()
    _u.GetClientRect(h, ctypes.byref(cr))
    img = QtWidgets.QApplication.primaryScreen().grabWindow(h, cr.right - 4, cr.bottom - 6, 1, 1).toImage()
    c = img.pixelColor(0, 0)
    return 60 <= c.red() <= 95 and abs(c.red() - c.blue()) < 6


def _corona_click_panel(h):
    cr = wintypes.RECT()
    _u.GetClientRect(h, ctypes.byref(cr))
    s = _u.GetDpiForWindow(h) / 96.0
    lp = (int(22 * s) << 16) | (cr.right - int(25 * s))
    res = ctypes.c_size_t()
    for m, wp in ((0x0200, 0), (0x0201, 1), (0x0202, 0)):
        # bounded (SMTO_ABORTIFHUNG, 500 ms): a plain SendMessage to a stuck thread hangs Max
        _u.SendMessageTimeoutW(h, m, wp, lp, 0x2, 500, ctypes.byref(res))


def _corona_ui(h, want):
    global _corona_panel
    if want:
        _clip(h, None)
        if _corona_panel and not _corona_panel_open(h):
            _corona_click_panel(h)
        _corona_panel = False
        return
    if _corona_panel_open(h):
        _corona_click_panel(h)
        _corona_panel = True
    l, t, r, b = _client_in(h)
    _clip(h, (l, t + int(CORONA_BAR * _u.GetDpiForWindow(h) / 96.0), r, b))


# ── watch: the setting follows whichever frame buffer shows ─────────────────

def _tick():
    try:
        _apply(kind())
    except Exception as e:
        print("[callis] frame buffer interface:", e)


def install():
    global _timer
    from PySide6.QtCore import QTimer
    if _timer is not None:
        _timer.stop()
    _timer = QTimer()
    _timer.timeout.connect(_tick)
    _timer.start(300)
