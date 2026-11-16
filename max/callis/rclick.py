"""Fusion's viewport clicks, read inside Windows.

Parallels takes the Mac's mouse ahead of any Mac event tap, so a right-click can't be
kept from Max there (reanchor tried; the quad menu opened anyway, and tapping every
right-click on the Mac made context menus elsewhere flash). So Max's own message queue
is watched instead: a WH_GETMESSAGE hook on Max's main thread sees every mouse message
posted to the viewports (native "Label" windows under the "ViewPanel"), whichever pump
— Qt's or Max's — takes it off the queue.

  right-click   no modifier, no command running (select / move / rotate / scale mode):
                eaten — down and up become WM_NULL, so no quad menu — and the Browser goes
                up a level. Ctrl / Alt / Shift + right-click are Max's quads; while a
                command runs (creating a line…) the right-click is Max's, to end it.
  click         a stationary left click is only WATCHED: Max picks as always, then
                nav._gesture({"op": "click", …}): Space+click goes down to the pick,
                Ctrl (the Mac's ⌘) + click adds / removes. callisPreClick (the selection
                from before, taken on the down, before Max has the message) is what a
                3-finger tap's click is undone to and what Ctrl+click toggles against.

  claim(owner)  a tool (callis/movetool.py) takes the keyboard and the left click: while
                claimed, every key message on Max's thread is offered to owner.want(vk,
                ctrl, alt, shift, char) → a token to eat it (WM_NULL — the hook runs inside
                GetMessage, before Max's and Qt's accelerators, so no hotkey fires) and
                owner.key(token) runs on a QTimer; None leaves it to Max. A clean Alt tap is
                offered as vk VK_MENU with alt set; Shift going down / up (no repeats) calls
                owner.shift() if it has one. Clicks aren't watched (no Browser jump).
                release() gives it back.

install() is idempotent (a reload swaps the hook); uninstall() takes it out.
"""
import builtins
import ctypes
import ctypes.wintypes as W

from pymxs import runtime as rt

WH_GETMESSAGE = 3
PM_REMOVE = 1
WM_NULL = 0
WM_LBUTTONDOWN, WM_LBUTTONUP, WM_LBUTTONDBLCLK = 0x201, 0x202, 0x203
WM_RBUTTONDOWN, WM_RBUTTONUP, WM_RBUTTONDBLCLK = 0x204, 0x205, 0x206
MK_SHIFT, MK_CONTROL = 0x4, 0x8
VK_SHIFT, VK_CONTROL, VK_MENU, VK_F20 = 0x10, 0x11, 0x12, 0x83
WM_KEYDOWN, WM_KEYUP, WM_SYSKEYDOWN, WM_SYSKEYUP = 0x100, 0x101, 0x104, 0x105
WM_KEYFIRST, WM_KEYLAST = 0x100, 0x109
MODIFIERS = {VK_SHIFT, VK_CONTROL, VK_MENU, 0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0x5B, 0x5C,
             0x14, VK_F20}

CLICK_PX = 6         # Windows px (the guest runs at 2x) — farther is a drag
CLICK_MS = 400
IDLE = {"select", "move", "rotate", "uscale", "nuscale", "squash", "scale"}

_u = ctypes.windll.user32
_k = ctypes.windll.kernel32
HOOKPROC = ctypes.WINFUNCTYPE(ctypes.c_ssize_t, ctypes.c_int, W.WPARAM, W.LPARAM)
_u.SetWindowsHookExW.restype = W.HHOOK
_u.SetWindowsHookExW.argtypes = [ctypes.c_int, HOOKPROC, W.HINSTANCE, W.DWORD]
_u.CallNextHookEx.restype = ctypes.c_ssize_t
_u.CallNextHookEx.argtypes = [W.HHOOK, ctypes.c_int, W.WPARAM, W.LPARAM]
_u.UnhookWindowsHookEx.argtypes = [W.HHOOK]
_u.GetParent.restype = W.HWND
_u.GetParent.argtypes = [W.HWND]
_u.GetKeyboardLayout.restype = W.HKL
_u.GetKeyboardLayout.argtypes = [W.DWORD]
_u.ToUnicodeEx.argtypes = [W.UINT, W.UINT, ctypes.POINTER(ctypes.c_ubyte), W.LPWSTR, ctypes.c_int,
                           W.UINT, W.HKL]

