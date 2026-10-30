#!/bin/bash
# Zusammenhang: .github/workflows/ios.yml (iPadOS), Paralist/App/LaunchOptions.swift, Paralist/App/DemoSeed.swift
set -euo pipefail
APP="$1"
OUT="$2"
mkdir -p "$OUT"
DEVICE=$(xcrun simctl list devices available -j | python3 -c "import json,sys; d=json.load(sys.stdin)['devices']; c=[x for k,v in d.items() if 'iOS' in k for x in v if x['name'].startswith('iPad Pro') and '13-inch' in x['name']]; c=c or [x for k,v in d.items() if 'iOS' in k for x in v if x['name'].startswith('iPad')]; print(c[-1]['udid'])")
xcrun simctl boot "$DEVICE" || true
xcrun simctl bootstatus "$DEVICE" -b
xcrun simctl status_bar "$DEVICE" override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 || true
xcrun simctl install "$DEVICE" "$APP"
shoot() {
  local screen="$1" look="$2" orient="${3:-landscape}" name="$screen-$look"
  [ "$orient" = "portrait" ] && name="$screen-$look-portrait"
  xcrun simctl terminate "$DEVICE" app.paralist.ipad >/dev/null 2>&1 || true
  xcrun simctl ui "$DEVICE" appearance "$look"
  xcrun simctl launch "$DEVICE" app.paralist.ipad -demo -screen "$screen" -appearance "$look" -orientation "$orient" -AppleLanguages "(de)" -AppleLocale de_DE >/dev/null
  sleep 6
  xcrun simctl io "$DEVICE" screenshot "$OUT/$name.png" >/dev/null
}
for screen in overview overviewstacked calendar tasks menu entry photo bookmark create search progress briefing flashcards settings feedback chats chat; do
  shoot "$screen" light landscape
done
for screen in overview overviewstacked calendar menu entry chat; do
  shoot "$screen" dark landscape
done
for screen in overview entry; do
  shoot "$screen" light portrait
done
