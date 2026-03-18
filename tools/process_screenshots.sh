#!/bin/bash
# Process raw screenshots: crop status bar, resize, add text overlays
set -e

RAW="$(dirname "$0")/raw_screenshots"
EN_OUT="/Users/tmaier/mirror_run/ios/fastlane/screenshots/en-US"
DE_OUT="/Users/tmaier/mirror_run/ios/fastlane/screenshots/de-DE"
TMPDIR="$(dirname "$0")/tmp_screenshots"

mkdir -p "$TMPDIR" "$EN_OUT" "$DE_OUT"

TARGET_W=1284
TARGET_H=2778

add_overlay() {
  local INPUT="$1"
  local OUTPUT="$2"
  local HEADLINE="$3"
  local SUBTEXT="$4"
  local COLOR="${5:-#B48CFF}"

  convert "$INPUT" \
    \( -size "${TARGET_W}x700" gradient:"rgba(0,0,0,0.85)"-"rgba(0,0,0,0)" \) \
    -gravity North -composite \
    \( -size "${TARGET_W}x500" gradient:"rgba(0,0,0,0)"-"rgba(0,0,0,0.6)" \) \
    -gravity South -composite \
    -gravity North \
    -font "Helvetica-Bold" \
    -pointsize 82 \
    -fill "$COLOR" \
    -annotate +0+160 "$HEADLINE" \
    -font "Helvetica" \
    -pointsize 44 \
    -fill "rgba(255,255,255,0.75)" \
    -annotate +0+270 "$SUBTEXT" \
    "$OUTPUT"
}

# Step 1: Resize all raw screenshots
for f in "$RAW"/*.png; do
  NAME=$(basename "$f")
  convert "$f" -resize "${TARGET_W}x${TARGET_H}!" "$TMPDIR/$NAME"
  echo "Resized: $NAME"
done

# Step 2: EN overlays
echo ""
echo "=== English overlays ==="
add_overlay "$TMPDIR/01_menu.png" "$EN_OUT/01_menu.png" \
  "Two Runners. One Move." "Dodge both sides to survive."

add_overlay "$TMPDIR/02_neon_gameplay.png" "$EN_OUT/02_neon_gameplay.png" \
  "11 Biomes to Unlock" "How far can you go?"

add_overlay "$TMPDIR/03_phantom.png" "$EN_OUT/03_phantom.png" \
  "Phantom Mode" "Obstacles turn invisible. Stay sharp."

add_overlay "$TMPDIR/04_swap.png" "$EN_OUT/04_swap.png" \
  "Mirror Swap" "Left is right. Right is left. Good luck." "#FF6644"

add_overlay "$TMPDIR/05_skins.png" "$EN_OUT/05_skins.png" \
  "7 Unlockable Skins" "Earn new looks as you explore."

echo "EN done!"

# Step 3: DE overlays
echo ""
echo "=== German overlays ==="
add_overlay "$TMPDIR/01_menu.png" "$DE_OUT/01_menu.png" \
  "Zwei Runner. Eine Bewegung." "Weiche auf beiden Seiten aus."

add_overlay "$TMPDIR/02_neon_gameplay.png" "$DE_OUT/02_neon_gameplay.png" \
  "11 Biome freischalten" "Wie weit kommst du?"

add_overlay "$TMPDIR/03_phantom.png" "$DE_OUT/03_phantom.png" \
  "Phantom-Modus" "Hindernisse werden unsichtbar."

add_overlay "$TMPDIR/04_swap.png" "$DE_OUT/04_swap.png" \
  "Mirror Swap" "Links ist rechts. Rechts ist links." "#FF6644"

add_overlay "$TMPDIR/05_skins.png" "$DE_OUT/05_skins.png" \
  "7 freischaltbare Skins" "Verdiene neue Looks auf deiner Reise."

echo "DE done!"
echo ""
echo "=== All screenshots processed! ==="