_MS = r"""
global callisPreClick = #()
fn callisSnapSel = ( callisPreClick = selection as array; ok )
fn callisClicked = (       -- what Max's click selected, when it is one new object
    local s = selection as array
    if s.count == 1 and (findItem callisPreClick s[1]) == 0 then s[1] else undefined
)
fn callisRestoreSel = (    -- true when the selection had to be put back
    local a = for n in callisPreClick where isValidNode n collect n
    local same = a.count == selection.count
    if same do for n in a while same do same = n.isSelected
    if not same do ( if a.count == 0 then clearSelection() else select a )
    not same
)
"""

_s = {"panel": 0, "seen": None, "eat": False, "down": None,
       "owner": None, "kseen": None, "keat": False, "ate": set(), "alt": False}


def _panel():
    p = _s["panel"]
    if not p or not _u.IsWindow(W.HWND(p)):
        h = int(rt.viewport.getHWnd())
        p = int(_u.GetParent(W.HWND(h)) or h)
        _s["panel"] = p
    return p


def _over_viewport(hwnd):
    h = int(hwnd or 0)
    if not h:
        return False
    p = _panel()
    return h == p or int(_u.GetParent(W.HWND(h)) or 0) == p


def _screen(m):
    """The message's own point (lParam, client px) on the screen."""
    lp = int(m.lParam or 0)
    x, y = ctypes.c_short(lp & 0xFFFF).value, ctypes.c_short((lp >> 16) & 0xFFFF).value
    p = W.POINT(x, y)
    _u.ClientToScreen(W.HWND(m.hWnd), ctypes.byref(p))
    return p.x, p.y


def _mods(wparam):
    out = []
    if _u.GetKeyState(VK_F20) & 0x8000:
        out.append("space")
    if wparam & MK_SHIFT:
        out.append("shift")
    if _u.GetKeyState(VK_MENU) & 0x8000:
        out.append("alt")
    if wparam & MK_CONTROL:
        out.append("ctrl")
    return out


def _idle():
    try:
        return str(rt.toolMode.commandMode) in IDLE
    except Exception:
        return False


def _later(fn):
    from PySide6.QtCore import QTimer
    QTimer.singleShot(0, fn)


def _nav_up():
    from . import browser
    browser.key("navup")


def _click(x, y, mods):
    from . import nav
    nav._gesture({"op": "click", "x": x, "y": y, "mods": ",".join(mods) or "-"})


def _mouse(m):
    msg = m.message
    # A message can be seen twice (a PM_NOREMOVE peek, then the get): decide and act on
    # the first sighting, then repeat only the decision.
    ident = (msg, m.time, m.pt.x, m.pt.y)
    first = ident != _s["seen"]
    _s["seen"] = ident
    if msg in (WM_RBUTTONDOWN, WM_RBUTTONDBLCLK):
        if first:
            _s["eat"] = not _mods(m.wParam) and _idle()
            if _s["eat"]:
                _later(_nav_up)
        if _s["eat"]:
            m.message = WM_NULL
    elif msg == WM_RBUTTONUP:
        if _s["eat"]:
            m.message = WM_NULL
    elif _s["owner"] is not None:          # a tool has the left click
        return
    elif msg in (WM_LBUTTONDOWN, WM_LBUTTONDBLCLK):
        if first:
            _s["down"] = _screen(m) + (m.time,)
            rt.callisSnapSel()                # before Max has the message: its pick comes after
    elif msg == WM_LBUTTONUP and first and _s["down"]:
        x, y, t = _s["down"]
        _s["down"] = None
        ux, uy = _screen(m)
        dx, dy = ux - x, uy - y
        if dx * dx + dy * dy <= CLICK_PX * CLICK_PX and (m.time - t) & 0xFFFFFFFF <= CLICK_MS:
            mods = _mods(m.wParam)
            _later(lambda: _click(x, y, mods))


