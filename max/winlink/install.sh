#!/bin/bash
# Install both ends of winlink (README.md):
#   max/winlink/install.sh            Mac LaunchAgent + build/start the agent in the VM
#   max/winlink/install.sh --revert   remove both
# Re-run after editing winlink.cs (rebuilds + restarts it) or winlink.py (restarts it).
HERE="$(cd "$(dirname "$0")" && pwd)"
VM="${MAX_VM:-Windows 11}"
PL="$HOME/Library/LaunchAgents/com.josh.winlink.plist"
launchctl bootout "gui/$UID/com.josh.winlink" 2>/dev/null
if [[ "$1" == "--revert" ]]; then
  rm -f "$PL" /tmp/winlink.sock
  arg="-Revert"
else
  cp "$HERE/../launchd/com.josh.winlink.plist" "$PL"
  launchctl bootstrap "gui/$UID" "$PL"
  arg=""
fi
# Desktop session (not SYSTEM): the agent watches the user's focus. max/ is \\Mac\ClaudeMax.
perl -e 'alarm 90; exec @ARGV' prlctl exec "$VM" --current-user powershell -NoProfile -WindowStyle Hidden \
  -ExecutionPolicy Bypass -File '\\Mac\ClaudeMax\winlink\install.ps1' $arg
