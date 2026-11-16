"""Shots panel — a dockable Qt window in 3ds Max.

    import callis.ui; callis.ui.show()

Shots tab: one card per shot (thumbnail, size, camera); clicking a card switches the
scene to that shot (scene.apply_view — per-shot poses, camera, size, only-in-shot
objects). The details below edit the current shot.
Mattes tab: which layers give mattes (every layer + material by default; Exclude, Glass).
Footer (always visible): log + "Render…", which opens the Render window (renderwin.py:
output folder, resolutions, Photoshop options, render settings).
Every edit saves straight into the scene (callis.project.save). Look: callis/style.py.

Module helpers for hotkeys/callbacks: step(±1), per_shot_selected(), on_undo().
"""
import os
import tempfile

import qtmax
from PySide6 import QtCore, QtGui, QtWidgets
from pymxs import runtime as rt

from . import project as P
from . import render as R
from . import scene as S
from . import form, style

SIZE_PRESETS = [("HD 1920 × 1080", 1920, 1080), ("QHD 2560 × 1440", 2560, 1440),
                ("4K 3840 × 2160", 3840, 2160), ("Square 2000 × 2000", 2000, 2000),
                ("A-landscape 3508 × 2480", 3508, 2480), ("A-portrait 2480 × 3508", 2480, 3508)]
ASPECTS = [(16 / 9, "16:9"), (9 / 16, "9:16"), (4 / 3, "4:3"), (3 / 4, "3:4"), (3 / 2, "3:2"),
           (2 / 3, "2:3"), (1.0, "1:1"), (2.39, "2.39:1"), (2 ** 0.5, "A landscape"),
           (2 ** -0.5, "A portrait"), (21 / 9, "21:9"), (5 / 4, "5:4"), (4 / 5, "4:5")]
ID = QtCore.Qt.UserRole

_panel = None


def show():
    """The Shots panel, in the Browser's strip (side.py); the command again (or D) closes it."""
    global _panel
    from . import side
    if _panel is None:
        _panel = ShotsPanel(qtmax.GetQMaxMainWindow())
        qtmax.GetQMaxMainWindow().addDockWidget(QtCore.Qt.RightDockWidgetArea, _panel)
    elif side.current() is _panel and _panel.isVisible():
        side.close()
        return _panel
    _panel.reload()
    side.take(_panel)
    QtCore.QTimer.singleShot(0, _panel._size_split)     # sizes are known once it's shown
    return _panel


def project():
    """The live project: the panel's copy if it's open (it may hold unsaved state),
    else the scene's."""
    return _panel.project if _panel is not None else P.load()


def step(delta):
    """Next / previous shot (hotkeys)."""
    p = project()
    if not p.views:
        return
    ids = [v.id for v in p.views]
    i = ids.index(p.active) if p.active in ids else -delta
    view = p.views[(i + delta) % len(p.views)]
    _go(p, view)


def _go(p, view):
    """Switch shots without leaving perspective: only a camera view follows the shot's camera."""
    look = str(rt.viewport.getType()) == "view_camera"
    if _panel is not None:
        _panel.go(view, look)
    else:
        S.apply_view(p, view, look)
    from . import hud
    hud.show(view.name)


def goto(n):
    """Shot number n (1-based, panel order); nothing if there are fewer."""
    p = project()
    if 1 <= n <= len(p.views):
        _go(p, p.views[n - 1])


def per_shot_selected():
    p = project()
    S.make_per_shot(p, list(rt.selection))
    P.save(p)
    if _panel is not None:
        _panel.refresh()


def on_undo():
    """sceneUndo / sceneRedo: a shot switch or Convert is undoable, project and all."""
    if _panel is not None and P.saved_json() != _panel.project.to_json():
        _panel.reload()


def _aspect(w, h):
    r = w / h if h else 1
    for val, label in ASPECTS:
        if abs(r - val) < 0.006:
            return label
    return f"{r:.2f}:1"


# ── Thumbnails ──────────────────────────────────────────────────────────────
# Grabbed from the viewport (cropped to the shot's aspect, i.e. its safe frame) when
# you leave a shot or arrive at one that has none. Kept per scene in LOCALAPPDATA,
# not in the .max.

def _thumb_dir():
    scene = os.path.splitext(str(rt.maxFileName))[0] or "Untitled"
    base = os.environ.get("LOCALAPPDATA") or tempfile.gettempdir()
    d = os.path.join(base, "Callis", "thumbs", R._safe(scene))
    os.makedirs(d, exist_ok=True)
    return d


def thumb_path(view):
    return os.path.join(_thumb_dir(), view.id + ".png")


