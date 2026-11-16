"""The Render window — everything about rendering in one place (macros Render,
RenderSettings; the Shots panel's "Render…" button).

Render tab:   which shots, resolutions, output folder, Photoshop file, Region only,
              save the scene first, log, Render (render.render_batch, Final settings).
Settings tab: the current renderer's Preview (Quick Render) and Final (Render) presets,
              rows drawn by form.Form from rsettings.SPECS.

In the Browser's strip (side.py), in the Shots panel's look (style.py). Each command
toggles it on its own tab (the other command switches tabs); Esc or D closes. It edits the same project
object as the Shots panel when that's open (ui.project()), so ticks agree.
"""
import json
import os

import qtmax
from PySide6 import QtCore, QtGui, QtWidgets
from pymxs import runtime as rt

from . import form, project as P, render as R, rsettings, side, style

TABS = {"render": 0, "settings": 1}
_w = None


def toggle(tab="render"):
    """Open on `tab`; already open there → close; open on the other tab → switch."""
    if _w is not None and _w.isVisible():
        if _w.tabs.currentIndex() == TABS[tab]:
            _w.close()
            return None
        _w.tabs.setCurrentIndex(TABS[tab])
        _w.activateWindow()
        return _w
    return show(tab)


def show(tab="render"):
    global _w
    if _w is None:
        _w = RenderWindow()
    _w.reload()
    _w.tabs.setCurrentIndex(TABS[tab])
    if side.current() is not _w or not _w.isVisible():
        side.take(_w)                      # in the Browser's place
    _w.raise_()
    _w.activateWindow()
    return _w


def render_now():
    """Render the ticked shots straight away (macro RenderTickedViews)."""
    show("render")._render()


def sync():
    """The Shots panel changed ticks / the project: redraw if open."""
    if _w is not None and _w.isVisible():
        _w.reload()


def _section(text):
    head = QtWidgets.QLabel(text.upper())
    head.setProperty("role", "section")
    return head


def _button(text, tip, slot, role=None):
    b = QtWidgets.QPushButton(text)
    b.setToolTip(tip)
    b.setCursor(QtCore.Qt.PointingHandCursor)
    if role:
        b.setProperty("role", role)
    b.clicked.connect(slot)
    return b


def _row(*widgets, stretch=True):
    h = QtWidgets.QHBoxLayout()
    h.setContentsMargins(0, 0, 0, 0)
    h.setSpacing(6)
    for w in widgets:
        h.addWidget(w)
    if stretch:
        h.addStretch(1)
    return h


def _pill(text, tip=""):
    c = QtWidgets.QCheckBox(text)
    c.setProperty("role", "pill")
    c.setCursor(QtCore.Qt.PointingHandCursor)
    c.setToolTip(tip)
    return c


