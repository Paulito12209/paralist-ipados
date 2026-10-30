#!/bin/bash
# Zusammenhang: tools/testflight.sh, tools/testflight_invite.sh, Paralist/App/StoreLinks.swift (App-ID), ~/.config/paralist/{team-id,asc-key-id,asc-issuer-id} (lokal), ~/.appstoreconnect/private_keys (lokal)
CFG="$HOME/.config/paralist"
need() { [ -r "$CFG/$1" ] || { echo "Fehlt: $CFG/$1" >&2; exit 1; }; tr -d '[:space:]' < "$CFG/$1"; }
TEAM=$(need team-id); KID=$(need asc-key-id); ISS=$(need asc-issuer-id)
KEY="$HOME/.appstoreconnect/private_keys/AuthKey_$KID.p8"
[ -r "$KEY" ] || { echo "Fehlt: $KEY" >&2; exit 1; }
APP_ID=$(sed -n 's/.*appId = "\([0-9]*\)".*/\1/p' "$(dirname "${BASH_SOURCE[0]}")/../Paralist/App/StoreLinks.swift")
[ -n "$APP_ID" ] || { echo "App-ID fehlt: in App Store Connect App anlegen und ID in StoreLinks.swift eintragen" >&2; exit 1; }
GROUP="${GROUP:-Freunde}"

b64() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
token() {
  local now h p sig
  now=$(date +%s)
  h=$(printf '{"alg":"ES256","kid":"%s","typ":"JWT"}' "$KID" | b64)
  p=$(printf '{"iss":"%s","iat":%d,"exp":%d,"aud":"appstoreconnect-v1"}' "$ISS" "$now" $((now + 1200)) | b64)
  sig=$(printf '%s.%s' "$h" "$p" | openssl dgst -sha256 -sign "$KEY" -binary | openssl asn1parse -inform DER | grep INTEGER | sed 's/.*://' | while read -r x; do printf '%064s' "$x" | tr ' ' 0; done | xxd -r -p | b64)
  printf '%s.%s.%s' "$h" "$p" "$sig"
}
api() { curl -sSg -X "$1" "https://api.appstoreconnect.apple.com/v1/$2" -H "Authorization: Bearer $(token)" -H "Content-Type: application/json" ${3:+-d "$3"}; }
field() { python3 -c "import sys,json; d=json.load(sys.stdin); print($1)"; }
group_id() { api GET "betaGroups?filter[app]=$APP_ID&filter[name]=$GROUP" | field "d['data'][0]['id']"; }