def grab_thumb(view):
    """The active viewport, as last drawn → this shot's thumbnail. Only when the
    viewport is looking through the shot's camera. No redraw of its own: one costs
    seconds in a software viewport, and apply_view has just drawn it. Hence a screen
    grab of the viewport's window (~70 ms) — gw.getViewportDib redraws first (2–3 s
    in the VM)."""
    cam = S.node(view.camera)
    if cam is None or rt.getActiveCamera() != cam:
        return False
    img = QtWidgets.QApplication.primaryScreen().grabWindow(int(rt.viewport.getHWnd())).toImage()
    if img.isNull() or img.width() < 8:
        return False
    iw, ih = img.width(), img.height()
    want = view.width / view.height if view.height else 1
    if iw / ih > want:
        cw, ch = round(ih * want), ih
    else:
        cw, ch = iw, round(iw / want)
    pad = 2      # the safe-frame line sits on the crop edge
    img = img.copy((iw - cw) // 2 + pad, (ih - ch) // 2 + pad, cw - 2 * pad, ch - 2 * pad)
    img.scaledToHeight(112, QtCore.Qt.SmoothTransformation).save(thumb_path(view))
    return True


# ── Shot cards ──────────────────────────────────────────────────────────────

class ShotDelegate(QtWidgets.QStyledItemDelegate):
    H = 72
    THUMB = QtCore.QSize(88, 56)

    def __init__(self, panel):
        super().__init__(panel)
        self.panel = panel
        self._pix = {}       # view id → (mtime, QPixmap)

    def _view(self, index):
        return self.panel.project.view(index.data(ID))

    def _rects(self, rect):
        r = rect.adjusted(6, 2, -6, -2)
        thumb = QtCore.QRect(r.left() + 10, r.center().y() - self.THUMB.height() // 2 + 1, self.THUMB.width(), self.THUMB.height())
        tick = QtCore.QRect(r.right() - 24, r.center().y() - 7, 14, 14)
        text = QtCore.QRect(thumb.right() + 12, r.top() + 8, tick.left() - thumb.right() - 20, r.height() - 16)
        return r, thumb, tick, text

    def pixmap(self, view):
        path = thumb_path(view)
        try:
            mt = os.path.getmtime(path)
        except OSError:
            return None
        cached = self._pix.get(view.id)
        if cached is None or cached[0] != mt:
            cached = (mt, QtGui.QPixmap(path))
            self._pix[view.id] = cached
        return cached[1]

    def sizeHint(self, option, index):
        return QtCore.QSize(200, self.H)

    def paint(self, p, option, index):
        view = self._view(index)
        if view is None:
            return
        active = view.id == self.panel.project.active
        hover = bool(option.state & QtWidgets.QStyle.State_MouseOver)
        r, thumb, tick, text = self._rects(option.rect)
        p.save()
        p.setRenderHint(QtGui.QPainter.Antialiasing)
        p.setPen(QtCore.Qt.NoPen)
        if active or hover:
            p.setBrush(QtGui.QColor(*style.RGBA["sel" if active else "hover"]))
            p.drawRoundedRect(r, 6, 6)
        if active:
            p.setBrush(QtGui.QColor(style.C["accent"]))
            p.drawRoundedRect(QtCore.QRect(r.left(), r.top() + 10, 3, r.height() - 20), 1.5, 1.5)

        # Thumbnail, letterboxed to the shot's aspect inside the slot.
        a = view.width / view.height if view.height else 1
        tw, th = thumb.width(), thumb.height()
        if tw / th > a:
            tw = round(th * a)
        else:
            th = round(tw / a)
        tr = QtCore.QRect(thumb.center().x() - tw // 2 + 1, thumb.center().y() - th // 2 + 1, tw, th)
        p.setBrush(QtGui.QColor(*style.RGBA["thumb_bg"]))
        p.drawRoundedRect(tr, 3, 3)
        pm = self.pixmap(view)
        if pm is not None and not pm.isNull():
            path = QtGui.QPainterPath()
            path.addRoundedRect(QtCore.QRectF(tr), 3, 3)
            p.setClipPath(path)
            p.drawPixmap(tr, pm)
            p.setClipping(False)
        p.setPen(QtGui.QPen(QtGui.QColor(*style.RGBA["sep"]), 1))
        p.setBrush(QtCore.Qt.NoBrush)
        p.drawRoundedRect(QtCore.QRectF(tr).adjusted(0.5, 0.5, -0.5, -0.5), 3, 3)
        p.setPen(QtCore.Qt.NoPen)

        # Text: name, size · aspect, camera · per-shot counts.
        f = QtGui.QFont(style.FONT)
        f.setPixelSize(13)
        f.setWeight(QtGui.QFont.DemiBold if active else QtGui.QFont.Normal)
        p.setFont(f)
        p.setPen(QtGui.QColor(style.C["bright"] if active else "#c4c4c4"))
        fm = QtGui.QFontMetrics(f)
        p.drawText(QtCore.QRect(text.left(), text.top(), text.width(), 18), QtCore.Qt.AlignLeft | QtCore.Qt.AlignVCenter,
                   fm.elidedText(view.name, QtCore.Qt.ElideRight, text.width()))
        f.setPixelSize(11)
        f.setWeight(QtGui.QFont.Normal)
        p.setFont(f)
        fm = QtGui.QFontMetrics(f)
        p.setPen(QtGui.QColor(style.C["text"]))
        line2 = f"{view.width} × {view.height}  ·  {_aspect(view.width, view.height)}"
        p.drawText(QtCore.QRect(text.left(), text.top() + 20, text.width(), 15), QtCore.Qt.AlignLeft | QtCore.Qt.AlignVCenter,
                   fm.elidedText(line2, QtCore.Qt.ElideRight, text.width()))
        cam = S.node(view.camera)
        bits = [str(cam.name) if cam is not None else "no camera"]
        if view.frame is not None:
            bits.append(f"frame {view.frame}")
        if view.only_objects:
            bits.append(f"{len(view.only_objects)} only here")
        p.setPen(QtGui.QColor(style.C["dim"] if cam is not None else style.C["warn"]))
        p.drawText(QtCore.QRect(text.left(), text.top() + 36, text.width(), 15), QtCore.Qt.AlignLeft | QtCore.Qt.AlignVCenter,
                   fm.elidedText("  ·  ".join(bits), QtCore.Qt.ElideRight, text.width()))

        # Render tick.
        if view.render:
            p.setBrush(QtGui.QColor(style.C["accent"]))
            p.drawRoundedRect(tick, 3, 3)
            pen = QtGui.QPen(QtGui.QColor("#000"), 1.8)
            p.setPen(pen)
            p.drawPolyline(QtGui.QPolygonF([QtCore.QPointF(tick.left() + 3.5, tick.center().y() + 0.5),
                                            QtCore.QPointF(tick.left() + 6, tick.bottom() - 3.5),
                                            QtCore.QPointF(tick.right() - 3, tick.top() + 3.5)]))
        else:
            p.setPen(QtGui.QPen(QtGui.QColor(style.C["dim"]), 1.2))
            p.setBrush(QtCore.Qt.NoBrush)
            p.drawRoundedRect(QtCore.QRectF(tick).adjusted(0.5, 0.5, -0.5, -0.5), 3, 3)
        p.restore()

    def editorEvent(self, event, model, option, index):
        """The render tick toggles without switching shots."""
        if event.type() in (QtCore.QEvent.MouseButtonPress, QtCore.QEvent.MouseButtonRelease,
                            QtCore.QEvent.MouseButtonDblClick):
            _, _, tick, _ = self._rects(option.rect)
            if tick.adjusted(-6, -6, 6, 6).contains(event.position().toPoint()):
                if event.type() == QtCore.QEvent.MouseButtonRelease:
                    view = self._view(index)
                    view.render = not view.render
                    self.panel.save()
                    self.panel.update_render_button()
                return True
        return super().editorEvent(event, model, option, index)

    def helpEvent(self, event, view, option, index):
        _, _, tick, _ = self._rects(option.rect)
        if tick.adjusted(-6, -6, 6, 6).contains(event.pos()):
            QtWidgets.QToolTip.showText(event.globalPos(), "Include in the next render", view)
            return True
        return super().helpEvent(event, view, option, index)

    # Rename in place (double-click / F2).
    def createEditor(self, parent, option, index):
        e = QtWidgets.QLineEdit(parent)
        e.setStyleSheet(f"background:{style.C['focus']}; color:{style.C['bright']}; border:none; "
                        f"border-radius:3px; padding:0 4px; font-size:13px;")
        return e

    def updateEditorGeometry(self, editor, option, index):
        _, _, _, text = self._rects(option.rect)
        editor.setGeometry(text.left() - 4, text.top() - 1, text.width() + 4, 20)

    def setEditorData(self, editor, index):
        editor.setText(index.data(QtCore.Qt.DisplayRole))
        editor.selectAll()

    def setModelData(self, editor, model, index):
        name = editor.text().strip()
        view = self._view(index)
        if name and view is not None:
            view.name = name
            model.setData(index, name, QtCore.Qt.DisplayRole)
            self.panel.save()


class ShotList(QtWidgets.QListWidget):
    def __init__(self, panel):
        super().__init__()
        self.panel = panel
        self.setItemDelegate(ShotDelegate(panel))
        self.setMouseTracking(True)
        self.setVerticalScrollMode(QtWidgets.QAbstractItemView.ScrollPerPixel)
        self.setDragDropMode(QtWidgets.QAbstractItemView.InternalMove)
        self.setDefaultDropAction(QtCore.Qt.MoveAction)
        self.setEditTriggers(QtWidgets.QAbstractItemView.DoubleClicked | QtWidgets.QAbstractItemView.EditKeyPressed)
        self.setContextMenuPolicy(QtCore.Qt.CustomContextMenu)
        self.setFocusPolicy(QtCore.Qt.StrongFocus)

    def dropEvent(self, event):
        super().dropEvent(event)
        self.panel.reordered()


def _button(text, tip, slot, role=None):
    b = QtWidgets.QPushButton(text)
    b.setToolTip(tip)
    b.clicked.connect(slot)
    b.setCursor(QtCore.Qt.PointingHandCursor)
    if role:
        b.setProperty("role", role)
    return b


def _label(text, role):
    l = QtWidgets.QLabel(text)
    l.setProperty("role", role)
    return l


def _row(*widgets, stretch=True):
    h = QtWidgets.QHBoxLayout()
    h.setContentsMargins(0, 0, 0, 0)
    h.setSpacing(6)
    for w in widgets:
        h.addWidget(w) if isinstance(w, QtWidgets.QWidget) else h.addLayout(w)
    if stretch:
        h.addStretch(1)
    return h


class ShotsPanel(QtWidgets.QDockWidget):
    def __init__(self, parent):
        super().__init__("Shots", parent)
        self.setObjectName("CallisRenderProject")   # "Callis…" docks stay up in clean mode
        self.project = P.Project()
        self._loading = False

        root = QtWidgets.QWidget()
        root.setObjectName("callisRoot")
        root.setStyleSheet(style.QSS)
        lay = QtWidgets.QVBoxLayout(root)
        lay.setContentsMargins(0, 0, 0, 0)
        lay.setSpacing(0)

        # Header
        head = QtWidgets.QWidget()
        hl = QtWidgets.QHBoxLayout(head)
        hl.setContentsMargins(14, 12, 10, 4)
        hl.addWidget(_label("Shots", "title"))
        self.count = _label("", "hint")
        hl.addWidget(self.count)
        hl.addStretch(1)
        hl.addWidget(_button("+  New shot", "New shot from the active viewport — everything as it is now",
                             self._add_from_viewport))
        more = QtWidgets.QToolButton()
        more.setText("▾")
        more.setProperty("role", "more")
        more.setToolTip("More ways to add shots")
        more.setPopupMode(QtWidgets.QToolButton.InstantPopup)
        more.setCursor(QtCore.Qt.PointingHandCursor)
        m = self._menu()
        m.addAction("New shot from the active viewport", self._add_from_viewport)
        m.addAction("One shot per selected camera", self._add_selected)
        more.setMenu(m)
        hl.addWidget(more)
        lay.addWidget(head)

        # Banner: old setups
        self.banner = QtWidgets.QFrame()
        self.banner.setProperty("role", "banner")
        bl = QtWidgets.QVBoxLayout(self.banner)
        bl.setContentsMargins(12, 10, 12, 10)
        self.banner_text = QtWidgets.QLabel()
        self.banner_text.setWordWrap(True)
        bl.addWidget(self.banner_text)
        self.import_btn = _button("Import old setup", "Read the Output Path / Frame Names / Frame Sizes "
                                  "dummies into shots", self._import_legacy)
        self.convert_btn = _button("Convert frames to shots", "Objects keyed per shot frame become per-shot "
                                   "objects and lose those keys; cameras are baked per shot. Real animation "
                                   "is left alone. One undo step.", self._convert, role="primary")
        bl.addLayout(_row(self.import_btn, self.convert_btn))
        wrap = QtWidgets.QWidget()
        wl = QtWidgets.QVBoxLayout(wrap)
        wl.setContentsMargins(10, 4, 10, 6)
        wl.addWidget(self.banner)
        self.banner_wrap = wrap
        lay.addWidget(wrap)

        tabs = QtWidgets.QTabWidget()
        tabs.tabBar().setDrawBase(False)
        tabs.addTab(self._shots_tab(), "Shots")
        tabs.addTab(self._mattes_tab(), "Mattes")
        lay.addWidget(tabs, 1)
        lay.addWidget(self._footer())
        self.setWidget(root)

    def _menu(self):
        m = QtWidgets.QMenu(self)
        m.setObjectName("callisMenu")
        m.setStyleSheet(style.QSS)
        return m

    # ── Shots tab ───────────────────────────────────────────────────────────

    def _shots_tab(self):
        split = QtWidgets.QSplitter(QtCore.Qt.Vertical)
        split.setChildrenCollapsible(False)
        self.list = ShotList(self)
        self.list.currentRowChanged.connect(self._row_changed)
        self.list.itemClicked.connect(self._clicked)
        self.list.customContextMenuRequested.connect(self._context_menu)
        self.empty = _label("No shots yet.\nFrame a view, then + New shot.", "hint")
        self.empty.setAlignment(QtCore.Qt.AlignCenter)
        top = QtWidgets.QStackedWidget()
        top.addWidget(self.list)
        top.addWidget(self.empty)
        self.list_stack = top
        split.addWidget(top)

        scroll = QtWidgets.QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setFrameShape(QtWidgets.QFrame.NoFrame)
        scroll.setHorizontalScrollBarPolicy(QtCore.Qt.ScrollBarAlwaysOff)
        self.details = QtWidgets.QWidget()
        self.details.setObjectName("callisDetails")
        d = QtWidgets.QVBoxLayout(self.details)
        d.setContentsMargins(16, 4, 14, 12)
        d.setSpacing(6)

        # Camera
        d.addWidget(_label("CAMERA", "section"))
        self.cam_combo = form.Combo()
        self.cam_combo.activated.connect(self._camera_changed)
        self.cam_combo.setSizeAdjustPolicy(QtWidgets.QComboBox.AdjustToMinimumContentsLengthWithIcon)
        self.cam_combo.setMinimumContentsLength(8)
        self.cam_combo.setSizePolicy(QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Fixed)
        d.addLayout(_row(self.cam_combo, _button("Select", "Select the camera", self._select_camera), stretch=False))

        # Size
        d.addWidget(_label("SIZE", "section"))
        self.w_spin = QtWidgets.QSpinBox(); self.w_spin.setRange(16, 32000)
        self.h_spin = QtWidgets.QSpinBox(); self.h_spin.setRange(16, 32000)
        for s in (self.w_spin, self.h_spin):
            s.setButtonSymbols(QtWidgets.QAbstractSpinBox.NoButtons)
            s.setAlignment(QtCore.Qt.AlignCenter)
            s.setFixedWidth(64)
            s.setKeyboardTracking(False)
        self.w_spin.valueChanged.connect(lambda val: self._size_changed("w", val))
        self.h_spin.valueChanged.connect(lambda val: self._size_changed("h", val))
        self.lock = QtWidgets.QToolButton()
        self.lock.setText("Lock aspect")
        self.lock.setCheckable(True)
        self.lock.setProperty("role", "lock")
        self.aspect = _label("", "hint")
        self.preset = form.Combo()
        self.preset.addItem("Presets")
        for label, *_ in SIZE_PRESETS:
            self.preset.addItem(label)
        self.preset.activated.connect(self._preset)
        x = _label("×", "hint")
        d.addLayout(_row(self.w_spin, x, self.h_spin, self.aspect))
        d.addLayout(_row(self.preset, self.lock))

        # Per-shot objects
        d.addWidget(_label("PER-SHOT OBJECTS", "section"))
        self.pose_hint = _label("", "hint")
        self.pose_hint.setWordWrap(True)
        d.addWidget(self.pose_hint)
        self.pose_list = self._small_list()
        d.addWidget(self.pose_list)
        d.addLayout(_row(_button("Add selected", "The selected objects can sit differently in each shot "
                                 "(every shot starts from where they are now)", self._make_per_shot),
                         _button("Same everywhere", "Back to one position for every shot — where it is now "
                                 "(the list's selection, else the scene's)", self._share),
                         _button("Select", "Select these in the scene", self._select_per_shot)))

        # Only in this shot
        d.addWidget(_label("ONLY IN THIS SHOT", "section"))
        self.only_hint = _label("", "hint")
        self.only_hint.setWordWrap(True)
        d.addWidget(self.only_hint)
        self.only_list = self._small_list()
        d.addWidget(self.only_list)
        d.addLayout(_row(_button("Add selected", "Selected objects appear only in this shot", self._only_add),
                         _button("Remove", "Back to appearing in every shot", self._only_remove),
                         _button("Select", "Select these in the scene", self._only_select)))

        # Region
        d.addWidget(_label("REGION", "section"))
        self.region_label = _label("", "value")
        self.region_label.setToolTip("The part of the frame \"Region only\" re-renders — kept as a fraction "
                                     "of the frame, so it fits every resolution")
        d.addWidget(self.region_label)
        d.addLayout(_row(_button("Edit in viewport", "Switch to this shot with Max's region frame showing — "
                                 "drag its handles, then press Use viewport", self._region_edit),
                         _button("Use viewport", "Take the region from the active viewport's region frame",
                                 self._region_take),
                         _button("Clear", "No region for this shot", self._region_clear)))
        d.addStretch(1)
        scroll.setWidget(self.details)
        split.addWidget(scroll)
        split.setStretchFactor(0, 0)
        split.setStretchFactor(1, 1)
        self.split = split
        return split

    def _size_split(self):
        """The shot list as tall as its cards, up to 60% — the details get the rest."""
        total = sum(self.split.sizes())
        if total > 0:
            want = max(ShotDelegate.H + 12, len(self.project.views) * ShotDelegate.H + 12)
            top = min(want, int(total * 0.6))
            self.split.setSizes([top, total - top])

    def _small_list(self):
        l = QtWidgets.QListWidget()
        l.setProperty("role", "small")
        l.setSelectionMode(QtWidgets.QAbstractItemView.ExtendedSelection)
        l.setHorizontalScrollBarPolicy(QtCore.Qt.ScrollBarAlwaysOff)
        l.setToolTip("Double-click to select in the scene")
        l.itemDoubleClicked.connect(lambda it: self._select_handles([it.data(ID)]))
        return l

    @staticmethod
    def _fit(l, hint, empty, filled):
        """Small lists take the height of their rows (up to 6), and hide when empty."""
        n = l.count()
        l.setVisible(n > 0)
        rh = l.sizeHintForRow(0) if n else 22
        l.setFixedHeight(min(n, 6) * rh + 2 * l.frameWidth() + 2)
        hint.setText(filled if n else empty)

    # ── Mattes tab ──────────────────────────────────────────────────────────

    def _mattes_tab(self):
        w = QtWidgets.QWidget()
        v = QtWidgets.QVBoxLayout(w)
        v.setContentsMargins(14, 10, 14, 10)
        hint = _label("Every layer and every visible material becomes a matte in Photoshop "
                      "(from Cryptomatte — no extra render cost). Exclude layers you never "
                      "want selections for; a layer follows the one above unless set.", "hint")
        hint.setWordWrap(True)
        v.addWidget(hint)
        self.matte_table = QtWidgets.QTableWidget(0, 2)
        self.matte_table.setHorizontalHeaderLabels(["LAYER", "MATTES"])
        self.matte_table.verticalHeader().hide()
        self.matte_table.setShowGrid(False)
        self.matte_table.setSelectionMode(QtWidgets.QAbstractItemView.NoSelection)
        self.matte_table.horizontalHeader().setDefaultAlignment(QtCore.Qt.AlignLeft)
        self.matte_table.horizontalHeader().setSectionResizeMode(0, QtWidgets.QHeaderView.Stretch)
        self.matte_table.horizontalHeader().setSectionResizeMode(1, QtWidgets.QHeaderView.ResizeToContents)
        v.addWidget(self.matte_table, 1)
        v.addLayout(_row(_button("Refresh layers", "Re-read the scene's layers", self._fill_mattes),
                         _button("Remove L/M/B/N layers", "Old scenes: move their objects up to the "
                                 "real layer and delete the sublayers (one undo step)",
                                 self._flatten_lmbn)))
        return w

    # ── Footer: log + the Render window ─────────────────────────────────────
    # Output, resolutions, Photoshop options and render settings live in the Render
    # window (renderwin.py) — one place for everything about rendering.

    def _footer(self):
        box = QtWidgets.QFrame()
        box.setProperty("role", "footer")
        v = QtWidgets.QVBoxLayout(box)
        v.setContentsMargins(14, 10, 14, 12)
        v.setSpacing(8)
        self.log = QtWidgets.QPlainTextEdit()
        self.log.setReadOnly(True)
        self.log.setMaximumHeight(64)
        self.log.setPlaceholderText("Log")
        v.addWidget(self.log)
        self.render_btn = _button("Render…", "Output, resolutions, Photoshop file and render settings",
                                  self._render, role="primary")
        v.addWidget(self.render_btn)
        return box

    # ── Load / save ─────────────────────────────────────────────────────────

    def reload(self):
        self.project = P.load()
        self.refresh()
        self._fill_mattes()

    def refresh(self):
        """Redraw everything from self.project without touching the scene."""
        self._fill_shots()
        self._fill_details()
        self._update_banner()
        self.update_render_button()

    def save(self):
        if not self._loading:
            P.save(self.project)

    def _say(self, text):
        self.log.appendPlainText(text)
        QtWidgets.QApplication.processEvents()

    def _update_banner(self):
        legacy = P.legacy_present() and not self.project.views
        frames = bool(self.project.frame_based())
        self.import_btn.setVisible(legacy)
        self.convert_btn.setVisible(frames)
        if legacy:
            self.banner_text.setText("This scene uses the old dummy-object setup. Import it, then convert "
                                     "its frames to shots.")
        elif frames:
            self.banner_text.setText("These shots still use one keyed frame each. Convert them: per-shot "
                                     "objects keep their positions with no keys, and the timeline is free "
                                     "for animation and motion blur.")
        self.banner_wrap.setVisible(legacy or frames)

    def update_render_button(self, sync=True):
        n = sum(1 for v in self.project.views if v.render)
        what = "regions" if self.project.region else ("shot" if n == 1 else "shots")
        self.render_btn.setText(f"Render {n} {what}…" if n else "Render…")
        if sync:
            from . import renderwin
            renderwin.sync()

    # ── Shot list ───────────────────────────────────────────────────────────

    def _fill_shots(self):
        self._loading = True
        self.list.clear()
        active_row = -1
        for i, view in enumerate(self.project.views):
            it = QtWidgets.QListWidgetItem(view.name)
            it.setData(ID, view.id)
            it.setFlags(it.flags() | QtCore.Qt.ItemIsEditable | QtCore.Qt.ItemIsDragEnabled)
            self.list.addItem(it)
            if view.id == self.project.active:
                active_row = i
        if active_row < 0 and self.project.views:
            active_row = 0
        self.list.setCurrentRow(active_row)
        self._loading = False
        n = len(self.project.views)
        self.count.setText(f"{n}" if n else "")
        self.list_stack.setCurrentIndex(0 if n else 1)
        self.details.setEnabled(bool(n))
        self._size_split()

    def _view(self):
        r = self.list.currentRow()
        return self.project.views[r] if 0 <= r < len(self.project.views) else None

    def _row_changed(self, row):
        if self._loading or not 0 <= row < len(self.project.views):
            return
        self.go(self.project.views[row])

    def _clicked(self, item):
        """The current row clicked again while another shot is live (after a delete,
        an undo…) — currentRowChanged won't fire for it."""
        view = self.project.view(item.data(ID))
        if view is not None and view.id != self.project.active:
            self.go(view)

    def go(self, view, look=True):
        """Switch the scene to `view`, with thumbnails for the shot left and the one reached."""
        prev = self.project.view(self.project.active)
        if look and prev is not None and prev is not view:
            try:
                grab_thumb(prev)
            except Exception as e:
                print("[callis] thumbnail:", e)
        S.apply_view(self.project, view, look)
        if look and not os.path.exists(thumb_path(view)):
            self._grab(view)
        self._loading = True
        self.list.setCurrentRow(self.project.views.index(view))
        self._loading = False
        self.list.viewport().update()
        self._fill_details()

    def _grab(self, view):
        try:
            if grab_thumb(view):
                self.list.viewport().update()
        except Exception as e:
            print("[callis] thumbnail:", e)

    def reordered(self):
        ids = [self.list.item(i).data(ID) for i in range(self.list.count())]
        by_id = {v.id: v for v in self.project.views}
        self.project.views = [by_id[i] for i in ids if i in by_id]
        self.save()

    def _context_menu(self, pos):
        it = self.list.itemAt(pos)
        if it is None:
            return
        view = self.project.view(it.data(ID))
        m = self._menu()
        m.addAction("Rename", lambda: self.list.editItem(it))
        m.addAction("Duplicate", lambda: self._duplicate(view))
        m.addAction("Update thumbnail", lambda: self._update_thumb(view))
        m.addSeparator()
        m.addAction("Delete", lambda: self._delete(view))
        m.exec(self.list.viewport().mapToGlobal(pos))

    def _update_thumb(self, view):
        if view.id != self.project.active:
            self.go(view)
        rt.completeRedraw()
        if not grab_thumb(view):
            self._say("Look through the shot's camera to grab its thumbnail.")
        self.list.viewport().update()

    # ── Details ─────────────────────────────────────────────────────────────

    def _fill_details(self):
        view = self._view()
        self._loading = True
        self.cam_combo.clear()
        self.cam_combo.addItem("(none)", 0)
        for c in S.cameras():
            self.cam_combo.addItem(str(c.name), S.handle(c))
        if view is not None:
            i = self.cam_combo.findData(view.camera)
            self.cam_combo.setCurrentIndex(max(0, i))
            self.w_spin.setValue(view.width)
            self.h_spin.setValue(view.height)
            self.aspect.setText(_aspect(view.width, view.height))
            self.only_list.clear()
            for h in view.only_objects:
                self.only_list.addItem(self._node_item(h))
            self._show_region(view)
        self._fit(self.only_list, self.only_hint,
                  "None — sun, sky, entourage… added here are on in this shot and off in the rest.",
                  "On in this shot, off in the rest.")
        self.pose_list.clear()
        for k in self.project.poses:
            self.pose_list.addItem(self._node_item(int(k)))
        self._fit(self.pose_list, self.pose_hint,
                  "None — everything sits the same in every shot. Add objects that move between shots.",
                  "Move these while you're in a shot — only that shot changes.")
        self._loading = False

    @staticmethod
    def _node_item(h):
        n = S.node(h)
        it = QtWidgets.QListWidgetItem(str(n.name) if n is not None else f"(deleted #{h})")
        it.setData(ID, h)
        return it

    def _camera_changed(self, _):
        view = self._view()
        if view is None:
            return
        view.camera = self.cam_combo.currentData() or 0
        self.save()
        self.go(view)

    def _select_camera(self):
        view = self._view()
        if view is not None:
            self._select_handles([view.camera])

    def _select_handles(self, handles):
        nodes = [n for n in (S.node(h) for h in handles) if n is not None]
        rt.select(nodes) if nodes else rt.clearSelection()
        rt.redrawViews()

    def _size_changed(self, which, val):
        view = self._view()
        if self._loading or view is None:
            return
        if self.lock.isChecked() and view.width and view.height:
            ratio = view.width / view.height
            self._loading = True
            if which == "w":
                self.h_spin.setValue(max(16, round(val / ratio)))
            else:
                self.w_spin.setValue(max(16, round(val * ratio)))
            self._loading = False
        self._set_size(view, self.w_spin.value(), self.h_spin.value())

    def _set_size(self, view, w, h):
        view.width, view.height = w, h
        self.aspect.setText(_aspect(w, h))
        self.save()
        if view.id == self.project.active:
            rt.renderWidth, rt.renderHeight = w, h
            rt.redrawViews()
        self.list.viewport().update()

    def _preset(self, idx):
        view = self._view()
        if view is None or idx == 0:
            return
        _, w, h = SIZE_PRESETS[idx - 1]
        self._loading = True
        self.w_spin.setValue(w)
        self.h_spin.setValue(h)
        self._loading = False
        self.preset.setCurrentIndex(0)
        self._set_size(view, w, h)

    # ── Per-shot objects ────────────────────────────────────────────────────

    def _make_per_shot(self):
        sel = list(rt.selection)
        if not sel:
            self._say("Select the objects that should sit differently per shot.")
            return
        S.make_per_shot(self.project, sel)
        self.save()
        self._fill_details()
        self._say(f"{len(sel)} object(s) per-shot — move them in each shot.")

    def _share(self):
        picked = [it.data(ID) for it in self.pose_list.selectedItems()]
        nodes = [n for n in (S.node(h) for h in picked) if n is not None] or list(rt.selection)
        nodes = [n for n in nodes if self.project.per_shot(S.handle(n))]
        if not nodes:
            self._say("Pick per-shot objects in the list (or select them in the scene).")
            return
        S.share(self.project, nodes)
        self.save()
        self._fill_details()
        self._say(f"{len(nodes)} object(s) now the same in every shot.")

    def _select_per_shot(self):
        self._select_handles([int(k) for k in self.project.poses])

    # ── Only in this shot ───────────────────────────────────────────────────

    def _only_add(self):
        view = self._view()
        if view is None:
            return
        for n in rt.selection:
            h = S.handle(n)
            if h not in view.only_objects:
                view.only_objects.append(h)
        self.save()
        self._fill_details()
        self.list.viewport().update()

    def _only_remove(self):
        view = self._view()
        if view is None:
            return
        gone = {it.data(ID) for it in self.only_list.selectedItems()}
        if not gone:
            return
        view.only_objects = [h for h in view.only_objects if h not in gone]
        self.save()
        self._fill_details()
        self.list.viewport().update()

    def _only_select(self):
        view = self._view()
        if view is not None:
            self._select_handles(view.only_objects)

    # ── Region ──────────────────────────────────────────────────────────────

    def _show_region(self, view):
        if not view.region:
            self.region_label.setText("Whole frame")
            return
        x0, y0, x1, y1 = view.region
        l, t, r, b = R.region_pixels(view.region, view.width, view.height)
        self.region_label.setText(f"{r - l} × {b - t} px at {l}, {t}  ({(x1 - x0) * (y1 - y0):.0%} of the frame)")

    def _region_edit(self):
        """Go to the shot and put Max's region frame up, on the saved region if there is one."""
        view = self._view()
        if view is None:
            return
        self.go(view)
        vp = rt.viewport.activeViewport
        if view.region:
            l, t, r, b = R.region_pixels(view.region, view.width, view.height)
            rt.viewport.setRegionRect(vp, rt.Box2(l, t, r - l, b - t))
        rt.setRenderType(rt.Name("region"))
        rt.execute("EditRenderRegion.EditRegion()")
        rt.redrawViews()
        self._say(f"{view.name}: drag the region frame's handles, then press Use viewport.")

    def _region_take(self):
        view = self._view()
        if view is None:
            return
        # The region frame is in render-output pixels at the CURRENT output size.
        w, h = int(rt.renderWidth), int(rt.renderHeight)
        box = rt.viewport.getRegionRect(rt.viewport.activeViewport)
        x, y, bw, bh = int(box.x), int(box.y), int(box.w), int(box.h)
        if bw <= 0 or bh <= 0:
            self._say("The viewport has no region frame — press Edit in viewport first.")
            return
        if (w, h) != (view.width, view.height):
            self._say(f"Note: output size is {w}×{h}, not this shot's {view.width}×{view.height} — "
                      f"region taken as a fraction of {w}×{h}.")
        view.region = [round(x / w, 5), round(y / h, 5), round(min(w, x + bw) / w, 5), round(min(h, y + bh) / h, 5)]
        self.save()
        self._show_region(view)

    def _region_clear(self):
        view = self._view()
        if view is not None:
            view.region = []
            self.save()
            self._show_region(view)

    # ── Adding / removing shots ─────────────────────────────────────────────

    def _new_view(self, cam, name=None):
        base = name or (str(cam.name) if cam else "Shot")
        names = {v.name for v in self.project.views}
        label, i = base, 2
        while label in names:
            label, i = f"{base} {i}", i + 1
        view = P.View(name=label, camera=S.handle(cam) if cam else 0,
                      width=int(rt.renderWidth), height=int(rt.renderHeight))
        self.project.views.append(view)
        return view

    def _add_from_viewport(self):
        cam = rt.getActiveCamera()
        if cam is None:
            # Perspective view → make a physical camera from it, like Ctrl+C.
            rt.execute('macros.run "Lights and Cameras" "PhysicalCamera_CreateFromView"')
            cam = rt.getActiveCamera()
        view = self._new_view(cam)
        self.save()
        self._fill_shots()
        self.go(view)            # per-shot objects start from where they are now
        self.update_render_button()

    def _add_selected(self):
        added = [self._new_view(n) for n in list(rt.selection) if rt.superClassOf(n) == rt.camera]
        if not added:
            self._say("Select one or more cameras first.")
            return
        self.save()
        self._fill_shots()
        self.go(added[-1])
        self.update_render_button()

    def _duplicate(self, view):
        S.capture(self.project)
        copy = P.View.from_dict({**view.__dict__, "id": P.View("x").id, "name": view.name + " copy",
                                 "only_objects": list(view.only_objects), "region": list(view.region)})
        for poses in self.project.poses.values():
            if view.id in poses:
                poses[copy.id] = list(poses[view.id])
        self.project.views.insert(self.project.views.index(view) + 1, copy)
        self.save()
        self._fill_shots()
        self.go(copy)
        self.update_render_button()

    def _delete(self, view):
        r = self.project.views.index(view)
        S.capture(self.project)
        del self.project.views[r]
        for poses in self.project.poses.values():
            poses.pop(view.id, None)
        try:
            os.remove(thumb_path(view))
        except OSError:
            pass
        was_active = self.project.active == view.id
        if was_active:
            self.project.active = ""
        self.save()
        self._fill_shots()
        if was_active and self.project.views:
            self.go(self.project.views[min(r, len(self.project.views) - 1)])
        self._fill_details()
        self.update_render_button()

    # ── Mattes ──────────────────────────────────────────────────────────────

    def _fill_mattes(self):
        rows = R.layer_rows(self.project)
        self.matte_table.setRowCount(len(rows))
        parent_mode = {}
        for i, row in enumerate(rows):
            name = str(row["layer"].name)
            parent_mode[name] = row["mode"]
            it = QtWidgets.QTableWidgetItem("    " * row["depth"] + row["path"].rsplit("/", 1)[-1])
            it.setFlags(it.flags() & ~QtCore.Qt.ItemIsEditable)
            self.matte_table.setItem(i, 0, it)
            combo = form.Combo()
            unset = row["mode"] if row["own"] is None else parent_mode.get(row["parent"], "normal")
            # Unset: "↑ Mattes" = whatever the layer above is (top layers: the default).
            combo.addItem(("↑ " if row["parent"] else "") + P.MATTE_MODES[unset], None)
            combo.setItemData(0, "Same as the layer above" if row["parent"] else "Default",
                              QtCore.Qt.ToolTipRole)
            for key, label in P.MATTE_MODES.items():
                combo.addItem(label, key)
            combo.setCurrentIndex(combo.findData(row["own"]) if row["own"] else 0)
            combo.currentIndexChanged.connect(lambda _, n=name, cb=combo: self._matte_changed(n, cb))
            self.matte_table.setCellWidget(i, 1, combo)

    def _flatten_lmbn(self):
        from . import convert
        convert.flatten_matte_layers(log=self._say)
        self._fill_mattes()

    def _matte_changed(self, layer_name, combo):
        if combo.currentData() is None:
            self.project.layer_mattes.pop(layer_name, None)
        else:
            self.project.layer_mattes[layer_name] = combo.currentData()
        self.save()
        # Children's "Same as above" labels follow; not from inside the combo's own signal
        # (the refill replaces that combo).
        QtCore.QTimer.singleShot(0, self._fill_mattes)

    # ── Legacy ──────────────────────────────────────────────────────────────

    def _import_legacy(self):
        if P.import_legacy(self.project):
            self.save()
            self.refresh()
            self._say(f"Imported {len(self.project.views)} shots from the old setup.")

    def _convert(self):
        from . import convert
        try:
            convert.frames_to_shots(self.project, log=self._say)
        except Exception as e:  # shown to the user, not swallowed
            self._say(f"Error: {e}")
        self.refresh()

    def _render(self):
        from . import renderwin
        renderwin.show("render")
