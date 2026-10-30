<!-- Zusammenhang: CLAUDE.md, docs/siri.md (Spracheingabe), docs/etappen-funktionen-snippets.md (läuft danach), ParalistCore/Sources/ParalistCore/Planning/SpokenParser.swift, ParalistCore/Sources/ParalistCore/Planning/SpokenWords.swift, ParalistCore/Sources/ParalistCore/Planning/SpokenRefinement.swift, Paralist/Capture/SpokenRefiner.swift, Paralist/Composer/ComposerDictation.swift -->
# Etappen: Titel-Robustheit der Spracheingabe

Drei Pakete, jedes in einer eigenen Sitzung. Ziel: Aus jedem gesprochenen
oder getippten Satz wird ein knapper To-do-Titel („Mail von Google
bearbeiten“), egal wie Paul den Satz formuliert. Zeitangaben, Leitsätze
(„Erstelle mir einen Reminder“), Nebensätze („dass ich … muss“) und
Erinnerungs-Wendungen landen nie im Titel.

## Stand (2026-10-30, Commit da2afdf)

- `SpokenEvent.parse` → `SpokenParser.run`: lead, dates, times, periods,
  durations, wholeDay, reminders, dangling, clauses, dangling, trailing,
  dangling. Wortlisten in `SpokenWords`. Tests `SpokenEventTests`,
  `SpokenWordingTests` (ParalistCore, Swift Testing).
- Modell-Nachprüfung: `SpokenRefiner` (FoundationModels, Zeitlimit 3 s,
  Anweisung in `SpokenPrompt`), Ergebnis läuft durch `SpokenEvent.refined`,
  dessen Titel noch einmal durch den Regel-Parser.
- Regeln für alle Sitzungen: CLAUDE.md gilt (keine Datei über 400 Zeilen,
  keine Kommentare außer `// Zusammenhang`, Texte nur über `L.s`, Logik im
  Kern mit Tests). Am Ende jeder Sitzung: `swift test` grün, Commit auf
  `main` mit klarer Nachricht, Push, `tools/deploy_ipad.sh`. Kein
  TestFlight. Freigabe für Commit und Push ist erteilt.

## Paket 1 – Satz-Korpus als Test

- Neue Datei `ParalistCore/Tests/ParalistCoreTests/Resources/spoken_corpus.tsv`
  (Testressource im Package.swift eintragen): je Zeile `Satz<TAB>Titel<TAB>
  Tag<TAB>Beginn<TAB>Ende<TAB>Erinnerung<TAB>Ganztag`, leer = nicht gesetzt.
  Tag relativ zu heute (`+1`, `+2`, `fr` = nächster Freitag, `2026-11-12`),
  Zeiten `HH:MM`, Erinnerung `ja/nein`, Ganztag `ja/nein`. Bezugstag im Test
  fest Donnerstag 2026-10-22, 10:00 Uhr.
- Mindestens 80 Sätze, Deutsch überwiegend, 15 Englisch, je 5 Spanisch und
  Französisch. Alle Sätze aus docs/siri.md und aus den bestehenden Tests
  aufnehmen, dazu Pauls echte Sätze:
  „Erstelle mir einen Reminder für morgen um 13:00 Uhr, dass ich die Mail
  von Google bearbeiten muss.“ → „Mail von Google bearbeiten“, +1, 13:00,
  Erinnerung ja.
  „stelle mir eine Erinnerung, dass ich morgen die Mails von Google
  bearbeiten muss um 13:00 Uhr.“ → „Mails von Google bearbeiten“.
  „E-Mail von Google bezüglich Speicherplatz. bearbeiten. Morgen um 13:00
  Uhr und erinnere mich daran .“ → „E-Mail von Google bezüglich
  Speicherplatz bearbeiten“.
  „stelle mir einen Reminder , dass ich morgen um 15:00 Uhr die
  Übersichtsseite überarbeiten muss.“ → „Übersichtsseite überarbeiten“.
  Weitere Varianten erfinden: „Denk dran, …“, „Nicht vergessen: …“,
  „Ich muss unbedingt …“, „Termin beim Zahnarzt am …“, „Anruf mit Lisa
  wegen Projekt …“, Sätze mit Komma, Punkt und Füllwörtern („ähm“, „also“).
- Ein parametrischer Test `SpokenCorpusTests` liest die Datei und prüft
  jede Zeile; Fehlermeldung nennt Satz, erwartet und erhalten. Zeilen, die
  mit `#` beginnen, sind Kommentare.
