# Paralist für iPadOS

Native iPad-App zur privaten Organisation nach der PARA-Methode (Projekte,
Arbeitsbereiche, Ressourcen, Archiv) mit Karteikarten und Wochen-Briefing.
Alle Daten bleiben auf dem Gerät. Gegenstück zu `paralist-ios` und
`paralist-android`, gleiches Dateiformat. Eigene App (`app.paralist.ipad`) mit
eigenem App-Store-Connect-Eintrag und eigenem TestFlight.

- Swift, SwiftUI, iPadOS 26 (Liquid Glass), Swift Charts
- Split View: Liste 1/3, Detail 2/3, Liquid-Glass-Tabs oben, alle
  Ausrichtungen, Multitasking und Stage Manager (siehe `docs/ipad.md`)
- `ParalistCore`: Logik als Swift-Paket mit Tests (`swift test`)
- `ParalistShare`: Teilen-Erweiterung – Links (z. B. YouTube) aus jeder App
  direkt als Lesezeichen speichern
- Projekt wird mit XcodeGen aus `project.yml` erzeugt

Loslegen: `brew install xcodegen && xcodegen generate && open Paralist.xcodeproj`.
Für ein echtes Gerät in Xcode unter „Signing & Capabilities“ das eigene Team
wählen und die App Group `group.app.paralist.ipad` bestätigen.

Einmalig einrichten:

1. In App Store Connect die App `app.paralist.ipad` anlegen.
2. Ihre App-ID in `Paralist/App/StoreLinks.swift` (`appId`) eintragen.
3. Geräte für `tools/deploy_ipad.sh`: je eine UDID pro Zeile in
   `~/.config/paralist/ipad-devices` oder `DEVICES="…"` setzen.
4. Optional für `.github/workflows/testflight.yml` die GitHub-Secrets
   `APPLE_TEAM_ID`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8` setzen.
