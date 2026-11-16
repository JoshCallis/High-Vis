"""A settings panel drawn BY THE BROWSER PAGE (max_browser/index.js renderPanel), in the
Browser's place: shot camera / sun settings, a smart verb's modifier settings (props.py).

Qt can't draw these see-through in the VM (translucency doesn't composite there — the
palette's black frame), so, like the Browser, Max holds the state and the Mac page only
draws it: browser.json `panel` (side.page()), clicks back as act {op:"panel"}.

Section heads (Exposure, Clipping…) are Browser groups: rows the cursor lands on, a click
opens / shuts one, Space / ⌘ / ⇧ clicks pick them (browser.py _pick_click's rules), rename
(⌃R, or the page's right-click menu ▸ Rename) renames them. A click on a drop-down setting
only lands on it — F / Enter opens it (the page draws its choices under the value); Esc in
Max or the page cancels it (_esc_watch). Shut sections and names are kept per panel
kind in .state/panel_sections.json.

The Browser's keys drive it (browser.key → key()):
  R / C        cursor up / down the rows (heads and the settings of open sections); inside
               an open drop-down, its choices — each one is tried on at once (no undo
               record), so the scene shows it.
  F / Enter    on a head: open the section (every picked head, if it's picked). On a
               setting: open the drop-down or number (landing never opens it); inside one,
               commit — one undo record. On a tick: switch it.
  D            inside a drop-down or number: cancel, the value goes back. On a setting: shut
               its section, cursor to the head. On an open head: shut it (picked heads too);
               on a shut one: close the panel — the Browser comes back where it was.
  Rename       a head: its name field; a number: = F.
A number opens as a text field in the page (`edit` n, like the Browser's rename field);
Enter or F commits, Esc or D cancels.
"""
import json
import os

from pymxs import runtime as rt

SECTIONS = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                        ".state", "panel_sections.json")


def _load():
    try:
        with open(SECTIONS) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def _kind(f, v):
    if "choices" in f.opts:
        return "choice"
    if isinstance(v, bool):
        return "bool"
    if isinstance(v, int):
        return "int"
    if isinstance(v, float):
        return "float"
    return None


def _num(f, v):
    if isinstance(v, int) and not isinstance(v, bool):
        return str(v)
    d = f.opts.get("decimals", 3)
    s = ("%." + str(d) + "f") % v
    return s.rstrip("0").rstrip(".") if "." in s and d > 1 else s


