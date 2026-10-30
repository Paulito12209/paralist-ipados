<!-- Zusammenhang: Paralist/Intents/ParalistShortcuts.swift, ParalistCore/Sources/ParalistCore/Planning/SpokenEvent.swift, Paralist/Composer/DictationSheet.swift, Paralist/Intents/NewEntryIntent.swift, Paralist/Intents/TypedEntryIntents.swift, Paralist/Intents/OpenEntryIntent.swift, Paralist/Intents/TodayIntent.swift, Paralist/Intents/EntryEntity.swift, Paralist/Resources/AppShortcuts.xcstrings, Paralist/App/ParalistApp.swift, ParalistCore/Sources/ParalistCore/Planning/TodayDigest.swift, ParalistCore/Sources/ParalistCore/Library/QuickEntry.swift, tools/strings_ios.json, docs/widget.md, ParalistCore/Tests/ParalistCoreTests/Resources/spoken_corpus.tsv -->

# Siri-Befehle

Stand: 2026-10-22.

## Ziel

Paralist ist per Siri und in der Kurzbefehle-App bedienbar. Alles läuft lokal
in der App. Siri bekommt nur den Text, den ein Befehl als Antwort zurückgibt.

## Bedienung

| Befehl | Beispiel | Ergebnis |
|---|---|---|
| Neuer Eintrag | „Erstelle eine Aufgabe in Paralist“ | Siri fragt nach dem Titel und legt den Eintrag an |
| Neuer Termin | „Neuer Termin in Paralist“ | Siri fragt „Wann und was?“, Paralist erkennt Datum, Uhrzeit und Titel und legt den Termin an |
| Eintrag öffnen | „Öffne Umzug in Paralist“ | App öffnet die Detailseite |
| Heute | „Was steht heute an in Paralist“ | Siri liest Termine und fällige Aufgaben vor, ohne die App zu öffnen |

Neuer Eintrag kennt fünf Typen: Notiz, Aufgabe, Projekt, Arbeitsbereich,
Dokument. Jeder Typ hat einen eigenen Befehl mit festen Sätzen, damit Siri
ihn sicher erkennt und seltener zwischen Paralist und Notizen nachfragt.
Freier Text ist in Apples Siri-Sätzen nicht erlaubt; den Titel fragt Siri
deshalb immer im zweiten Schritt ab. Erste Zeile wird Titel, der Rest Text.
Notizen, Aufgaben und Dokumente landen im Eingang. Lesezeichen gehen über die
Teilen-Erweiterung, nicht über Siri.

Neuer Termin: Siri fragt nach dem Inhalt, zum Beispiel „morgen 8 Uhr
Zahnarzt“ oder „übermorgen von 15 bis 17 Uhr Workshop“. Die Erkennung
(`SpokenEvent` im Kern, Deutsch und Englisch) liest Tage (heute, morgen,
übermorgen, Wochentage, „in 3 Tagen“, „24.10.“, „3. März“), Uhrzeiten
(„15 Uhr“, „15:30“, „halb neun“, „3 pm“), Spannen („von 9 bis 11“, „für 2
Stunden“) und Tageszeiten („morgens“, „mittags“, „nachmittags“, „abends“,
Uhrzeiten aus den Einstellungen unter „Tageszeiten“). Der Rest wird Titel.
Ohne erkanntes Datum fragt Siri noch einmal. Ohne Ende dauert der Termin
eine Stunde. Sätze: „Neuer Termin in Paralist“, „Neuer Termin für
Paralist“, „Erstelle einen Termin in Paralist“, „Erstell mir einen Termin in
Paralist“, „Termin in Paralist anlegen“, „Neuer Paralist-Termin“.

Sätze je Typ (Beispiel Aufgabe): „Neue Aufgabe in Paralist“, „Neue Aufgabe
für Paralist“, „Erstelle eine Aufgabe in Paralist“, „Erstell mir eine
Aufgabe in Paralist“, „Aufgabe in Paralist anlegen“, „Neue
Paralist-Aufgabe“; bei Projekt und Dokument mit „Neues/ein“, bei
Arbeitsbereich mit „Neuer/einen“. Dazu „Öffne <Eintrag> in Paralist“, „Öffne Paralist-Eintrag“, „Was
steht heute an in Paralist“, „Was steht heute in Paralist an“. Alle acht
Sprachen in `AppShortcuts.xcstrings`. Siri erkennt den Namen auch als
„Parallelist“, „Paralyst“ und „Para List“ (`INAlternativeAppNames` in
`project.yml`).

