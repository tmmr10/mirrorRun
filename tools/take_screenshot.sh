#!/bin/bash
# Take an App Store screenshot from the running iOS Simulator
# Usage: ./tools/take_screenshot.sh <name>
# Example: ./tools/take_screenshot.sh 01_menu
#
# Screenshots are saved to ios/fastlane/screenshots/en-US/
# and resized to 1284x2778 (iPhone 6.5" requirement)

set -e

DEVICE_ID="39F5DEDB-6F62-497C-BEF9-B47EE17EA7C0"
OUT_DIR="ios/fastlane/screenshots/en-US"
NAME="${1:-screenshot}"
TIMESTAMP=$(date +%s)
RAW="/tmp/screenshot_raw_${TIMESTAMP}.png"
FINAL="${OUT_DIR}/${NAME}.png"

# Capture
xcrun simctl io "$DEVICE_ID" screenshot --type=png "$RAW"

# Resize to 1284x2778 (iPhone 6.5" App Store requirement)
sips -z 2778 1284 "$RAW" --out "$FINAL" > /dev/null 2>&1

rm -f "$RAW"
echo "Saved: $FINAL (1284x2778)"
