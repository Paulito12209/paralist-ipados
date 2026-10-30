<!-- Zusammenhang: CLAUDE.md, docs/widget.md, docs/siri.md (folgt), docs/chat.md, ParalistWidgets/*, Paralist/Pages/MenuPage.swift -->
# Etappen: Widget, Siri, Chat

Prompt für eine neue Sitzung auf dem Mac (Umgebung paralist-ios). Text ab
„Lies zuerst“ vollständig einfügen.

## Modellwahl für Paket 3

Apple stellt Apps über das Framework FoundationModels ein allgemeines
Sprachmodell zur Verfügung, das komplett auf dem Gerät läuft
(`SystemLanguageModel.default`). Daneben gibt es nur die Spezialvariante
`.contentTagging` für Schlagworte. Größere Apple-Modelle in der Cloud sind für
Apps nicht freigegeben und wären nicht lokal. Fremde offene Modelle (z. B. über
MLX) bräuchten mehrere GB Download, viel Speicher und Akku. Deshalb: Apples
On-Device-Modell, mit Prüfung im aktuellen SDK, ob ein neueres lokales Modell
verfügbar ist. Grenzen: nur Geräte mit Apple Intelligence, kleines
Kontextfenster.

## Prompt

```
Lies zuerst CLAUDE.md. Du arbeitest drei Pakete nacheinander ab. Jedes Paket ist eine eigene Etappe: bauen → swift test grün → tools/deploy_ipad.sh → Review im Chat (Problem, Lösung, Begründung, Skizze vorher/nachher, Risiken) → warten auf „commit“ → nach Commit fragen „TestFlight-Build hochladen?“. Erst danach das nächste Paket. Je Paket höchstens drei Rückfragen. Keine Extras über den Umfang hinaus. Für jedes Paket eine Doku in docs/ anlegen und aktuell halten (Ziel, Bedienung, Aufbau, Prüfliste, Stand), damit nichts verloren geht. Logik ohne Oberfläche gehört nach ParalistCore mit Tests (Swift Testing). Alle Texte über L.s/L.f in Localizable.xcstrings und tools/strings_ios.json, acht Sprachen. Maße/Farben/Schrift in Theme/.

━━━━━━━━━━━━━━━━━━━━
PAKET 1 – Widget „Schnellzugriff“ (erledigt)
━━━━━━━━━━━━━━━━━━━━
Das Widget steht in main (docs/widget.md, ParalistWidgets/). Nur offene Punkte aus der Prüfliste in docs/widget.md erledigen, falls es welche gibt; sonst direkt mit Paket 2 weitermachen.

━━━━━━━━━━━━━━━━━━━━
PAKET 2 – Siri-Befehle (erledigt)
━━━━━━━━━━━━━━━━━━━━
Die Siri-Befehle stehen in main (docs/siri.md, Paralist/Intents/). Nur offene Punkte aus der Prüfliste in docs/siri.md erledigen, falls es welche gibt; sonst direkt mit Paket 3 weitermachen.

━━━━━━━━━━━━━━━━━━━━
PAKET 3 – Chat mit lokalem Sprachmodell
━━━━━━━━━━━━━━━━━━━━
Grundsatz: Alles bleibt auf dem Gerät. Kein Netz, keine Cloud, kein Private Cloud Compute, keine Fremdmodelle, keine Schlüssel.

Teil 3a – Menü und Oberfläche (erledigt, siehe docs/chat.md):
- Neuer Menüpunkt „Chat“ im Menü (MenuPage/MenuDrawer), Symbol aus SF Symbols in AppIcons.
- Chat-Liste: Unterhaltungen (Threads) mit Titel, letzter Nachricht, Datum; neu anlegen, umbenennen, löschen (Wischen), .searchable.
- Thread-Seite: Nachrichtenverlauf, Eingabefeld unten wie die App-Tastaturleisten, Senden-Knopf; Antworten werden gestreamt angezeigt; Markdown-Darstellung über vorhandenes MarkdownText.
- Speicher: neuer Ordner chats/ im App-Root, eine Datei je Thread. Modell ChatThread/ChatMessage in ParalistCore mit Kodierung und Tests. Frag mich, ob Chats in die Sicherung (Backup) sollen; Android kennt den Ordner nicht, Import darf daran nicht scheitern.
- In 3a antwortet noch kein Modell: Platzhalter-Hinweis, wenn das Modell fehlt.

Teil 3b – Foundation Models anbinden:
- Framework FoundationModels, Modell SystemLanguageModel.default (allgemeines On-Device-Modell). Prüfe im aktuellen SDK, ob es ein neueres oder besseres ON-DEVICE-Modell gibt, und nimm das beste lokale; .contentTagging ist dafür nicht gedacht.
- Verfügbarkeit sauber behandeln (model.availability): Gerät nicht geeignet → Menüpunkt ausblenden oder erklären; Apple Intelligence aus → Hinweis mit Weg in die Einstellungen; Modell lädt noch → Hinweis. Texte lokalisiert.
- LanguageModelSession je Thread mit Instructions: Antworten in App-Sprache, knapp, nur auf Paralist-Daten und allgemeines Wissen gestützt, nichts erfinden, Einträge per Titel nennen.
- Zugriff auf Paralist-Daten nur über Tools (Tool-Protokoll), zunächst nur lesend:
  • SearchEntries(text, typ?) → Titel, Typ, ID, Kurzvorschau (höchstens 10)
  • ReadEntry(id) → Titel, Typ, Ort, Status, Fälligkeit, Text (gekürzt)
  • ListTasks(zeitraum: heute/woche/überfällig) → offene Aufgaben
  • WeekOverview() → Daten aus dem vorhandenen WeekBriefing
  Die Auswahl- und Kürzungslogik der Tools liegt in ParalistCore mit Tests.
- Kontextfenster ist klein: Verlauf kürzen (älteste Nachrichten raus, bei Bedarf Zusammenfassung), Tool-Ausgaben knapp halten. Bei exceededContextWindowSize neue Session mit Zusammenfassung.
- In Antworten genannte Einträge als Chips unter der Nachricht, Tipp öffnet die Detailseite.
- Fehler (guardrail, Kontext, Abbruch) als freundliche Meldung im Thread, Erneut-Knopf.
- Thread verknüpfen: ChatThread bekommt ein optionales Feld verknuepft (IDs beliebiger Einträge aller Typen: Arbeitsbereiche, Projekte, Aufgaben, Notizen, Termine, Lesezeichen, Dateien, Dokumente, Decks, Karteikarten; alte Dateien bleiben gültig). Im Thread-Menü „Verknüpfen“ mit der vorhandenen Eintragsauswahl (LinkPicker) samt Suche und Typfilter. Verknüpfte Einträge gehen als knapper Kontext in die Session (je Typ passend: Titel, Status, Fälligkeit, offene Aufgaben bei Bereichen/Projekten, Kartenzahl und fällige Karten bei Decks, Vorder- und Rückseite bei Karteikarten; alles gekürzt). Auf der Detailseite jedes verknüpften Eintrags erscheinen die zugehörigen Chats. Gelöschte Einträge werden beim Laden still übergangen. Auswahl- und Kürzungslogik in ParalistCore mit Tests.
- Vorschläge für den leeren Thread: „Was steht diese Woche an?“, „Fasse Projekt … zusammen“, „Welche Aufgaben sind überfällig?“
Doku: docs/chat.md (inkl. welches Modell, warum, Grenzen: nur Geräte mit Apple Intelligence, kleines Kontextfenster).

Teil 3c – Unterhaltungen aus anderen KI-Apps übernehmen (nach 3b, eigene Review je Schritt):
Ziel: Ein Verlauf aus Claude, ChatGPT oder einer anderen KI-App landet in Paralist, zuerst als Lesezeichen, dann auf Wunsch als Chat-Thread in chats/. Das Modell aus 3b kann darin weiterarbeiten.
- Schritt 1 – Teilen als Lesezeichen: Ein geteilter Link (claude.ai/share/…, chatgpt.com/share/…, gemini.google.com/share/…, g.co/gemini/share/…, perplexity.ai/search/…) wird über die Teilen-Erweiterung wie jeder Link als Lesezeichen gespeichert. Logo aus LinkLogos (claude.ai ist schon da; fehlende wie chatgpt.com, gemini.google.com, perplexity.ai ergänzen, mit Dunkel-Variante; Kurzlinks über LinkLogoLibrary.aliases). Erkennung „KI-Unterhaltung“ als reine Funktion in ParalistCore (Anbieter + Freigabe-ID aus der URL), mit Tests.
- Schritt 2 – „Als Chat übernehmen“ für solche Lesezeichen: Die öffentliche Freigabeseite wird einmal geladen (UrlGuard, Größen- und Zeitgrenzen wie beim TitleFetcher, keine Cookies, kein Login). Je Anbieter ein Parser in ParalistCore, der aus HTML bzw. eingebettetem JSON die Nachrichten (Rolle, Text, ggf. Zeit) liest. Parser nur gegen gespeicherte Beispielseiten testen (Fixtures), keine Netztests. Vorher prüfen und in docs/chat.md festhalten, welche Anbieter die Inhalte ohne JavaScript ausliefern. Wo das nicht geht, ehrlich „nicht unterstützt“ melden, nichts nachbauen, was ein Login oder eine Umgehung braucht. Freigabeseiten sind kein offizielles Format und können sich jederzeit ändern: Scheitert der Parser, bleibt das Lesezeichen, der Nutzer bekommt eine freundliche Meldung und den Hinweis auf Schritt 3.
- Schritt 3 – Import aus dem offiziellen Datenexport (der robuste Weg): conversations.json aus dem ChatGPT- bzw. Claude-Export (Datei über Dateien-App oder Teilen öffnen, auch als .zip). Parser in ParalistCore mit Grenzen (Dateigröße, Anzahl Threads und Nachrichten, Textlänge) und Tests. Auswahlliste der gefundenen Unterhaltungen mit Suche, Mehrfachauswahl, Import als Threads.
- Datenformat: ChatThread bekommt ein optionales Feld quelle {anbieter, url, id, importiert}. Alte Dateien ohne Feld bleiben gültig. Doppelte Übernahme derselben Quelle erkennen (anbieter + id) und aktualisieren statt doppelt anlegen. Neue Rollenwerte sind nicht nötig: Fremdantworten werden „modell“, eigene Fragen „nutzer“; Anhänge, Bilder und Code-Ausführungen werden als kurzer Platzhaltertext übernommen.
- Oberfläche: Übernommene Threads zeigen in der Chat-Liste das Anbieter-Logo statt des Standard-Symbols und oben im Thread eine Zeile „Übernommen aus … am …“ mit Link zum Original. Weiterschreiben mit dem lokalen Modell ist erlaubt; der Verlauf wird dafür nach den Regeln aus 3b gekürzt bzw. zusammengefasst.
- Grundsatz bleibt: Das Modell läuft lokal. Netz nur für das einmalige Laden einer Seite, die der Nutzer selbst geteilt hat.
Doku: Abschnitt „Übernehmen“ in docs/chat.md (unterstützte Anbieter, was übernommen wird, Grenzen).

Starte mit Paket 3, Teil 3a (Paket 1 und 2 sind erledigt).
```
