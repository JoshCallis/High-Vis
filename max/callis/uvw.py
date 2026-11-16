"""Cycle the topmost UVW Map's axis X → Y → Z on the selection (macro CycleUVWAxis).

Each selected object's highest UVW Map modifier turns one step; an instanced modifier
(shared by several objects) turns once. The first one found sets where the others go, so a
mixed selection ends up on one axis. One undo record; the HUD says the axis.
"""
import pymxs
from pymxs import runtime as rt

from . import hud

AXES = "XYZ"


def _top_uvw(n):
    for m in n.modifiers:                     # top of the stack first
        if str(rt.classOf(m)) == "Uvwmap":
            return m
    return None


def cycle_axis():
    mods, seen = [], set()
    for n in rt.selection:
        m = _top_uvw(n)
        if m is not None and rt.getHandleByAnim(m) not in seen:
            seen.add(rt.getHandleByAnim(m))
            mods.append(m)
    if not mods:
        hud.show("No UVW Map", 900)
        return
    to = (int(mods[0].axis) + 1) % 3
    with pymxs.undo(True, "UVW Axis"):
        for m in mods:
            m.axis = to
    rt.redrawViews()
    hud.show("UVW " + AXES[to], 900)
