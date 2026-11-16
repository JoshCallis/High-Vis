# 3ds Max in Control Room

Goal: a **3ds Max** category in Control Room where shortcuts are set the way Fusion's are.

## The catch: Max is inside a VM

remapd sees keys on the Mac. While the Parallels window is in front, the frontmost
app is *Parallels Desktop*, whatever Windows app has focus. So there are two places a
shortcut can live:

| | A. Max's own hotkeys — **built** | B. Mac-side bindings that call Max — not built |
|---|---|---|
| how | Control Room writes Max's hotkey set (`hotkeys/Callis.hsx`), applied live via the bridge (`actionMan.loadKeyboardFile`) | a remapd `run` binding → `maxctl eval 'callis.actions.run("<id>")'` over the bridge (~100 ms) |
| works with | ordinary chords Parallels passes through (⌃ ⌥ ⇧) | holds, layers, chords Parallels/Windows would swallow |
| needs | — | an "app is 3ds Max" situation — Parallels alone isn't enough |

## A — what's there (2026-10-09)

- `callis/actions.py` exports every action (3,858) + Max's built-in hotkeys
  (`Default.hsxb`, 532) to `.state/actions.json`; Control Room's **Read Actions Again**
  re-exports (~7 s).
- `remap/maxapp.py` + `/max`, `/max/set`, `/max/view`, `/max/refresh` in `remap/server.py`;
  page kind `max-shortcuts` (the shared Fusion/Chrome page). Show Custom Unassigned =
  macroscripts, Show Native Unassigned = Max's own actions.
- A chord set here takes the chord from whatever held it by DEFAULT in the same context
  and from the action's other defaults; Clear removes the key entirely (Max's default too).
- Max closed → the set is applied by `callis.startup` on the next start.

## B needs a focus signal

(2026-10-10: the VM itself is now an app, `windows` — bundle `com.parallels.*` — and
remapd's bindings that reach it are compiled into Karabiner, since Parallels' tap
sits ahead of remapd's: `remap/README.md` § Windows (Parallels). Its window is the
3ds Max slot, `goto_app.sh max`, four/five fingers + M. What's still missing for B
is telling Max apart from other Windows apps, below.)

Use the bridge in reverse: Max's Qt app reports focus in/out (`QApplication.applicationStateChanged`)
by touching a file on the share (`max/.state/focus`), and remapd's app axis treats
"Parallels in front + Max focused" as `app: 3dsmax`. No polling, and nothing runs per key.
Then `remap/contexts.json` gets `app: 3dsmax`, and max_set stops refusing held/finger triggers.

Open questions for the user:
- ⌘ in Max: Parallels sends ⌘ on as the Windows key (except its own few ⌘C/⌘V… maps), so
  the page refuses ⌘ chords. A Parallels keyboard profile mapping ⌘→Ctrl would let ⌘ be Ctrl.
- Which old utility macros come back first? Two-Click Move, Consolidate Cameras, Attach and
  Material Guesser are the big ones.
