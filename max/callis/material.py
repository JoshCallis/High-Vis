"""Materials: Eyedropper and Apply Last Material. Silent always — no dialogs, no HUD
(the user's call, 2026-10-13: a click is its own confirmation).

  last material   the most recently used one: what Eyedropper took, the last material
                  assigned to a node any other way (#mtlRefAdded: Material Editor, drag and
                  drop…), or the one picked in the Browser's Appearances (appearance.py). Not while a file opens / merges / imports, never clean.paint's grey
                  "Default (Callis)". In memory, this session.
  Eyedropper      something selected → the material it wears (all of it one material);
                  nothing selected → pick an object in the viewport (Max's pickObject, Esc
                  or right-click cancels; objects without one usable material can't be
                  picked). No material, a Multi/Sub, a mixed selection → nothing.
  Apply Last      onto the selected geometry and shapes (cameras, lights, helpers, group
                  heads skipped), one undo record; anything that refuses is skipped.
"""
import traceback

import contextlib
import pymxs
from pymxs import runtime as rt

from .clean import DEFAULT_MTL

_last = [None]
_quiet = [0]     # > 0: we are assigning — don't count those
_loading = [False]   # a file opening / merging / importing (a pre without its post is
                     # cleared by the next post of any kind)

_MS = r"""
fn callisMtlOf n = (
    if not (isValidNode n) or isGroupHead n do return undefined
    local sc = superClassOf n
    if sc != GeometryClass and sc != shape do return undefined
    if classOf n == Targetobject do return undefined
    local m = n.material
    if callisDimReal != undefined do m = callisDimReal n    -- through the Browser's dim
    if m == undefined or classOf m == Multimaterial or m.name == "%s" do return undefined
    m
)
fn callisMtlPickable o = callisMtlOf o != undefined
""" % DEFAULT_MTL


def _ms():
    if not hasattr(rt, "callisMtlPickable") or str(rt.callisMtlPickable) == "undefined":
        rt.execute(_MS)


def _usable(m):
    return (m is not None and rt.isValidObj(m) and str(rt.classOf(m)) != "Multimaterial"
            and str(m.name) != DEFAULT_MTL)


def last():
    m = _last[0]
    if isinstance(m, str):                       # a library material picked in Appearances:
        from . import appearance                 # loaded into the scene only when applied
        m = _last[0] = appearance.scene_material(m)
    if m is not None and not rt.isValidObj(m):
        _last[0] = m = None
    return m


def _take(m):
    _last[0] = m


def take_ref(mid):
    """Appearances: a library material picked (its id) — Apply Last loads it when used."""
    _last[0] = mid


def eyedropper():
    try:
        _ms()
        sel = list(rt.selection)
        if sel:
            mats = [rt.callisMtlOf(n) for n in sel if _capable(n)]
            if mats and all(m is not None for m in mats) and \
                    len({rt.getHandleByAnim(m) for m in mats}) == 1:
                _take(mats[0])
            return
        n = rt.pickObject(filter=rt.callisMtlPickable)
        if n is not None and str(n) not in ("undefined", "#escape"):
            m = rt.callisMtlOf(n)
            if m is not None:
                _take(m)
    except Exception:
        traceback.print_exc()


def _capable(n):
    sc = str(rt.superClassOf(n))
    return (sc in ("GeometryClass", "shape") and not rt.isGroupHead(n)
            and str(rt.classOf(n)) != "Targetobject")


def apply_last():
    try:
        m = last()
        if m is None:
            return
        nodes = [n for n in rt.selection if _capable(n)]
        if not nodes:
            return
        _quiet[0] += 1
        try:
            with pymxs.undo(True, "Apply Material"):
                for n in nodes:
                    try:
                        n.material = m
                    except Exception:
                        pass
        finally:
            _quiet[0] -= 1
    except Exception:
        traceback.print_exc()


# ──────────────────────────────────────────────────────────────── watching assignments

def _assigned(*_):
    if _quiet[0] or _loading[0]:
        return
    try:
        m = rt.callbacks.notificationParam()       # the material (also fires as one is made)
        if rt.superClassOf(m) == rt.material and str(m.name) and _usable(m):
            _last[0] = m
    except Exception:
        pass


def _hush(*_):
    _loading[0] = True


def _unhush(*_):
    _loading[0] = False


@contextlib.contextmanager
def paused():
    """Bulk material swaps (the Browser's dim): #mtlRefAdded off altogether — a muted
    Python callback still costs ~0.15 ms an assignment."""
    rt.callbacks.removeScripts(id=rt.Name("callisMaterialRef"))
    try:
        yield
    finally:
        rt.callbacks.addScript(rt.Name("mtlRefAdded"), _assigned, id=rt.Name("callisMaterialRef"))


def install():
    rt.callbacks.removeScripts(id=rt.Name("callisMaterial"))
    rt.callbacks.removeScripts(id=rt.Name("callisMaterialRef"))
    rt.callbacks.addScript(rt.Name("mtlRefAdded"), _assigned, id=rt.Name("callisMaterialRef"))
    for pre, post in (("filePreOpen", "filePostOpen"), ("filePreMerge", "filePostMerge"),
                      ("preImport", "postImport"), ("systemPreReset", "systemPostReset"),
                      ("systemPreNew", "systemPostNew")):
        rt.callbacks.addScript(rt.Name(pre), _hush, id=rt.Name("callisMaterial"))
        rt.callbacks.addScript(rt.Name(post), _unhush, id=rt.Name("callisMaterial"))