class RenderWindow(QtWidgets.QWidget):
    def __init__(self):
        super().__init__(qtmax.GetQMaxMainWindow(), QtCore.Qt.Tool)
        self.setObjectName("callisRoot")
        self.setWindowTitle("Render")
        self.setStyleSheet(style.QSS)
        self._own = None          # the project when the Shots panel isn't open
        self._loading = False
        self.which = "final"
        self.form = None

        lay = QtWidgets.QVBoxLayout(self)
        lay.setContentsMargins(0, 0, 0, 0)
        lay.setSpacing(0)
        head = QtWidgets.QHBoxLayout()
        head.setContentsMargins(16, 12, 16, 2)
        head.setSpacing(10)
        title = QtWidgets.QLabel("Render")
        title.setProperty("role", "title")
        head.addWidget(title)
        self.renderer = QtWidgets.QLabel()
        self.renderer.setProperty("role", "hint")
        head.addWidget(self.renderer)
        head.addStretch(1)
        lay.addLayout(head)

        self.tabs = QtWidgets.QTabWidget()
        self.tabs.tabBar().setDrawBase(False)
        self.tabs.addTab(self._render_tab(), "Render")
        self.tabs.addTab(self._settings_tab(), "Settings")
        lay.addWidget(self.tabs, 1)

        QtGui.QShortcut(QtGui.QKeySequence("Esc"), self, activated=self.close)
        for ev in ("sceneUndo", "sceneRedo", "filePostOpen", "systemPostNew", "systemPostReset",
                   "postRendererChange"):
            rt.callbacks.addScript(rt.Name(ev), self._scene_changed, id=rt.Name("callisRenderWin"))

    @property
    def project(self):
        from . import ui
        if ui._panel is not None:
            return ui._panel.project
        if self._own is None:
            self._own = P.load()
        return self._own

    def _scene_changed(self):
        self._own = None
        if self.isVisible():
            QtCore.QTimer.singleShot(0, self.reload)

    def closeEvent(self, e):
        global _w
        rt.callbacks.removeScripts(id=rt.Name("callisRenderWin"))
        if _w is self:
            _w = None
        self.deleteLater()
        super().closeEvent(e)

    # ── Render tab ──────────────────────────────────────────────────────────

    def _render_tab(self):
        page = QtWidgets.QWidget()
        v = QtWidgets.QVBoxLayout(page)
        v.setContentsMargins(16, 6, 16, 16)
        v.setSpacing(6)

        v.addLayout(_row(_section("Shots"),
                         _button("All", "Tick every shot", lambda: self._tick_all(True)),
                         _button("None", "Untick every shot", lambda: self._tick_all(False))))
        self.shots = QtWidgets.QListWidget()
        self.shots.setProperty("role", "small")
        self.shots.itemChanged.connect(self._shot_ticked)
        v.addWidget(self.shots)

        v.addWidget(_section("Resolution"))
        self.res_checks = {}
        for key, spec in P.RESOLUTIONS.items():
            c = _pill(spec["label"], f'{spec["scale"]:g}× each shot\'s size → "{spec["folder"]}" folder')
            c.toggled.connect(self._res_changed)
            self.res_checks[key] = c
        pills = list(self.res_checks.values())
        for i in range(0, len(pills), 2):              # two a row: fits the Browser's strip
            v.addLayout(_row(*pills[i:i + 2]))

        v.addWidget(_section("Output"))
        self.out_edit = QtWidgets.QLineEdit()
        self.out_edit.setPlaceholderText("Output folder — one sub-folder per shot")
        self.out_edit.setMinimumWidth(60)
        self.out_edit.editingFinished.connect(self._out_changed)
        v.addLayout(_row(self.out_edit, _button("…", "Choose folder", self._browse),
                         _button("Open", "Open in Explorer", self._open_folder), stretch=False))

        v.addWidget(_section("Options"))
        self.ps_check = QtWidgets.QCheckBox("Photoshop file")
        self.ps_check.setToolTip("Build / update the shot's PSB when the passes land")
        self.depth = form.Combo()
        self.depth.addItems(["16-bit", "32-bit linear"])
        self.depth.setToolTip("Passes always combine in 32-bit linear, so the light adds up correctly.\n"
                              "16-bit converts the finished file afterwards — half the memory.")
        self.region_check = QtWidgets.QCheckBox("Region only")
        self.region_check.setToolTip("Re-render just each shot's region and patch it into the last full\n"
                                     "render at that size — the Photoshop file's passes update in place")
        self.save_check = QtWidgets.QCheckBox("Save scene first")
        for w in (self.ps_check, self.region_check, self.save_check):
            w.toggled.connect(self._opts_changed)
        self.depth.currentIndexChanged.connect(self._opts_changed)
        v.addLayout(_row(self.ps_check, self.depth))
        v.addLayout(_row(self.region_check, self.save_check))

        self.log = QtWidgets.QPlainTextEdit()
        self.log.setReadOnly(True)
        self.log.setMaximumHeight(90)
        self.log.setPlaceholderText("Log")
        v.addStretch(1)
        v.addWidget(self.log)
        self.render_btn = _button("Render", "Render every ticked shot at every chosen resolution, "
                                  "with the Final settings", self._render, role="primary")
        v.addWidget(self.render_btn)
        return page

    def reload(self):
        p = self.project
        self.renderer.setText(rsettings.label())
        self._loading = True
        try:
            self.shots.clear()
            for view in p.views:
                it = QtWidgets.QListWidgetItem(f"{view.name}    {view.width} × {view.height}")
                it.setFlags(it.flags() | QtCore.Qt.ItemIsUserCheckable)
                it.setCheckState(QtCore.Qt.Checked if view.render else QtCore.Qt.Unchecked)
                it.setData(QtCore.Qt.UserRole, view.id)
                self.shots.addItem(it)
            rows = min(max(len(p.views), 1), 10)     # fit the shots, scroll past 10
            self.shots.setFixedHeight(rows * max(self.shots.sizeHintForRow(0), 22) + 6)
            self.out_edit.setText(p.output_root)
            for key, c in self.res_checks.items():
                c.setChecked(key in p.resolutions)
            self.ps_check.setChecked(p.photoshop)
            self.depth.setCurrentIndex(1 if p.bit_depth == 32 else 0)
            self.region_check.setChecked(p.region)
            self.save_check.setChecked(p.save_scene)
        finally:
            self._loading = False
        self._update_button()
        self._build_settings()

    def _save(self, shots=False):
        P.save(self.project)
        self._update_button()
        if shots:
            from . import ui
            if ui._panel is not None:
                ui._panel.list.viewport().update()
                ui._panel.update_render_button(sync=False)

    def _update_button(self):
        p = self.project
        n = sum(1 for v in p.views if v.render)
        what = "regions" if p.region else ("shot" if n == 1 else "shots")
        ok = n > 0 and bool(p.resolutions)
        self.render_btn.setText(f"Render {n} {what}" if ok else
                                ("Tick a shot to render" if n == 0 else "Pick a resolution"))
        self.render_btn.setEnabled(ok)

    def _shot_ticked(self, it):
        if self._loading:
            return
        view = self.project.view(it.data(QtCore.Qt.UserRole))
        if view is not None:
            view.render = it.checkState() == QtCore.Qt.Checked
            self._save(shots=True)

    def _tick_all(self, on):
        for v in self.project.views:
            v.render = on
        self._save(shots=True)
        self.reload()

    def _res_changed(self):
        if not self._loading:
            self.project.resolutions = [k for k, c in self.res_checks.items() if c.isChecked()]
            self._save()

    def _out_changed(self):
        if not self._loading:
            self.project.output_root = self.out_edit.text().strip()
            self._save()

    def _browse(self):
        d = QtWidgets.QFileDialog.getExistingDirectory(self, "Render output folder", self.project.output_root)
        if d:
            self.out_edit.setText(os.path.normpath(d))
            self._out_changed()

    def _open_folder(self):
        root = self.project.output_root
        if root and os.path.isdir(root):
            os.startfile(root)

    def _opts_changed(self):
        if self._loading:
            return
        p = self.project
        p.photoshop = self.ps_check.isChecked()
        p.bit_depth = 32 if self.depth.currentIndex() == 1 else 16
        p.region = self.region_check.isChecked()
        p.save_scene = self.save_check.isChecked()
        self._save(shots=True)      # the Shots panel's button says shots / regions

    def _say(self, text):
        self.log.appendPlainText(text)
        QtWidgets.QApplication.processEvents()

    def _render(self):
        p = self.project
        if not p.resolutions:
            self._say("Pick at least one resolution.")
            return
        self.tabs.setCurrentIndex(TABS["render"])
        self.render_btn.setEnabled(False)
        try:
            done = R.render_batch(p, log=self._say)
            self._say(f"Finished — {len(done)} render(s).")
        except Exception as e:  # shown to the user, not swallowed
            self._say(f"Error: {e}")
        finally:
            self._update_button()
            from . import ui
            if ui._panel is not None:
                ui._panel.refresh()

    # ── Settings tab ────────────────────────────────────────────────────────

    def _settings_tab(self):
        page = QtWidgets.QWidget()
        v = QtWidgets.QVBoxLayout(page)
        v.setContentsMargins(16, 8, 16, 16)
        v.setSpacing(6)
        self.pills = QtWidgets.QButtonGroup(self)
        self.pills.setExclusive(True)
        self.preview_pill = _pill("Preview", "Quick Render — the current shot, nothing saved")
        self.final_pill = _pill("Final", "The Render button — every ticked shot")
        self.pills.addButton(self.preview_pill)
        self.pills.addButton(self.final_pill)
        self.final_pill.setChecked(True)
        self.pills.buttonToggled.connect(self._which_changed)
        v.addLayout(_row(self.preview_pill, self.final_pill))
        self.which_hint = QtWidgets.QLabel()
        self.which_hint.setProperty("role", "hint")
        self.which_hint.setWordWrap(True)
        v.addWidget(self.which_hint)

        self.scroll = QtWidgets.QScrollArea()
        self.scroll.setWidgetResizable(True)
        self.scroll.setFrameShape(QtWidgets.QFrame.NoFrame)
        v.addWidget(self.scroll, 1)
        self.reset_btn = _button("Reset from Render Setup", "This preset ← Max's current render settings "
                                 "(Preview also gets its lighter values)", self._reset)
        v.addLayout(_row(self.reset_btn))
        return page

    def _which_changed(self, button, on):
        if on:
            self.which = "preview" if button is self.preview_pill else "final"
            self._build_settings()

    def _build_settings(self):
        p = self.project
        self.which_hint.setText("Used by Quick Render — the current shot, shown only, nothing saved."
                                if self.which == "preview" else
                                "Used by Render — every ticked shot. Max's Render Setup is put back after.")
        before = json.dumps(p.render_presets, sort_keys=True)
        fields = rsettings.fields(p, self.which, lambda: P.save(self.project))
        if json.dumps(p.render_presets, sort_keys=True) != before:
            P.save(p)                       # keep a just-seeded preset
        page = QtWidgets.QWidget()
        page.setObjectName("callisDetails")     # style.QSS: the black fill
        lay = QtWidgets.QVBoxLayout(page)
        lay.setContentsMargins(0, 0, 8, 0)
        if fields:
            self.form = form.Form(fields)
            lay.addWidget(self.form)
        else:
            self.form = None
            msg = QtWidgets.QLabel(f"No settings for {rsettings.label()} yet — Quick Render and Render "
                                   "use Max's Render Setup as it is.")
            msg.setWordWrap(True)
            msg.setProperty("role", "hint")
            lay.addWidget(msg)
        lay.addStretch(1)
        self.scroll.setWidget(page)
        self.reset_btn.setVisible(bool(fields))

    def _reset(self):
        rsettings.reset(self.project, self.which)
        P.save(self.project)
        self._build_settings()