- Alle Zeilen müssen grün sein. Was rot ist, wird durch Erweiterung der
  Wortlisten oder Regeln in `SpokenParser`/`SpokenDates`/`SpokenTimes`
  behoben (nicht durch Abschwächen der Erwartung), außer der Satz ist
  wirklich mehrdeutig; dann Zeile mit `#` auskommentieren und am Ende der
  Datei unter `# offen` sammeln.
- docs/siri.md: Absatz „Satz-Korpus“ (wo, wie erweitern).

## Paket 2 – Titel-Normalisierung als eigener Schritt

- Neue Datei `ParalistCore/Sources/ParalistCore/Planning/SpokenTitle.swift`
  mit `enum SpokenTitle { static func normalize(_ tokens: …) }` oder als
  eigener Schritt `SpokenParser.normalizeTitle()`, der nach allen Datums-,
  Zeit- und Erinnerungs-Schritten läuft und die heutigen Teile `lead`,
  `clauses`, `trailing`, `dangling` und die Artikel-Logik ersetzt. Klare
  Stufen in fester Reihenfolge, jede als eigene Funktion:
  1. Leitsatz vorn (Verb + Füllwörter + Nomen; Wendungen wie „denk dran“,
     „nicht vergessen“, „ich muss/soll/will“, „wir müssen“, „bitte“).
  2. Nebensatz („dass ich/wir/du …“, „that I …“), auch nach Füllwerk.
  3. Pronomen und Hilfsverben, die nach 1 und 2 übrig bleiben („ich“,
     „wir“, „noch“, „mal“, „unbedingt“, „auch“, „dann“), Modalverb am Ende.
  4. Nachsätze („eintragen“, „bitte“, „danke“, „okay“).
  5. Hängende Präpositionen und Artikel an den Rändern, Satzzeichen-Reste,
     Punkt mitten im Titel vor Kleinbuchstaben.
  6. Großschreibung des ersten Buchstabens; Höchstlänge
     `Limits.maxInputTitleChars`.
- Verb ans Ende bei Nebensätzen, falls die Wortstellung es verlangt
  („dass ich anrufe Oma“ kommt nicht vor; „dass ich Oma anrufen soll“ →
  „Oma anrufen“ reicht). Keine Grammatik-Umstellung darüber hinaus.
- `SpokenParser.swift` wird dabei kürzer; `SpokenWords` behält die Listen,
  neue Listen (Pronomen, Hilfswörter) dort ergänzen.
- Alle bestehenden Tests und der Korpus aus Paket 1 bleiben grün; 20 neue
  Korpus-Zeilen für die Stufen 3 bis 5.
- docs/siri.md: Abschnitt „Titel-Normalisierung“ mit den sechs Stufen.

## Paket 3 – Modell-Vergleich mit Regel-Titel

- `SpokenEvent.refined(by:today:)`: Der Modell-Titel gewinnt nur, wenn er
  (a) nach Normalisierung nicht leer ist, (b) höchstens so lang ist wie der
  Regel-Titel plus 20 % oder kürzer, und (c) alle Kernwörter des
  Regel-Titels enthält (Kernwörter = Wörter ab 4 Buchstaben ohne
  Stoppwörter, Vergleich ohne Groß/Klein und Umlaute). Sonst bleibt der
  Regel-Titel. Reine Funktion `SpokenTitle.choose(rule:, model:) -> String`
  mit Tests (Modell kürzt korrekt, Modell lässt Kernwort weg, Modell hängt
  Zeit an, Modell antwortet leer).
- `SpokenPrompt.instructions`: fünf Beispiele statt drei, davon zwei mit
  Nebensatz und eines mit Füllwörtern; Hinweis „answer in the language of
  the sentence“.
- `SpokenRefiner`: Zeitlimit als Konstante bleibt 3 s; zusätzlich merkt sich
  `ComposerDictation`, ob das Modell geantwortet hat (`refinedByModel:
  Bool`). Nur im Debug-Build zeigt das Overlay unter dem Text eine kleine
  graue Zeile „Modell“ oder „Regel“ (Text über `L.s`, Schlüssel
  `dictation_source_model` / `dictation_source_rules`), im Release nichts.
- Messung am Gerät gehört Paul; in docs/siri.md einen Platzhalter
  „Zeit bis Antwort, beide iPhones: … / …“ anlegen.

## Danach

Es folgt docs/etappen-funktionen-snippets.md (drei Pakete) in neuen
Sitzungen.
