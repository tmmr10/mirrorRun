#!/bin/bash
# Add text overlay to App Store screenshot
# Usage: ./add_overlay.sh input.png "HEADLINE" "Subtext" output.png [top_color]

set -e

INPUT="$1"
HEADLINE="$2"
SUBTEXT="$3"
OUTPUT="$4"
COLOR="${5:-#B48CFF}"

WIDTH=$(identify -format "%w" "$INPUT")
HEIGHT=$(identify -format "%h" "$INPUT")

# Create gradient overlay at top (dark fade)
convert "$INPUT" \
  \( -size ${WIDTH}x600 gradient:"#000000CC"-"#00000000" \) \
  -gravity North -composite \
  \( -size ${WIDTH}x400 gradient:"#00000000"-"#000000AA" \) \
  -gravity South -composite \
  -gravity North \
  -font "Helvetica-Bold" \
  -pointsize 88 \
  -fill "$COLOR" \
  -annotate +0+140 "$HEADLINE" \
  -font "Helvetica" \
  -pointsize 48 \
  -fill "#FFFFFFBB" \
  -annotate +0+260 "$SUBTEXT" \
  "$OUTPUT"

echo "Created: $OUTPUT"
