"""Command search for Max — Fusion's palette, the SAME page code: fusion_ui/search.js
(vendored into max/palette/, see its sync.sh) in a QWebEngineView inside Max. Replaces
Max's own Search Actions (X). Inside Max on purpose: it has to work when Max runs on a
Windows PC with no Mac beside it.

    import callis.palette as P
    P.show()          # at the pointer; type, ↑/↓, Enter runs, Esc closes, right-click = sheet

The page (max/palette/index.js) is only the adapter; this file is its back end over a
QWebChannel object (`Bridge`): the catalog, running, and the sheet's stores.

Catalog: Max's action tables (callis.actions.catalog), Main UI context only — an Edit Poly
or Track View action does nothing outside its context — one row per name.
Keys: Max's own hotkeys (Default.hsxb + the active set's changes); a chord that is a
Control Room SURROGATE for a held trigger (fingers / Space / ⌘ — remap/maxapp.py) is shown
as that reach, from hotkeys/reach.json (written by remap/karabiner_layers.py).
State: .state/palette.json — recents, show (hidden = []), names, pins.

Measured 2026-10-14 in the VM: view 7 ms to make, first show ~110 ms, its renderer
82 MB and idle at 0 CPU while hidden — built hidden by warm(), so X only shows it.
"""
import json
import os
import time
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STATE = os.path.join(HERE, ".state", "palette.json")
PAGE = os.path.join(HERE, "palette", "index.html")
REACH = os.path.join(HERE, "hotkeys", "reach.json")
MAIN_UI = 0
SELF = "647394-CommandSearch`Callis"
RECENTS = 50

# Max's key names that differ from Control Room's (remap/maxapp.py MAX_TO_KEY).
_MAX_KEY = {"enter": "return", "esc": "escape", "backspace": "delete"}


# ──────────────────────────────────────────────────────────────── keys (pure)

def chord(shortcut):
    """'Ctrl+Shift+S' → 'ctrl+shift+s' (Control Room's spelling)."""
    s = str(shortcut or "").strip()
    plus = s.endswith("+") and len(s) > 1       # 'Num++', 'Ctrl++'
    parts = [p.strip().lower() for p in (s[:-1] if plus else s).split("+") if p.strip()]
    if plus:
        parts[-1:] = [parts[-1] + " +"] if parts and parts[-1] == "num" else parts[-1:] + ["+"]
    if not parts:
        return ""
    key = _MAX_KEY.get(parts[-1], parts[-1])
    mods = [m for m in ("ctrl", "alt", "shift") if m in parts[:-1]]
    return "+".join(mods + [key])


def keymap(defaults, changes, ids, reach=None):
    """{action id: {kind, seq | key, fingers}} for `ids`.
    defaults: [(shortcut, id)] (Default.hsxb); changes: [(tag, shortcut, id)] (the active
    .hsx, Assign_Hotkey / Unassign_Hotkey in order); reach: {chord: {kind, key, fingers}}."""
    have = {}
    for sc, aid in defaults:
        have.setdefault(aid, []).append(chord(sc))
    for tag, sc, aid in changes:
        c = chord(sc)
        lst = have.setdefault(aid, [])
        if tag == "Unassign_Hotkey":
            have[aid] = [x for x in lst if x != c]
        elif c not in lst:
            lst.insert(0, c)            # ours first: it's the one Control Room shows
    out = {}
    reach = reach or {}
    for aid in ids:
        scs = [c for c in have.get(aid, []) if c]
        if not scs:
            continue
        r = next((reach[c] for c in scs if c in reach), None)
        out[aid] = dict(r) if r else {"kind": "chord", "seq": scs[0]}
    return out


def dedup(items):
    """One row per name: the first of a same-named group (Max lists some actions both in
    a table and as a macro)."""
    seen, out = set(), []
    for c in items:
        key = (c.get("name") or c["id"]).strip().lower()
        if key not in seen:
            seen.add(key)
            out.append(c)
    return out


# ──────────────────────────────────────────────────────────────── state

