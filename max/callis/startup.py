"""Run once at Max startup (install/callis.ms): menu command + scene callbacks."""
from pymxs import runtime as rt

MACROS = """
macroScript RenderProject category:"Callis" buttonText:"Shots" tooltip:"Shots panel (shots, mattes, render)"
(
    python.Execute "import callis.ui; callis.ui.show()"
)
macroScript RenderTickedViews category:"Callis" buttonText:"Render Ticked Views" tooltip:"Render the project's ticked views"
(
    python.Execute "import callis.renderwin; callis.renderwin.render_now()"
)
macroScript Render category:"Callis" buttonText:"Render…" tooltip:"Render window: shots, output, Photoshop file (toggle)"
(
    python.Execute "import callis.renderwin; callis.renderwin.toggle('render')"
)
macroScript RenderSettings category:"Callis" buttonText:"Render Settings" tooltip:"Preview / Final render settings (toggle)"
(
    python.Execute "import callis.renderwin; callis.renderwin.toggle('settings')"
)
macroScript QuickRender category:"Callis" buttonText:"Quick Render" tooltip:"Render the current shot at low res with the Preview settings — a region drawn in the frame buffer alone"
(
    python.Execute "import callis.quick; callis.quick.run()"
)
macroScript ViewportIPR category:"Callis" buttonText:"Viewport IPR" tooltip:"Interactive render in the viewport (toggle)"
(
    python.Execute "import callis.ipr; callis.ipr.toggle()"
)
macroScript ToggleFrameBuffer category:"Callis" buttonText:"Frame Buffer" tooltip:"Show / hide the current renderer's frame buffer"
(
    python.Execute "import callis.vfb; callis.vfb.toggle()"
)
macroScript ToggleFrameBufferUI category:"Callis" buttonText:"Frame Buffer Interface" tooltip:"Frame buffer interface on / off (sticks)"
(
    python.Execute "import callis.vfb; callis.vfb.toggle_ui()"
)
macroScript CleanMode category:"Callis" buttonText:"Clean Mode" tooltip:"Hide / show all of Max's interface"
(
    python.Execute "import callis.clean; callis.clean.toggle()"
)
macroScript CommandSearch category:"Callis" buttonText:"Search Commands" tooltip:"Search Max's commands (Fusion-style palette)"
(
    python.Execute "import callis.palette; callis.palette.show()"
)
macroScript JumpToName category:"Callis" buttonText:"Jump to Name" tooltip:"Jump to Name"
(
    python.Execute "import callis.hud; callis.hud.jump()"
)
macroScript GoTo category:"Callis" buttonText:"Go To" tooltip:"Go To"
(
    python.Execute "import callis.hud; callis.hud.goto()"
)
macroScript NextShot category:"Callis" buttonText:"Next Shot" tooltip:"Switch to the next shot"
(
    python.Execute "import callis.ui; callis.ui.step(1)"
)
macroScript PreviousShot category:"Callis" buttonText:"Previous Shot" tooltip:"Switch to the previous shot"
(
    python.Execute "import callis.ui; callis.ui.step(-1)"
)
macroScript ToggleCameraLock category:"Callis" buttonText:"Toggle Camera Lock" tooltip:"Lock / unlock every camera"
(
    python.Execute "import callis.cameras; callis.cameras.toggle()"
)
macroScript ToggleShotCamera category:"Callis" buttonText:"Shot Camera / Perspective" tooltip:"Switch between the shot's camera and your perspective view"
(
    python.Execute "import callis.cameras; callis.cameras.toggle_view()"
)
macroScript ShotCameraSettings category:"Callis" buttonText:"Shot Camera Settings" tooltip:"Settings of the current shot's camera"
(
    python.Execute "import callis.props; callis.props.camera()"
)
macroScript ShotSun category:"Callis" buttonText:"Shot Sun Settings" tooltip:"Settings of the current shot's sun and sky"
(
    python.Execute "import callis.props; callis.props.sun()"
)
macroScript MakePerShot category:"Callis" buttonText:"Make Selected Per-Shot" tooltip:"Selected objects can sit differently in each shot"
(
    python.Execute "import callis.ui; callis.ui.per_shot_selected()"
)
macroScript Eyedropper category:"Callis" buttonText:"Eyedropper" tooltip:"Take the material of the selection, or of the object you click"
(
    python.Execute "import callis.material; callis.material.eyedropper()"
)
macroScript ApplyLastMaterial category:"Callis" buttonText:"Apply Last Material" tooltip:"Give the selection the most recently used material"
(
    python.Execute "import callis.material; callis.material.apply_last()"
)
macroScript EscapeOrDeselect category:"Callis" buttonText:"Escape / Deselect" tooltip:"Escape / Deselect"
(
    python.Execute "import callis.browser; callis.browser.escape_or_deselect()"
)
macroScript SuperEscape category:"Callis" buttonText:"Super Escape" tooltip:"Super Escape"
(
    python.Execute "import callis.browser; callis.browser.super_escape()"
)
macroScript SnapView category:"Callis" buttonText:"Snap View to Nearest Axis" tooltip:"Turn the view to the nearest front/back/left/right/top/bottom, staying in perspective"
(
    python.Execute "import callis.nav; callis.nav.snap_view()"
)
macroScript ToggleViewportBackground category:"Callis" buttonText:"Toggle Viewport Background" tooltip:"Viewport background: black / the environment"
(
    python.Execute "import callis.clean; callis.clean.toggle_background()"
)
"""
MACROS += "".join(
    'macroScript Shot%d category:"Callis" buttonText:"Shot %d" tooltip:"Switch to shot %d"\n'
    '(\n    python.Execute "import callis.ui; callis.ui.goto(%d)"\n)\n' % (n, n, n, n)
    for n in range(1, 11))
