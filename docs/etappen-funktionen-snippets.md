<!-- Zusammenhang: CLAUDE.md, docs/siri.md (Spracheingabe), ParalistCore/Sources/ParalistCore/Planning/SpokenEvent.swift, ParalistCore/Sources/ParalistCore/Planning/SpokenWords.swift, ParalistCore/Sources/ParalistCore/Library/ComposerDraft.swift, Paralist/Composer/ComposerDictation.swift, Paralist/Pages/SettingsPage.swift, Paralist/Chat/ChatEngine.swift -->
# Etappen: Funktionen und Snippets (Trigger-Wörter)

Prompt für eine neue Sitzung auf dem Mac (Umgebung paralist-ios). Text ab
„Lies zuerst“ vollständig einfügen.

## Ziel

Ein Abschnitt „Funktionen“ in den Einstellungen, in dem Paul eigene
**Snippets** anlegt: ein Trigger-Wort (z. B. „Spätschicht“) plus Vorlage,
die beim Erstellen eines Eintrags automatisch Titel, Details, Typ, Datum,
Uhrzeit (Beginn und Ende) und Erinnerung füllt, sobald das Wort gesprochen
oder getippt wird. Snippets bauen auf der bestehenden Spracheingabe auf
(`SpokenEvent`, Regel-Bibliothek, Modell-Nachprüfung) und greifen auf allen
drei Wegen: Diktat-Overlay, Tastatur-Diktat beim Absenden, getippter Titel.

## Stand (2026-10-30)

- `SpokenEvent.parse` liest aus einem Satz Titel, Tag, Beginn, Ende,
  Ganztag, Erinnerungs-Absicht; Wortlisten in `SpokenWords`, Tage in
  `SpokenDates`, Uhrzeiten in `SpokenTimes`, Nebensätze/Leitsätze in
  `SpokenParser`. Tests: `SpokenEventTests`, `SpokenWordingTests`.
- `ComposerDraft.apply`, `remind`, `absorbTitle` übernehmen das Ergebnis in
  den Entwurf; `ComposerDictation` steuert Vorschau, Modell (`SpokenRefiner`)
  und Ziel (Titel/Details); Overlay `DictationOverlay`.
- Einstellungen: `AppPrefs` (UserDefaults), `SettingsPage`; Tageszeiten
  (`DayPeriods`) sind das Vorbild für eine Einstellung mit Logik im Kern.
- Dateiformat ist mit Android geteilt; iOS-eigene Dateien im Datenordner
  (`chats/`, `linkverlauf.json`) ignoriert Android.

## Entscheidungen (vorab von Paul, 2026-10-30)

- Snippets sind Daten, keine Programmierung: Trigger-Wort, Vorlage, fertig.
- Trigger-Wort schlägt die Regel-Bibliothek: sagt ein Snippet „Uhrzeit
  14:00–22:00“, gilt das, auch wenn der Satz keine Zeit nennt. Nennt der
  Satz ausdrücklich eine andere Zeit, gewinnt der Satz (gesprochen schlägt
  Vorlage).
- Mehrere Snippets je Satz sind erlaubt, das erste im Text gewinnt bei
  Konflikten.
- Speicherort: `snippets.json` im Datenordner (iOS-eigen, Android ignoriert
  es), Backup/Wiederherstellung nimmt die Datei mit.
- Kein Netz, kein Konto. Das lokale Modell darf Snippets kennen (Liste der
  Trigger-Wörter in der Anweisung), entscheidet aber nicht über sie.

## Prompt

