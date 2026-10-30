#!/bin/bash
# Zusammenhang: tools/asc_api.sh (API-Zugang), tools/deploy_ipad.sh, project.yml, CLAUDE.md
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/asc_api.sh"
cd "$(dirname "$0")/.."
WORK="${WORK:-$HOME/Library/Caches/paralist-ipad-tf}"

LAST=$(api GET "builds?filter[app]=$APP_ID&fields[builds]=version&limit=200" | field "max([int(b['attributes']['version']) for b in d['data']] or [0])")
NUM=$((LAST + 1))
echo "Build $NUM (zuletzt bei Apple: $LAST)"

rm -rf "$WORK"; mkdir -p "$WORK/src"
git archive HEAD | tar -x -C "$WORK/src"
cd "$WORK/src"
xcodegen generate >/dev/null
AUTH=(-allowProvisioningUpdates -authenticationKeyPath "$KEY" -authenticationKeyID "$KID" -authenticationKeyIssuerID "$ISS")
xcodebuild -project Paralist.xcodeproj -scheme Paralist -configuration Release -destination 'generic/platform=iOS' \
  -archivePath "$WORK/Paralist.xcarchive" -derivedDataPath "$WORK/dd" DEVELOPMENT_TEAM="$TEAM" CURRENT_PROJECT_VERSION="$NUM" \
  "${AUTH[@]}" archive > "$WORK/archive.log" 2>&1 || { grep -E "error:" "$WORK/archive.log" | sort -u >&2; echo "Archiv fehlgeschlagen, Protokoll: $WORK/archive.log" >&2; exit 1; }
cat > "$WORK/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>method</key><string>app-store-connect</string>
<key>destination</key><string>upload</string>
<key>teamID</key><string>$TEAM</string>
<key>uploadSymbols</key><true/>
<key>signingStyle</key><string>automatic</string>
</dict></plist>
PLIST
xcodebuild -exportArchive -archivePath "$WORK/Paralist.xcarchive" -exportPath "$WORK/export" -exportOptionsPlist "$WORK/ExportOptions.plist" \
  "${AUTH[@]}" > "$WORK/export.log" 2>&1 || { grep -iE "error" "$WORK/export.log" | sort -u >&2; echo "Upload fehlgeschlagen, Protokoll: $WORK/export.log" >&2; exit 1; }
echo "Upload ok, warte auf Verarbeitung"

GID=$(group_id)
for _ in $(seq 1 30); do
  BID=$(api GET "builds?filter[app]=$APP_ID&filter[version]=$NUM&fields[builds]=processingState" | field "next((b['id'] for b in d['data'] if b['attributes']['processingState']=='VALID'), '')")
  [ -n "$BID" ] && break
  sleep 30
done
[ -n "$BID" ] || { echo "Build $NUM ist nach 15 Minuten noch nicht verarbeitet; Gruppe später von Hand zuweisen." >&2; exit 1; }
STATE=$(api GET "builds/$BID/buildBetaDetail" | field "d.get('data',{}).get('attributes',{}).get('externalBuildState','')")
if [ "$STATE" = "READY_FOR_BETA_SUBMISSION" ]; then
  api POST "betaAppReviewSubmissions" "{\"data\":{\"type\":\"betaAppReviewSubmissions\",\"relationships\":{\"build\":{\"data\":{\"type\":\"builds\",\"id\":\"$BID\"}}}}}" >/dev/null
  echo "Build $NUM zur Beta-Prüfung eingereicht"
fi
DID=$(api GET "builds/$BID/buildBetaDetail" | field "d['data']['id']")
api PATCH "buildBetaDetails/$DID" "{\"data\":{\"type\":\"buildBetaDetails\",\"id\":\"$DID\",\"attributes\":{\"autoNotifyEnabled\":true}}}" >/dev/null
IN=""
for _ in $(seq 1 20); do
  api POST "betaGroups/$GID/relationships/builds" "{\"data\":[{\"type\":\"builds\",\"id\":\"$BID\"}]}" >/dev/null || true
  IN=$(api GET "betaGroups/$GID/builds?fields[builds]=version&limit=200" | field "'ja' if any(b['id']=='$BID' for b in d.get('data',[])) else ''")
  [ -n "$IN" ] && break
  sleep 30
done
[ -n "$IN" ] || { echo "Build $NUM hängt nach 10 Minuten noch nicht an $GROUP; Gruppe später von Hand zuweisen." >&2; exit 1; }
NOTIFIED=""
for _ in $(seq 1 20); do
  STATE=$(api GET "builds/$BID/buildBetaDetail" | field "d.get('data',{}).get('attributes',{}).get('externalBuildState','')")
  case "$STATE" in IN_BETA_TESTING|WAITING_FOR_BETA_REVIEW|IN_BETA_REVIEW) break;; esac
  if [ "$STATE" = "BETA_APPROVED" ] && [ -z "$NOTIFIED" ]; then
    api POST "buildBetaNotifications" "{\"data\":{\"type\":\"buildBetaNotifications\",\"relationships\":{\"build\":{\"data\":{\"type\":\"builds\",\"id\":\"$BID\"}}}}}" >/dev/null && NOTIFIED=ja && echo "Build $NUM war nur genehmigt, Tester benachrichtigt"
  fi
  sleep 30
done
echo "Build $NUM an Gruppe $GROUP gehängt, Beta-Status: $STATE"
[ "$STATE" = "IN_BETA_TESTING" ] && echo "Build $NUM ist für die Tester verfügbar" || echo "Build $NUM ist noch nicht verteilt, Status später prüfen" >&2
