"""3ds Max bridge — lets Claude Code on the Mac run Python / MAXScript in this Max.

Loaded at Max startup by max/install/claude_bridge.ms (copied into the user
startup folder). Lives on the Mac; Windows reads it via \\Mac\\ClaudeMax.

Protocol (TCP, PORT): request and reply are each a 4-byte big-endian length
followed by UTF-8 JSON.
  request:  {"lang": "py" | "ms", "code": "..."}
  reply:    {"ok": bool, "result": str|null, "stdout": str, "error": str|null}
  {"lang": "nav", ...} frames (bin/reanchor.m's trackpad zoom stream) get no reply and
  leave the socket open for more — see callis/nav.py.

QTcpServer lives on Max's main thread, so every job runs on the main thread
(pymxs is not thread-safe) — no worker threads, no queue.
"""
import contextlib
import io
import json
import struct
import traceback

import pymxs
from pymxs import runtime as rt
from PySide6.QtCore import QObject
from PySide6.QtNetwork import QHostAddress, QNetworkInterface, QTcpServer

PORT = 27120
SUBNET = "10.211.55."          # Parallels shared network
ALLOWED_PEERS = {"10.211.55.2", "127.0.0.1"}   # the Mac host, and local tests

# One namespace for the life of the session, so variables persist between calls.
NS = {"pymxs": pymxs, "rt": rt, "__name__": "__claude__"}


def _run(lang, code):
    out = io.StringIO()
    reply = {"ok": True, "result": None, "stdout": "", "error": None}
    try:
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(out):
            if lang == "ms":
                value = rt.execute(code)
            else:
                try:
                    compiled = compile(code, "<claude>", "eval")
                except SyntaxError:
                    compiled = None
                if compiled is not None:
                    value = eval(compiled, NS)
                else:
                    exec(compile(code, "<claude>", "exec"), NS)
                    value = NS.pop("_result", None)
        reply["result"] = None if value is None else str(value)
    except Exception:
        reply["ok"] = False
        reply["error"] = traceback.format_exc()
    reply["stdout"] = out.getvalue()
    return reply


class Bridge(QObject):
    def __init__(self):
        super().__init__()
        self.server = QTcpServer(self)
        self.buffers = {}
        self.busy, self.gone = set(), set()      # sockets mid-job / disconnected mid-job
        addr = self._bind_address()
        if not self.server.listen(addr, PORT):
            print(f"[claude bridge] listen failed on {addr.toString()}:{PORT}: "
                  f"{self.server.errorString()}")
            return
        self.server.newConnection.connect(self._accept)
        print(f"[claude bridge] listening on {addr.toString()}:{PORT}")

    @staticmethod
    def _bind_address():
        for a in QNetworkInterface.allAddresses():
            if a.toString().startswith(SUBNET):
                return a
        return QHostAddress(QHostAddress.SpecialAddress.Any)

    def _accept(self):
        while self.server.hasPendingConnections():
            sock = self.server.nextPendingConnection()
            peer = sock.peerAddress().toString().replace("::ffff:", "")
            if peer not in ALLOWED_PEERS:
                sock.abort()
                continue
            self.buffers[sock] = b""
            sock.readyRead.connect(lambda s=sock: self._read(s))
            sock.disconnected.connect(lambda s=sock: self._drop(s))

    def _read(self, sock):
        # A "nav" frame (reanchor's trackpad stream, callis/nav.py) gets no reply and
        # keeps the socket open; frames that arrived together are handled as one batch.
        # Anything else is the one-shot request/reply above.
        buf = self.buffers.get(sock, b"") + bytes(sock.readAll())
        nav = []
        while len(buf) >= 4:
            (n,) = struct.unpack(">I", buf[:4])
            if len(buf) < 4 + n:
                break
            frame, buf = buf[4:4 + n], buf[4 + n:]
            try:
                req = json.loads(frame.decode("utf-8"))
            except ValueError:
                req = {}
            if req.get("lang") == "nav":
                nav.append(req)
                continue
            self.buffers[sock] = b""
            # A job can outlive its client (maxctl timed out while a modal dialog held
            # the job): the disconnect arrives mid-job, through the dialog's event loop.
            # _drop then leaves the socket alone; writing the reply to a deleted socket
            # crashed Max (twice, 2026-10-12).
            self.busy.add(sock)
            try:
                reply = _run(req.get("lang", "py"), req.get("code", ""))
            except Exception:
                reply = {"ok": False, "result": None, "stdout": "",
                         "error": traceback.format_exc()}
            self.busy.discard(sock)
            if sock in self.gone:
                self.gone.discard(sock)
                self._drop(sock)
                return
            data = json.dumps(reply).encode("utf-8")
            sock.write(struct.pack(">I", len(data)) + data)
            sock.flush()
            sock.disconnectFromHost()
            return
        self.buffers[sock] = buf
        if nav:
            try:
                import callis.nav
                callis.nav.handle(nav)
            except Exception:
                traceback.print_exc()

    def _drop(self, sock):
        if sock in self.busy:          # mid-job: _read drops it when the job ends
            self.gone.add(sock)
            return
        self.buffers.pop(sock, None)
        sock.deleteLater()


def start():
    # Re-running the file (e.g. after an edit) replaces the old server cleanly.
    import builtins
    # The reload itself usually ARRIVES through the old server, inside its _read: drop
    # the last reference to it then and Python frees it — and its socket — mid-call,
    # which crashed Max (2026-10-10). So it only stops listening and is kept alive.
    prev = getattr(builtins, "_claude_bridge", None)
    if prev is not None:
        prev.server.close()
        builtins.__dict__.setdefault("_claude_bridge_retired", []).append(prev)
    builtins._claude_bridge = Bridge()


start()