Beim ersten Siri-Befehl fragt iOS einmal, ob die Paralist-Kurzbefehle
aktiviert werden sollen. Vorher antwortet Siri mit „keine passende App“.

Heute: zuerst Termine (ganztägige vorn, sonst nach Uhrzeit, mit Uhrzeit nur
wenn sie heute beginnen), dann offene Aufgaben mit Fälligkeit heute oder
früher (Überfällige zuerst, mit „überfällig“). Höchstens fünf, der Rest als
„n weitere Einträge“. Erledigtes und Archiviertes fehlt.

Sperrbildschirm: Ist „Inhalt auf dem Sperrbildschirm“ in den Einstellungen
aus und das iPad gesperrt, nennt „Heute“ keine Inhalte und bittet ums
Entsperren (`UIApplication.isProtectedDataAvailable`).

## Aufbau

- `Paralist/Intents/ParalistShortcuts.swift`: `AppShortcutsProvider` mit
  acht Befehlen (fünf Typen, Termin, Öffnen, Heute). Symbolnamen stehen dort als Text, weil Apple sie zur
  Bauzeit ausliest.
- `TypedEntryIntents.swift`: je Typ ein eigener Befehl (`NewNoteIntent`,
  `NewTaskIntent`, `NewProjectIntent`, `NewAreaIntent`, `NewDocumentIntent`,
  `NewEventIntent`) mit festem Typ. Termine baut `EntryCreator.createEvent`
  über `SpokenEvent` und `ComposerDraft`. Ein vorbelegter Typ in einem gemeinsamen Befehl ging bei
  Siris Rückfragen verloren und wurde zur Notiz.
- `NewEntryIntent.swift`: `NewEntryKind` (AppEnum, Namen aus `type_*`) für
  den allgemeinen Befehl in der Kurzbefehle-App (ohne Siri-Sätze, fragt
  nach dem Typ statt stillschweigend Notiz zu nehmen), `EntryCreator` speichert
  für alle über `AppModel.save`.
- `OpenEntryIntent.swift`: `OpenIntent` mit `target: EntryEntity`,
  `supportedModes = .foreground`, öffnet über `Router.open(.entry)`.
- `TodayIntent.swift`: Hintergrund, Antwort aus `TodayDigest`.
- `EntryEntity.swift`: Entity und Suche, gemeinsam mit dem Widget (gleiche
  Auswahl wie dort, `WidgetPicks`).
- `ParalistApp.init` legt `AppModel` und `Router` in den
  `AppDependencyManager`. Beim Start und beim Wechsel in den Hintergrund
  ruft die App `updateAppShortcutParameters()` auf, damit Siri die Titel kennt.
- Kern: `Planning/TodayDigest.swift`, `Library/QuickEntry.swift`,
  `Planning/SpokenEvent.swift` (mit `SpokenParser`, `SpokenWords`,
  `DayPeriods`), Tests in `TodayDigestTests.swift`, `QuickEntryTests.swift`
  und `SpokenEventTests.swift`.
- Texte: `siri_*` in `tools/strings_ios.json`; Sätze nur in
  `Paralist/Resources/AppShortcuts.xcstrings` (Apple-Vorgabe).

Simulator: Siri-Befehle laufen nur, wenn die App mit dem Entwicklerzertifikat
signiert ist; eine Ad-hoc-Signatur lehnt das System ab.

## Spracheingabe in der App