def _load():
    try:
        with open(STATE) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def _save(st):
    try:
        os.makedirs(os.path.dirname(STATE), exist_ok=True)
        tmp = STATE + ".tmp"
        with open(tmp, "w") as f:
            json.dump(st, f, indent=1)
        os.replace(tmp, STATE)
    except OSError as e:
        print("[callis.palette] state not saved:", e)


def _remember(cid):
    st = _load()
    st["recents"] = ([cid] + [r for r in st.get("recents", []) if r != cid])[:RECENTS]
    _save(st)


def store(kind, body):
    """The sheet's writes — fusion_shortcuts' /search_* shapes."""
    st = _load()
    cid = body.get("cmd_id")
    if not cid:
        return
    if kind == "show":
        d = st.setdefault("show", {})
        if body.get("env") is None:
            d.pop(cid, None)
        else:
            d[cid] = list(body["env"])
    elif kind == "name":
        d = st.setdefault("names", {})
        if body.get("name"):
            d[cid] = body["name"]
        else:
            d.pop(cid, None)
    elif kind == "pin":
        d = st.setdefault("pins", {})
        if body.get("pinned"):
            d[cid] = True
        else:
            d.pop(cid, None)
    _save(st)


# ──────────────────────────────────────────────────────────────── catalog + keys (Max)

_catalog = None
_keys = [None, None]       # (kbd file, mtimes) → keymap


def catalog():
    global _catalog
    if _catalog is None:
        from . import actions
        items = [c for c in actions.catalog()
                 if c["context"] == MAIN_UI and c["name"] and c["id"] != SELF]
        _catalog = [{"id": c["id"], "name": c["name"], "group": c["category"]}
                    for c in dedup(items)]
    return _catalog


def _mtime(p):
    try:
        return os.path.getmtime(p)
    except OSError:
        return 0


def _hotkeys(path, tags):
    try:
        root = ET.parse(path).getroot()
    except (OSError, ET.ParseError):
        return []
    return [(el.tag, el.get("Shortcut", ""), el.get("Id", "")) for el in root if el.tag in tags]


def current_keys():
    """The keymap, rebuilt only when the keyboard file or reach.json changed."""
    from pymxs import runtime as rt
    from . import actions
    kbd = str(rt.actionMan.getKeyboardFile())
    sig = (kbd, _mtime(kbd), _mtime(REACH))
    if _keys[0] != sig:
        defaults = [(sc, aid) for _, sc, aid in _hotkeys(actions._defaults_file(), ("Hotkey",))]
        changes = _hotkeys(kbd, ("Assign_Hotkey", "Unassign_Hotkey"))
        try:
            with open(REACH) as f:
                reach = json.load(f)
        except (OSError, ValueError):
            reach = {}
        _keys[:] = [sig, keymap(defaults, changes, [c["id"] for c in catalog()], reach)]
    return _keys[1]


def data():
    st = _load()
    return {"commands": catalog(), "recents": st.get("recents", []), "keymap": current_keys(),
            "show": st.get("show", {}), "names": st.get("names", {}), "pins": st.get("pins", {})}


# ──────────────────────────────────────────────────────────────── the window

_panel = None


