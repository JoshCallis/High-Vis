#!/bin/bash
# Copy the shared search kit into max/palette/vendor/ — Max loads the palette from the
# \\Mac\ClaudeMax share (and later a standalone PC), which can't see fusion_ui/.
# Run after editing any of these in fusion_ui/; test_palette.py fails while they differ.
#   /Users/josh/Code/Scripts/max/palette/sync.sh
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/../../fusion_ui"
for f in search.js search.css theme.css fingers.js; do
  cp "$SRC/$f" "$HERE/vendor/$f"
done
echo "synced: $(ls "$HERE/vendor" | tr '\n' ' ')"
