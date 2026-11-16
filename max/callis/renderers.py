"""Renderer adapters: set up passes + Cryptomatte and say where the files land.

Every adapter writes, into one output folder:
  beauty.exr   — the main render
  passes.exr   — every pass as a layer of ONE multi-layer EXR, plus Cryptomatte
                 (Corona: its VFB dump, a CXR)
and reports `layers`: renderer layer name → canonical pass key (see compose/recipes.json).

Arnold, V-Ray 7 and Corona 15 are tested end to end. Anything missing (a plug-in
class) is reported in `warnings` rather than raised.
"""
import os
import shutil
import tempfile
import uuid
from contextlib import contextmanager

from pymxs import runtime as rt


def _cls(name):
    """A MAXScript class by name, or None if that plug-in isn't installed."""
    try:
        return getattr(rt, name)
    except AttributeError:
        return None


class Adapter:
    key = "generic"
    label = "Unsupported renderer"
    recipe = "generic"
    own_render = False    # True: render.py calls adapter.render() instead of MAXScript render()

    @staticmethod
    def matches(renderer):
        return False

    def __init__(self, renderer):
        self.r = renderer
        self.warnings = []

    def configure(self, out_dir, glass=False):
        """Set passes for a normal render (or the glass-only pass). Returns
        {"beauty": path, "passes": [paths], "layers": {layer: key}, "crypto": {...}}."""
        raise NotImplementedError

    def crypto_name(self, name):
        """How this renderer spells a scene name inside its Cryptomatte hash."""
        return name

    def rendering(self):
        """True while a render started without waiting (own_render Quick Render) runs."""
        return False

    @contextmanager
    def quiet(self):
        """A render that only shows in the frame buffer (Quick Render): no render
        elements, nothing saved — all put back after."""
        mgr = rt.maxOps.GetCurRenderElementMgr()
        was = (bool(mgr.GetElementsActive()), bool(rt.rendSaveFile))
        mgr.SetElementsActive(False)
        rt.rendSaveFile = False
        try:
            with self._quiet_own():
                yield
        finally:
            mgr.SetElementsActive(was[0])
            rt.rendSaveFile = was[1]

    @contextmanager
    def _quiet_own(self):
        yield

    def _props_off(self, names):
        """Set each existing bool prop False; returns what to put back."""
        saved = {}
        for n in names:
            if rt.isProperty(self.r, n):
                saved[n] = rt.getProperty(self.r, n)
                rt.setProperty(self.r, n, False)
        return saved

    def render_error(self):
        """Why the renderer aborted a render it reported as cancelled, or None (a real cancel)."""
        return None

    def finish(self):
        """After the render: move anything staged locally to its real folder."""
        for src, dst in getattr(self, "_staged", []):
            if os.path.isdir(src):
                for f in os.listdir(src):
                    shutil.move(os.path.join(src, f), os.path.join(dst, f))
                shutil.rmtree(src, ignore_errors=True)
        self._staged = []

    def _stage(self, out_dir):
        """A local folder to write to when `out_dir` is a network path (Arnold's AOV
        driver silently writes nothing to \\\\server\\share paths)."""
        if not out_dir.startswith("\\\\"):
            return out_dir
        local = os.path.join(tempfile.gettempdir(), "callis_stage", uuid.uuid4().hex[:8])
        os.makedirs(local, exist_ok=True)
        self._staged = getattr(self, "_staged", []) + [(local, out_dir)]
        return local


# ── Arnold ──────────────────────────────────────────────────────────────────

