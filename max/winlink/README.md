# winlink — a live line between the Mac and Windows (File Explorer)

| piece | runs | what |
|---|---|---|
| `winlink.cs` | Windows, user session (`%LOCALAPPDATA%\Callis\winlink.exe`, HKCU Run `CallisWinLink`) | dials out to the Mac; reports text-field focus (UIA); raises / opens File Explorer |
| `winlink.py` | Mac, LaunchAgent `com.josh.winlink` (`../launchd/`) | listens on `10.211.55.2:27121` (Parallels' host address only); sets Karabiner's `vm_text_field` through one resident `karabiner_cli --set-variables-from-stdin`; local commands on `/tmp/winlink.sock` |
| `install.sh` | Mac | installs both (`--revert` removes both); re-run after editing either side |

`winlink.py` also relays 3ds Max's HUD: UDP datagrams `"<hold ms>\t<text>"` on
`10.211.55.2:27122` (from `../callis/hud.py`) → `~/bin/hud show <text> --ms <hold>`, the
HUD the Photoshop scripts use. Test: `printf '900\tTest' | nc -u -w1 10.211.55.2 27122`.

```bash
printf 'explorer\n' | nc -U -w 7 /tmp/winlink.sock    # raised <hwnd> | opened <hwnd> | down
printf 'status\n' | nc -U -w 2 /tmp/winlink.sock      # up | down
```

Log: `/tmp/winlink.log` (connects, commands with timings, every text-focus change).

## Why

- **Text focus.** Karabiner is the only thing that reaches the VM's keys (remap/README § Windows
  (Parallels)) and it can't see Windows' focus. File Explorer's Finder keys (A deselect, C/R
  down/up, D back, F open — Control Room ▸ Windows ▸ File Explorer) are plain letters, so they
  gate on `vm_text_field` (`karabiner_layers.vm_element`) and stand aside in the address bar,
  search box and rename field. Focus → Karabiner is a few ms (no `karabiner_cli` spawn per change).
  Agent gone → `vm_text_field` 0 (the keys stay live).
- **Dialogs** (2026-10-15). The agent also reports `dialog 0|1` → Karabiner `vm_dialog`: the
  foreground window is a modal dialog (class `#32770`, or its owner window is disabled — how
  Win32 and Qt/3ds Max both go modal; polled every 150 ms, Win32 only). Bindings with
  `"dialog": true` (`vm.dialog.d` / `vm.dialog.f`: D presses the far-left button, F the second
  from the left — `printf 'button N\n' | nc -U /tmp/winlink.sock`; the agent picks the bottom
  button row, BM_CLICK for Win32 buttons, UIA Invoke for Qt / TaskDialog) hold only then — Karabiner's only (`karabiner_layers.dialog_cond`), no situation of
  their own; their `desc` says so on Remap ▸ Keys. Agent gone → `vm_dialog` 0.
- **Opening Explorer.** `prlctl exec … explorer.exe` takes ~5 s; the agent raises the frontmost
  Explorer window in ~30 ms or opens one in ~1 s. `goto_app.sh explorer` / `focus.sh explorer`
  (settings.json `special: "explorer"` → `app_resolve.sh open_explorer`), keys: 4 / 5 fingers +
  Space while Windows is in front (Finder's key on the Mac; situations `finger4-windows`,
  `finger5-windows`).
- The agent dials OUT, so Windows' firewall needs no rule. The Mac's firewall is off; if it is
  ever turned on, python3 needs to accept incoming connections.

## Floating — `../explorer/` (2026-10-11)

Explorer floats on the Windows Spaces like Finder over the slots:

- 3ds Max's full-screen Space belongs to Max's stub; macOS shows **no other app's ordinary
  window** there. yabai's SA `WINDOW_TO_SPACE` (what `../coherence_home.py` sends) is accepted and
  does nothing — the "still off the full-screen Space" lines in `/tmp/slots.log` for `Windows 11`
  helper windows are the same failure.
- Windows' TOPMOST on an Explorer window makes Parallels pin its Mac window to **every
  non-full-screen desktop** (and it stays pinned after TOPMOST is cleared). The agent never sets it.
- So `../explorer/float.dylib` is injected into File Explorer's stub (the `../notitle/` mechanism —
  LSEnvironment `DYLD_INSERT_LIBRARIES`, stub ad-hoc signed): every window `FullScreenAuxiliary |
  CanJoinAllSpaces`, floating level, alpha 0 + click-through unless another Parallels stub's
  window covers the screen. `../explorer/install.sh [--restart|--revert]`; re-run quietly by every
  jump (Parallels regenerates stubs). Log `/tmp/explorer_float.log`.
- The jump (`open_explorer`) flips to the Windows Space shown / last flipped to, then asks the
  agent; Parallels makes the stub key itself. **Never `open` the stub** — that activation switched
  macOS to desktop 1.
