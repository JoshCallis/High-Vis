#!/bin/bash
# coherence_fullscreen.sh "<open name>" [wait-seconds]
#
# Put a Coherence app's main window (3ds Max) back on its OWN full-screen macOS
# Space. The slot engine's jump to Max (app_resolve.sh open_coherence,
# slotd.py coherence_flip) just focuses whatever Space Max's window is on — but
# Parallels gives a Coherence window its own Space only when it goes full screen
# in Windows while it is the active Mac app. A relaunched Max (or one whose full
# screen came up offset — see callis/clean.py _fill) opens on the desktop being
# shown instead, on top of a slot (it sat over Claude+Chrome, hiding Chrome).
# No-op (one space_query, ~40 ms) when the window already has its own Space.
#
# How (verified 2026-10-10): flip to its desktop, `open` the stub (System Events'
# `set frontmost` isn't enough), then over the bridge leave + re-enter Qt full
# screen (callis.clean.respace). Fallback when the bridge can't: AXFullScreen on
# the stub's window — took only sometimes. wait-seconds (default 0) keeps trying
# for a Max that is still launching.
export PATH="/opt/homebrew/bin:/usr/local/bin:/Users/josh/bin:$PATH"
HERE="$(cd "$(dirname "$0")" && pwd)"
NAME="${1:?open name required, e.g. \"3ds Max 2027\"}"
WAIT="${2:-0}"
LOCK="/tmp/.coherence_fs_${NAME//[^A-Za-z0-9]/_}.lock"
shlock -f "$LOCK" -p $$ || exit 0
trap 'rm -f "$LOCK"' EXIT
log() { echo "[$(date '+%H:%M:%S')] [coherence_fs] $*" >> /tmp/slots.log; }

# → "pid fullscreen spaceIndex" of the main window (biggest on exactly one Space,
#   at least a quarter of the screen — not a dialog or Max's splash), or nothing.
main_win() {
  space_query json 2>/dev/null | jq -r --arg a "$NAME" '
    . as $r
    | ([.windows[] | select(.app == $a and (.spaces | length) == 1 and .w * .h >= 3440 * 1440 / 4)]
       | max_by(.w * .h)) as $w
    | select($w != null)
    | ($r.spaces[] | select(.id == $w.spaces[0])) as $s
    | "\($w.pid) \($s.fullscreen) \($s.index)"'
}

# bring the stub forward, wait until it is. An `open` sent while the desktop flip
# is still animating can be lost (2026-10-13: the stub never came front, so every
# respace ran from behind and the whole heal failed) — so re-send it.
front() {
  local i
  for i in $(seq 20); do
    (( i % 5 == 1 )) && open "$stub"
    sleep 0.1
    [[ "$(osascript -e "tell application \"System Events\" to get frontmost of (first process whose unix id is $pid)" 2>/dev/null)" == true ]] && return 0
  done
  log "$NAME: stub did not come to the front"
  return 1
}

ax_fullscreen() {
  osascript -e "tell application \"System Events\" to set value of attribute \"AXFullScreen\" of window 1 of (first process whose unix id is $pid) to true" >/dev/null 2>&1
}

# No main window (2026-10-16: Max hung on its splash for 40 min after a crash —
# every jump to it did nothing, silently). Show whatever window it does have
# (splash, dialog) and say why on the HUD, so a jump never looks like a dead key.
not_ready() {
  local r p i
  r=$(space_query json 2>/dev/null | jq -r --arg a "$NAME" '
    . as $r
    | ([.windows[] | select(.app == $a and (.spaces | length) == 1)] | max_by(.w * .h)) as $w
    | select($w != null)
    | ($r.spaces[] | select(.id == $w.spaces[0])) as $s
    | "\($w.pid) \($s.index) \($w.w)x\($w.h)"')
  read -r p i dims <<< "$r"
  if [[ -n "$p" ]]; then
    log "[not_ready] $NAME: no main window, only $dims on desktop $i (still starting / dialog?) — showing it"
    yabai -m space --focus "$i" 2>/dev/null
    pid=$p; stub=$(ps -o comm= -p "$pid"); stub="${stub%%/Contents/MacOS/*}"
    open "$stub"; pid=
    hud show "$NAME isn't ready — still starting or a dialog is up" --pos center --ms 2500 >/dev/null 2>&1
  else
    log "[not_ready] $NAME: no window on any desktop"
    hud show "$NAME has no window yet" --pos center --ms 2500 >/dev/null 2>&1
  fi
}

# keep the title-strip hook in Max's stub (Parallels regenerates stubs) — notitle/notitle.m
[[ "$NAME" == "3ds Max"* ]] && "$HERE/notitle/install.sh" >> /tmp/slots.log 2>&1

end=$(( SECONDS + WAIT )); logged=
while :; do
  read -r pid fs idx < <(main_win)
  [[ "$fs" == 1 ]] && { [[ -n "$logged" ]] && { log "$NAME back on its own Space ($idx)"; "$HERE/coherence_home.py" >/dev/null 2>&1; }; exit 0; }
  if [[ -n "$pid" ]]; then
    [[ -z "$logged" ]] && { log "$NAME on desktop $idx, not full screen → re-entering"; logged=1; }
    stub=$(ps -o comm= -p "$pid"); stub="${stub%%/Contents/MacOS/*}"
    yabai -m space --focus "$idx" 2>/dev/null
    front
    # Often the stub coming front is enough: Parallels re-creates the full-screen Space
    # itself within ~1 s while Qt is still full screen. respace() then KNOCKED IT BACK OUT
    # (its showNormal leaves full screen; the re-enter didn't take) — 2026-10-16.
    for _ in $(seq 8); do
      sleep 0.25
      read -r pid fs idx < <(main_win)
      [[ "$fs" == 1 ]] && { log "$NAME back on its own Space ($idx) — stub front was enough"; "$HERE/coherence_home.py" >/dev/null 2>&1; exit 0; }
    done
    if [[ "$NAME" == "3ds Max"* ]] \
       && [[ "$(perl -e 'alarm 15; exec @ARGV' python3 "$HERE/maxctl.py" eval \
               $'import callis.clean as c\n_result=repr(c.respace())' 2>/dev/null)" == True ]]; then
      :
    else
      ax_fullscreen
    fi
    for _ in $(seq 10); do
      sleep 0.3
      read -r pid fs idx < <(main_win)
      [[ "$fs" == 1 ]] && { log "$NAME back on its own Space ($idx)"; "$HERE/coherence_home.py" >/dev/null 2>&1; exit 0; }
    done
    tries=$(( ${tries:-0} + 1 ))
    (( tries >= 3 && SECONDS >= end )) && break
  fi
  [[ -z "$pid" && -z "$told" ]] && { not_ready; told=1; }
  (( SECONDS >= end )) && [[ -z "$pid" ]] && exit 0
  sleep 2
done
log "$NAME: full screen did not take"
exit 1
