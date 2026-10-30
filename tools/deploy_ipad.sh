#!/bin/bash
# Zusammenhang: project.yml, Paralist/Paralist.entitlements, ~/.config/paralist/{team-id,asc-key-id,asc-issuer-id} (lokal, nicht im Repo), ~/.appstoreconnect/private_keys (lokal), tools/testflight.sh, Paralist/App/AppPaths.swift, CLAUDE.md
set -euo pipefail
cd "$(dirname "$0")/.."
TEAM_FILE="$HOME/.config/paralist/team-id"
TEAM="${TEAM:-$( [ -r "$TEAM_FILE" ] && tr -d '[:space:]' < "$TEAM_FILE" )}"
if [ -z "$TEAM" ]; then
  read -r -p "Apple-Team-ID (wird in $TEAM_FILE gemerkt): " TEAM
  mkdir -p "$(dirname "$TEAM_FILE")"
  printf '%s\n' "$TEAM" > "$TEAM_FILE"
  chmod 600 "$TEAM_FILE"
fi
AUTH=(-allowProvisioningUpdates)
KID="$( [ -r "$HOME/.config/paralist/asc-key-id" ] && tr -d '[:space:]' < "$HOME/.config/paralist/asc-key-id" || true)"
ISS="$( [ -r "$HOME/.config/paralist/asc-issuer-id" ] && tr -d '[:space:]' < "$HOME/.config/paralist/asc-issuer-id" || true)"
KEY="$HOME/.appstoreconnect/private_keys/AuthKey_$KID.p8"
if [ -n "$KID" ] && [ -n "$ISS" ] && [ -r "$KEY" ]; then
  AUTH+=(-authenticationKeyPath "$KEY" -authenticationKeyID "$KID" -authenticationKeyIssuerID "$ISS")
fi
DEVICES_FILE="$HOME/.config/paralist/ipad-devices"
DEVICES="${DEVICES:-${DEVICE:-$( [ -r "$DEVICES_FILE" ] && tr -s '[:space:]' ' ' < "$DEVICES_FILE" || true)}}"
if [ -z "${DEVICES// /}" ]; then
  echo "Keine Geräte angegeben: DEVICES=\"<UDID> …\" setzen oder je eine UDID pro Zeile in $DEVICES_FILE eintragen." >&2
  exit 1
fi
DD="${DD:-$HOME/Library/Caches/paralist-ipad-dd}"
XCODEGEN="$(command -v xcodegen || true)"
for candidate in "$HOME/.local/xcodegen/bin/xcodegen" /opt/homebrew/bin/xcodegen /usr/local/bin/xcodegen; do
  [ -n "$XCODEGEN" ] && break
  [ -x "$candidate" ] && XCODEGEN="$candidate"
done
if [ -z "$XCODEGEN" ]; then
  command -v brew >/dev/null || { echo "xcodegen fehlt und Homebrew ist nicht installiert." >&2; exit 1; }
  brew install xcodegen
  XCODEGEN="$(command -v xcodegen)"
fi
"$XCODEGEN" generate >/dev/null
LOG="$DD/build.log"
mkdir -p "$DD"
FAILED=0
for DEVICE in $DEVICES; do
  if ! xcrun devicectl device info details --device "$DEVICE" >/dev/null 2>&1; then
    echo "Gerät $DEVICE nicht erreichbar, übersprungen" >&2
    FAILED=1
    continue
  fi
  if ! xcodebuild -project Paralist.xcodeproj -scheme Paralist -configuration Debug \
    -destination "id=$DEVICE" -derivedDataPath "$DD" DEVELOPMENT_TEAM="$TEAM" \
    "${AUTH[@]}" build >"$LOG" 2>&1; then
    grep -E "error:" "$LOG" | sort -u >&2 || true
    echo "Build für $DEVICE fehlgeschlagen, Protokoll: $LOG" >&2
    FAILED=1
    continue
  fi
  echo "Build ok für $DEVICE"
  if ! xcrun devicectl device install app --device "$DEVICE" "$DD/Build/Products/Debug-iphoneos/Paralist.app"; then
    FAILED=1
    continue
  fi
  xcrun devicectl device process launch --device "$DEVICE" app.paralist.ipad >/dev/null 2>&1 || echo "Installiert auf $DEVICE, Start nicht möglich (Gerät gesperrt?)" >&2
done
exit $FAILED
