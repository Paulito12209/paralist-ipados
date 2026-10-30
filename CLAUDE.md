# Paralist für iPadOS – Arbeitsregeln

Native iPad-App „Paralist“ (Swift, SwiftUI, iPadOS 26, Liquid Glass), eigene App
`app.paralist.ipad` mit eigenem App-Store-Connect-Eintrag und eigenem TestFlight.
Gegenstück zu `paralist-ios` und `paralist-android`: gleiche Funktionen, gleiches
Dateiformat, aber iPad-typische Bausteine. Aufbau: Split View, Liste 1/3 und
Detail 2/3, native Liquid-Glass-Tabs oben, alle Ausrichtungen, Multitasking und
Stage Manager (siehe `docs/ipad.md`). Private Organisation nach der PARA-Methode mit Karteikarten und
Wochen-Briefing. Alles lokal, kein Konto, kein Server. Der Name wird immer
„Paralist“ geschrieben.

## Ablauf je Sitzung

1. `TZ=Europe/Berlin date +%F` für das Datum.
2. Aufgabe aus dem Prompt verstehen, höchstens drei Rückfragen, dann bauen.
3. Vor dem Ende: `swift test` in `ParalistCore` muss grün sein. App-Build und
   Screenshots laufen über den Workflow `.github/workflows/ios.yml`
   (Screenshots landen im Branch `ci-screenshots`, Ordner `latest/`). Danach
   Review im Chat (Problem, Lösung, Begründung, Skizze vorher/nachher, Risiken).
4. **Nichts committen, bis ich „commit“ sage.** Dann ein Commit mit klarer
   Nachricht direkt auf `main` und sofort pushen. Ohne Freigabe bleibt alles
   unversioniert.
5. Nach jedem Commit und Push: `tools/deploy_ipad.sh` baut, installiert und startet
   die App auf Pauls iPad (Kabel/WLAN, mit App-Gruppe; nicht erreichbare
   werden übersprungen). Geräte stehen lokal in `~/.config/paralist/ipad-devices`
   (eine UDID pro Zeile), `DEVICES=…` wählt einzelne.
6. Danach einmal fragen: „TestFlight-Build hochladen?“ Bei Ja, oder wenn Paul von
   sich aus „TestFlight“ sagt, `tools/testflight.sh` ausführen (baut den Stand von `HEAD`, lädt ihn mit der nächsten Build-Nummer zu
   App Store Connect, reicht ihn bei Bedarf zur Beta-Prüfung ein und hängt ihn an
   die Testgruppe „Freunde“, mit Wiederholung, bis er dort sichtbar ist). Nicht nach jedem
   Prompt, nur am Ende einer Etappe. Kennungen liegen lokal in
   `~/.config/paralist/`, der API-Schlüssel in `~/.appstoreconnect/private_keys/`.
   Die erste Build-Nummer einer neuen Versionsnummer braucht Apples Beta-Prüfung,
   alle weiteren derselben Version nicht. Neue Tester: `tools/testflight_invite.sh
   mail@example.com …` lädt sie in die Gruppe „Freunde“ ein und zeigt die Liste.
7. Nie `git stash`, `git reset --hard` oder `--force`.

## Code-Regeln

- Keine Datei über 400 Zeilen; vorher teilen.
- Keine Kommentare im Code. Einzige Ausnahme: ganz oben in jeder Datei ein
  kurzer Kommentar `// Zusammenhang: …`, der nennt, mit welchen anderen Dateien
  sie zusammenhängt. Das gilt auch für YAML, Skripte und Plists.
- Module: `Paralist` (App, SwiftUI), `ParalistShare` (Teilen-Erweiterung),
  `ParalistWidgets` (Widget „Schnellzugriff“, siehe `docs/widget.md`) und
  `ParalistCore` (Swift-Paket: Modelle, Speicher, Logik; nur Foundation, läuft
  auch unter Linux). Siri-Befehle liegen in `Paralist/Intents/` (siehe
  `docs/siri.md`), ihre Sätze in `AppShortcuts.xcstrings`.
