#!/bin/bash
# vm.sh — pause / resume the Windows VM that 3ds Max runs in.
#
#   vm.sh toggle     pause if running, resume if paused (the Control Room binding)
#   vm.sh pause      pause it (frees the ~4 cores it idles at)
#   vm.sh resume     resume it
#   vm.sh ensure     resume it if WE paused it — instant when not (a marker file,
#                    no prlctl call); goto_app/focus run this before showing
#                    3ds Max or the Windows window. Then a background check also
#                    resumes a VM paused some other way (Parallels' own menu).
#   vm.sh status     running / paused / stopped …
#
# prlctl costs 120–150ms a call and pause/resume ~0.4s/0.2s, so the jump path
# trusts the marker and only verifies in the background.
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"
VM="Windows 11"
MARK=/tmp/.vm_paused_by_slots

status() { prlctl status "$VM" 2>/dev/null | awk '{print $NF}'; }
pause()  { prlctl pause "$VM" >/dev/null 2>&1 && touch "$MARK"; }
resume() { rm -f "$MARK"; prlctl resume "$VM" >/dev/null 2>&1; }

case "${1:-status}" in
  toggle) if [[ "$(status)" == paused ]]; then resume; echo resumed; else pause; echo paused; fi ;;
  pause)  pause ;;
  resume) resume ;;
  ensure)
    [[ -f "$MARK" ]] && resume
    ( [[ "$(status)" == paused ]] && resume ) >/dev/null 2>&1 &
    ;;
  status) status ;;
  *) echo "usage: vm.sh toggle|pause|resume|ensure|status" >&2; exit 2 ;;
esac