def _build():
    from PySide6 import QtCore, QtGui, QtWidgets
    from PySide6.QtWebChannel import QWebChannel
    from PySide6.QtWebEngineWidgets import QWebEngineView
    import qtmax

    class Bridge(QtCore.QObject):
        def __init__(self, view):
            super().__init__(view)
            self.view = view

        @QtCore.Slot(result=str)
        def catalog(self):
            try:
                return json.dumps(data())
            except Exception as e:
                print("[callis.palette] catalog:", e)
                return json.dumps({"commands": []})

        @QtCore.Slot(str)
        def run(self, cid):
            self.view.dismiss()
            _remember(cid)

            def go():
                from . import actions
                try:
                    actions.run(cid)
                except Exception as e:
                    print("[callis.palette] %s: %s" % (cid, e))
            QtCore.QTimer.singleShot(0, go)    # after the window is gone; never inside a bridge call

        @QtCore.Slot(str, str)
        def store(self, kind, body):
            try:
                store(kind, json.loads(body))
            except Exception as e:
                print("[callis.palette] store:", e)

        @QtCore.Slot(int, int)
        def size(self, w, h):
            self.view.fit(w, h)

        @QtCore.Slot()
        def close(self):
            self.view.dismiss()

    class View(QWebEngineView):
        def __init__(self):
            super().__init__(qtmax.GetQMaxMainWindow())
            self.setWindowFlags(QtCore.Qt.Tool | QtCore.Qt.FramelessWindowHint
                                | QtCore.Qt.NoDropShadowWindowHint)
            # Opaque + a rounded mask: a translucent window doesn't composite in the VM —
            # the shadow gutter painted as a big black frame (2026-10-14). No gutter now
            # (palette/index.css), so the window is exactly the panel.
            self.setAttribute(QtCore.Qt.WA_ShowWithoutActivating, False)
            self.page().setBackgroundColor(QtGui.QColor(0, 0, 0))   # --panel-bg
            self.acc0 = None
            self.setContextMenuPolicy(QtCore.Qt.NoContextMenu)
            self.channel = QWebChannel(self.page())
            self.bridge = Bridge(self)
            self.channel.registerObject("palette", self.bridge)
            self.page().setWebChannel(self.channel)
            self.anchor = QtCore.QPoint()
            self.shown_at = 0.0
            self.resize(352, 120)
            # X before the page finished loading (not warmed yet): open it once it has.
            self.loadFinished.connect(lambda ok: self.isVisible() and self.page().runJavaScript(
                "window.paletteOpen && window.paletteOpen()"))
            self.load(QtCore.QUrl.fromLocalFile(PAGE))

        def open(self):
            # Max's accelerators take every key before Qt sees it — the field had focus
            # and stayed empty (2026-10-14). Off while the palette is up.
            from pymxs import runtime as rt
            if self.acc0 is None:
                self.acc0 = bool(rt.enableAccelerators)
            rt.enableAccelerators = False
            self.anchor = QtGui.QCursor.pos()
            self.shown_at = time.time()
            self._place()
            self.show()
            self.raise_()
            self.activateWindow()
            self.setFocus()
            self.page().runJavaScript("window.paletteOpen && window.paletteOpen()")

        def fit(self, w, h):
            if w > 0 and h > 0 and (w, h) != (self.width(), self.height()):
                self.resize(w, h)
                self._place()

        def _place(self):
            """Panel top-left on the pointer (the window's margin is the panel's shadow
            room, --panel-gutter), clamped to the screen."""
            gut = 0
            pos = self.anchor
            scr = QtGui.QGuiApplication.screenAt(pos) or QtGui.QGuiApplication.primaryScreen()
            g = scr.availableGeometry()
            x = min(pos.x() - gut, g.right() - self.width())
            y = min(pos.y() - gut, g.bottom() - self.height())
            self.move(max(g.left(), x), max(g.top(), y))

        def resizeEvent(self, ev):
            super().resizeEvent(ev)
            r = 9                          # --panel-radius
            path = QtGui.QPainterPath()
            path.addRoundedRect(QtCore.QRectF(self.rect()), r, r)
            self.setMask(QtGui.QRegion(path.toFillPolygon().toPolygon()))

        def dismiss(self):
            self.hide()
            if self.acc0 is not None:
                from pymxs import runtime as rt
                rt.enableAccelerators = self.acc0
                self.acc0 = None
            mw = qtmax.GetQMaxMainWindow()
            mw.activateWindow()

        def changeEvent(self, ev):
            # Clicked away (into Max, another window) → gone, as the Qt popup was.
            if ev.type() == QtCore.QEvent.ActivationChange and self.isVisible() \
                    and not self.isActiveWindow() and time.time() - self.shown_at > 0.3:
                QtCore.QTimer.singleShot(0, self.dismiss)
            super().changeEvent(ev)

    return View()


def show():
    global _panel
    if _panel is None:
        _panel = _build()
    _panel.open()
    return _panel


def warm():
    """Build the catalog and the hidden view ahead of the first X (a few hundred ms
    across ~4000 actions; the page loads behind it)."""
    global _panel
    catalog()
    if _panel is None:
        _panel = _build()
