"""The render project: output folder, views, matte rules — saved inside the .max file.

Replaces the old convention of encoding settings in the layer names of three
dummy objects ("Output Path: …", "Frame Names: …", "Frame Sizes: 1. 1920x1080, …").
`import_legacy()` reads those once so old scenes carry over.

Storage: one custom attribute on rootNode holding JSON. Edits stay off the undo
stack, except shot switches and Convert (save(undoable=True)).
"""
import json
import re
import uuid
from dataclasses import asdict, dataclass, field

import pymxs
from pymxs import runtime as rt

SCHEMA = 2   # 2: shots carry poses (Project.poses) instead of a render frame

# ── Resolution presets ──────────────────────────────────────────────────────
# Same four the old dialog offered (thumbnail ¼, test ½, low 1×, high 4×).
RESOLUTIONS = {
    "thumb": {"label": "Thumbnail", "scale": 0.25, "folder": "Thumbnail"},
    "test":  {"label": "Test",      "scale": 0.5,  "folder": "Test"},
    "low":   {"label": "Low Res",   "scale": 1.0,  "folder": "Low Res"},
    "high":  {"label": "High Res",  "scale": 4.0,  "folder": "High Res"},
}

# What a layer (and the layers inside it) gives Photoshop. Cryptomatte costs the same
# for any number of mattes, so every layer and every material gets one by default;
# the compose step drops materials too small to matter (render.matte_plan).
MATTE_MODES = {
    "normal":  "Mattes",            # a layer matte + its materials' mattes (the default)
    "exclude": "No mattes",         # Linework, Drafting… — nothing from this layer
    "glass":   "Glass (separate)",  # one Glass matte, and rendered in its own glass pass
}
_OLD_MODES = {"material": "normal", "layer": "normal", "none": "exclude"}   # before 2026-10-10


@dataclass
class View:
    """A shot (the UI's word; the code and the saved JSON still say view)."""
    name: str
    camera: int = 0                 # node handle; 0 = none
    width: int = 1920
    height: int = 1080
    frame: int = None               # legacy only: the frame this shot was keyed on, until
                                    # convert.frames_to_shots; None = render at the current time
    render: bool = True             # ticked for the next batch render
    only_objects: list = field(default_factory=list)  # node handles visible ONLY in this view
    region: list = field(default_factory=list)        # [x0, y0, x1, y1] as 0–1 of the frame; [] = none
    id: str = field(default_factory=lambda: uuid.uuid4().hex[:8])

    @classmethod
    def from_dict(cls, d):
        known = {k: d[k] for k in cls.__dataclass_fields__ if k in d}
        return cls(**known)


@dataclass
class Project:
    output_root: str = ""
    views: list = field(default_factory=list)
    layer_mattes: dict = field(default_factory=dict)   # layer name → MATTE_MODES key
    resolutions: list = field(default_factory=lambda: ["low"])
    photoshop: bool = True
    bit_depth: int = 32   # the PSB is built in 32-bit (linear, so the additive groups are right)
    region: bool = False   # "Region only": re-render each ticked view's region and patch it in
    # Per-shot objects: str(node handle) → {view id: 12 floats, the node's transform
    # relative to its parent, at animationRange.start}. Everything not in here is the
    # same in every shot. See scene.apply_view.
    poses: dict = field(default_factory=dict)
    active: str = ""       # id of the shot the scene is showing (whose poses are live)
    persp: dict = field(default_factory=dict)   # {"tm": 12 floats, "fov"}: the perspective view left for a shot camera (cameras.toggle_view)
    render_presets: dict = field(default_factory=dict)   # renderer key → {"preview"|"final": {prop: value}} (rsettings.py)
    save_scene: bool = True   # save the .max before a batch render (Render window)
    schema: int = SCHEMA

    @classmethod
    def from_dict(cls, d):
        p = cls(**{k: d[k] for k in cls.__dataclass_fields__ if k in d and k != "views"})
        p.views = [View.from_dict(v) for v in d.get("views", [])]
        if d.get("schema", 1) < 2:
            # Schema 1 gave every view a frame; only the legacy import's (1..N) meant one.
            for v in p.views:
                if not v.frame:
                    v.frame = None
            p.schema = SCHEMA
        return p

    def frame_based(self):
        """Views still rendered at their own frame — convert.frames_to_shots clears these."""
        return [v for v in self.views if v.frame is not None]

    def per_shot(self, handle):
        return str(handle) in self.poses

    def to_json(self):
        return json.dumps(asdict(self), indent=1)

    def view(self, view_id):
        return next((v for v in self.views if v.id == view_id), None)

    def matte_mode(self, layer_name, inherited="normal"):
        """This layer's own setting, else its parent's (`inherited`), else the old
        "Glass (Separate)" layer name."""
        mode = self.layer_mattes.get(layer_name)
        if mode is not None:
            return _OLD_MODES.get(mode, mode)
        if layer_name.startswith("Glass (Separate)"):
            return "glass"
        return inherited

    def own_matte_mode(self, layer_name):
        """The layer's explicit setting, or None (= same as the layer above)."""
        mode = self.layer_mattes.get(layer_name)
        return _OLD_MODES.get(mode, mode) if mode is not None else None


