"""Max's own Scene Explorer / Layer Explorer / Select From Scene never stay open — the Max
Browser (max_browser/, callis/browser.py) is the outliner here.

    import callis.explorer as E
    E.install()       # close any open now, and close any that shows from now on

Explorers are Qt docks on the main window (MaxSDK::QmaxDockWidget, objectName
"Scene Explorer - <name>"), created once and then shown/hidden — so watching each dock's
visibility catches every way one opens: hotkeys, menus, quad menus, a workspace reset,
clean mode turning off. Their hotkeys are also unbound (remap/max_keys.json).
"""
from pymxs import runtime as rt

PREFIXES = ("Scene Explorer", "Layer Explorer", "Select From Scene", "Select from Scene")
_filter = None
QTimer = None


def _is_explorer(w):
    name = w.objectName() or ""
    title = w.windowTitle() or ""
    return any(name.startswith(p) or title.startswith(p) for p in PREFIXES)


def close_all():
    m = rt.SceneExplorerManager
    for i in range(1, int(m.GetExplorerCount()) + 1):
        n = m.GetExplorerName(i)
        if m.ExplorerIsOpen(n):
            m.CloseExplorer(n)
    if m.IsLayerManagerOpen():
        m.CloseLayerManager()


def _close(w):
    try:
        if w.isVisible():
            close_all()
        if w.isVisible():          # not a named explorer (Select From Scene…): just close it
            w.close()
    except Exception as e:        # the widget may already be gone
        print("[callis.explorer]", e)


def _watch(w):
    if w.property("callisWatched"):
        return
    w.setProperty("callisWatched", True)
    w.visibilityChanged.connect(lambda shown, w=w: shown and QTimer.singleShot(0, lambda: _close(w)))
    if w.isVisible():
        QTimer.singleShot(0, lambda: _close(w))


def _scan(main):
    from PySide6.QtWidgets import QDockWidget
    for d in main.findChildren(QDockWidget):
        if _is_explorer(d):
            _watch(d)


def install():
    """Watch the explorer docks themselves (visibilityChanged), and the main window for
    new docks — not an application-wide event filter, which would run Python on every
    Qt event in Max."""
    global _filter, QTimer
    import qtmax
    from PySide6.QtCore import QEvent, QObject, QTimer

    main = qtmax.GetQMaxMainWindow()

    class _Filter(QObject):
        def eventFilter(self, obj, ev):
            if ev.type() == QEvent.ChildAdded:
                QTimer.singleShot(0, lambda: _scan(main))   # named only after construction
            return False

    if _filter is not None:
        main.removeEventFilter(_filter)
    _filter = _Filter()
    main.installEventFilter(_filter)
    _scan(main)
    close_all()