# The Browser's keys (callis/browser.py KEYS), one macro each so Control Room can
# put a hotkey on it. Same names the Mac window posts.
BROWSER_KEYS = [("Up", "up", "Move Selection Up"), ("Down", "down", "Move Selection Down"),
                ("Top", "top", "Jump To Level Top"), ("Bottom", "bottom", "Jump To Level Bottom"),
                ("In", "in", "Go In"), ("InDeep", "deep", "Go In Deep"), ("Out", "out", "Go Out"),
                ("Deselect", "deselect", "Deselect Everything"), ("Hide", "hide", "Toggle Visibility"),
                ("Rename", "rename", "Rename Selection"),
                # a Browser folder is a "component"; the macro id stays (it's bound)
                ("NewFolder", "newfolder", "New Component"),
                ("NewGroup", "newgroup", "New Group"), ("Ungroup", "ungroup", "Ungroup"),
                ("Cut", "cut", "Cut"), ("Paste", "paste", "Paste"),
                ("Isolate", "isolate", "Toggle Isolate"),
                ("GoUp", "navup", "Go Up"), ("GoTop", "navtop", "Go to Top"),
                ("GoDown", "navdown", "Go Down"), ("GoBottom", "navbottom", "Go to Bottom")]
MACROS += "".join(
    'macroScript Browser%s category:"Callis Browser" buttonText:"Browser: %s" tooltip:"Browser: %s"\n'
    '(\n    python.Execute "import callis.browser; callis.browser.key(\'%s\')"\n)\n' % (m, t, t, k)
    for m, k, t in BROWSER_KEYS)
# Move Selection Up / Down run twice — the key pressed two times, nothing more.
MACROS += "".join(
    'macroScript Browser%s2 category:"Callis Browser" buttonText:"Browser: %s Twice" tooltip:"Browser: %s Twice"\n'
    '(\n    python.Execute "import callis.browser; callis.browser.key(\'%s\'); callis.browser.key(\'%s\')"\n)\n'
    % (m, t, t, k, k)
    for m, k, t in BROWSER_KEYS[:2])
# Smart modelling verbs (callis/smart.py): one command per verb, whatever is current.
SMART_VERBS = ["Extrude", "Bevel", "Inset", "Offset", "Chamfer", "Fillet", "Weld", "Connect",
               "Bridge", "Cap", "Cut", "Slice", "Detach", "Combine", "Shell", "Revolve"]
MACROS += "".join(
    'macroScript Smart%s category:"Callis Modeling" buttonText:"%s" tooltip:"%s (knows what is selected)"\n'
    '(\n    python.Execute "import callis.smart; callis.smart.run(\'%s\')"\n)\n' % (v, v, v, v.lower())
    for v in SMART_VERBS)
