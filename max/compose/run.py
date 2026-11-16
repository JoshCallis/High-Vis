"""Process render jobs: prepare passes + mattes, then build the PSB in Photoshop.

    .venv/bin/python -m compose.run                 # every job waiting in the queue
    .venv/bin/python -m compose.run "<render folder>"   # one folder directly
        [--no-ps] prepare only · [--patch] paste _region/ first · [--undo] undo the last patch first

Max drops a job file (the render folder's Windows path) into the queue after each
render with "Build Photoshop file" ticked, and after every "Region only" render
({"patch": "_region"} — compose.patch pastes it into the full render first).
launchd/com.callis.compose.plist runs this whenever the queue changes.

Photoshop: no PSB yet → build.jsx makes one. A PSB already there → update_links.jsx
refreshes its linked passes; it is never rebuilt over your edits.
"""
import json
import os
import subprocess
import sys
import time

from . import patch as patch_mod
from . import prepare

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUILD_JSX = os.path.join(ROOT, "compose", "photoshop", "build.jsx")
UPDATE_JSX = os.path.join(ROOT, "compose", "photoshop", "update_links.jsx")
LOG = os.path.join(ROOT, ".queue", "compose.log")


def _config():
    with open(os.path.join(ROOT, "config.json"), encoding="utf-8") as f:
        return json.load(f)


def local_path(win_path, cfg):
    for win, mac in cfg["path_maps"]:
        if win_path.lower().startswith(win.lower()):
            rest = win_path[len(win):].replace("\\", "/").lstrip("/")
            return os.path.join(mac, rest)
    return win_path.replace("\\", "/")


def log(msg):
    os.makedirs(os.path.dirname(LOG), exist_ok=True)
    line = time.strftime("%H:%M:%S ") + msg
    print(line)
    with open(LOG, "a", encoding="utf-8") as f:
        f.write(line + "\n")


def _photoshop(jsx, arg):
    script = (f'tell application id "com.adobe.Photoshop" to do javascript '
              f'(file (POSIX file "{jsx}")) with arguments {{"{arg}"}}')
    r = subprocess.run(["osascript", "-e", "with timeout of 3600 seconds", "-e", script,
                        "-e", "end timeout"], capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(r.stderr.strip())
    out = r.stdout.strip()
    if out in ("no plan", "no psb"):     # the script never got its argument
        raise RuntimeError(f"Photoshop got no file to work on ({out})")
    return out


def process(folder, photoshop=True, patch=None):
    t0 = time.time()
    if patch:
        log(patch_mod.patch(folder))
    plan = prepare.prepare(folder)
    if photoshop:
        if os.path.exists(plan["psb"]):
            log(_photoshop(UPDATE_JSX, plan["psb"]))
        else:
            log(_photoshop(BUILD_JSX, os.path.join(folder, "ps", "plan.json")))
    log(f"{folder} done in {time.time() - t0:.1f} s")


def drain():
    cfg = _config()
    q = os.path.join(ROOT, cfg["queue_local"])
    os.makedirs(q, exist_ok=True)
    for name in sorted(f for f in os.listdir(q) if f.endswith(".job")):
        path = os.path.join(q, name)
        try:
            with open(path, encoding="utf-8") as f:
                job = json.load(f)
            os.remove(path)
            folder = local_path(job["folder"], cfg)
            log(f"job {name}: {folder}")
            process(folder, job.get("photoshop", True), job.get("patch"))
        except Exception as e:   # logged; the next job still runs
            log(f"job {name} failed: {e}")


if __name__ == "__main__":
    if len(sys.argv) > 1:
        # --undo: put back the files from before the last region patch, then refresh.
        # A failure is logged like a queued job's, so Control Room can show it.
        try:
            if "--undo" in sys.argv:
                patch_mod.undo(sys.argv[1])
                log(f"{sys.argv[1]}: region patch undone")
            process(sys.argv[1], photoshop="--no-ps" not in sys.argv,
                    patch=patch_mod.REGION_DIR if "--patch" in sys.argv else None)
        except Exception as e:
            log(f"{sys.argv[1]} failed: {e}")
            sys.exit(1)
    else:
        drain()
