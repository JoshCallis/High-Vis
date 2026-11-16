"""Render settings as two presets saved in the scene — Preview (Quick Render) and Final
(the batch render) — per renderer, edited in the Render window's Settings tab.

Only the settings in SPECS are touched. `applied(project, "final")` sets a preset on the
live renderer for the length of a render and puts the previous values back after, so
Max's own Render Setup is left as the user had it.

Project.render_presets = {renderer key: {"preview": {prop: value}, "final": {...}}}.
A preset is seeded the first time it's needed: Final from the live renderer, Preview
from Final with PREVIEW's lighter values.

V-Ray names are from its MAXScript docs and UNTESTED (V-Ray for Max isn't installed yet);
a property the renderer doesn't have is simply left out. Properties starting with "@"
aren't renderer properties — see _get / _set.
"""
from contextlib import contextmanager

from pymxs import runtime as rt

from . import form, renderers

# (section, label, [names], opts) — a name may be (name, opts) for that property alone.
_ON_OFF = {"choices": [(0, "Off"), (1, "On")]}
SPECS = {
    "arnold": [
        ("Sampling", "Camera (AA)", ["AA_samples"], {"min": 1, "max": 32, "tip": "Rays per pixel = AA²"}),
        ("Sampling", "Diffuse", ["GI_diffuse_samples"], {"min": 0, "max": 16}),
        ("Sampling", "Specular", ["GI_specular_samples"], {"min": 0, "max": 16}),
        ("Sampling", "Transmission", ["GI_transmission_samples"], {"min": 0, "max": 16}),
        ("Sampling", "SSS", ["GI_sss_samples"], {"min": 0, "max": 16}),
        ("Adaptive", "Adaptive sampling", ["enable_adaptive_sampling"], {}),
        ("Adaptive", "Max camera (AA)", ["AA_samples_max"], {"min": 1, "max": 64}),
        ("Adaptive", "Noise threshold", ["adaptive_threshold"], {"decimals": 3, "step": 0.005, "min": 0}),
        ("Ray depth", "Total", ["GI_total_depth"], {"min": 0, "max": 64}),
        ("Ray depth", "Diffuse", ["GI_diffuse_depth"], {"min": 0, "max": 16}),
        ("Ray depth", "Specular", ["GI_specular_depth"], {"min": 0, "max": 16}),
        ("Ray depth", "Transmission", ["GI_transmission_depth"], {"min": 0, "max": 16}),
        ("Clamping", "Clamp samples", ["AA_sample_clamp_enabled"], {}),
        ("Clamping", "Clamp value", ["AA_sample_clamp"], {"decimals": 2, "min": 0}),
        ("Clamping", "Indirect clamp", ["indirect_sample_clamp"], {"decimals": 2, "min": 0}),
    ],
    "vray": [
        ("Image sampler", "Type", [("imageSampler_type_new", {"choices": [(0, "Bucket"), (1, "Progressive")]}),
                                   ("imageSampler_type", {"choices": [(1, "Bucket"), (3, "Progressive")]})], {}),
        ("Image sampler", "Min subdivs", ["twoLevel_baseSubdivs"], {"min": 1, "max": 100}),
        ("Image sampler", "Max subdivs", ["twoLevel_fineSubdivs"], {"min": 1, "max": 100}),
        ("Image sampler", "Noise threshold", ["twoLevel_threshold"], {"decimals": 3, "step": 0.005, "min": 0}),
        ("Progressive", "Max subdivs", ["progressive_maxSamples"], {"min": 1, "max": 100}),
        ("Progressive", "Noise threshold", ["progressive_noise_threshold"], {"decimals": 3, "step": 0.005, "min": 0}),
        ("Progressive", "Time limit", ["progressive_max_render_time"],
         {"decimals": 1, "step": 1, "min": 0, "suffix": " min", "tip": "0 = no limit"}),
        ("Global illumination", "GI", ["gi_on"], {}),
        ("Global illumination", "Primary", [("gi_primary_type", {"choices": [(0, "Irradiance map"), (2, "Brute force")]})], {}),
        ("Global illumination", "Secondary", [("gi_secondary_type", {"choices": [(0, "None"), (2, "Brute force"),
                                                                              (3, "Light cache")]})], {}),
        ("Global illumination", "Light cache subdivs", ["lightcache_subdivs"], {"min": 1, "max": 10000, "step": 100}),
        ("Denoiser", "Denoiser", [("@denoiser", {"choices": [(-1, "Off"), (0, "V-Ray"), (1, "NVIDIA AI"),
                                                             (2, "Intel Open Image")]})], {}),
        ("Colour mapping", "Type", [("colorMapping_type", {"choices": [(0, "Linear"), (1, "Exponential"),
                                                                      (2, "HSV exponential"), (3, "Intensity exponential"),
                                                                      (4, "Gamma"), (5, "Intensity gamma"),
                                                                      (6, "Reinhard")]})], {}),
        ("Colour mapping", "Clamp output", ["colorMapping_clampOutput"], {}),
        ("Colour mapping", "Max ray intensity", ["options_maxRayIntensity_on"], {}),
        ("Colour mapping", "Max intensity", ["options_maxRayIntensity"], {"decimals": 1, "min": 0}),
        ("Switches", "Displacement", ["options_displacement"], {}),
        ("Switches", "Lights", ["options_lights"], {}),
        ("Switches", "Hidden lights", ["options_hiddenLights"], {}),
        ("Switches", "Default lights", [("options_defaultLights", {"choices": [(0, "Off"), (1, "On"),
                                                                              (2, "Off with GI")]})], {}),
    ],
    # Corona (checked against the installed Corona, 2026-10-15). Colour mapping is an operator
    # stack (colorMap_pipeline) — "@op:<class>.<prop>", see _op.
    "corona": [
        ("Sampling", "Pass limit", ["progressive_passLimit"], {"min": 0, "max": 10000, "tip": "0 = no limit"}),
        ("Sampling", "Time limit (s)", ["progressive_timeLimit"], {"min": 0, "tip": "0 = no limit"}),
        ("Sampling", "Noise level limit", ["adaptivity_targetError"],
         {"decimals": 1, "step": 0.5, "min": 0, "suffix": " %", "tip": "0 = no limit"}),
        ("Sampling", "Max sample intensity", ["shading_maxSampleIntensity"], {"decimals": 1, "min": 0}),
        ("Global illumination", "Secondary solver", [("shading_secondarySolver", {"choices": [(1, "Path tracing"),
                                                                                            (2, "UHD cache")]})], {}),
        # denoise_filterType read off Corona 15's Render Setup; 3 = "Gather data for later" left out
        ("Denoiser", "Denoiser", [("denoise_filterType", {"choices": [(0, "Off"), (1, "Only fireflies"),
                                                                       (2, "Corona"), (4, "NVIDIA AI"),
                                                                       (5, "Intel AI")]})], {}),
        ("Denoiser", "Amount", ["denoise_blendAmount"], {"decimals": 2, "step": 0.05, "min": 0, "max": 1}),
        ("Colour mapping", "Exposure (EV)", ["@op:SimpleExposureOperatorPlugin.colorMappingOperator_simpleExposure"],
         {"decimals": 2, "step": 0.25}),
        ("Colour mapping", "Contrast", ["@op:ContrastOperatorPlugin.colorMappingOperator_contrast"],
         {"decimals": 2, "step": 0.1, "min": 1}),
        ("Colour mapping", "White balance (K)", ["@op:WhiteBalanceImprovedOperatorPlugin.colorMappingOperator_colorTemperature"],
         {"min": 1000, "max": 40000, "step": 100}),
    ],
}
# Preview = Final with these (only where the renderer has the property).
PREVIEW = {
    "arnold": {"AA_samples": 2, "GI_diffuse_samples": 1, "GI_specular_samples": 1,
               "GI_transmission_samples": 2, "GI_sss_samples": 1, "enable_adaptive_sampling": False},
    "vray": {"twoLevel_fineSubdivs": 8, "twoLevel_threshold": 0.05, "progressive_maxSamples": 8,
             "progressive_noise_threshold": 0.05, "progressive_max_render_time": 1.0,
             "lightcache_subdivs": 500},
    "corona": {"progressive_passLimit": 20, "adaptivity_targetError": 8.0},
}


