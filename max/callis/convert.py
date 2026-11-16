"""Convert frames to shots: the old keyed-frame setup → per-shot poses, no keys.

The 2017 setup gave shot N frame N: one camera keyed on frames 1..N (focal length
and all), and anything that sits differently per shot keyed on those frames too
(`max set key all`). That keyed the first frames of the timeline, so no motion blur
and no real animation. Here, in one undo step:

  cameras  a view's camera keyed on shot frames is baked to that frame — in place if
           only that view uses it, else a copy per view ("Camera — Kitchen"); the
           original goes to a hidden "Cameras (frames, superseded)" layer
  objects  a node whose transform keys all sit on shot frames (or the range start —
           Auto Key's first key) becomes per-shot: its pose per shot is read off that
           frame, then its transform keys are deleted. Same pose in every shot → just
           unkeyed, stays shared.
  the rest keys anywhere else are real animation: left alone, listed.
           Non-transform keys on converted objects are listed too, not touched.

    import callis.convert as C; C.frames_to_shots(project, log=print)
"""
import pymxs
from pymxs import runtime as rt

from . import project as P
from . import scene as S

SUPERSEDED = "Cameras (frames, superseded)"

_FNS = r"""
global callisKeyTimes, callisBake, callisStripKeys, callisKeyedTracks, callisClone
fn callisClone nodes = (local out; maxOps.cloneNodes nodes cloneType:#copy newNodes:&out; out)
-- Every key time (frames) on sa's controller and everything under it.
fn callisKeyTimes sa out depth = (
    if depth > 12 do return out
    local c = try (sa.controller) catch undefined
    if c != undefined do (
        local n = try (numKeys c) catch -1
        for i = 1 to n do appendIfUnique out (getKeyTime c i).frame
    )
    for i = 1 to sa.numSubs do (
        local s = sa[i]
        if s != undefined do callisKeyTimes s out (depth + 1)
    )
    out
)
-- Names of keyed tracks under sa (for the log).
fn callisKeyedTracks sa path out depth = (
    if depth > 12 do return out
    local c = try (sa.controller) catch undefined
    if c != undefined and (try (numKeys c) catch -1) > 0 do appendIfUnique out path
    for i = 1 to sa.numSubs do (
        local s = sa[i]
        if s != undefined do callisKeyedTracks s (path + "." + (getSubAnimName sa i) as string) out (depth + 1)
    )
    out
)
-- Each keyed controller under sa: its value at frame f, keys gone. Returns the count.
fn callisBake sa f depth = (
    if depth > 12 do return 0
    local count = 0
    local c = try (sa.controller) catch undefined
    if c != undefined and (try (numKeys c) catch -1) > 0 do (
        local v = at time f c.value
        deleteKeys c #allKeys
        try (c.value = v; count += 1) catch ()
    )
    for i = 1 to sa.numSubs do (
        local s = sa[i]
        if s != undefined do count += callisBake s f (depth + 1)
    )
    count
)
-- All keys under sa deleted (the node's transform is put back by the caller).
fn callisStripKeys sa depth = (
    if depth > 12 do return ok
    local c = try (sa.controller) catch undefined
    if c != undefined and (try (numKeys c) catch -1) > 0 do deleteKeys c #allKeys
    for i = 1 to sa.numSubs do (
        local s = sa[i]
        if s != undefined do callisStripKeys s (depth + 1)
    )
    ok
)
"""


def _fns():
    rt.execute(_FNS)


def _xform(n):
    return n[rt.Name("transform")]


def _xform_times(n):
    return set(int(t) for t in rt.callisKeyTimes(_xform(n), rt.Array(), 0))


def _object_times(n):
    """Key times on the camera itself (focal length, exposure, target distance…)."""
    return set(int(t) for t in rt.callisKeyTimes(n.baseObject, rt.Array(), 0))


def _bake_node(n, f):
    """n as it is at frame f, with no keys on its transform or object."""
    with pymxs.attime(f):
        tm = n.transform
    rt.callisStripKeys(_xform(n), 0)
    rt.callisBake(n.baseObject, f, 0)
    with pymxs.animate(False):
        n.transform = tm


def _camera_nodes(cam):
    """The camera and its target, if it has one."""
    tgt = getattr(cam, "target", None)
    return [cam] + ([tgt] if tgt is not None and rt.isValidNode(tgt) else [])


def _superseded_layer():
    layer = rt.LayerManager.getLayerFromName(SUPERSEDED) or rt.LayerManager.newLayerFromName(SUPERSEDED)
    layer.isHidden = True
    return layer


def _copy_camera(cam, name):
    nodes = list(rt.callisClone(rt.Array(*_camera_nodes(cam))))
    new = next(n for n in nodes if rt.superClassOf(n) == rt.camera)
    new.name = name if rt.getNodeByName(name) is None else rt.uniqueName(name)
    return new, nodes


