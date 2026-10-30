#!/bin/bash
# Zusammenhang: tools/asc_api.sh, tools/testflight.sh, CLAUDE.md
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/asc_api.sh"
[ $# -gt 0 ] || { echo "Aufruf: tools/testflight_invite.sh mail@example.com [weitere …]" >&2; exit 1; }
GID=$(group_id)
for MAIL in "$@"; do
  OUT=$(api POST "betaTesters" "{\"data\":{\"type\":\"betaTesters\",\"attributes\":{\"email\":\"$MAIL\"},\"relationships\":{\"betaGroups\":{\"data\":[{\"type\":\"betaGroups\",\"id\":\"$GID\"}]}}}}")
  echo "$OUT" | field "('eingeladen: ' + d['data']['attributes']['email']) if 'data' in d else ('Fehler bei $MAIL: ' + '; '.join(e.get('detail','') for e in d.get('errors',[])))"
done
echo "== Gruppe $GROUP"
api GET "betaGroups/$GID/betaTesters?fields[betaTesters]=email,state&limit=200" | field "'\n'.join(f\"{t['attributes']['email']}  {t['attributes'].get('state','')}\" for t in d['data'])"
