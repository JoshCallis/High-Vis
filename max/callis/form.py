"""Label + control rows under section heads, each bound to get() / set(v).

Shared by the camera / sun panel (props.py) and the Render window's Settings tab
(renderwin.py). The control follows the value: bool → tick, int → whole number,
float → number, `choices` → drop-down. A row whose get() raises or returns anything
else is left out, so one spec can list properties a renderer / camera may not have.

opts: choices [(value, label)], suffix, decimals, step, min, max, tip.

Numbers are read-only until asked: a click only picks the field; F, Enter or Rename
(`edit_focused`, from browser.key) opens it for typing with the number selected; Enter
or leaving the field takes the value, Esc puts the old one back.
"""
from dataclasses import dataclass, field

from PySide6 import QtCore, QtWidgets


class Combo(QtWidgets.QComboBox):
    """A drop-down whose list opens INSIDE its own window. Qt's popup is a separate
    Windows window, which Coherence makes a new Mac window — the panel vanished
    behind it (2026-10-15)."""
    _list = None

    def showPopup(self):
        if self._list is not None:
            return self.hidePopup()
        top = self.window()
        lst = QtWidgets.QListWidget(top)
        lst.setProperty("role", "small")
        lst.setStyleSheet("background:#0b0b0b; border:1px solid #292929; border-radius:4px;")
        for k in range(self.count()):
            lst.addItem(self.itemText(k))
        lst.setCurrentRow(self.currentIndex())
        row = max(lst.sizeHintForRow(0), 20)
        p = self.mapTo(top, QtCore.QPoint(0, self.height()))
        h = min(row * self.count() + 6, max(top.height() - p.y() - 4, row * 3))
        if p.y() + h > top.height():                    # no room below: open above
            p.setY(max(0, p.y() - self.height() - h))
        lst.setGeometry(p.x(), p.y(), self.width(), h)
        lst.itemClicked.connect(lambda it: self._pick(lst.row(it)))
        lst.itemActivated.connect(lambda it: self._pick(lst.row(it)))
        lst.installEventFilter(self)
        self._list = lst
        lst.show()
        lst.raise_()
        lst.setFocus()

    def _pick(self, k):
        self.hidePopup()
        self.setCurrentIndex(k)

    def hidePopup(self):
        lst, self._list = self._list, None
        if lst is not None:
            lst.hide()
            lst.deleteLater()
            self.setFocus()

    def eventFilter(self, obj, e):
        if obj is self._list:
            if e.type() == QtCore.QEvent.KeyPress and e.key() == QtCore.Qt.Key_Escape:
                self.hidePopup()
                return True
            if e.type() == QtCore.QEvent.FocusOut:
                QtCore.QTimer.singleShot(0, self.hidePopup)
        return False


@dataclass
class Field:
    section: str
    label: str
    get: object
    set: object
    opts: dict = field(default_factory=dict)