Im Erstellen-Panel bei Termin und Aufgabe steht ein Mikrofon-Knopf. Er
öffnet `DictationOverlay`: der gesprochene Text steht frei über der Karte
(wächst von unten nach oben), darunter „Verwerfen“ und „Übernehmen“; die
Karte bleibt sichtbar. Apples On-Device-Modell `SpeechTranscriber` (iOS 26,
`Capture/SpeechDictation.swift`) schreibt live mit, und `ComposerDictation`
zeigt im selben Moment in der Karte die Vorschau: Titel im Feld, Datum und
Uhrzeit in der Datumszeile (`SpokenEvent`, bei Aufgaben Titel, Datum und
Uhrzeit, Ende nur bei Terminen). Übernehmen übernimmt die Vorschau.
Verwerfen beendet nur die Aufnahme, die Vorschau bleibt in der Karte; das
Overlay bietet dann „Titel leeren“ (bzw. „Details leeren“) und „Neu
sprechen“ (neue Aufnahme auf dem aktuellen Entwurf). Ein Tipp in ein Feld
schließt das Overlay. Verwerfen ohne gesprochenen Text stellt den Entwurf
von vor der Aufnahme wieder her und schließt. Ein im Panel schon gewähltes Datum
gilt, wenn nur eine Uhrzeit gesagt wird. Das Details-Feld (Werkzeug „Text“)
hat rechts ein eigenes Mikrofon: der Text landet in den Details, angehängt
als neue Zeile, ohne Datums- und Modellprüfung. Titel sind in der Eingabe auf
`Limits.maxInputTitleChars` (200) begrenzt, die letzten 15 Zeichen zeigen
einen Zähler „185 / 200“; das Dateiformat erlaubt weiter 500.

Erinnerungs-Wendungen an jeder Stelle im Satz („… und erinnere mich daran“,
„mit Erinnerung“, „stelle mir einen Reminder“, „set a reminder“,
`SpokenWords.reminderPhrases`) setzen bei Aufgabe und Projekt eine
Erinnerung auf Tag und Uhrzeit (ohne Uhrzeit: die Morgens-Zeit aus den
Einstellungen) und fallen aus dem Titel. Die Erinnerung steht schon in der
Live-Vorschau im Entwurf (nicht erst nach Übernehmen) und ist in der
Datumszeile als Glocke sichtbar (gefüllt = gesetzt, Tipp öffnet das
Erinnerungs-Blatt; bei Aufgabe und Projekt). „Um diese / dieselbe Uhrzeit“ meint
die schon gesetzte Uhrzeit, sonst die jetzige auf die Viertelstunde
gerundet. Ein Nachsatz über „Neu sprechen“ („und stelle mir einen Reminder
um diese Uhrzeit“) ändert Datum, Uhrzeit oder Erinnerung und lässt den
Titel stehen.
Nebensätze werden zum knappen Titel: „stelle mir einen Reminder, dass ich
morgen um 15 Uhr die Übersichtsseite überarbeiten muss“ ergibt
„Übersichtsseite überarbeiten“ (`dass ich … muss/soll/will`, `that I have
to …`, führender Artikel vor Großgeschriebenem fällt weg, nur nach einem
Leitsatz). Der Toast „Erinnerung gestellt“ erscheint erst beim Absenden,
wenn die Erinnerung noch im Entwurf steht.
Text aus der Tastatur-Diktierfunktion wird beim Absenden ausgewertet
(`ComposerDraft.absorbTitle`): enthält der Titel eine Erinnerungs-Wendung
oder, ohne gesetztes Datum, eine Zeitangabe, werden sie übernommen und aus
dem Titel entfernt. Satzpunkte der Spracherkennung mitten im Titel
(„Speicherplatz. bearbeiten.“) fallen weg. Nach
Übernehmen erscheint oben ein grüner Toast „Erinnerung gestellt“ mit dem
Zeitpunkt (`AppModel.cheer`, `NoticeBar`). Versatz („in einer halben
Stunde“, „in 2 Stunden“) wird auf die Viertelstunde gerundet.

Die Wortbibliothek liegt in `ParalistCore/Planning/` (`SpokenWords`,
`SpokenDates`, `SpokenTimes`), Deutsch und Englisch vollständig, Spanisch und
Französisch in den Grundwörtern: heute, morgen, übermorgen, gestern,
Wochentage (auch „Mo.“), „am 24.“, „3. März“, „in 3 Tagen / 2 Wochen / einem
Monat“, „nächste / übernächste Woche (Montag)“, „nächsten Monat“, „am
Wochenende“; Uhrzeiten als „15 Uhr“, „7 Uhr 30“, „14:30“, „18h30“, „3 pm“,
„halb 9“, „viertel / dreiviertel 3“, „viertel vor / nach“, „zehn nach acht“,
„half past / quarter to“, „Mitternacht“; Tageszeiten (morgens, mittags,
nachmittags, abends, nachts) mit den Uhrzeiten aus den Einstellungen; Spannen
„von 9 bis 11“, „zwischen 14 und 16“, „15–17 Uhr“; Dauern „für 2 Stunden“,
„eine halbe Stunde lang“; Versatz „in einer Stunde“, „in 20 Minuten“;
„ganztägig“ / „den ganzen Tag“. Leitsätze („Erinnere mich an“, „Ich muss“,
„Erstelle einen Termin“, „Remind me to“) und Nachsätze („eintragen“, „bitte“)
fallen aus dem Titel, ebenso „Denk dran“, „Nicht vergessen“, „Wir müssen“,
„Don't forget to“, Füllwörter („ähm“, „äh“, überall) und vorn „also“, „okay“,
„bitte“ sowie nach einem Leitsatz „unbedingt“, „noch“, „mal“. „Montag, den 2.
November“ nimmt das Datum, „Mittwochabend“ Tag und Tageszeit, „from 2 to 3 pm“
gilt für beide Zeiten. Tests in `SpokenEventTests` und `SpokenWordingTests`.

