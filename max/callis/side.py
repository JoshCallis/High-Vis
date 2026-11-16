"""The Browser's strip: a complex panel (the Shots panel, the Render window) opens IN the
Browser's place down the left of the screen, and the Browser steps aside until it closes.
Settings panels (shot camera / sun, a modifier's settings) are drawn by the Browser page
itself instead (take_page, panel.py): see-through, the Browser's type and keys. One at a time — opening another swaps it in. Closing it —
its command again (each is a toggle), D (BrowserOut, browser.key), Esc — brings the
Browser back.

The Browser is a Mac overlay (../max_browser), so its size comes from the page:
act {"op": "frame"} → .state/browser_frame.json (Mac points); the strip here is the same
fraction of Max's screen (Coherence full screen: the Windows desktop is the Mac screen).
"""
import json
import os

from PySide6 import QtCore, QtGui, QtWidgets

FRAME = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                     ".state", "browser_frame.json")
DEFAULT = {"w": 320, "h": 950, "sw": 1512, "sh": 982}   # 14" MacBook Pro until the page reports
_cur = None
_page = None     # a panel.PagePanel: drawn by the Browser page itself (browser.json `panel`)


def set_frame(a):
    """The Browser page's size (op "frame"): its window and the Mac screen, in points."""
    f = {k: float(a[k]) for k in ("w", "h", "sw", "sh") if a.get(k)}
    if len(f) == 4 and f != _frame():
        try:
            with open(FRAME, "w") as fh:
                json.dump(f, fh)
        except OSError:
            pass
        if _cur is not None:
            _place(_cur)


def _frame():
    try:
        with open(FRAME) as fh:
            return json.load(fh)
    except (OSError, ValueError):
        return dict(DEFAULT)


def strip():
    """The Browser's rect on Max's screen, in Qt coordinates."""
    f = _frame()
    g = QtGui.QGuiApplication.primaryScreen().geometry()
    top = round(g.height() * (f["sh"] - f["h"]) / f["sh"])
    return QtCore.QRect(g.left(), g.top() + top, round(g.width() * f["w"] / f["sw"]), g.height() - top)


def _place(w):
    r = strip()
    w.setMinimumSize(0, 0)
    w.setGeometry(r)


def current():
    return _cur


def title():
    """A Qt panel's title while it has the Browser's place (the page draws nothing)."""
    return _cur.windowTitle() if _cur is not None else None


def page():
    """The page-drawn panel, if one is up (gone with its object → closed)."""
    global _page
    if _page is not None and not _page.alive():
        _page.closed()
        _page = None
    return _page


def take_page(p):
    """Put a panel.PagePanel in the Browser's place: the page draws it, no Qt window."""
    global _cur, _page
    if _cur is not None:
        old, _cur = _cur, None
        old.close()
    if _page is not None:
        _page.closed()
    _page = p
    _browser()


class _Watch(QtCore.QObject):
    """Notices the strip's panel closing or hiding, whatever closed it; a plain D typed
    where no field takes it closes it too (the BrowserOut hotkey does when Max's
    accelerators see the key first)."""

    def eventFilter(self, obj, e):
        t = e.type()
        if obj is _cur and t in (QtCore.QEvent.Close, QtCore.QEvent.Hide):
            QtCore.QTimer.singleShot(0, lambda o=obj: _gone(o))
        elif obj is _cur and t == QtCore.QEvent.KeyPress and e.key() == QtCore.Qt.Key_D \
                and not e.modifiers() and not isinstance(QtWidgets.QApplication.focusWidget(),
                                                         QtWidgets.QLineEdit):
            close()
            return True
        return False


_watch = _Watch()


def take(w):
    """Show `w` in the Browser's strip (frameless), the Browser stepping aside."""
    global _cur, _page
    if _cur is not None and _cur is not w:
        old, _cur = _cur, None
        old.close()
    if _page is not None:
        _page.closed()
        _page = None
    _cur = w
    if isinstance(w, QtWidgets.QDockWidget):       # the Shots panel: float it, no title bar
        if w.titleBarWidget() is None:
            w.setTitleBarWidget(QtWidgets.QWidget())
        w.setFloating(True)
    else:
        w.setWindowFlags(QtCore.Qt.Tool | QtCore.Qt.FramelessWindowHint)
    w.installEventFilter(_watch)
    _place(w)
    w.show()
    w.raise_()
    w.activateWindow()
    _browser()


def _gone(w):
    global _cur
    if _cur is w and not w.isVisible():
        _cur = None
        _browser()


def close():
    """Close the strip's panel; False if there was none (D then goes to the Browser)."""
    global _cur, _page
    w, _cur = _cur, None
    p, _page = _page, None
    if w is None and p is None:
        return False
    if p is not None:
        p.closed()
    if w is not None:
        w.close()
    _browser()
    return True


def edit():
    """Rename: open the picked number field in the panel for typing (form.Form);
    False if none is picked (Rename then goes to the Browser)."""
    from . import form
    if _page is not None:
        return _page.key("rename")
    if _cur is None or not _cur.isVisible():
        return False
    return any(f.edit_focused() for f in _cur.findChildren(form.Form))


def toggle(w, make):
    """A panel command: `w` (the open one, or None) in the strip → close it; else open
    `make()` there."""
    if w is not None and w is _cur and w.isVisible():
        close()
        return None
    w = make()
    take(w)
    return w


def _browser():
    from . import browser
    browser.publish()
