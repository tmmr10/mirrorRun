#!/bin/bash
# Burst mode: take a screenshot every 1.5 seconds for 45 seconds.
# Then we pick the best ones for each scene.
set -e

DEVICE="39F5DEDB-6F62-497C-BEF9-B47EE17EA7C0"
OUTDIR="$(dirname "$0")/burst"
rm -rf "$OUTDIR"
mkdir -p "$OUTDIR"

echo "Burst screenshot mode - capturing every 1.5s for 45s"
echo "Tap SCREENSHOT TOUR in the app NOW!"
echo ""

for i in $(seq -w 1 30); do
  xcrun simctl io "$DEVICE" screenshot "$OUTDIR/frame_${i}.png" 2>/dev/null
  echo "  Frame $i captured"
  sleep 1.5
done

echo ""
echo "Done! $OUTDIR/ has all frames."
echo "Pick the best ones for each scene."