Satz-Korpus: `ParalistCore/Tests/ParalistCoreTests/Resources/spoken_corpus.tsv`
(Testressource im `Package.swift`), geprüft von `SpokenCorpusTests`. Je Zeile
`Satz<TAB>Titel<TAB>Tag<TAB>Beginn<TAB>Ende<TAB>Erinnerung<TAB>Ganztag`, leer =
nicht gesetzt; Tag als `+1`/`-1` relativ, Wochentag-Kürzel (`fr` = nächster
Freitag) oder `2026-11-12`, Zeiten `HH:MM`, Erinnerung und Ganztag `ja`/`nein`.
Bezugstag ist Donnerstag 2026-10-22, 10:00 Uhr, Tageszeiten Standard. Zeilen mit
`#` sind Kommentare. Neuer Satz: Zeile anhängen, `swift test` laufen lassen;
ist sie rot, Wortlisten oder Regeln in `SpokenWords`, `SpokenParser`,
`SpokenDates` oder `SpokenTimes` erweitern, nicht die Erwartung abschwächen.
Wirklich mehrdeutige Sätze (etwa „halb drei“ ohne Tageszeit, „next Friday“ an
einem Donnerstag, Datumsspannen, Wiederholungen, trennbare Verben, „eine Stunde
vorher“) stehen auskommentiert unter `# offen` am Ende der Datei.

Nach „Fertig“ prüft das lokale Sprachmodell (`SpokenRefiner`,
FoundationModels, nur wenn Apple Intelligence verfügbar ist) den Satz mit der
Regel-Vermutung als Vorgabe: Titel kompakt, Datum und Uhrzeit nachgerechnet.
Antwortet es nicht innerhalb von drei Sekunden, bleibt die Regel-Vermutung;
`SpokenEvent.refined(by:)` übernimmt nur gültige Werte (Tests in
`SpokenRefinementTests`). Die Leiste zeigt solange „Wird geprüft …“.

Das Sprachmodell für die Erkennung verwaltet iOS selbst (`AssetInventory`,
beim ersten Mal einmaliger Download mit Fortschritt), die App wird dadurch
nicht größer. Ohne Internet beim ersten Mal oder in einer nicht
unterstützten Sprache zeigt das Overlay einen Hinweis. Im Chat bleibt das
Blatt `DictationSheet`.

## Prüfliste

- [x] Kurzbefehle-App zeigt alle Befehle (Simulator)
- [x] Heute ohne Einträge: „Heute steht nichts an.“ (Simulator)
- [x] Neuer Eintrag fragt nach Text und speichert in den Eingang (Simulator)
- [x] Eintrag öffnen zeigt die Liste und öffnet die Detailseite (Simulator)
- [x] Heute und Neue Notiz per Sprache am iPad
- [ ] Per Sprache am iPad: „Erstelle eine Aufgabe in Paralist“, „Neues Projekt in Paralist“, „Neuer Arbeitsbereich in Paralist“, „Erstelle ein Dokument in Paralist“
- [ ] Per Sprache: „Öffne <Titel> in Paralist“
- [ ] Per Sprache: „Neuer Termin in Paralist“, dann „morgen 8 Uhr Zahnarzt“
- [ ] Heute mit Terminen und Aufgaben, Grenze fünf
- [ ] Sperrbildschirm mit Einstellung aus und an
- [ ] Siri hell und dunkel
- [ ] Sprache der Auswahlliste prüfen (im Simulator stand dort „Entry“ statt „Eintrag“)

## Stand

Gebaut, Kern-Tests grün, im Simulator über die Kurzbefehle-App geprüft.
Sprachtest am Gerät steht aus.
