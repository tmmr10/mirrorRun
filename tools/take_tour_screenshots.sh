#!/bin/bash
# Take screenshots at fixed intervals matching the screenshot tour timing.
# Run this FIRST, then immediately tap SCREENSHOT TOUR in the app.
set -e

DEVICE="39F5DEDB-6F62-497C-BEF9-B47EE17EA7C0"
OUTDIR="$(dirname "$0")/raw_screenshots"
mkdir -p "$OUTDIR"

echo "Waiting for you to tap SCREENSHOT TOUR..."
echo "Taking screenshots at fixed intervals."
echo ""

# Tour timing:
# 0s: tour starts
# 2.5s: menu ready -> screenshot at ~3s
# 3s+3s=6s: gameplay starts, +3s run +pause = screenshot at ~9s
# +3s resume +goToMenu +2.5s run +0.5s phantom +pause = screenshot at ~15s
# +3s resume +goToMenu +2.5s run +0.5s swap +pause = screenshot at ~21s
# +3s resume +goToMenu +0.5s +0.8s skins = screenshot at ~25s

take() {
  xcrun simctl io "$DEVICE" screenshot "$OUTDIR/$1.png" 2>/dev/null
  echo "  Captured: $1"
}

echo "Starting in 3 seconds... tap SCREENSHOT TOUR NOW!"
sleep 3

echo ""
echo "Tour running..."

# 1. Menu (at ~2.5s after tour start)
sleep 3
take "01_menu"

# 2. Gameplay (menu wait 3s done, game starts, 3s gameplay, pause)
sleep 6
take "02_gameplay"

# 3. Phantom (resume 3s, goToMenu, start, 2.5s play, phantom, pause)
sleep 6.5
take "03_phantom"

# 4. Swap (resume 3s, goToMenu, start, 2.5s play, swap, pause)
sleep 6.5
take "04_swap"

# 5. Skins (resume 3s, goToMenu, 0.5+0.8s skins)
sleep 5
take "05_skins"

echo ""
echo "Done! Screenshots in $OUTDIR/"