```
Lies zuerst CLAUDE.md, docs/siri.md (Abschnitt „Spracheingabe in der App“) und docs/etappen-funktionen-snippets.md. Du arbeitest drei Pakete nacheinander ab. Jedes Paket ist eine eigene Etappe: bauen → swift test grün → tools/deploy_ipad.sh → Review im Chat (Problem, Lösung, Begründung, Skizze vorher/nachher, Risiken) → warten auf „commit“ → nach Commit fragen „TestFlight-Build hochladen?“. Je Paket höchstens drei Rückfragen. Keine Extras über den Umfang hinaus. Logik ohne Oberfläche gehört nach ParalistCore mit Tests (Swift Testing). Alle Texte über L.s/L.f in Localizable.xcstrings und tools/strings_ios.json, acht Sprachen. Maße/Farben/Schrift in Theme/. Keine Datei über 400 Zeilen, keine Kommentare außer „// Zusammenhang“.

Grundsatz: Snippets sind Daten (Trigger-Wort + Vorlage), die beim Erstellen eines Eintrags greifen, egal ob gesprochen (Overlay), per Tastatur-Diktat oder getippt. Sie bauen auf SpokenEvent auf und ersetzen nichts davon.

━━━━━━━━━━━━━━━━━━━━
PAKET 1 – Kern: Snippet-Modell, Speicher, Anwendung
━━━━━━━━━━━━━━━━━━━━
- Neues Modell `Snippet` in ParalistCore (Ordner Library/ oder neu Functions/):
  id, trigger (ein Wort oder kurze Wortfolge, Groß/Klein egal, Umlaute tolerant wie in SpokenWords), aliases (weitere Trigger), enabled,
  type (EntryType, optional: leer = Typ des Composers behalten),
  title (Vorlage mit Platzhaltern), body (optional, Vorlage), 
  dayRule (none | today | tomorrow | nextWeekday(1…7) | spokenOrToday), 
  startMinute / endMinute (optional, Minuten ab Mitternacht), allDay,
  reminder (none | atStart | before(minutes) | at(minuteOfDay)), 
  place (optional: Ziel-Eintrag-ID für Ablegen), favorite.
- Platzhalter in Titel/Details: {rest} = Satz ohne Trigger, Datum und Zeit; {datum} = Tag kurz; {zeit} = Beginn; {wochentag}. Unbekannte Platzhalter bleiben leer. Leerer Titel nach Einsetzen → Trigger-Wort als Titel.
- `SnippetStore`: liest/schreibt `snippets.json` im Datenordner (Codable, Version im Kopf, max. 200 Snippets, Trigger max. 40 Zeichen, Titel/Details max. Limits.maxInputTitleChars bzw. 2000), robust gegen defekte Datei (leere Liste, Datei umbenennen `.defekt`). Backup (Backup/*) nimmt die Datei mit, Wiederherstellen schreibt sie zurück.
- `SnippetMatcher.apply(text:, snippets:, spoken: SpokenEvent, now:, zone:, periods:) -> SnippetResult`: findet Trigger als ganzes Wort (oder Wortfolge) im Satz, Reihenfolge im Text; erstes Snippet gewinnt bei Konflikten, weitere dürfen nur Felder füllen, die noch leer sind. Regel „gesprochen schlägt Vorlage“: hat SpokenEvent Tag/Beginn/Ende aus dem Satz, bleiben sie; sonst setzt die Vorlage. Entfernt das Trigger-Wort aus dem Titel. Liefert außerdem die Liste der getroffenen Snippets (für den Toast).
- `ComposerDraft.applySnippets(…)` nutzt Matcher und setzt Typ, Titel, Details (showBody = true, wenn gefüllt), Datum, Zeiten, Erinnerung (reminders bzw. eventOffset bei Terminen), Ablage, Favorit. `absorbTitle` ruft es ebenfalls (Tastatur-Weg).
- Tests (SnippetTests): Trigger mit Umlaut/Groß-Klein, Wortfolge, Platzhalter, Vorrang gesprochen vs. Vorlage, zwei Snippets im Satz, Typwechsel, Erinnerung vor Beginn, Datei-Rundreise, defekte Datei, Grenzen.
- Beispiel, das grün sein muss: Snippet „Spätschicht“ = Termin, Titel „Spätschicht“, 14:00–22:00, Erinnerung 60 Min vorher, dayRule spokenOrToday. Satz „Spätschicht Freitag“ → Termin Freitag 14:00–22:00, Titel „Spätschicht“, Erinnerung 13:00. Satz „Spätschicht morgen ab 15 Uhr“ → Beginn 15:00, Ende 22:00 (Vorlage füllt nur das Ende). Satz „Übersichtsseite überarbeiten“ ohne Trigger → unverändert.

━━━━━━━━━━━━━━━━━━━━
PAKET 2 – Einstellungen: Abschnitt „Funktionen“ mit Snippets
━━━━━━━━━━━━━━━━━━━━
- In SettingsPage neuer Abschnitt „Funktionen“ mit Zeile „Snippets“ (Zähler aktiv/gesamt) → `SnippetsPage` (Liste, Suche über .searchable, Wischen zum Löschen, Schalter aktiv, Plus oben rechts). Leerzustand mit kurzem Beispieltext („Spätschicht → Termin 14–22 Uhr mit Erinnerung“).
- `SnippetEditSheet` (Form, nativ): Trigger-Wort, weitere Wörter (Chips), Typ (Menü mit TypeLook), Titel-Vorlage mit Platzhalter-Knöpfen ({rest} {datum} {zeit} {wochentag}), Details (optional, Mehrzeilig), Datum-Regel (Picker), Beginn/Ende (DatePicker hourAndMinute, Ende nur bei Termin), Ganztag, Erinnerung (Picker: keine / zu Beginn / 15·30·60 Min vorher / feste Uhrzeit), Ablegen in (LinkPickerSheet wie im Composer), Favorit. Unten eine Live-Vorschau „So würde ‚<Trigger> morgen‘ aussehen“ mit demselben Matcher wie in der App.
- Validierung: Trigger darf kein Wort aus SpokenWords (Tage, Zeiten, Erinnerungs-Wendungen) und kein Duplikat sein → Hinweis unter dem Feld, Sichern gesperrt.
- Demo-Daten: Startargument `-screen snippets` und `-screen snippetedit` mit zwei Beispiel-Snippets (Spätschicht, Frühschicht).
- Prüfen: hell und dunkel, Zurück-Wischen, Screenshot-Workflow.

━━━━━━━━━━━━━━━━━━━━
PAKET 3 – Anwendung im Composer, Modell, Toast
━━━━━━━━━━━━━━━━━━━━
- ComposerDictation: nach SpokenEvent (und nach Modell-Nachprüfung) `applySnippets` auf Vorschau und Ergebnis; Overlay zeigt getroffene Trigger als kleine Chips über den Knöpfen („Spätschicht“), tippbar → öffnet das Snippet zur Bearbeitung.
- Absenden ohne Diktat (getippter Titel, Tastatur-Diktat): `absorbTitle` wendet Snippets an; Toast nach dem Schließen: „Snippet ‚Spätschicht‘ angewendet“ (AppModel.cheer), bei Erinnerung zusätzlich die bestehende Zeile.
- SpokenRefiner: Trigger-Wörter als Liste in die Anweisung („these words are snippet names, keep them out of the title“), damit das Modell sie nicht umformuliert; Modell-Antwort läuft weiter durch den Regelfilter.
- Siri „Neuer Termin in Paralist“ (NewEventIntent/TypedEntryIntents) nutzt denselben Weg, damit „Spätschicht Freitag“ auch per Siri klappt.
- docs/siri.md um Abschnitt „Snippets“ erweitern; neue Datei docs/funktionen.md (Modell, Datei, Vorrangregeln, Platzhalter, Grenzen).
- Prüfen am iPhone: „Spätschicht Freitag“ sprechen; „Spätschicht“ tippen und absenden; Snippet ändern und erneut sprechen.

Starte mit Paket 1.
```

## Zurückgestellt

Snippets mit Bedingungen (wenn Wochentag …), Snippets aus dem Chat anlegen,
Import/Export als Datei, Teilen mit Android.
