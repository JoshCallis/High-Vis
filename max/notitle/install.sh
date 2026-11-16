#!/bin/bash
# install.sh [stub.app] [--revert] — load notitle.dylib into 3ds Max's Coherence stub
# (see notitle.m for why). Adds LSEnvironment DYLD_INSERT_LIBRARIES to the stub's
# Info.plist and re-registers it with LaunchServices. Takes effect the next time the
# stub starts (Max restart). Idempotent and quiet when already installed — it's run
# on every jump to Max (coherence_fullscreen.sh) because Parallels regenerates stubs.
# No stub given → the one app_resolve.sh cached for "3ds Max 2027", else a search.
HERE="$(cd "$(dirname "$0")" && pwd)"
DYLIB="$HERE/notitle.dylib"
SRC="$HERE/notitle.m"
LSREG=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
PB=/usr/libexec/PlistBuddy
REVERT=; STUB=
for a in "$@"; do [[ "$a" == --revert ]] && REVERT=1 || STUB="$a"; done

if [[ -z "$STUB" ]]; then
  STUB=$(cat /tmp/.coherence_stub_3ds_Max_2027 2>/dev/null)
  [[ -d "$STUB" ]] || STUB=$(grep -l '3ds Max 2027\\3dsmax.exe' ~/Applications\ \(Parallels\)/*/*.app/Contents/Info.plist 2>/dev/null | head -1)
  STUB="${STUB%/Contents/Info.plist}"
fi
PLIST="$STUB/Contents/Info.plist"
[[ -f "$PLIST" ]] || { echo "notitle: no 3ds Max stub found" >&2; exit 1; }

if [[ -n "$REVERT" ]]; then
  "$PB" -c "Delete :LSEnvironment:DYLD_INSERT_LIBRARIES" "$PLIST" 2>/dev/null
  "$LSREG" -f "$STUB"; echo "notitle: removed from $STUB (live at the next Max start)"; exit 0
fi

# build if missing or stale
if [[ ! -f "$DYLIB" || "$SRC" -nt "$DYLIB" ]]; then
  clang -arch arm64 -dynamiclib -fobjc-arc -framework AppKit -o "$DYLIB" "$SRC" || exit 1
fi

[[ "$("$PB" -c "Print :LSEnvironment:DYLD_INSERT_LIBRARIES" "$PLIST" 2>/dev/null)" == "$DYLIB" ]] && exit 0
"$PB" -c "Add :LSEnvironment dict" "$PLIST" 2>/dev/null
"$PB" -c "Delete :LSEnvironment:DYLD_INSERT_LIBRARIES" "$PLIST" 2>/dev/null
"$PB" -c "Add :LSEnvironment:DYLD_INSERT_LIBRARIES string $DYLIB" "$PLIST"
"$LSREG" -f "$STUB"
echo "notitle: installed into $STUB (live at the next Max start)"