def frames_to_shots(project, log=print):
    views = project.frame_based()
    if not views:
        log("Nothing to convert — no shot uses a frame.")
        return project
    _fns()
    frames = {v.frame for v in views}
    start = int(rt.animationRange.start.frame)
    allowed = frames | {start}
    summary = {"split": 0, "baked": 0, "per_shot": 0, "unkeyed": 0, "left": []}

    with pymxs.undo(True, "Convert frames to shots"):
        # ── Cameras ──
        users = {}
        for v in views:
            if S.node(v.camera) is not None:
                users.setdefault(v.camera, []).append(v)
        camera_nodes = set()
        for handle, vs in users.items():
            cam = S.node(handle)
            group = _camera_nodes(cam)
            camera_nodes.update(S.handle(n) for n in group)
            keyed = set().union(*(_xform_times(n) | _object_times(n) for n in group))
            if not keyed:
                continue
            if len(vs) == 1:
                for n in group:
                    _bake_node(n, vs[0].frame)
                summary["baked"] += 1
                continue
            for v in vs:
                new, nodes = _copy_camera(cam, f"{cam.name} — {v.name}")
                for n in nodes:
                    _bake_node(n, v.frame)
                    camera_nodes.add(S.handle(n))
                v.camera = S.handle(new)
                summary["split"] += 1
            layer = _superseded_layer()
            for n in group:
                layer.addNode(n)

        # ── Everything else keyed on shot frames ──
        # Every pose is read before any keys go — a keyed parent would skew its children.
        by_frame = {}
        for v in views:
            by_frame.setdefault(v.frame, []).append(v)
        found = []      # (node, {view id: pose})
        for n in list(rt.objects):
            if S.handle(n) in camera_nodes:
                continue
            times = _xform_times(n)
            if not times:
                continue
            if not times <= allowed:
                summary["left"].append(str(n.name))
                continue
            poses = {}
            for f, vs in by_frame.items():
                with pymxs.attime(f):
                    pose = S._local(n)
                for v in vs:
                    poses[v.id] = pose
            found.append((n, poses))
        for n, _ in found:
            rt.callisStripKeys(_xform(n), 0)
        first_id = views[0].id
        with pymxs.animate(False):
            for n, poses in sorted(found, key=lambda np: S._depth(np[0])):
                first = poses[first_id]
                S._set_local(n, first)
                if any(p != first for p in poses.values()):
                    project.poses[str(S.handle(n))] = poses
                    summary["per_shot"] += 1
                else:
                    summary["unkeyed"] += 1
                other = list(rt.callisKeyedTracks(n.baseObject, "object", rt.Array(), 0))
                if other:
                    log(f"  ! {n.name}: {', '.join(other)} still keyed — not a pose, left as is")

        for v in views:
            v.frame = None
        project.active = views[0].id
        P.save(project, undoable=True)

    rt.sliderTime = rt.animationRange.start
    S.apply_view(project, views[0])
    parts = [f"{summary['per_shot']} objects now per-shot"]
    if summary["unkeyed"]:
        parts.append(f"{summary['unkeyed']} the same in every shot (keys removed)")
    if summary["split"]:
        parts.append(f"{summary['split']} shot cameras made")
    if summary["baked"]:
        parts.append(f"{summary['baked']} cameras unkeyed")
    log("Converted: " + ", ".join(parts) + ".")
    if summary["left"]:
        names = summary["left"]
        log(f"  Left animated ({len(names)}): " + ", ".join(names[:12]) + (" …" if len(names) > 12 else ""))
    return project


# ── L/M/B/N sublayers ───────────────────────────────────────────────────────

def flatten_matte_layers(log=print):
    """The 2017 L/M/B/N sublayers are gone from maxstart (every layer and material gets a
    matte now — render.matte_plan). Old scenes: objects move up to the real layer and
    the sublayers are deleted, in one undo step.

        import callis.convert as C; C.flatten_matte_layers()
    """
    from . import render as R
    markers = [l for l in S.layers() if R.is_marker(l)]
    if not markers:
        log("No L/M/B/N layers.")
        return 0, 0
    zero = rt.LayerManager.getLayer(0)
    moved = 0
    with pymxs.undo(True, "Flatten L/M/B/N layers"):
        names = [str(l.name) for l in markers]
        cur = rt.LayerManager.current
        if str(cur.name) in names:
            zero.current = True
        for lay in markers:
            dest = R.owner_layer(lay) or zero
            for n in S.layer_nodes(lay):
                dest.addNode(n)
                moved += 1
        left = []
        for name in names:
            if not rt.LayerManager.deleteLayerByName(name):
                left.append(name)
    log(f"Flattened {len(names) - len(left)} L/M/B/N layers, {moved} objects moved up."
        + (f" Not deleted: {', '.join(left[:8])}" if left else ""))
    return len(names) - len(left), moved
