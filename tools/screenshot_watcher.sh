#!/bin/bash
# Watches Flutter console output and takes screenshots when SCREENSHOT_READY markers appear.
# Usage: ./tools/screenshot_watcher.sh <flutter_log_file>
#
# The screenshot tour in the app prints markers like:
#   >>> SCREENSHOT_READY:01_menu
# This script watches for those and runs simctl screenshot.

set -e

DEVICE="39F5DEDB-6F62-497C-BEF9-B47EE17EA7C0"
OUTDIR="$(dirname "$0")/raw_screenshots"
LOGFILE="$1"

if [ -z "$LOGFILE" ]; then
  echo "Usage: $0 <flutter_log_file>"
  echo "The log file is typically at /private/tmp/claude-502/-Users-tmaier/tasks/<task_id>.output"
  exit 1
fi

mkdir -p "$OUTDIR"

echo "Watching $LOGFILE for SCREENSHOT_READY markers..."
echo "Start the screenshot tour in the app now."

tail -f "$LOGFILE" | while read -r line; do
  if echo "$line" | grep -q "SCREENSHOT_READY:"; then
    NAME=$(echo "$line" | sed 's/.*SCREENSHOT_READY://')
    echo "Taking screenshot: $NAME"
    xcrun simctl io "$DEVICE" screenshot "$OUTDIR/$NAME.png"
    echo "  Saved: $OUTDIR/$NAME.png"
  fi
  if echo "$line" | grep -q "SCREENSHOT_TOUR_DONE"; then
    echo "Tour complete!"
    break
  fi
done
