#!/bin/bash
# Generate App Store screenshots from the iOS Simulator.
#
# Requirements:
#   - Xcode with simulators installed
#   - Flutter SDK in PATH
#   - App must be running in the simulator
#
# Usage:
#   1. Start the app:  flutter run -d <simulator-id>
#   2. Navigate to the screen you want to capture
#   3. Run:  bash tools/generate_screenshots.sh <device-name> <label>
#
# Apple required screenshot sizes:
#   - 6.9" (iPhone 16 Pro Max): 1320 x 2868
#   - 6.7" (iPhone 15 Plus):    1290 x 2796
#   - 6.5" (iPhone 14 Plus):    1284 x 2778
#   - 5.5" (iPhone 8 Plus):     1242 x 2208
#   - iPad Pro 13" (6th gen):   2048 x 2732
#   - iPad Pro 12.9" (2nd gen): 2048 x 2732

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SCREENSHOTS_DIR="$PROJECT_DIR/ios/fastlane/screenshots"

# Screenshot destinations per locale
LOCALES=("en-US" "de-DE")

echo "=== Mirror Runners Screenshot Helper ==="
echo ""
echo "This script captures screenshots from a running iOS Simulator."
echo ""

# Create screenshot directories
for locale in "${LOCALES[@]}"; do
    mkdir -p "$SCREENSHOTS_DIR/$locale"
done

echo "Screenshot directories created at: $SCREENSHOTS_DIR"
echo ""
echo "--- Manual Screenshot Workflow ---"
echo ""
echo "1. Boot simulators and run the app:"
echo "   iPhone 16 Pro Max (6.9\"):"
echo "     flutter run -d 'iPhone 16 Pro Max'"
echo ""
echo "2. Take screenshots with xcrun:"
echo "   xcrun simctl io booted screenshot screenshot_name.png"
echo ""
echo "3. Required screenshots (minimum 3 per device):"
echo "   - Gameplay (Forest biome)"
echo "   - Gameplay (Neon or Void biome)"
echo "   - Death screen with score"
echo "   - Menu screen"
echo "   - Biome transition"
echo ""
echo "4. Naming convention for fastlane:"
echo "   {locale}/{order}_{description}_{device}.png"
echo "   Example: en-US/01_gameplay_forest_6.9.png"
echo ""
echo "5. Device display sizes needed:"

DEVICES=(
    "iPhone 16 Pro Max:6.9 inch:1320x2868"
    "iPhone 15 Plus:6.7 inch:1290x2796"
    "iPhone 8 Plus:5.5 inch:1242x2208"
    "iPad Pro 13-inch:iPad Pro 13:2048x2732"
)

for device_info in "${DEVICES[@]}"; do
    IFS=':' read -r name display_size resolution <<< "$device_info"
    echo "   - $name ($display_size): $resolution"
done

echo ""
echo "--- Quick Capture (single device) ---"
echo ""

# If a simulator is booted, offer to take a screenshot now
BOOTED=$(xcrun simctl list devices | grep "Booted" | head -1 | sed 's/.*(\(.*\)) (Booted)/\1/')

if [ -n "$BOOTED" ]; then
    DEVICE_NAME=$(xcrun simctl list devices | grep "Booted" | head -1 | sed 's/^[[:space:]]*//' | sed 's/ (.*//')
    echo "Active simulator: $DEVICE_NAME ($BOOTED)"
    echo ""

    LABEL="${1:-screenshot}"
    TIMESTAMP=$(date +%s)

    for locale in "${LOCALES[@]}"; do
        OUTPUT="$SCREENSHOTS_DIR/$locale/${LABEL}_${TIMESTAMP}.png"
        xcrun simctl io "$BOOTED" screenshot "$OUTPUT"
        echo "Saved: $OUTPUT"
    done
else
    echo "No simulator currently booted."
    echo "Start one with: open -a Simulator"
    echo "Then run the app: flutter run -d <device-id>"
fi
