#!/usr/bin/python3 -S
"""winlink.py — the Mac end of max/winlink (README.md there). LaunchAgent com.josh.winlink.

Windows' agent (winlink.cs, in the VM) dials in on 10.211.55.2:27121 — the host's
Parallels address only, never the LAN. One connection, lines:
  agent → "text 0|1"        → Karabiner variable vm_text_field (one resident
                               karabiner_cli --set-variables-from-stdin: no 90 ms spawn)
  agent → "dialog 0|1"      → Karabiner variable vm_dialog (bindings with "dialog": true)
  agent → "re <id> <what>"  → the answer to a local command
Local commands come in on /tmp/winlink.sock, one line each, answered with one line:
  printf 'explorer\\n' | nc -U -w 5 /tmp/winlink.sock    → "raised <hwnd>" | "opened <hwnd>"
  "status" → "up" / "down" without asking Windows. No agent → "down".
HUD relay: UDP datagrams "<hold ms>\\t<text>" on 10.211.55.2:27122 (3ds Max's callis/hud.py)
  → ~/bin/hud's resident (/tmp/hud.sock; `hud show` starts it) — the same HUD the
  Photoshop scripts use. The datagram "!jump" instead opens Jump to Name for Max
  (../../jump/open.sh max — the invisible name box, on the Mac).
"""
import itertools, json, os, socket, subprocess, threading, time

HOST, PORT = "10.211.55.2", 27121
HUD_PORT = 27122
HUD = os.path.expanduser("~/bin/hud")
HUD_SOCK = "/tmp/hud.sock"           # hud.m's resident
GOTO = "/Users/josh/Code/Scripts/jump/goto.sh"   # "!goto": Go To (voice)
JUMP = "/Users/josh/Code/Scripts/jump/open.sh"   # "!jump" on the HUD port: Jump to Name
LOCAL = "/tmp/winlink.sock"
KCLI = "/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"
VAR = "vm_text_field"
VM_TEXT_FILE = "/tmp/vm_text_field"   # the same, for remapd (trackpad per-situation keys)
DIALOG_VAR = "vm_dialog"         # a modal dialog in front: D / F are Left / Right
LOG = "/tmp/winlink.log"
TIMEOUT = 6.0

lock = threading.Lock()
agent = None                    # the connected agent's socket
pending = {}                    # id → [Event, answer]
ids = itertools.count(1)
kcli = None


def log(msg):
    with open(LOG, "a") as f:
        f.write("[%s] %s\n" % (time.strftime("%H:%M:%S"), msg))


def set_text(v, var=VAR):
    """vm_text_field (or `var`) = v, through the one karabiner_cli kept open."""
    global kcli
    if var == VAR:                  # remapd's twin: /tmp/vm_text_field exists = typing (auxValue)
        try:
            if v: open(VM_TEXT_FILE, "w").close()
            else: os.unlink(VM_TEXT_FILE)
        except OSError:
            pass
    line = json.dumps({var: v}) + "\n"
    for _ in range(2):
        try:
            if kcli is None or kcli.poll() is not None:
                kcli = subprocess.Popen([KCLI, "--set-variables-from-stdin"], stdin=subprocess.PIPE,
                                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, text=True)
            kcli.stdin.write(line)
            kcli.stdin.flush()
            return
        except (OSError, ValueError) as e:
            log("karabiner_cli: %r" % e)
            kcli = None


def serve_agent():
    global agent
    while True:
        try:
            srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            srv.bind((HOST, PORT))          # bridge100 exists only while Parallels runs
            srv.listen(2)
            break
        except OSError:
            srv.close()
            time.sleep(5)
    log("listening on %s:%d" % (HOST, PORT))
    while True:
        conn, addr = srv.accept()
        conn.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        conn.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
        with lock:
            old, agent = agent, conn
        if old is not None:
            try: old.close()
            except OSError: pass
        threading.Thread(target=read_agent, args=(conn, addr), daemon=True).start()


def read_agent(conn, addr):
    global agent
    log("agent connected from %s" % addr[0])
    try:
        for raw in conn.makefile("r", encoding="utf-8", errors="replace"):
            line = raw.strip()
            if line.startswith("text "):
                set_text(1 if line[5:] == "1" else 0)
                log(line)
            elif line.startswith("dialog "):
                set_text(1 if line[7:] == "1" else 0, DIALOG_VAR)
                log(line)
            elif line.startswith("re "):
                _, rid, ans = (line.split(" ", 2) + [""])[:3]
                with lock:
                    p = pending.get(rid)
                if p:
                    p[1] = ans
                    p[0].set()
            elif line.startswith("hello"):
                log("agent: " + line)
    except OSError:
        pass
    with lock:
        if agent is conn:
            agent = None
    set_text(0)                     # no agent, no text field: Explorer's keys stay live
    set_text(0, DIALOG_VAR)         # ...and D / F stay letters
    log("agent gone")


def ask(cmd):
    with lock:
        conn = agent
    if conn is None:
        return "down"
    rid = str(next(ids))
    p = pending[rid] = [threading.Event(), "timeout"]
    try:
        conn.sendall(("%s %s\n" % (rid, cmd)).encode())
        p[0].wait(TIMEOUT)
    except OSError:
        p[1] = "down"
    finally:
        pending.pop(rid, None)
    return p[1]


def serve_local():
    try: os.unlink(LOCAL)
    except OSError: pass
    srv = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    srv.bind(LOCAL)
    os.chmod(LOCAL, 0o600)
    srv.listen(8)
    while True:
        conn, _ = srv.accept()
        threading.Thread(target=local_one, args=(conn,), daemon=True).start()


def local_one(conn):
    try:
        conn.settimeout(TIMEOUT + 1)
        cmd = conn.makefile("r").readline().strip()
        if cmd == "status":
            ans = "up" if agent is not None else "down"
        elif cmd:
            t0 = time.time()
            ans = ask(cmd)
            log("%s → %s (%.0f ms)" % (cmd, ans, (time.time() - t0) * 1000))
        else:
            ans = ""
        conn.sendall((ans + "\n").encode())
    except OSError:
        pass
    finally:
        conn.close()


def serve_hud():
    while True:
        try:
            srv = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            srv.bind((HOST, HUD_PORT))
            break
        except OSError:
            srv.close()
            time.sleep(5)
    out = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
    while True:
        try:
            data, _ = srv.recvfrom(2048)
            if data == b"!jump":             # Max's Jump to Name macro (callis/hud.py jump())
                subprocess.Popen([JUMP, "max"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                continue
            if data == b"!goto":             # Max's Go To macro (callis/hud.py goto())
                subprocess.Popen([GOTO, "max"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                continue
            ms, _, text = data.decode("utf-8", "replace").partition("\t")
            if not text:
                continue
            # Straight to the resident's socket (hud.m's own "<pos>\t<ms>\t<text>"): the
            # move tool streams a reading per frame, and a `hud show` per datagram is a
            # spawn storm. Only when no resident answers does `hud show` start one.
            try:
                out.sendto(("bottom\t%d\t%s" % (int(ms or 0), text)).encode()[:1023], HUD_SOCK)
            except (OSError, ValueError):
                subprocess.Popen([HUD, "show", text, "--ms", ms or "0"],
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except OSError:
            pass


if __name__ == "__main__":
    set_text(0)
    set_text(0, DIALOG_VAR)
    threading.Thread(target=serve_agent, daemon=True).start()
    threading.Thread(target=serve_hud, daemon=True).start()
    serve_local()