MACROS += """
macroScript Delete category:"Callis Modeling" buttonText:"Delete" tooltip:"Delete (knows what is selected)"
(
    python.Execute "import callis.delete; callis.delete.run()"
)
macroScript Move category:"Callis Modeling" buttonText:"Move" tooltip:"SketchUp's Move: click a point, move, click (F ortho, Space lock, arrows X/Y/Z, Option copy, type a distance)"
(
    python.Execute "import callis.movetool; callis.movetool.start()"
)
macroScript Copy category:"Callis Modeling" buttonText:"Copy" tooltip:"Copy the selection, or the Browser's picked folders"
(
    python.Execute "import callis.clip; callis.clip.copy()"
)
macroScript Paste category:"Callis Modeling" buttonText:"Paste" tooltip:"Paste: a copy onto the cursor (click to place), or the Browser's cut re-filed"
(
    python.Execute "import callis.clip; callis.clip.paste()"
)
macroScript SnapsToggle category:"Callis Modeling" buttonText:"Snaps On / Off" tooltip:"Max's snaps on / off, with the HUD"
(
    python.Execute "import callis.movetool; callis.movetool.toggle_snaps()"
)
macroScript ToggleAppearances category:"Callis Browser" buttonText:"Appearances" tooltip:"Appearances"
(
    python.Execute "import callis.appearance; callis.appearance.toggle()"
)
macroScript CycleUVWAxis category:"Callis Modeling" buttonText:"Cycle UVW Axis" tooltip:"Cycle UVW Axis"
(
    python.Execute "import callis.uvw; callis.uvw.cycle_axis()"
)
"""


def _on_scene_changed():
    from . import clean, ui
    try:
        clean.on_scene()
    except Exception as e:
        print("[callis] look not applied:", e)
    if ui._panel is not None and ui._panel.isVisible():
        ui._panel.reload()


def _cameras():
    try:
        from . import cameras
        cameras.apply()
    except Exception as e:
        print("[callis] cameras not locked:", e)


def _node_added():
    from . import cameras
    try:
        p = rt.callbacks.notificationParam()
        for n in (p if hasattr(p, "__iter__") else [p]):
            cameras.on_node(n)
    except Exception as e:
        print("[callis] new camera not locked:", e)


def _on_undo():
    from . import ui
    try:
        ui.on_undo()
    except Exception as e:
        print("[callis] panel not refreshed after undo:", e)


def _on_pre_save():
    """Moves made in the current shot go into its poses before the file is written."""
    from . import project as P, scene as S, ui
    try:
        p = ui.project()
        if p.poses:
            S.capture(p)
            P.save(p)
    except Exception as e:
        print("[callis] shot poses not captured:", e)


def _phase(phase, settle=0.0):
    """.state/startup.json — the Mac's veil over a launching Max (notitle/notitle.m)
    lifts `settle` s after a "ready" newer than Max's stub. The settle is counted on
    the Mac: a QTimer here didn't fire across max_restart's scene load (2026-10-16)."""
    import json
    import os
    import time
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    try:
        with open(os.path.join(here, ".state", "startup.json"), "w") as f:
            json.dump({"phase": phase, "settle": settle, "t": time.time()}, f)
    except OSError as e:
        print("[callis] startup phase not written:", e)


def _look():
    settle = 0.5
    try:
        from . import clean
        clean.look()
        if clean.is_on():          # it was on when Max closed
            clean.on(reapply=True)
            settle = 6.5           # clean.on's last _fill is 6 s out
    except Exception as e:
        print("[callis] look / clean mode not applied:", e)
    _phase("ready", settle)


def _hotkeys():
    """Control Room's 3ds Max ▸ Shortcuts writes hotkeys/Callis.hsx; one written
    while Max was closed is applied here (remap/maxapp.py `pending`)."""
    import os
    import time
    from . import actions
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    hsx = os.path.join(here, "hotkeys", "Callis.hsx")
    applied = os.path.join(here, ".state", "applied")
    if not os.path.exists(hsx):
        return
    try:
        stale = os.path.getmtime(hsx) > os.path.getmtime(applied)
    except OSError:
        stale = True
    if stale or not str(rt.actionMan.getKeyboardFile()).endswith("Callis.hsx"):
        if actions.apply(hsx)["ok"]:
            os.makedirs(os.path.dirname(applied), exist_ok=True)
            with open(applied, "w") as f:
                f.write(str(time.time()))


def _catalog():
    """Re-export the action catalog (.state/actions.json, Control Room's 3ds Max list)
    when it lacks one of our macros — else a command just added here can't be bound
    until someone presses Read Actions Again. Max keeps a macro id's FIRST spelling
    (Delete → delete), so compared without case."""
    import json
    import os
    import re
    from . import actions
    try:
        with open(os.path.join(actions.STATE, "actions.json"), encoding="utf-8") as f:
            have = {it["id"].lower() for it in json.load(f).get("items", [])}
    except (OSError, ValueError):
        have = set()
    ours = {("%d-%s`%s" % (actions.MACRO_TABLE, n, c)).lower()
            for n, c in re.findall(r'macroScript (\w+) category:"([^"]+)"', MACROS)}
    if ours - have:
        try:
            print("[callis] catalog re-exported:", actions.export())
        except Exception as e:
            print("[callis] catalog not exported:", e)