class Arnold(Adapter):
    key = "arnold"
    label = "Arnold"
    recipe = "arnold"

    AOVS = {  # Arnold AOV → canonical pass
        "diffuse_direct": "diffuse_direct", "diffuse_indirect": "diffuse_indirect",
        "diffuse_albedo": "diffuse_filter", "specular": "specular", "coat": "coat",
        "sheen": "sheen", "transmission": "transmission", "sss": "sss",
        "emission": "self_illum", "background": "background", "volume": "atmosphere",
        "N": "normals", "Z": "z",
    }
    GLASS_AOVS = {"specular": "reflection", "coat": "coat", "N": "normals"}
    CRYPTO = ("crypto_material", "crypto_object")

    @staticmethod
    def matches(renderer):
        return str(rt.classOf(renderer)) == "Arnold"

    def crypto_name(self, name):
        return name.replace(" ", "_")

    def _manager(self):
        if self.r.AOV_Manager is None:
            # The manager only exists once its window has been opened.
            rt.execute("(MaxToAOps.AOVsManagerWindow()).open(); (MaxToAOps.AOVsManagerWindow()).close()")
        return self.r.AOV_Manager

    def _crypto_shader(self):
        for i in range(3):
            slot = f"aov_shaders_map_{i}"
            cur = getattr(self.r, slot)
            if cur is not None and str(rt.classOf(cur)) == "ai_cryptomatte":
                return cur
        for i in range(3):
            slot = f"aov_shaders_map_{i}"
            if getattr(self.r, slot) is None:
                shader = rt.ai_cryptomatte()
                setattr(self.r, slot, shader)
                return shader
        self.warnings.append("No free Arnold AOV shader slot for Cryptomatte.")
        return None

    # Python lists assigned to MAXtoA's array properties are silently dropped,
    # so the driver is built in MAXScript.
    _DRIVER_FN = """fn callisArnoldDriver names cryptos outPath = (
        local items = for n in names collect (ArnoldAOV name:n)
        for base in cryptos do (
            append items (ArnoldAOV name:base)
            for rank = 0 to 2 do (   -- the ID/coverage layers that carry the actual mattes
                local a = ArnoldAOV name:(base + "0" + (rank as string))
                a.data = "rgba"
                a.filter = "cryptomatte_filter"
                append items a
            )
        )
        local d = ArnoldEXRDriver()
        d.filenameSuffix = "passes"
        d.halfPrecision = false
        d.aovList = items
        renderers.current.AOV_Manager.drivers = #(d)
        renderers.current.AOV_Manager.outputPath = outPath
        (for a in renderers.current.AOV_Manager.drivers[1].aovList collect a.name).count
    )"""

    @contextmanager
    def _quiet_own(self):
        # The AOV driver writes passes.exr wherever the last batch pointed it: send it to
        # a scratch folder instead. NEVER empty `drivers` and put the array back — the
        # emptied drivers are freed and the next render crashed Max (2026-10-13).
        mgr = self.r.AOV_Manager
        if mgr is None:
            yield
            return
        was = str(mgr.outputPath)
        scratch = os.path.join(tempfile.gettempdir(), "callis_quick")
        os.makedirs(scratch, exist_ok=True)
        mgr.outputPath = scratch + "\\"
        try:
            yield
        finally:
            mgr.outputPath = was

    def configure(self, out_dir, glass=False):
        self._manager()
        self._crypto_shader()
        aovs = self.GLASS_AOVS if glass else self.AOVS
        rt.execute(self._DRIVER_FN)
        rt.callisArnoldDriver(list(aovs), list(self.CRYPTO), self._stage(out_dir) + "\\")
        layers = dict(aovs)
        return {
            "beauty": out_dir + "\\beauty.exr",
            "passes": [out_dir + "\\passes.exr"],
            "layers": layers,
            "crypto": {"material": "crypto_material", "object": "crypto_object"},
        }


# ── V-Ray ────────────────────────────────────────────────────────