def _down(vk):
    return bool(_u.GetKeyState(vk) & 0x8000)


def _char(m, vk):
    """The character the key types, without disturbing dead-key state (flag 4)."""
    state = (ctypes.c_ubyte * 256)()
    if not _u.GetKeyboardState(state):
        return ""
    buf = ctypes.create_unicode_buffer(8)
    scan = (int(m.lParam or 0) >> 16) & 0xFF
    n = _u.ToUnicodeEx(vk, scan, state, buf, 8, 4, _u.GetKeyboardLayout(0))
    return buf.value[:n] if n > 0 else ""


def _key(m):
    owner, msg, vk = _s["owner"], m.message, int(m.wParam or 0) & 0xFFFF
    ident = (msg, m.time, int(m.wParam or 0), int(m.lParam or 0))
    first = ident != _s["kseen"]
    _s["kseen"] = ident
    if first:
        _s["keat"] = False
        if vk in (VK_SHIFT, 0xA0, 0xA1) and hasattr(owner, "shift") and (
                msg in (WM_KEYUP, WM_SYSKEYUP) or not (int(m.lParam or 0) >> 30) & 1):
            _later(owner.shift)                        # Shift (F held) down / up, not repeats
        if msg in (WM_KEYDOWN, WM_SYSKEYDOWN):
            _s["alt"] = vk == VK_MENU and (_s["alt"] or not (int(m.lParam or 0) >> 30) & 1)
            if vk not in MODIFIERS:
                _s["alt"] = False
                ctrl, alt, shift = _down(VK_CONTROL), _down(VK_MENU), _down(VK_SHIFT)
                tok = owner.want(vk, ctrl, alt, shift, "" if ctrl or alt else _char(m, vk))
                if tok is not None:
                    _s["keat"] = True
                    _s["ate"].add(vk)
                    _later(lambda: owner.key(tok))
        elif msg in (WM_KEYUP, WM_SYSKEYUP):
            if vk == VK_MENU and _s["alt"]:            # a clean Alt tap
                _s["alt"] = False
                tok = owner.want(VK_MENU, False, True, False, "")
                if tok is not None:
                    _s["keat"] = True                  # (and no menu bar)
                    _later(lambda: owner.key(tok))
            elif vk in _s["ate"]:
                _s["ate"].discard(vk)
                _s["keat"] = True
        elif msg in (0x102, 0x106) and _s["ate"]:      # WM_CHAR / WM_SYSCHAR of an eaten key
            _s["keat"] = True
    if _s["keat"]:
        m.message = WM_NULL


def claim(owner):
    _s["owner"], _s["ate"], _s["alt"] = owner, set(), False


def release(owner=None):
    if owner is None or _s["owner"] is owner:
        _s["owner"] = None


def _proc(code, wparam, lparam):
    try:
        if code >= 0 and lparam:
            m = ctypes.cast(lparam, ctypes.POINTER(W.MSG)).contents
            if WM_LBUTTONDOWN <= m.message <= WM_RBUTTONDBLCLK and _over_viewport(m.hWnd):
                _mouse(m)
            elif WM_KEYFIRST <= m.message <= WM_KEYLAST and _s["owner"] is not None:
                _key(m)
    except Exception as e:
        print("[callis.rclick]", e)
    return _u.CallNextHookEx(None, code, wparam, lparam)


def install():
    uninstall()
    rt.execute(_MS)
    proc = HOOKPROC(_proc)
    tid = _u.GetWindowThreadProcessId(W.HWND(_panel()), None)
    hook = _u.SetWindowsHookExW(WH_GETMESSAGE, proc, None, tid)
    if not hook:
        print("[callis.rclick] hook not installed, error", _k.GetLastError())
        return False
    builtins._callis_rclick = (hook, proc)        # the proc must outlive this module
    return True


def uninstall():
    old = getattr(builtins, "_callis_rclick", None)
    if old:
        _u.UnhookWindowsHookEx(old[0])
        builtins._callis_rclick = None