def key():
    """The current renderer's adapter key ("arnold", "vray", "corona"), or None."""
    a = renderers.for_current()
    return a.key if a else None


def label():
    a = renderers.for_current()
    return a.label if a else str(rt.classOf(rt.renderers.current)).replace("_", " ")


# ── Live renderer ───────────────────────────────────────────────────────────

def _denoiser():
    mgr = rt.maxOps.GetCurRenderElementMgr()
    for i in range(mgr.NumRenderElements()):
        el = mgr.GetRenderElement(i)
        if str(rt.classOf(el)) == "VRayDenoiser":
            return el
    return None


def _op(r, name):
    """"@op:<class>.<prop>" → (operator, prop): Corona's tone-mapping operator of that class
    in colorMap_pipeline (a list linked by colorMappingOperator_nextOperator), or (None, prop)."""
    cls, prop = name[4:].split(".", 1)
    p = rt.getProperty(r, "colorMap_pipeline") if rt.isProperty(r, "colorMap_pipeline") else None
    while p is not None:
        if str(rt.classOf(p)) == cls:
            return p, prop
        p = p.colorMappingOperator_nextOperator
    return None, prop


def _has(r, name):
    if name == "@denoiser":
        return hasattr(rt, "VRayDenoiser")
    if name.startswith("@op:"):
        return _op(r, name)[0] is not None
    return bool(rt.isProperty(r, name))