class VRay(Adapter):
    key = "vray"
    label = "V-Ray"
    recipe = "vray"

    # Element class → (element name, canonical key). The old pipeline's set.
    ELEMENTS = [
        ("VRayDiffuseFilter", "Diffuse", "diffuse_filter"),
        ("VRayRawLighting", "Raw Lighting", "raw_lighting"),
        ("VRayRawGlobalIllumination", "Raw GI", "raw_gi"),
        ("VRayRawReflection", "Raw Reflection", "raw_reflection"),
        ("VRayReflectionFilter", "Reflection Filter", "reflection_filter"),
        ("VRayRawRefraction", "Raw Refraction", "raw_refraction"),
        ("VRayRefractionFilter", "Refraction Filter", "refraction_filter"),
        ("VRaySpecular", "Specular", "specular"),
        ("VRaySelfIllumination", "Self Illumination", "self_illum"),
        ("VRayAtmosphere", "Atmosphere", "atmosphere"),
        ("VRayBackground", "Background", "background"),
        ("VRayZDepth", "Z-Depth", "z"),
        ("VRayNormals", "Normals", "normals"),
    ]
    GLASS_ELEMENTS = [
        ("VRayReflection", "Reflection", "reflection"),
        ("VRaySpecular", "Specular", "specular"),
        ("VRayNormals", "Normals", "normals"),
    ]
    TAG = "callis_"   # elements we own carry this prefix; the user's own are left alone

    @staticmethod
    def matches(renderer):
        return str(rt.classOf(renderer)).lower().startswith("v_ray")

    @staticmethod
    def _last_render_log():
        """vraylog.txt lines of the last render (from its beginSequence on)."""
        log = os.path.join(tempfile.gettempdir(), "vraylog.txt")
        try:
            with open(log, errors="replace") as f:
                f.seek(max(0, os.path.getsize(log) - 200000))
                tail = f.read()
        except OSError:
            return []
        return tail[tail.rfind("Entering beginSequence()"):].splitlines()

    def render_error(self):
        # A failed licence aborts the render the same way Esc does — vraylog.txt says which.
        for line in self._last_render_log():
            if "error:" in line and "license" in line.lower():
                return "V-Ray couldn't get a licence — " + line.split("error:", 1)[1].strip()
        return None

    def finish(self):
        # V-Ray's own warnings ("Unable to create light from node Sun") → the render log + manifest.
        for line in self._last_render_log():
            for tag in ("warning:", "error:"):
                if tag in line and "error(s)" not in line:
                    msg = "V-Ray: " + line.split(tag, 1)[1].strip()
                    if msg not in self.warnings:
                        self.warnings.append(msg)
        # V-Ray stamps the frame on its raw file (passes.0000.exr) — give it the planned name.
        for path in getattr(self, "_raw", []):
            stem, ext = os.path.splitext(path)
            folder = os.path.dirname(path)
            base = os.path.basename(stem) + "."
            if not os.path.isdir(folder):
                continue
            stamped = sorted(f for f in os.listdir(folder)
                             if f.startswith(base) and f.endswith(ext) and f[len(base):-len(ext)].isdigit())
            if stamped:
                os.replace(os.path.join(folder, stamped[-1]), path)
        self._raw = []
        super().finish()

    def _clear_ours(self, mgr):
        for i in reversed(range(mgr.NumRenderElements())):
            el = mgr.GetRenderElement(i)
            if str(el.elementName).startswith(self.TAG):
                mgr.RemoveRenderElement(el)

    def _add(self, mgr, cls_name, name, **props):
        cls = _cls(cls_name)
        if cls is None:
            self.warnings.append(f"V-Ray element {cls_name} not available.")
            return
        el = cls(elementName=self.TAG + name)
        for k, v in props.items():
            try:
                setattr(el, k, v)
            except Exception:
                self.warnings.append(f"{cls_name}.{k} not settable.")
        mgr.AddRenderElement(el)

    @contextmanager
    def _quiet_own(self):
        # V-Ray's own file output (the raw multi-layer EXR the batch sets up) — off.
        # (output_on is the VFB itself — left on.)
        saved = self._props_off(("output_saveRawFile", "output_splitgbuffer"))
        try:
            yield
        finally:
            for n, v in saved.items():
                rt.setProperty(self.r, n, v)

    def configure(self, out_dir, glass=False):
        mgr = rt.maxOps.GetCurRenderElementMgr()
        self._clear_ours(mgr)
        elements = self.GLASS_ELEMENTS if glass else self.ELEMENTS
        for cls_name, name, _ in elements:
            self._add(mgr, cls_name, name)
        # id_type, measured on V-Ray 7 (2026-10-14): 0 = node name, 1 = node name again
        # ("<unknown>" for the root), 2 = material name, 4 = layer name.
        self._add(mgr, "VRayCryptomatte", "CryptoMaterial", id_type=2)
        self._add(mgr, "VRayCryptomatte", "CryptoObject", id_type=0)
        r = self.r
        for prop, val in (("output_getsetsfrommax", True), ("output_on", True),
                          ("output_splitgbuffer", False), ("output_saveRawFile", True),
                          # Half floats wreck Cryptomatte: its ids are float32 bit patterns.
                          ("output_rawExrUseHalf", False),
                          ("output_rawFileName", out_dir + "\\passes.exr")):
            try:
                setattr(r, prop, val)
            except Exception:
                self.warnings.append(f"V-Ray renderer has no {prop}.")
        layers = {self.TAG + name: key for _, name, key in elements}
        self._raw = getattr(self, "_raw", []) + [out_dir + "\\passes.exr"]
        return {
            "beauty": out_dir + "\\beauty.exr",
            "passes": [out_dir + "\\passes.exr"],
            "layers": layers,
            "crypto": {"material": self.TAG + "CryptoMaterial", "object": self.TAG + "CryptoObject"},
        }


