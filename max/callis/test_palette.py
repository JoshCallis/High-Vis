"""callis.palette — run on the Mac: python3 max/callis/test_palette.py
Ranking is the shared kit's now (fusion_ui/search.js, tested by fusion_value/test/run.py);
this checks Max's half: the key readout, one row per name, and that the vendored kit
still matches fusion_ui/ (max/palette/sync.sh)."""
import filecmp
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
from callis.palette import chord, dedup, keymap  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))


def check(label, got, want):
    ok = got == want
    print(("ok  " if ok else "FAIL"), label, "" if ok else "got %r want %r" % (got, want))
    return ok


DEFAULTS = [("A", "0-1"), ("Ctrl+Shift+S", "0-2"), ("C", "0-3"), ("Num++", "0-4")]
CHANGES = [("Unassign_Hotkey", "C", "0-3"), ("Assign_Hotkey", "C", "647394-Down`B"),
           ("Assign_Hotkey", "Ctrl+Alt+Shift+F4", "647394-In`B"),
           ("Assign_Hotkey", "W", "0-1")]
REACH = {"ctrl+alt+shift+f4": {"kind": "space", "key": "f"}}
km = keymap(DEFAULTS, CHANGES, ["0-1", "0-2", "0-3", "0-4", "647394-Down`B", "647394-In`B"], REACH)

results = [
    check("chord spelling", chord("Ctrl+Shift+S"), "ctrl+shift+s"),
    check("chord modifier order", chord("Shift+Alt+Ctrl+X"), "ctrl+alt+shift+x"),
    check("chord Max key names", chord("Enter"), "return"),
    check("chord Num +", chord("Num++"), "num +"),
    check("default kept", km["0-2"], {"kind": "chord", "seq": "ctrl+shift+s"}),
    check("unassigned dropped", "0-3" in km, False),
    check("assigned", km["647394-Down`B"], {"kind": "chord", "seq": "c"}),
    check("ours shown before the default", km["0-1"], {"kind": "chord", "seq": "w"}),
    check("surrogate → its reach", km["647394-In`B"], {"kind": "space", "key": "f"}),
    check("one row per name", [c["id"] for c in dedup([{"id": "1", "name": "Box"},
                                                       {"id": "2", "name": "box "}])], ["1"]),
]
for f in ("search.js", "search.css", "theme.css", "fingers.js"):
    results.append(check("vendor/%s matches fusion_ui (run max/palette/sync.sh)" % f,
                         filecmp.cmp(os.path.join(ROOT, "fusion_ui", f),
                                     os.path.join(ROOT, "max", "palette", "vendor", f), shallow=False),
                         True))
sys.exit(0 if all(results) else 1)
