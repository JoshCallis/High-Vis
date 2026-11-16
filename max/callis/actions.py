"""Max's action catalog and hotkeys, for Control Room's 3ds Max ▸ Shortcuts page.

    import callis.actions as A
    A.export()                 # → max/.state/actions.json (read by remap/max.py on the Mac)
    A.apply(r"\\\\Mac\\ClaudeMax\\hotkeys\\Callis.hsx")   # copy local + make it Max's keyboard file

Max 2027 hotkeys are two files:
  Default.hsxb   (UI_ln/CUI) every built-in hotkey: <Hotkey Shortcut Id Description/>
  <set>.hsx      the active set — only CHANGES to the defaults:
                 <Assign_Hotkey Shortcut Id/> / <Unassign_Hotkey Shortcut Id/>
An action's Id is "<action table id>-<persistentActionId>" (macroscripts:
"647394-Name`Category"). Hotkeys are per action CONTEXT: one chord can mean
different actions in different contexts (main UI, Edit Poly, Track View…).
Max's own API has no per-action hotkey getter, so defaults + the set are read
from the files here rather than asked of Max.
"""
import json
import os
import re
import shutil
import time
import xml.etree.ElementTree as ET

from pymxs import runtime as rt

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STATE = os.path.join(HERE, ".state")
MACRO_TABLE = 647394


def _defaults_file():
    return os.path.join(str(rt.getDir(rt.Name("maxroot"))), "UI_ln", "CUI", "Default.hsxb")


def _local_ui():
    """Where Max keeps the user's own UI files — a local copy of the set lives here,
    so Max still finds its keyboard file when the Mac share isn't mounted."""
    d = os.path.join(os.environ["LOCALAPPDATA"], "Autodesk", "3dsMax", "2027 - 64bit", "ENU", "en-US", "UI", "Hotkeys")
    os.makedirs(d, exist_ok=True)
    return d


def _hotkeys(path, tags):
    """[(tag, shortcut, id)] from a .hsx/.hsxb file."""
    try:
        root = ET.parse(path).getroot()
    except (OSError, ET.ParseError):
        return []
    return [(el.tag, el.get("Shortcut", ""), el.get("Id", "")) for el in root if el.tag in tags]


def catalog():
    items = []
    for ti in range(1, rt.actionMan.numActionTables + 1):
        t = rt.actionMan.getActionTable(ti)
        if t is None:
            continue
        tid, tname, ctx, cname = int(t.id), str(t.name), int(t.contextID), str(t.contextName)
        for ii in range(1, t.numActionItems + 1):
            it = t.getActionItem(ii)
            if it is None:
                continue
            pid = str(it.persistentActionId)
            name = str(it.description or "").strip() or str(it.buttonText or "").strip() or pid
            items.append({"id": f"{tid}-{pid}", "name": name, "category": str(it.category or ""),
                          "table": tname, "context": ctx, "context_name": cname,
                          "macro": tid == MACRO_TABLE})
    return items


def export(path=None):
    t0 = time.time()
    defaults = {}
    for _, sc, aid in _hotkeys(_defaults_file(), ("Hotkey",)):
        defaults.setdefault(aid, []).append(sc)
    kbd = str(rt.actionMan.getKeyboardFile())
    doc = {
        "ts": int(time.time()), "max": int(rt.maxVersion()[7]),
        "keyboard_file": kbd,
        "items": catalog(),
        "defaults": defaults,
        # The active set's changes, so the Mac can tell when Max is running a set
        # it didn't write (one edited in Max's own Hotkey Editor).
        "active": [list(x) for x in _hotkeys(kbd, ("Assign_Hotkey", "Unassign_Hotkey"))],
    }
    path = path or os.path.join(STATE, "actions.json")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False)
    os.replace(tmp, path)
    return {"items": len(doc["items"]), "defaults": len(defaults), "seconds": round(time.time() - t0, 1),
            "keyboard_file": kbd}


def apply(hsx):
    """Make `hsx` Max's keyboard file, live. Copied local first (see _local_ui)."""
    local = os.path.join(_local_ui(), os.path.basename(hsx))
    shutil.copyfile(hsx, local)
    ok = bool(rt.actionMan.loadKeyboardFile(local))
    return {"ok": ok, "file": local}


def run(action_id):
    """Run one action by its catalog id (what a remapd `run` binding will call)."""
    tid, _, pid = action_id.partition("-")
    return bool(rt.actionMan.executeAction(int(tid), pid))
