"""Max's file dialogs (Open File, Save, Merge…) never show the file list's hover tooltip.

Hovering a file in the list for ~0.5 s shows its tooltip (type / size / date). That is a
TOPMOST tooltips_class32 window, so Parallels gives it a new Coherence window, sticky on
every Mac desktop, and the dialog drops out of sight on the Mac — still open (and modal)
in Windows. The Explorer setting ShowInfoTip=0 doesn't reach these old-style dialogs'
list, so the list's own tooltip is switched off whenever one shows.

    import callis.filedlg as F
    F.install()       # idempotent (a reload swaps the hook); F.uninstall() takes it out

A WinEvent hook (EVENT_OBJECT_SHOW, Max's process, out of context → runs on Max's main
thread from whatever pump is running, the dialog's modal loop included) sees the shell's
list ("SysListView32" titled "FolderView") each time one shows — a new dialog or a new
folder — and deactivates its tooltip control (TTM_ACTIVATE false) and its info / label
tips. Every other show event returns at the idObject check.
"""
import builtins
import ctypes
import ctypes.wintypes as W
import os

EVENT_OBJECT_SHOW = 0x8002
WINEVENT_OUTOFCONTEXT = 0
OBJID_WINDOW = 0
LVM_GETTOOLTIPS = 0x104E
LVM_SETEXTENDEDLISTVIEWSTYLE = 0x1036
LVS_EX_INFOTIP, LVS_EX_LABELTIP = 0x400, 0x4000
TTM_ACTIVATE = 0x401

_u = ctypes.windll.user32
WINEVENTPROC = ctypes.WINFUNCTYPE(None, W.HANDLE, W.DWORD, W.HWND, W.LONG, W.LONG, W.DWORD, W.DWORD)
_u.SetWinEventHook.restype = W.HANDLE
_u.SetWinEventHook.argtypes = [W.DWORD, W.DWORD, W.HMODULE, WINEVENTPROC, W.DWORD, W.DWORD, W.DWORD]
_u.UnhookWinEvent.argtypes = [W.HANDLE]
_u.SendMessageTimeoutW.restype = ctypes.c_ssize_t
_u.SendMessageTimeoutW.argtypes = [W.HWND, W.UINT, W.WPARAM, W.LPARAM, W.UINT, W.UINT,
                                   ctypes.POINTER(ctypes.c_size_t)]


def _send(h, m, wp, lp):
    """SendMessage that can't hang Max: the hook sees windows of EVERY thread in Max,
    and a plain send to a stuck one blocks the main thread for good (2026-10-16)."""
    res = ctypes.c_size_t()
    ok = _u.SendMessageTimeoutW(h, m, wp, lp, 0x2, 500, ctypes.byref(res))   # SMTO_ABORTIFHUNG
    return res.value if ok else 0


def _name(fn, h):
    b = ctypes.create_unicode_buffer(32)
    fn(h, b, 32)
    return b.value


def quiet(lv):
    """No hover tooltip on this list view."""
    _send(lv, LVM_SETEXTENDEDLISTVIEWSTYLE, LVS_EX_INFOTIP | LVS_EX_LABELTIP, 0)
    tt = _send(lv, LVM_GETTOOLTIPS, 0, 0)
    if tt:
        _send(tt, TTM_ACTIVATE, 0, 0)


def _proc(hook, event, hwnd, obj, child, thread, t):
    try:
        if obj != OBJID_WINDOW or not hwnd:
            return
        if _name(_u.GetClassNameW, hwnd) == "SysListView32" and _name(_u.InternalGetWindowText, hwnd) == "FolderView":
            quiet(hwnd)
    except Exception as e:
        print("[callis.filedlg]", e)


def install():
    uninstall()
    proc = WINEVENTPROC(_proc)
    hook = _u.SetWinEventHook(EVENT_OBJECT_SHOW, EVENT_OBJECT_SHOW, None, proc,
                              os.getpid(), 0, WINEVENT_OUTOFCONTEXT)
    if not hook:
        print("[callis.filedlg] hook not installed")
        return False
    builtins._callis_filedlg = (hook, proc)       # the proc must outlive this module
    return True


def uninstall():
    old = getattr(builtins, "_callis_filedlg", None)
    if old:
        _u.UnhookWinEvent(old[0])
        builtins._callis_filedlg = None
