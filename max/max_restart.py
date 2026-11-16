#!/usr/bin/env python3
"""max_restart — restart 3ds Max (Parallels VM) with the same scene open.

The 3ds Max half of Control Room's "Restart app" (F13, remap/restart/app_restart.sh;
the Fusion half is ~/bin/fusion-restart). Through the bridge (maxctl): save the scene
if it has a file and unsaved changes — an untitled scene with changes is HELD
(holdMaxFile) instead — then quitMax #noPrompt; wait for Max to go; reopen it
through its Coherence stub (as app_resolve.sh open_coherence does); once the
bridge answers again, load the scene (or fetch the hold).

Log: ~/Library/Logs/max-restart.log. Exit 0 ok, 1 aborted (nothing done), 2 partial.
"""
import json
import os
import socket
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import maxctl  # noqa: E402

LOG = os.path.expanduser("~/Library/Logs/max-restart.log")
LOCK = "/tmp/max-restart.lock"
APP = "3ds Max 2027"
STUB_CACHE = "/tmp/.coherence_stub_3ds_Max_2027"   # app_resolve.sh's cache
QUIT_TIMEOUT = 90     # s for Max to be gone after quitMax
READY_TIMEOUT = 420   # s for the bridge to answer after relaunch
VEIL_HOLD = "/tmp/.max_veil_hold"
SETTLE = 6.0          # s after the bridge answers: callis.startup's delayed steps


def log(msg):
    line = time.strftime("%Y-%m-%d %H:%M:%S  ") + msg
    try:
        with open(LOG, "a") as f:
            f.write(line + "\n")
    except OSError:
        pass
    print(line, flush=True)


def notify(msg):
    subprocess.run(["osascript", "-e", 'display notification %s with title "3ds Max restart"'
                    % ('"' + msg.replace('"', "'") + '"')], capture_output=True)


def ms(code, timeout=60, lang="ms"):
    """MAXScript (or lang="py") through the bridge → (ok, result-or-error). Never exits."""
    try:
        r = maxctl.call(lang, code, timeout=timeout)
    except SystemExit as e:          # maxctl.call exits when it can't connect
        return False, str(e)
    except (OSError, ValueError) as e:
        return False, repr(e)
    return (True, r["result"]) if r["ok"] else (False, r["error"])


def bridge_up(ip):
    try:
        socket.create_connection((ip, maxctl.PORT), timeout=2).close()
        return True
    except OSError:
        return False


def stub_path():
    try:
        p = open(STUB_CACHE).read().strip()
        if p and os.path.exists(p):
            return p
    except OSError:
        pass
    out = subprocess.run(["mdfind", "-onlyin", os.path.expanduser("~/Applications (Parallels)"),
                          "kMDItemDisplayName == '%s'" % APP],
                         capture_output=True, text=True).stdout.split("\n")[0].strip()
    return out or None


def stub_running(stub):
    # Not pgrep: the path's ( ) { } would be read as a regex.
    ps = subprocess.run(["ps", "-axo", "command"], capture_output=True, text=True).stdout
    return bool(stub) and (stub + "/Contents/MacOS/") in ps


def main():
    import fcntl
    lock = open(LOCK, "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        log("already restarting — ignored")
        return 1

    log("=== restart requested")
    ip = maxctl.host()
    ok, info = ms("__import__('json').dumps([rt.maxFilePath + rt.maxFileName, rt.getSaveRequired()])",
                  lang="py")
    if not ok:
        log("bridge not answering: %s" % info)
        notify("3ds Max's bridge is not answering — restart cancelled")
        return 1
    path, dirty = json.loads(info)
    log("scene %r dirty=%s" % (path or "(untitled)", dirty))

    held = False
    if dirty and path:
        ok, err = ms("saveMaxFile (maxFilePath + maxFileName) quiet:true", timeout=600)
        if not ok or err == "false":
            log("save failed: %s" % err)
            notify("Couldn't save the scene — restart cancelled")
            return 1
        log("saved")
    elif dirty:
        ok, err = ms("holdMaxFile()", timeout=600)
        if not ok:
            log("hold failed: %s" % err)
            notify("Couldn't hold the untitled scene — restart cancelled")
            return 1
        held = True
        log("untitled scene held")

    stub = stub_path()
    # The stub veils Max's windows from "quitting" (notitle/notitle.m); the hold keeps
    # that veil — and the next stub's — up until the scene is back.
    open(VEIL_HOLD, "w").close()
    try:
        return quit_and_relaunch(stub, ip, held, path)
    finally:
        try:
            os.remove(VEIL_HOLD)
        except OSError:
            pass


def lift_veil():
    """Max didn't quit: lift the quitting veil now (notitle's own backstop is 60 s)."""
    try:
        os.remove(VEIL_HOLD)
    except OSError:
        pass
    subprocess.run(["osascript", "-l", "JavaScript", "-e",
                    "ObjC.import('Foundation'); $.NSDistributedNotificationCenter.defaultCenter"
                    ".postNotificationNameObjectUserInfoDeliverImmediately('com.callis.maxveil.lift', $(), $(), true)"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def quit_and_relaunch(stub, ip, held, path):
    # Quit on a timer so this bridge call returns before Max starts closing.
    ms("import callis.startup as _s; _s._phase('quitting')\n"
       "from PySide6.QtCore import QTimer\n"
       "QTimer.singleShot(300, lambda: rt.quitMax(rt.Name('noPrompt')))", lang="py")
    log("quit sent")
    t0 = time.time()
    while time.time() - t0 < QUIT_TIMEOUT:
        if not bridge_up(ip) and not stub_running(stub):
            break
        time.sleep(1)
    else:
        log("Max still up after %ds" % QUIT_TIMEOUT)
        notify("3ds Max didn't quit — see the log")
        lift_veil()
        return 2
    log("Max gone after %.0fs" % (time.time() - t0))
    time.sleep(2)

    if not stub:
        notify("Couldn't find the 3ds Max app to relaunch")
        return 2
    return relaunch(stub, ip, held, path)


def relaunch(stub, ip, held, path):
    subprocess.run(["open", stub])
    log("relaunched")
    # Max reopens un-fullscreened on whatever desktop is shown (over a slot):
    # put it back on its own full-screen Space once its window is up.
    subprocess.Popen([os.path.join(os.path.dirname(os.path.abspath(__file__)), "coherence_fullscreen.sh"),
                      APP, str(READY_TIMEOUT)], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                     stderr=subprocess.DEVNULL, start_new_session=True)
    t0 = time.time()
    while time.time() - t0 < READY_TIMEOUT:
        if bridge_up(ip) and ms("1")[0]:
            break
        time.sleep(2)
    else:
        log("bridge never answered after relaunch")
        notify("3ds Max restarted but its bridge never answered — scene not reopened")
        return 2
    log("bridge up after %.0fs" % (time.time() - t0))
    time.sleep(SETTLE)

    if held:
        ok, err = ms("fetchMaxFile quiet:true", timeout=900)
    elif path:
        ok, err = ms("loadMaxFile %s quiet:true" % json.dumps(path, ensure_ascii=False), timeout=900)
    else:
        ok, err = True, None
    if not ok or err == "false":
        log("reopen failed: %s" % err)
        notify("3ds Max restarted, but the scene didn't reopen — see the log")
        return 2
    log("done")
    return 0


if __name__ == "__main__":
    sys.exit(main())
