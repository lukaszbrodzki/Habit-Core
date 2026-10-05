#!/bin/zsh
# Captures raw App Store screenshots + widget renders from a 6.9" simulator (Debug build).
# Usage: ./capture.sh [simulator-udid]   (default: iPhone 17 Pro Max, iOS 26.2+)
set -e
UDID=${1:-C1055DE1-027A-4032-908D-8C7870C8A040}
BID=com.lukbro.atomichabits
DIR=${0:A:h}
RAW="$DIR/raw"; mkdir -p "$RAW"
DD="${TMPDIR:-/tmp}/habitcore-shots-dd"

xcrun simctl boot $UDID 2>/dev/null || true
xcodebuild -project "$DIR/../../Habit Core/Habit Core.xcodeproj" -scheme "Habit Core" -configuration Debug \
  -destination "id=$UDID" -derivedDataPath "$DD" build | grep -E "error:|BUILD"
xcrun simctl install $UDID "$DD/Build/Products/Debug-iphonesimulator/Habit Core.app"
xcrun simctl status_bar $UDID override --time "9:41" --batteryState discharging --batteryLevel 100 --cellularBars 4 --wifiBars 3

shot() { local name=$1 lang=$2; shift 2
  local locale=$([ $lang = pl ] && echo pl_PL || echo en_US)
  xcrun simctl terminate $UDID $BID 2>/dev/null || true
  xcrun simctl launch $UDID $BID UI_TESTING_SEED_DATA "$@" -AppleLanguages "($lang)" -AppleLocale $locale >/dev/null
  sleep 7
  [ "$name" = "-" ] || xcrun simctl io $UDID screenshot "$RAW/${name}_${lang}.png" >/dev/null 2>&1; }

for lang in pl en; do
  shot focus $lang UI_TESTING_INITIAL_TAB=today
  shot tracker $lang UI_TESTING_INITIAL_TAB=tracker
  shot allhabits $lang UI_TESTING_INITIAL_TAB=tracker UI_TESTING_SHOW_COMBINED
  shot add $lang UI_TESTING_INITIAL_TAB=today UI_TESTING_OPEN_ADD
  shot - $lang UI_TESTING_RENDER_WIDGETS
  DATA=$(xcrun simctl get_app_container $UDID $BID data)
  for w in widget_small widget_medium_all widget_medium_single; do cp "$DATA/Documents/$w.png" "$RAW/${w}_${lang}.png"; done
done
xcrun simctl terminate $UDID $BID 2>/dev/null || true
echo "Raw captures in $RAW — now run: node generator/generate.js"
