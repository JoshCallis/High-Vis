"""Plugin (and unused Max) toolbars are never shown — parked off the main window.

    import callis.toolbars as T
    T.install()       # park them now, and any that's added from now on

WHY: the V-Ray / Corona / Scatter toolbars float, so each is its own window, and a
quitting Max shows them all again (expert mode coming off) — they flashed over the
launch/quit veil (2026-10-16, .tmp/showlog.py). A parked toolbar is reparented to a
widget that is never shown: Max can still show() it, but it never gets a window.
Max's main window loses it, so it's not in the saved layout either; the plugin makes
it again at the next start and it's parked again. Their commands stay in Control Room.
"""
from pymxs import runtime as rt

PARK = {
    # plugins
    "V-Ray Toolbar", "Chaos Corona Toolbar", "Corona Power Tools Toolbar",
    "Chaos Scatter Toolbar", "MAXtoAToolbar", "Flow Studio",
    # Max's own, never used here
    "MassFX Toolbar", "Brush Presets", "ProjectsToolbar", "AutobackupToolbar",
    "Axis Constraints", "Layers", "State Sets", "Extras", "Render Shortcuts",
    "Animation Layers", "Containers", "SnapPivotToolbar",
}
_holder = None
_filter = None


def _main():
    import qtmax
    return qtmax.GetQMaxMainWindow()


def park():
    global _holder
    from PySide6 import QtWidgets
    if _holder is None:
        _holder = QtWidgets.QWidget()           # never shown
        _holder.setObjectName("CallisParkedToolbars")
    mw = _main()
    n = 0
    for tb in mw.findChildren(QtWidgets.QToolBar):
        if tb.objectName() in PARK and tb.parent() is not _holder:
            mw.removeToolBar(tb)
            tb.setParent(_holder)
            n += 1
    return n


def install():
    global _filter
    from PySide6 import QtCore
    park()
    if _filter is None:
        class F(QtCore.QObject):
            def eventFilter(self, o, e):
                if e.type() == QtCore.QEvent.ChildAdded:
                    QtCore.QTimer.singleShot(0, park)
                return False
        _filter = F()
        _main().installEventFilter(_filter)
    QtCore.QTimer.singleShot(15000, park)       # plugins that build theirs late
