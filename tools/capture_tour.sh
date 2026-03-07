#!/bin/bash
# Capture screenshots by watching flutter log for SCREENSHOT_READY markers.
# Usage: Run this script, then tap SCREENSHOT TOUR in the debug overlay.
set -e

DEVICE="39F5DEDB-6F62-497C-BEF9-B47EE17EA7C0"
OUTDIR="$(dirname "$0")/raw_screenshots"
mkdir -p "$OUTDIR"

echo "Watching simulator log for SCREENSHOT_READY markers..."
echo "Go to Debug > SCREENSHOT TOUR in the app."
echo ""

# Use predicate to filter for flutter prints from Runner process
xcrun simctl spawn "$DEVICE" log stream --level debug --predicate 'process == "Runner"' 2>/dev/null | while IFS= read -r line; do
  if echo "$line" | grep -q "SCREENSHOT_READY:"; then
    name=$(echo "$line" | grep -o "SCREENSHOT_READY:[^ ]*" | sed 's/SCREENSHOT_READY://')
    sleep 0.5
    xcrun simctl io "$DEVICE" screenshot "$OUTDIR/${name}.png" 2>/dev/null
    echo "  Captured: ${name}"
  fi
  if echo "$line" | grep -q "SCREENSHOT_TOUR_DONE"; then
    echo ""
    echo "Tour complete! Screenshots in $OUTDIR/"
    kill $$ 2>/dev/null
    exit 0
  fi
done