class Form(QtWidgets.QWidget):
    def __init__(self, fields, parent=None):
        super().__init__(parent)
        self.fields, self.widgets = [], []
        self._loading = False
        grid = QtWidgets.QGridLayout(self)
        grid.setContentsMargins(0, 0, 0, 0)
        grid.setVerticalSpacing(6)
        grid.setHorizontalSpacing(12)
        grid.setColumnStretch(1, 1)
        last, r = None, 0
        for f in fields:
            try:
                v = f.get()
            except Exception:
                continue
            w = self._widget(f, v, len(self.fields))
            if w is None:
                continue
            if f.section != last:
                head = QtWidgets.QLabel(f.section.upper())
                head.setProperty("role", "section")
                grid.addWidget(head, r, 0, 1, 2)
                r, last = r + 1, f.section
            label = QtWidgets.QLabel(f.label)
            if f.opts.get("tip"):
                label.setToolTip(f.opts["tip"])
                w.setToolTip(f.opts["tip"])
            grid.addWidget(label, r, 0)
            grid.addWidget(w, r, 1)
            self.fields.append(f)
            self.widgets.append(w)
            r += 1
        grid.setRowStretch(r, 1)
        self.refresh()

    def _widget(self, f, v, i):
        o = f.opts
        if "choices" in o:
            w = Combo()
            for val, lab in o["choices"]:
                w.addItem(lab, val)
            w.currentIndexChanged.connect(lambda k, i=i: self._edit(i, self.widgets[i].itemData(k)))
        elif isinstance(v, bool):
            w = QtWidgets.QCheckBox()
            w.toggled.connect(lambda x, i=i: self._edit(i, x))
        elif isinstance(v, int):
            w = QtWidgets.QSpinBox()
            w.setRange(int(o.get("min", -10 ** 9)), int(o.get("max", 10 ** 9)))
            w.setSingleStep(int(o.get("step", 1)))
            w.valueChanged.connect(lambda x, i=i: self._edit(i, x))
        elif isinstance(v, float):
            w = QtWidgets.QDoubleSpinBox()
            w.setRange(o.get("min", -1e9), o.get("max", 1e9))
            w.setDecimals(o.get("decimals", 3))
            w.setSingleStep(o.get("step", 0.1))
            w.valueChanged.connect(lambda x, i=i: self._edit(i, x))
        else:
            return None
        if isinstance(w, QtWidgets.QAbstractSpinBox):
            w.setKeyboardTracking(False)
            w.setSuffix(o.get("suffix", ""))
            w.setReadOnly(True)
            w.installEventFilter(self)
            w.lineEdit().installEventFilter(self)
        w.setFocusPolicy(QtCore.Qt.StrongFocus)     # no value change from a passing scroll
        return w

    # ── numbers: pick, then F / Enter / Rename to type ─────────────────────────
    def _spin(self, obj):
        for w in self.widgets:
            if isinstance(w, QtWidgets.QAbstractSpinBox) and (obj is w or obj is w.lineEdit()):
                return w
        return None

    def edit_focused(self):
        """Open the picked number field for typing; False if no number field is picked."""
        w = self._spin(QtWidgets.QApplication.focusWidget())
        if w is None:
            return False
        w.setReadOnly(False)
        w.selectAll()
        return True

    def _stop(self, w, keep):
        if not keep:                                # the typed text, not just the value, goes
            i = self.widgets.index(w)
            self._loading = True
            try:
                v = self.fields[i].get()
                w.lineEdit().setText(w.prefix() + w.textFromValue(v) + w.suffix())
                w.interpretText()
                w.setValue(v)
            except Exception:
                pass
            finally:
                self._loading = False
        else:
            w.interpretText()                       # commits → valueChanged → _edit
        w.setReadOnly(True)
        w.selectAll()

    def eventFilter(self, obj, e):
        w = self._spin(obj)
        if w is None:
            return False
        t = e.type()
        if t == QtCore.QEvent.KeyPress:
            k = e.key()
            if w.isReadOnly():
                if k in (QtCore.Qt.Key_Return, QtCore.Qt.Key_Enter) or \
                        (k == QtCore.Qt.Key_F and not e.modifiers()):
                    self.edit_focused()
                    return True
                return False
            if k in (QtCore.Qt.Key_Return, QtCore.Qt.Key_Enter):
                self._stop(w, True)
                return True
            if k == QtCore.Qt.Key_Escape:           # don't let Esc close the panel
                self._stop(w, False)
                return True
        elif t == QtCore.QEvent.ShortcutOverride and not w.isReadOnly() \
                and e.key() == QtCore.Qt.Key_Escape:
            e.accept()                              # Esc is the field's while typing
            return True
        elif t == QtCore.QEvent.FocusIn and obj is w:
            QtCore.QTimer.singleShot(0, w.selectAll)
        elif t == QtCore.QEvent.FocusOut and obj is w and not w.isReadOnly():
            self._stop(w, True)
        return False

    def refresh(self):
        self._loading = True
        try:
            for f, w in zip(self.fields, self.widgets):
                try:
                    v = f.get()
                except Exception as e:      # object deleted, renderer changed
                    print("[callis] form refresh:", f.label, e)
                    continue
                if isinstance(w, QtWidgets.QComboBox):
                    w.setCurrentIndex(w.findData(v))
                elif isinstance(w, QtWidgets.QCheckBox):
                    w.setChecked(bool(v))
                else:
                    w.setValue(v)
        finally:
            self._loading = False

    def _edit(self, i, v):
        if not self._loading:
            self.fields[i].set(v)
