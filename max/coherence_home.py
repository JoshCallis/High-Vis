#!/usr/bin/env python3
"""coherence_home.py — keep every Windows window on its Coherence app's own Space.

Parallels puts a NEW Coherence window (a dialog, the Arnold RenderView, a nag) on
whatever Mac Space is active when it appears; a Qt window sitting over Max's
viewport in Windows then freezes that patch of the main window. This sweep moves
each stray back to the app's full-screen Space (~50 ms, no Accessibility).

yabai's CLI refuses `window --space <fullscreen space>`, but that is a CLI check:
the scripting addition's SA_OPCODE_WINDOW_TO_SPACE (0x13) calls
SLSMoveWindowsToManagedSpace directly, so we send it ourselves (yabai 7.1.22
framing: int16 len = 1+8+4, opcode, uint64 sid, uint32 wid, little-endian; 1-byte ack).

Home of a stub app = Space of its main window (biggest, on one Space, >= a quarter
of the screen), only if that Space is full screen (otherwise coherence_fullscreen.sh
heals it first). VM-helper ("Windows 11": Settings, Photos, toasts) windows go to
the home of the last-flipped stub (/tmp/.coherence_last), else any home.
Triggers: yabai window_created signal, slotd coherence_flip, coherence_fullscreen.sh.
"""
import json, os, socket, struct, subprocess, sys, time

BIN = os.path.expanduser("~/bin")
SOCK = "/tmp/yabai-sa_%s.socket" % os.environ.get("USER", "josh")
LAST = "/tmp/.coherence_last"
LOG = "/tmp/slots.log"
OP_WINDOW_TO_SPACE = 0x13


def log(msg):
    try:
        with open(LOG, "a") as f:
            f.write("[%s] [coherence_home] %s\n" % (time.strftime("%H:%M:%S"), msg))
    except OSError:
        pass


def query():
    r = subprocess.run([BIN + "/space_query", "json", "--all"], capture_output=True, text=True, timeout=3)
    return json.loads(r.stdout)


def pid_kinds():
    """pid → 'stub' | 'vm' for every WinAppHelper process."""
    out = subprocess.run(["ps", "-axo", "pid=,comm="], capture_output=True, text=True).stdout
    kinds = {}
    for ln in out.splitlines():
        pid, _, cmd = ln.strip().partition(" ")
        if not cmd.rstrip().endswith("/WinAppHelper"):
            continue
        kinds[int(pid)] = "vm" if "/Parallels/" in cmd and ".pvm/" in cmd else "stub"
    return kinds


def sa_move(wid, sid):
    msg = struct.pack("<BQI", OP_WINDOW_TO_SPACE, sid, wid)
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.settimeout(2)
    try:
        s.connect(SOCK)
        s.sendall(struct.pack("<h", len(msg)) + msg)
        s.recv(1)
    finally:
        s.close()


def sweep():
    j = query()
    kinds = pid_kinds()
    fs = {s["id"] for s in j["spaces"] if s.get("fullscreen") == 1}
    quarter = 3440 * 1440 / 4
    wins = [w for w in j["windows"] if w["pid"] in kinds]

    home = {}                                   # stub pid → full-screen sid
    for pid in {w["pid"] for w in wins if kinds[w["pid"]] == "stub"}:
        mains = [w for w in wins if w["pid"] == pid and len(w["spaces"]) == 1 and w["w"] * w["h"] >= quarter]
        if mains:
            sid = max(mains, key=lambda w: w["w"] * w["h"])["spaces"][0]
            if sid in fs:
                home[pid] = sid
    if not home:
        return 0
    try:
        last = int(open(LAST).read().strip())
    except (OSError, ValueError):
        last = None
    vm_home = home.get(last) or next(iter(home.values()))

    moved = 0
    for w in wins:
        if len(w["spaces"]) != 1:               # offscreen/minimised, or sticky on all
            continue
        want = vm_home if kinds[w["pid"]] == "vm" else home.get(w["pid"])
        if want is None or w["spaces"][0] == want:
            continue
        try:
            sa_move(w["id"], want)
        except OSError as e:
            log("SA move of wid %s failed: %s" % (w["id"], e))
            continue
        moved += 1
        log("%s wid %s: space %s → %s" % (w["app"], w["id"], w["spaces"][0], want))
    if moved:
        time.sleep(0.15)
        left = [w["id"] for w in query()["windows"] if w["id"] in {x["id"] for x in wins}
                and len(w["spaces"]) == 1 and w["spaces"][0] not in fs]
        if left:
            log("still off the full-screen Space after SA move: %s" % left)
    return moved


if __name__ == "__main__":
    try:
        n = sweep()
    except (OSError, subprocess.SubprocessError, ValueError, KeyError) as e:
        log("sweep failed: %r" % e)
        sys.exit(1)
    print("moved %d" % n)