# ── Corona ──────────────────────────────────────────────────────────────────

class Corona(Adapter):
    """Corona 15, tested 2026-10-15. Renders through Max's production render, not
    MAXScript's render(): that one never fills Corona's VFB, and only the VFB dump (a CXR,
    which is a multi-layer EXR) carries Cryptomatte's ranks + manifest — Max's own element
    files hold just an RGBA preview of it. So: elements unsaved, VFB → passes.exr."""
    key = "corona"
    label = "Corona"
    recipe = "corona"
    own_render = True
    CRYPTO_ID = {"CryptoMaterial": 3, "CryptoObject": 0}   # idType: 0 object, 2 layer, 3 material

    ELEMENTS = [
        ("CESSENTIAL_Direct", "Direct", "raw_lighting"),
        ("CESSENTIAL_Indirect", "Indirect", "raw_gi"),
        ("CESSENTIAL_Reflect", "Reflect", "reflection"),
        ("CESSENTIAL_Refract", "Refract", "refraction"),
        ("CESSENTIAL_Emission", "Emission", "self_illum"),
        ("CESSENTIAL_Translucency", "Translucency", "translucency"),
        ("CESSENTIAL_Volumetrics", "Volumetrics", "atmosphere"),
        ("CGeometry_ZDepth", "ZDepth", "z"),   # no "-": Corona writes it as "_" in the dump
        ("CGeometry_NormalsShading", "Normals", "normals"),
    ]
    GLASS_ELEMENTS = [
        ("CESSENTIAL_Reflect", "Reflect", "reflection"),
        ("CGeometry_NormalsShading", "Normals", "normals"),
    ]
    TAG = "callis_"

    @staticmethod
    def matches(renderer):
        return "corona" in str(rt.classOf(renderer)).lower()

    def rendering(self):
        # `max quick render` returns at once when run from a script; 1 = production, 0 = idle
        return int(rt.CoronaRenderer.CoronaFp.getRenderType()) != 0

    def configure(self, out_dir, glass=False):
        mgr = rt.maxOps.GetCurRenderElementMgr()
        for i in reversed(range(mgr.NumRenderElements())):
            el = mgr.GetRenderElement(i)
            if str(el.elementName).startswith(self.TAG):
                mgr.RemoveRenderElement(el)
        elements = list(self.GLASS_ELEMENTS if glass else self.ELEMENTS)
        layers, crypto = {}, {}
        for cls_name, name, key in elements + [("CMasking_Cryptomatte", "CryptoMaterial", None),
                                                ("CMasking_Cryptomatte", "CryptoObject", None)]:
            cls = _cls(cls_name)
            if cls is None:
                self.warnings.append(f"Corona element {cls_name} not available.")
                continue
            el = cls(elementName=self.TAG + name)
            if cls_name == "CMasking_Cryptomatte":
                el.idType = self.CRYPTO_ID[name]
                crypto["material" if name == "CryptoMaterial" else "object"] = self.TAG + name
            mgr.AddRenderElement(el)
            mgr.SetRenderElementFilename(mgr.NumRenderElements() - 1, "")
            if key:
                layers[self.TAG + name] = key
        return {"beauty": out_dir + "\\beauty.exr", "passes": [out_dir + "\\passes.exr"],
                "layers": layers, "crypto": crypto, "raw_passes": True}

    def render(self, cam, w, h, path, frame, rect):
        """Production render of the active view (render_view's apply_view put the shot
        camera there), then the VFB dumped next to the beauty as passes.exr. Returns False:
        a stopped Corona render still saves, like V-Ray's."""
        local = self._stage(os.path.dirname(path))
        keep = (rt.renderWidth, rt.renderHeight, rt.rendSaveFile, rt.rendOutputFilename,
                rt.getRenderType(), rt.sliderTime)
        try:
            rt.renderWidth, rt.renderHeight = w, h
            rt.rendSaveFile = True
            rt.rendOutputFilename = os.path.join(local, os.path.basename(path))
            if rt.viewport.getCamera() != cam:
                rt.viewport.setCamera(cam)
            if frame is not None:
                rt.sliderTime = frame
            self._fit_depth(cam)
            if rect:
                l, t, r, b = rect
                rt.setRenderType(rt.Name("region"))
                rt.viewport.setRegionRect(rt.viewport.activeViewport, rt.Box2(l, t, r - l, b - t))
            else:
                rt.setRenderType(rt.Name("view"))
            rt.execute("max quick render")
            cxr = os.path.join(local, "passes.cxr")
            if rt.CoronaRenderer.CoronaFp.dumpVfb(cxr) != 0 or not os.path.exists(cxr):
                raise RuntimeError("Corona couldn't save its frame buffer (dumpVfb).")
            os.replace(cxr, os.path.join(local, "passes.exr"))
        finally:
            (rt.renderWidth, rt.renderHeight, rt.rendSaveFile, rt.rendOutputFilename) = keep[:4]
            rt.setRenderType(keep[4])
            rt.sliderTime = keep[5]
        return False

    def _fit_depth(self, cam):
        """Z-Depth's range (default 0–100 units, clipped → all black) → 0 to the
        farthest visible geometry corner from the camera, so 0–1 spans the scene."""
        mgr = rt.maxOps.GetCurRenderElementMgr()
        els = [mgr.GetRenderElement(i) for i in range(mgr.NumRenderElements())]
        z = [e for e in els if str(e.elementName) == self.TAG + "ZDepth"]
        if not z:
            return
        pos, d = cam.pos, []
        for n in rt.geometry:
            if n.isHidden or not n.renderable:
                continue
            lo, hi = n.min, n.max
            d += [rt.distance(pos, rt.Point3(x, y, zz)) for x in (lo.x, hi.x)
                  for y in (lo.y, hi.y) for zz in (lo.z, hi.z)]
        if d:
            z[0].minZ, z[0].maxZ = 0.0, max(d)


ADAPTERS = (Arnold, VRay, Corona)


def for_current():
    r = rt.renderers.current
    for cls in ADAPTERS:
        if cls.matches(r):
            return cls(r)
    return None
