"""Scene helpers: node lookup, cameras, layers, and switching to a view (shot)."""
import contextlib

import pymxs
from pymxs import runtime as rt


def handle(n):
    """A node's handle. Not n.handle: a Teapot's own `handle` parameter shadows it."""
    return int(n.inode.handle)


def node(h):
    if not h:
        return None
    n = rt.maxOps.getNodeByHandle(h)
    return n if n is not None and rt.isValidNode(n) else None


def cameras():
    """All scene cameras (not targets), sorted by name."""
    return sorted((c for c in rt.cameras if rt.superClassOf(c) == rt.camera),
                  key=lambda c: str(c.name).lower())


def layers():
    return [rt.LayerManager.getLayer(i) for i in range(rt.LayerManager.count)]


def layer_nodes(layer):
    return [n for n in rt.refs.dependents(layer.layerAsRefTarg) if rt.isValidNode(n)]


def _is_light(n):
    return rt.superClassOf(n) == rt.light


def _set_shown(n, shown):
    """Show/hide for rendering. Lights are switched off rather than hidden —
    V-Ray renders hidden lights by default."""
    if _is_light(n):
        for prop in ("on", "enabled"):
            if rt.isProperty(n, prop):
                rt.setProperty(n, prop, shown)
                return
    n.isHidden = not shown


# ── Shot poses ──────────────────────────────────────────────────────────────
# A per-shot object keeps one transform per shot (project.poses). Switching shots
# stores where the per-shot objects are now under the outgoing shot, then moves them
# to the incoming shot's pose — so moving something while in a shot is all it takes
# to change that shot. Nothing is keyed: the timeline stays free for real animation.
# Poses are read and written at animationRange.start with Auto Key off, so an
# animated per-shot object has its whole track offset, not a key added.

def _local(n):
    m = n.transform
    if n.parent is not None:
        m = m * rt.inverse(n.parent.transform)
    return [c for row in (m.row1, m.row2, m.row3, m.row4) for c in (row.x, row.y, row.z)]


def _set_local(n, vals):
    rows = [rt.Point3(*vals[i:i + 3]) for i in range(0, 12, 3)]
    m = rt.Matrix3(*rows)
    if n.parent is not None:
        m = m * n.parent.transform
    n.transform = m


def _depth(n):
    d = 0
    while n.parent is not None:
        n, d = n.parent, d + 1
    return d


def _pose_nodes(project):
    """(handle key, node) for every live per-shot object, parents before children."""
    found = [(k, node(int(k))) for k in project.poses]
    found = [(k, n) for k, n in found if n is not None]
    return sorted(found, key=lambda kn: _depth(kn[1]))


@contextlib.contextmanager
def _at_rest():
    """Reading/writing poses: at the start of the range, Auto Key off."""
    with pymxs.animate(False), pymxs.attime(rt.animationRange.start):
        yield


def capture(project):
    """Store where every per-shot object is now under the active shot. Drops poses of
    deleted objects and of deleted shots."""
    ids = {v.id for v in project.views}
    for k in [k for k in project.poses if node(int(k)) is None]:
        del project.poses[k]
    if project.active not in ids:
        return
    with _at_rest():
        for k, n in _pose_nodes(project):
            poses = project.poses[k]
            for sid in [s for s in poses if s not in ids]:
                del poses[sid]
            poses[project.active] = _local(n)


def make_per_shot(project, nodes):
    """Each node gets its current transform as its pose in every shot (from here on,
    moving it only changes the shot you're in)."""
    if project.active not in {v.id for v in project.views} and project.views:
        project.active = project.views[0].id    # never switched yet: the scene is "shot 1"
    with _at_rest():
        for n in nodes:
            here = _local(n)
            poses = project.poses.setdefault(str(handle(n)), {})
            for v in project.views:
                poses.setdefault(v.id, list(here))


@contextlib.contextmanager
def reparenting():
    """Around anything that re-parents nodes (the Browser's groups: group / ungroup /
    attach / detach). Poses are parent-relative, so a per-shot object that changes parent
    keeps each shot's WORLD placement: local × old parent, then × inverse new parent (the
    parents' transforms as they are now — a group head is never per-shot). Writes into the
    caller's undo record; the Shots panel's live project is the one edited when it's open."""
    from . import project as P
    try:
        from . import ui
        live = getattr(getattr(ui, "_panel", None), "project", None)
    except Exception:
        live = None
    proj = live or P.load()
    if not proj.poses:
        yield
        return
    capture(proj)
    with _at_rest():
        before = {}
        for k, n in _pose_nodes(proj):
            p = n.parent
            before[k] = (None if p is None else handle(p),
                         rt.Matrix3(1) if p is None else rt.copy(p.transform))
    yield
    changed = False
    with _at_rest():
        for k, (old_h, old_m) in before.items():
            n = node(int(k))
            if n is None:
                continue
            p = n.parent
            if (None if p is None else handle(p)) == old_h:
                continue
            new_inv = rt.Matrix3(1) if p is None else rt.inverse(p.transform)
            for sid, vals in proj.poses[k].items():
                rows = [rt.Point3(*vals[i:i + 3]) for i in range(0, 12, 3)]
                m = rt.Matrix3(*rows) * old_m * new_inv
                proj.poses[k][sid] = [c for row in (m.row1, m.row2, m.row3, m.row4)
                                      for c in (row.x, row.y, row.z)]
            changed = True
    if changed:
        P.save(proj, undoable=True)


def share(project, nodes):
    """Back to one transform for every shot — wherever the node is now."""
    for n in nodes:
        project.poses.pop(str(handle(n)), None)


def apply_view(project, view, look=True):
    """Make the scene match `view`: per-shot poses, camera in the active viewport,
    output size (camera + safe frames only when `look`), and the per-view objects (sun, sky, entourage…) on only in their views.

    One undo record, project included: Ctrl+Z after a switch goes back to the previous
    shot whole. (Off the undo stack, undoing an earlier move would land an object from
    one shot in another.)"""
    from . import project as P
    with pymxs.undo(True, f"Shot: {view.name}"):
        capture(project)
        with _at_rest():
            for k, n in _pose_nodes(project):
                pose = project.poses[k].get(view.id)
                if pose is None:     # a shot added since this object became per-shot
                    project.poses[k][view.id] = _local(n)
                else:
                    _set_local(n, pose)
        project.active = view.id
        scoped = {h for v in project.views for h in v.only_objects}
        mine = set(view.only_objects)
        for h in scoped:
            n = node(h)
            if n is not None:
                _set_shown(n, h in mine)
        P.save(project, undoable=True)
    if view.frame is not None:
        rt.sliderTime = view.frame       # not converted yet: the old keyed-frame setup
    cam = node(view.camera)
    if cam is not None and look:
        rt.viewport.setCamera(cam)
        rt.displaySafeFrames = True
    rt.renderWidth = view.width
    rt.renderHeight = view.height
    rt.redrawViews()
    return cam