# ── Scene storage ───────────────────────────────────────────────────────────

_CA_NAME = "callisProject"
_CA_DEF = f"""
attributes {_CA_NAME} attribID:#(0x3c1a5e01, 0x6b2d9f02)
(
    parameters main ( projectJson type:#string default:"" )
)
"""


def _ca():
    for i in range(1, rt.custAttributes.count(rt.rootNode) + 1):
        ca = rt.custAttributes.get(rt.rootNode, i)
        if str(rt.custAttributes.getDef(ca).name) == _CA_NAME:
            return ca
    return None


def load():
    """The scene's project, or a fresh one (with legacy settings imported if found)."""
    ca = _ca()
    if ca is not None and ca.projectJson:
        try:
            return Project.from_dict(json.loads(ca.projectJson))
        except (ValueError, TypeError):
            pass
    p = Project()
    import_legacy(p)
    return p


def _write(project):
    ca = _ca()
    if ca is None:
        rt.custAttributes.add(rt.rootNode, rt.execute(_CA_DEF))
        ca = _ca()
    ca.projectJson = project.to_json()


def save(project, undoable=False):
    """undoable: part of the caller's open undo record (a shot switch, Convert) so
    Ctrl+Z puts the project back with the scene — the panel reloads on sceneUndo."""
    if undoable:
        _write(project)
    else:
        with pymxs.undo(False):
            _write(project)


def saved_json():
    ca = _ca()
    return ca.projectJson if ca is not None else ""


# ── Legacy import (the "… Dummy" objects) ───────────────────────────────────

def _dummy_layer(name):
    node = rt.getNodeByName(name)
    return str(node.layer.name) if node is not None else None


def legacy_present():
    return _dummy_layer("Output Path Dummy") is not None


def import_legacy(project):
    """Fill `project` from the old dummy-object layer names. Returns True if anything was found.

    Frame N of the old single animated "Camera" becomes one view at time N.
    """
    out = _dummy_layer("Output Path Dummy")
    names = _dummy_layer("Frame Names Dummy")
    sizes = _dummy_layer("Frame Sizes Dummy")
    if out is None and names is None:
        return False
    if out:
        project.output_root = out.replace("Output Path: ", "").strip()
    name_list = [s.strip() for s in (names or "").replace("Frame Names:", "").split(",") if s.strip()]
    size_list = [s.strip() for s in (sizes or "").replace("Frame Sizes:", "").split(",") if s.strip()]
    cam = rt.getNodeByName("Camera")
    for i, name in enumerate(name_list, start=1):
        w, h = 1920, 1080
        if i - 1 < len(size_list):
            m = re.search(r"(\d+)\s*x\s*(\d+)", size_list[i - 1])
            if m:
                w, h = int(m.group(1)), int(m.group(2))
        # Later scenes: per-frame cameras/suns/skies on "Cameras"/"Sun"/"Sky" layers,
        # each named with the frames it serves ("Camera 1, 3", "Sun All Frames").
        frame_cams = _frame_nodes("Cameras", i)
        view_cam = frame_cams[0] if frame_cams else cam
        only = [int(n.inode.handle) for lay in ("Sun", "Sky") for n in _frame_nodes(lay, i)]
        project.views.append(View(name=name, camera=int(view_cam.inode.handle) if view_cam else 0,
                                  width=w, height=h, frame=i, only_objects=only))
    return True


def _frame_nodes(layer_name, frame):
    layer = rt.LayerManager.getLayerFromName(layer_name)
    if layer is None:
        return []
    found = []
    for n in rt.refs.dependents(layer.layerAsRefTarg):
        if not rt.isValidNode(n):
            continue
        name = str(n.name)
        tokens = {t.strip(",") for t in name.split()}
        if str(frame) in tokens or "All Frames" in name:
            found.append(n)
    return found