- Oberfläche, Daten und Logik bleiben getrennt. Logik, die sich ohne Gerät
  prüfen lässt, liegt in `ParalistCore` und hat Tests (Swift Testing).
- Dateiformat (Markdown mit Kopf, Ordner `eintraege/`, `anhaenge/`,
  `papierkorb/`, `lernverlauf/`) bleibt identisch zu Android. Nur iOS:
  `chats/` (JSON je Thread, siehe `docs/chat.md`) und `linkverlauf.json`
  (siehe `docs/lesezeichen.md`), Android ignoriert beides.
- Alle Texte in `Paralist/Resources/Localizable.xcstrings`, in allen acht
  Sprachen (de, en, es, fr, zh-Hans, hi, ar, bn). Die Schlüssel kommen aus den
  Android-`strings.xml` (`tools/strings_from_android.py`), iOS-eigene Texte aus
  `tools/strings_ios.json`. Keine Texte im Swift-Code, Zugriff über `L.s`/`L.f`.
- Maße, Farben und Schrift in `Paralist/Theme/` (Dimens, Palette, Typography).
- Icons: eigene Zeichnungen (`Icons/XoolIcons.swift`, Assets `XoolMenu`,
  `XoolPlus`) haben Vorrang. Alles andere aus SF Symbols, eingetragen in
  `Icons/AppIcons.swift`.
- Logo-Bibliothek für Lesezeichen: `Resources/Assets.xcassets/LinkLogos/`,
  ein Bildsatz je Domain (z. B. `spotify.com.imageset`, Subdomains erben,
  Kurzlinks über `LinkLogoLibrary.aliases`), Dunkel-Variante als
  Appearance im Bildsatz. Fehlt ein Bildsatz, holt die App das Icon der Seite.
- Schrift DM Sans liegt in `Paralist/Resources/Fonts/`, nichts aus dem Netz laden.
- Detailseite (Cover-, Canvas-Bereich, Ansichten, Edge Picker, Bottom-Zeile):
  vor Änderungen `docs/detailseite.md` und `docs/cover.md` lesen und danach
  aktuell halten.
- So nativ wie möglich: TabView mit Liquid Glass, NavigationStack, Sheets,
  Menüs, `.searchable`, Swift Charts, PasteButton, Quick Look, AVKit.
- Nur was im Umfang der Etappe steht. Keine Extras.
- Keine persönlichen Daten, keine Schlüssel, keine Sicherheitsgrenzwerte in
  Code-Kommentaren, Doku oder Commit-Nachrichten. Sicherheitsregeln stehen nur
  im Code und in den Tests.

## Bauen und Prüfen

```
cd ParalistCore && swift test
brew install xcodegen && xcodegen generate
open Paralist.xcodeproj
```

Simulator mit Beispieldaten (iPad, z. B. iPad Pro 13-inch): Startargumente `-demo -screen overview`
(weitere: overviewstacked, calendar, tasks, menu, entry, task, photo, deck, bookmark, create, search, progress,
briefing, flashcards, settings, feedback, chats, chat, chatnew, chatwait, chatfail) `-appearance light|dark` und `-orientation landscape|portrait`. Hell und Dunkel
sowie Quer- und Hochformat prüfen, Zurück-Wischgeste prüfen.

## Einmalig einzurichten

1. In App Store Connect die App `app.paralist.ipad` anlegen.
2. Ihre App-ID in `Paralist/App/StoreLinks.swift` (`appId`) eintragen; solange
   sie leer ist, brechen `tools/asc_api.sh`, `tools/testflight.sh` und
   `tools/testflight_invite.sh` mit einer Meldung ab.
3. Geräte-UDIDs lokal in `~/.config/paralist/ipad-devices` ablegen, nie ins Repo.
4. Optional für `.github/workflows/testflight.yml` die GitHub-Secrets
   `APPLE_TEAM_ID`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8` setzen.

## Antworten

Auf Deutsch, knapp und konkret.