def _get(r, name):
    if name == "@denoiser":       # V-Ray's denoiser is a render element: off = absent / disabled
        el = _denoiser()
        return -1 if el is None or not el.enabled else int(el.denoising_engine)
    if name.startswith("@op:"):
        return rt.getProperty(*_op(r, name))
    return rt.getProperty(r, name)


def _set(r, name, v):
    if name.startswith("@op:"):
        rt.setProperty(*_op(r, name), v)
        return
    if name == "@denoiser":
        el = _denoiser()
        if v == -1:
            if el is not None:
                el.enabled = False
            return
        if el is None:
            el = rt.VRayDenoiser()
            rt.maxOps.GetCurRenderElementMgr().AddRenderElement(el)
        el.enabled = True
        el.denoising_engine = v
        return
    rt.setProperty(r, name, v)


def rows(k):
    """[(section, label, prop, opts)] for the props the live renderer has."""
    r = rt.renderers.current
    out = []
    for section, lab, names, opts in SPECS.get(k, []):
        for n in names:
            name, own = (n, {}) if isinstance(n, str) else n
            if _has(r, name):
                out.append((section, lab, name, {**opts, **own}))
                break
    return out


# ── Presets ─────────────────────────────────────────────────────────────────

def presets(project, k=None):
    """{"preview": {...}, "final": {...}} for renderer `k` (default: current), seeded on
    first use. Returns None for a renderer with no SPECS. Seeding doesn't save — the
    caller's next save does."""
    k = k or key()
    if k not in SPECS:
        return None
    r = rt.renderers.current
    have = project.render_presets.setdefault(k, {})
    live = {}
    for _, _, name, _ in rows(k):
        try:
            v = _get(r, name)
        except Exception:
            continue
        if isinstance(v, (bool, int, float)):
            live[name] = v
    final = have.setdefault("final", {})
    for name, v in live.items():                 # props added to SPECS since last time
        final.setdefault(name, v)
    preview = have.setdefault("preview", {})
    for name in live:
        preview.setdefault(name, PREVIEW.get(k, {}).get(name, final[name]))
    return have


def reset(project, which):
    """`which` preset ← the live renderer's values (Preview: plus its lighter values)."""
    k = key()
    if k in SPECS:
        project.render_presets.setdefault(k, {}).pop(which, None)
        if which == "preview":       # seeded from Final, so take Final from live first
            final = project.render_presets[k].pop("final", None)
            presets(project, k)
            if final is not None:
                project.render_presets[k]["final"] = final
        else:
            presets(project, k)


def fields(project, which, on_change):
    """form.Fields editing preset `which` of the current renderer; on_change() after each edit."""
    k = key()
    have = presets(project, k)
    if have is None:
        return []
    r = rt.renderers.current
    out = []
    for section, lab, name, opts in rows(k):
        def get(name=name):
            p = have[which]
            return p[name] if name in p else _get(r, name)

        def put(v, name=name):
            have[which][name] = v
            on_change()
        out.append(form.Field(section, lab, get, put, opts))
    return out


@contextmanager
def applied(project, which, log=print):
    """Preset `which` on the live renderer for the duration; previous values restored."""
    have = presets(project)
    r = rt.renderers.current
    saved = {}
    if have:
        for name, v in have[which].items():
            try:
                old = _get(r, name)
                _set(r, name, v)
                saved[name] = old
            except Exception as e:
                log(f"  ! {which} setting {name}: {e}")
    try:
        yield
    finally:
        for name, v in saved.items():
            try:
                _set(r, name, v)
            except Exception as e:
                log(f"  ! couldn't restore {name}: {e}")