class PagePanel:
    def __init__(self, kind, node, title, sub, fields):
        self.kind, self.node, self.title, self.sub = kind, node, title, sub
        self.fields = []
        for f in fields:
            try:
                k = _kind(f, f.get())
            except Exception:
                continue
            if k is not None:
                self.fields.append(f)
        mem = _load().get(kind, {})
        self.shut = set(mem.get("shut", []))
        self.names = dict(mem.get("names", {}))
        self.picks, self.anchor = set(), None
        self.rename_n, self.renaming = 0, None
        self.cursor = ("h", self.fields[0].section) if self.fields else None
        self.open = None        # index of the drop-down / number being edited
        self.pick = 0           # the lit choice in an open drop-down
        self.draft = None       # its value before the edit (cancel puts it back)
        self.edit_n = 0         # a new number per number field opened (the page's text field)
        rt.callbacks.removeScripts(id=rt.Name("callisPanel"))
        for ev in ("sceneUndo", "sceneRedo"):
            rt.callbacks.addScript(rt.Name(ev), _republish, id=rt.Name("callisPanel"))

    # ── what the page draws ───────────────────────────────────────────────────
    def alive(self):
        try:
            return bool(rt.isValidObj(self.node))
        except Exception:
            return False

    def _secs(self):
        out = []
        for f in self.fields:
            if f.section not in out:
                out.append(f.section)
        return out

    def _items(self):
        """What the cursor walks: ("h", section) heads, ("f", i) settings of open sections."""
        out, last = [], object()
        for i, f in enumerate(self.fields):
            if f.section != last:
                last = f.section
                out.append(("h", last))
            if f.section not in self.shut:
                out.append(("f", i))
        return out

    def _save(self):
        d = _load()
        d[self.kind] = {"shut": sorted(self.shut), "names": self.names}
        try:
            os.makedirs(os.path.dirname(SECTIONS), exist_ok=True)
            with open(SECTIONS + ".tmp", "w") as f:
                json.dump(d, f, indent=1)
            os.replace(SECTIONS + ".tmp", SECTIONS)
        except OSError:
            pass

    def snapshot(self):
        rows = []
        for it in self._items():
            if it[0] == "h":
                sec = it[1]
                rows.append({"h": sec, "name": self.names.get(sec) or sec,
                             "shut": sec in self.shut, "cursor": it == self.cursor,
                             "pick": sec in self.picks})
                continue
            i = it[1]
            f = self.fields[i]
            try:
                v = f.get()
            except Exception:
                v = None
            k = _kind(f, v) or "none"
            r = {"i": i, "section": f.section, "label": f.label, "kind": k,
                 "cursor": it == self.cursor, "open": i == self.open}
            if k == "choice":
                ch = f.opts["choices"]
                r["text"] = next((lab for val, lab in ch if val == v), str(v))
                if i == self.open:
                    r["choices"] = [lab for _, lab in ch]
                    r["pick"] = self.pick
            elif k == "bool":
                r["value"] = bool(v)
            elif k in ("int", "float"):
                r["num"] = _num(f, v)
                r["text"] = r["num"] + f.opts.get("suffix", "")
            else:
                r["text"] = "—"
            rows.append(r)
        return {"title": self.title, "rows": rows,
                "rename": {"n": self.rename_n, "h": self.renaming} if self.renaming else None,
                "edit": self.edit_n if self.open is not None and
                self._k(self.open) in ("int", "float") else 0}

    def _k(self, i):
        f = self.fields[i]
        try:
            return _kind(f, f.get())
        except Exception:
            return None

    # ── setting values ────────────────────────────────────────────────────────
    def _try(self, i, v):
        """Put a value on without an undo record (a drop-down's choice being tried on)."""
        f = self.fields[i]
        try:
            f.set(v, record=False)
        except TypeError:
            f.set(v)

    def _commit(self, i, v):
        """The value for good: back to the draft unrecorded, then set as one undo record."""
        if self.draft is not None:
            self._try(i, self.draft)
        if v != self.draft or self.draft is None:
            self.fields[i].set(v)

    def _choices(self, i):
        return [val for val, _ in self.fields[i].opts["choices"]]

    def _open(self, i):
        k = self._k(i)
        if k is None:
            return
        f = self.fields[i]
        if k == "bool":
            f.set(not bool(f.get()))
            return
        self.open, self.draft = i, f.get()
        if k == "choice":
            ch = self._choices(i)
            self.pick = ch.index(self.draft) if self.draft in ch else 0
            _esc_watch(self)
        else:
            self.edit_n += 1

    def _close(self, keep):
        i, self.open = self.open, None
        if i is None:
            return
        if self._k(i) == "choice":
            v = self._choices(i)[self.pick]
            if keep:
                self._commit(i, v)
            elif self.draft is not None:
                self._try(i, self.draft)
        self.draft = None
        rt.redrawViews()

    def set_text(self, text):
        """The page's number field: Enter / F."""
        i = self.open
        if i is None or self._k(i) not in ("int", "float"):
            return
        f = self.fields[i]
        self.open = None
        try:
            v = float(str(text).replace(",", ".").split()[0])
        except (ValueError, IndexError):
            self.draft = None
            return
        if self._k(i) == "int":
            v = int(round(v))
        lo, hi = f.opts.get("min"), f.opts.get("max")
        v = max(v, lo) if lo is not None else v
        v = min(v, hi) if hi is not None else v
        self.draft = None
        if v != f.get():
            f.set(v)

    # ── keys ──────────────────────────────────────────────────────────────────
    def key(self, name):
        """A Browser key; True if the panel took it."""
        from . import side
        if self.cursor is None:
            if name == "out":
                side.close()
                return True
            return name in ("up", "down", "top", "bottom", "in", "deep", "rename")
        k = self._k(self.open) if self.open is not None else None
        head = self.cursor[1] if self.cursor[0] == "h" else None
        if name in ("up", "down", "top", "bottom"):
            if k == "choice":
                m = len(self._choices(self.open))
                self.pick = {"up": max(0, self.pick - 1), "down": min(m - 1, self.pick + 1),
                             "top": 0, "bottom": m - 1}[name]
                self._try(self.open, self._choices(self.open)[self.pick])
                rt.redrawViews()
            elif k is None:
                items = self._items()
                j = items.index(self.cursor) if self.cursor in items else 0
                j = {"up": max(0, j - 1), "down": min(len(items) - 1, j + 1),
                     "top": 0, "bottom": len(items) - 1}[name]
                self.cursor = items[j]
            return True
        if name in ("in", "deep"):
            if k == "choice":
                self._close(True)
            elif k is None and head is not None:
                self._fold(head, False)
            elif k is None:
                self._open(self.cursor[1])
            return True                          # (a number: the page's field commits)
        if name == "rename":
            if k is None and head is not None:
                self.renaming, self.rename_n = head, self.rename_n + 1
            elif k is None and self._k(self.cursor[1]) in ("int", "float"):
                self._open(self.cursor[1])
            return True
        if name == "out":
            if k is not None:
                self._close(False)
            elif head is None:                   # a setting: shut its section
                sec = self.fields[self.cursor[1]].section
                self.cursor = ("h", sec)
                self._fold(sec, True)
            elif head not in self.shut:
                self._fold(head, True)
            else:
                side.close()
            return True
        return False

    def _fold(self, sec, shut):
        """Open / shut a section — every picked one, if it's picked."""
        for s in (self.picks if sec in self.picks else {sec}):
            (self.shut.add if shut else self.shut.discard)(s)
        self._save()

    def _pick(self, sec, a):
        """Space (alt) / ⌘ (meta) / ⇧ (shift) clicks on heads (browser._pick_click's rules)."""
        secs = self._secs()
        if a.get("shift") and self.anchor in secs:
            i, j = sorted((secs.index(self.anchor), secs.index(sec)))
            self.picks = set(secs[i:j + 1])
            return
        self.anchor = sec
        if a.get("meta"):
            self.picks ^= {sec}
        else:
            self.picks = set() if self.picks == {sec} else {sec}

    def act(self, a):
        """The page: a click on a head (h, with meta / alt / shift) or a row (i) or an open
        drop-down's choice (i + choice), a head's new name (h + name; renamed n), a number
        typed (set), or a cancel (cancel)."""
        if "set" in a:
            self.set_text(a["set"])
        elif a.get("cancel"):
            self._close(False)
        elif "h" in a and "name" in a:
            sec, name = a["h"], str(a["name"]).strip()
            self.renaming = None
            if name and name != sec:
                self.names[sec] = name
            else:
                self.names.pop(sec, None)
            self._save()
        elif "h" in a and a.get("renamed"):          # the page's field closed unchanged
            self.renaming = None
        elif "h" in a:
            sec = a["h"]
            if self.open is not None:
                self._close(False)
            self.cursor = ("h", sec)
            if a.get("meta") or a.get("alt") or a.get("shift"):
                self._pick(sec, a)
            else:
                self.picks = set()
                self._fold(sec, sec not in self.shut)
        elif "choice" in a and self.open == a.get("i"):
            self.pick = int(a["choice"])
            self._close(True)
        elif "i" in a:
            i = int(a["i"])
            if self.open is not None and self.open != i:
                self._close(False)
            self.cursor = ("f", i)
            if self.open != i and self._k(i) != "choice":   # a drop-down: F / Enter opens it
                self._open(i)
            elif self._k(i) == "choice":            # a click on an open drop-down shuts it
                self._close(False)

    def closed(self):
        if self.open is not None:
            self._close(False)
        rt.callbacks.removeScripts(id=rt.Name("callisPanel"))


# Esc in Max while a drop-down is open cancels it. Max's keys don't pass through Qt here,
# so a 40 ms poll of the key (only while one is open, only with Max in front) catches it.
_esc = {"timer": None, "panel": None, "down": True}


def _esc_watch(p):
    import ctypes
    from PySide6.QtCore import QTimer
    _esc["panel"], _esc["down"] = p, True        # a press already down isn't this one
    if _esc["timer"] is None:
        u = ctypes.windll.user32

        def tick():
            q = _esc["panel"]
            if q is None or q.open is None or q._k(q.open) != "choice":
                _esc["timer"].stop()
                _esc["panel"] = None
                return
            down = bool(u.GetAsyncKeyState(0x1B) & 0x8000)
            pid = ctypes.c_ulong()
            u.GetWindowThreadProcessId(u.GetForegroundWindow(), ctypes.byref(pid))
            if down and not _esc["down"] and pid.value == os.getpid():
                q._close(False)
                from . import browser
                browser.publish(now=True)
            _esc["down"] = down
        t = QTimer()
        t.setInterval(40)
        t.timeout.connect(tick)
        _esc["timer"] = t
    _esc["timer"].start()


def _republish(*_):
    from . import browser
    browser.publish()
