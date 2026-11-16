#!/usr/bin/env python3
"""
max_browser/server.py — the 3ds Max Browser window's server (port 8740).

The Fusion windows' servers live inside Fusion. This one can't live inside Max (Max is
in the Parallels VM; the window is a Mac app), so it is a small standalone process on
the Mac between the two:

  Max (callis/browser.py) ── writes ──► max/.state/browser.json  (shared folder)
                                               │  GET /wait?t=<last t>  (long-poll, 25 s)
                                               ▼
                                  this server ◄──── index.{html,css,js}
                                               │  POST /act {op, tok, …}
  Max ◄── bridge (TCP 27120, max/maxctl.py's protocol) ┘

All state — the tree, where you are, what's open, the cursor — is Max's. The page
draws /wait's snapshot and posts what was clicked or typed; Max answers by
re-publishing. The VM's address comes from max/.state/nav.json (callis/nav.py).

Start: `python3 max_browser/server.py` (max_browser/browser.sh does it, idempotent).
"""
import importlib.util
import json
import os
import socket
import struct
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
FUSION_UI = os.path.join(ROOT, "fusion_ui")
MAX_STATE = os.path.join(ROOT, "max", ".state")
SNAPSHOT = os.path.join(MAX_STATE, "browser.json")
NAV = os.path.join(MAX_STATE, "nav.json")
PORT = 8740

_spec = importlib.util.spec_from_file_location("fusion_webwin", os.path.join(FUSION_UI, "webwin.py"))
webwin = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(webwin)


def read_snapshot():
    try:
        with open(SNAPSHOT) as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def bridge(code, timeout=10):
    """Run Python in Max; (ok, result-or-error)."""
    try:
        with open(NAV) as f:
            nav = json.load(f)
        host, port = nav["ip"], int(nav.get("port", 27120))
    except (OSError, ValueError, KeyError):
        return False, "Max isn't running (no max/.state/nav.json)"
    req = json.dumps({"lang": "py", "code": code}).encode("utf-8")
    try:
        with socket.create_connection((host, port), timeout=2) as s:
            s.settimeout(timeout)
            s.sendall(struct.pack(">I", len(req)) + req)
            buf = b""
            while True:
                chunk = s.recv(65536)
                if not chunk:
                    break
                buf += chunk
    except OSError as e:
        return False, "can't reach Max: %s" % e
    (n,) = struct.unpack(">I", buf[:4])
    reply = json.loads(buf[4:4 + n].decode("utf-8"))
    return reply["ok"], reply["result"] if reply["ok"] else reply["error"]


class Handler(webwin.Handler):
    HERE = HERE

    def do_GET(self):
        if self.serve_static():
            return
        if self.route.startswith("/swatch/"):
            # Appearances swatches (callis/appearance.py): only these two folders under max/
            rel = self.route[len("/swatch/"):]
            p = os.path.realpath(os.path.join(ROOT, "max", rel))
            ok = any(p.startswith(os.path.join(ROOT, "max", d) + os.sep)
                     for d in ("materials/thumbs", ".state/swatches"))
            try:
                with open(p, "rb") as f:
                    body = f.read() if ok and p.endswith(".png") else None
            except OSError:
                body = None
            if body is None:
                return self.not_found()
            self.send_response(200)
            self.send_header("Content-Type", "image/png")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "max-age=86400")
            self.end_headers()
            self.wfile.write(body)
        elif self.route == "/state":
            self.send_json(read_snapshot() or {"rows": [], "path": [], "waiting": True})
        elif self.route == "/wait":
            # Long-poll: answer as soon as Max writes a snapshot newer than `t`.
            try:
                since = float(self.path.split("t=", 1)[1].split("&")[0])
            except (IndexError, ValueError):
                since = 0.0
            end = time.time() + 25
            while True:
                s = read_snapshot()
                if s and s.get("t", 0) > since:
                    return self.send_json(s)
                if time.time() > end:
                    return self.send_json(s or {"rows": [], "path": [], "waiting": True})
                time.sleep(0.02)
        else:
            self.not_found()

    def do_POST(self):
        data = self.read_json_body()
        if data is None or self.serve_shared_post(data):
            return
        if self.route == "/act":
            ok, out = bridge("import callis.browser as B; _result = B.act(%r)" % (data,))
            return self.send_json({"ok": ok, "error": None if ok else out})
        self.not_found()


def make():
    return webwin.make_server(PORT, Handler)


if __name__ == "__main__":
    webwin.main("Max Browser", make, PORT)
