#!/usr/bin/env python3
"""Run Python / MAXScript in 3ds Max (Parallels VM) via max/bridge_startup.py.

  maxctl eval '<python>'      expression → its value; statements → set _result
  maxctl run file.py          run a Python file in Max's session namespace
  maxctl ms '<maxscript>'     MAXScript, returns its value
  maxctl shot [out.png]       active viewport → PNG on the Mac (default max/.shots/shot.png)
  maxctl ping                 Max version, or why it can't connect

Code arg '-' reads stdin. Exit status 1 on error (traceback on stderr).
Host: $MAX_HOST, else the VM's IP from prlctl ($MAX_VM, default "Windows 11").
"""
import json
import os
import socket
import struct
import subprocess
import sys

PORT = 27120
HERE = os.path.dirname(os.path.abspath(__file__))
# This folder as seen from Windows: Parallels host shared folder "ClaudeMax".
WIN_HERE = "\\\\Mac\\ClaudeMax"


def host():
    if os.environ.get("MAX_HOST"):
        return os.environ["MAX_HOST"]
    vm = os.environ.get("MAX_VM", "Windows 11")
    out = subprocess.run(["prlctl", "list", "-f", "-o", "ip,name"],
                         capture_output=True, text=True).stdout
    for line in out.splitlines()[1:]:
        ip, _, name = line.strip().partition(" ")
        if name.strip() == vm and ip not in ("-", ""):
            return ip
    sys.exit(f"maxctl: VM {vm!r} not running (prlctl shows no IP)")


def call(lang, code, timeout=120):
    req = json.dumps({"lang": lang, "code": code}).encode("utf-8")
    try:
        s = socket.create_connection((host(), PORT), timeout=5)
    except OSError as e:
        sys.exit(f"maxctl: can't reach Max bridge on port {PORT}: {e}\n"
                 "  Is 3ds Max running with the bridge loaded? See max/CLAUDE.md.")
    with s:
        s.settimeout(timeout)
        s.sendall(struct.pack(">I", len(req)) + req)
        buf = b""
        while True:
            chunk = s.recv(65536)
            if not chunk:
                break
            buf += chunk
    (n,) = struct.unpack(">I", buf[:4])
    return json.loads(buf[4:4 + n].decode("utf-8"))


def report(reply):
    if reply["stdout"]:
        sys.stdout.write(reply["stdout"])
    if not reply["ok"]:
        sys.stderr.write(reply["error"])
        sys.exit(1)
    if reply["result"] is not None:
        print(reply["result"])


def shot(out):
    win = WIN_HERE + "\\.shots\\_shot.png"
    os.makedirs(os.path.join(HERE, ".shots"), exist_ok=True)
    # A Qt grab of the viewport window, not gw.getViewportDib(): that redraws first
    # and comes back black with Nitrous antialiasing off (the clean look).
    code = ("from PySide6 import QtWidgets\n"
            "QtWidgets.QApplication.processEvents()\n"
            "QtWidgets.QApplication.primaryScreen().grabWindow("
            f"int(rt.viewport.getHWnd())).save({win!r})\n")
    reply = call("py", code)
    if not reply["ok"]:
        report(reply)
    os.replace(os.path.join(HERE, ".shots", "_shot.png"), out)
    print(out)


def main(argv):
    if len(argv) < 2 or argv[1] in ("-h", "--help"):
        sys.exit(__doc__)
    cmd, args = argv[1], argv[2:]
    arg = (sys.stdin.read() if args and args[0] == "-" else args[0]) if args else None
    if cmd == "ping":
        report(call("ms", "(maxVersion()) as string", timeout=10))
    elif cmd == "eval" and arg is not None:
        report(call("py", arg))
    elif cmd == "ms" and arg is not None:
        report(call("ms", arg))
    elif cmd == "run" and arg is not None:
        with open(arg) as f:
            report(call("py", f.read()))
    elif cmd == "shot":
        shot(os.path.abspath(arg) if arg else os.path.join(HERE, ".shots", "shot.png"))
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv)