def _carryover():
    """A Max update undid one of our install-folder patches (carryover/steps.tsv) → ask the
    Mac to re-apply it (com.josh.max-carryover watches the request file). Off the main
    thread: it hashes a few DLLs."""
    import json
    import os
    import threading

    def work():
        try:
            from carryover import check
            stale = check.stale()
            if stale:
                here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
                with open(os.path.join(here, ".state", "carryover_request"), "w") as f:
                    json.dump({"stale": stale}, f)
        except Exception as e:
            print("[callis] carryover check failed:", e)
    threading.Thread(target=work, daemon=True).start()


def install():
    _phase("starting")
    _carryover()
    rt.execute(MACROS)
    try:
        rt.snapMode.active = True
    except Exception as e:
        print("[callis] snaps not turned on:", e)
    try:
        _hotkeys()
    except Exception as e:   # never let hotkeys stop the rest of startup
        print("[callis] hotkeys not applied:", e)
    # Startup scripts run before Max has finished building its viewports, and it
    # turns the viewport labels back on after them — so the look / clean mode go in
    # once the UI is up.
    from PySide6.QtCore import QTimer
    QTimer.singleShot(3000, _look)
    try:
        from . import nav
        nav.setup()                # MMB orbit / Shift+MMB pan, viewport → .state/nav.json
    except Exception as e:
        print("[callis] trackpad nav not set up:", e)
    try:
        from . import browser
        browser.install()          # the Mac's Max Browser window reads .state/browser.json
    except Exception as e:
        print("[callis] browser not installed:", e)
    try:
        from . import rclick
        rclick.install()           # right-click = up a level (no quad menu), click = jump, not select
    except Exception as e:
        print("[callis] viewport clicks not hooked:", e)
    try:
        from . import explorer
        explorer.install()         # Max's Scene Explorer never stays open: the Browser is ours
    except Exception as e:
        print("[callis] explorer guard not installed:", e)
    try:
        from . import toolbars
        toolbars.install()         # plugin toolbars never get a window (they flashed at quit)
    except Exception as e:
        print("[callis] toolbars not parked:", e)
    try:
        from . import filedlg
        filedlg.install()          # file dialogs: no hover tooltip (it hides the dialog on the Mac)
    except Exception as e:
        print("[callis] file dialog tooltips not hooked:", e)
    try:
        from . import material
        material.install()         # remembers the last material assigned (Apply Last Material)
    except Exception as e:
        print("[callis] material watch not installed:", e)
    try:
        from . import appearance
        appearance.install()       # the Browser's Appearances: shared libraries ⇄ this scene
    except Exception as e:
        print("[callis] appearances not installed:", e)
    try:
        from . import vfb
        vfb.install()              # the frame buffer interface setting follows every frame buffer
    except Exception as e:
        print("[callis] frame buffer watch not installed:", e)
    QTimer.singleShot(12000, _catalog)          # a new macro → Control Room can bind it
    try:
        from . import palette
        QTimer.singleShot(8000, palette.warm)   # catalog ready before the first X
    except Exception as e:
        print("[callis] palette not warmed:", e)
    rt.callbacks.removeScripts(id=rt.Name("callisProject"))
    for event in ("filePostOpen", "systemPostReset", "systemPostNew", "filePostMerge"):
        rt.callbacks.addScript(rt.Name(event), _on_scene_changed, id=rt.Name("callisProject"))
    for event in ("filePostOpen", "systemPostNew", "systemPostReset"):
        rt.callbacks.addScript(rt.Name(event), _cameras, id=rt.Name("callisProject"))
    rt.callbacks.addScript(rt.Name("sceneNodeAdded"), _node_added, id=rt.Name("callisProject"))
    _cameras()
    rt.callbacks.addScript(rt.Name("filePreSave"), _on_pre_save, id=rt.Name("callisProject"))
    try:
        from . import maxstart     # an empty new scene gets the user's folder tree
        for event in ("systemPostNew", "systemPostReset"):
            rt.callbacks.addScript(rt.Name(event), maxstart.ensure, id=rt.Name("callisProject"))
        maxstart.ensure()
    except Exception as e:
        print("[callis] maxstart not hooked:", e)
    for event in ("sceneUndo", "sceneRedo"):
        rt.callbacks.addScript(rt.Name(event), _on_undo, id=rt.Name("callisProject"))
    # a closing Max un-fullscreens and redraws its chrome: the stub veils it again
    rt.callbacks.addScript(rt.Name("preSystemShutdown"), lambda: _phase("quitting"),
                           id=rt.Name("callisProject"))
