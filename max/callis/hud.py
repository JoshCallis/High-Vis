"""A short message at the bottom middle of the Mac's screen — the SAME HUD the Photoshop
scripts use (../../bin/hud.m, `~/bin/hud show`), so a change to how it looks shows in
both. Max is in the VM, so the message goes as one UDP datagram "<hold ms>\\t<text>" to
the Mac's winlink LaunchAgent (../winlink/winlink.py, 10.211.55.2:27122), which runs
`hud show`. Fire and forget: never raises, never waits."""
import socket

ADDR = ("10.211.55.2", 27122)

_s = None


def show(text, ms=500):
    global _s
    try:
        if _s is None:
            _s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        _s.sendto(("%d\t%s" % (ms, text)).encode("utf-8"), ADDR)
    except OSError:
        pass


def jump():
    """Jump to Name (macro JumpToName): ask the Mac to open its invisible name box for
    Max (winlink → ../../jump/open.sh max); the pick comes back as callis.jump.go."""
    global _s
    try:
        if _s is None:
            _s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        _s.sendto(b"!jump", ADDR)
    except OSError:
        pass


def goto():
    """Go To (macro GoTo, Universal): the Mac's jump box in voice mode + Wispr Flow
    (winlink → ../../jump/goto.sh max); the spoken folder / object comes back as
    callis.jump.go — a folder entered, an object selected."""
    global _s
    try:
        if _s is None:
            _s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        _s.sendto(b"!goto", ADDR)
    except OSError:
        pass
