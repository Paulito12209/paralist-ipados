<!-- Zusammenhang: CLAUDE.md, docs/chat.md, docs/etappen-lokale-modelle.md, Paralist/Chat/ChatInputBar.swift, Paralist/Chat/ChatEngine.swift, Paralist/Chat/ChatEngineWriteTools.swift, Paralist/Chat/ChatDraftCard.swift, Paralist/Chat/ChatDraftSheet.swift, Paralist/App/AppModel.swift (applyChatDraft), ParalistCore/Sources/ParalistCore/Chat/* -->
# Etappen: Schichtplan-Foto im Chat

Prompt für eine neue Sitzung auf dem Mac (Umgebung paralist-ios). Text ab
„Lies zuerst“ vollständig einfügen. Pakete der Reihe nach, je Paket eine
Etappe.

## Ziel

Ein Foto vom Wochen- oder Schichtplan in den Chat geben, „trag mir meine
Schichten ein“ sagen und eine Entwurfskarte mit den eigenen Terminen
bekommen. Alles auf dem Gerät, kein Netz, keine Fremdmodelle. Nichts wird
ohne „Anlegen“ gespeichert.

## Entscheidungen

- 2026-10-28: Nur Apple-Bausteine. Tabellenerkennung mit Vision
  (`RecognizeDocumentsRequest`, ab iOS 26), Auswertung mit festen Regeln in
  ParalistCore. Das Sprachmodell formuliert nur die Antwort; für
  unbekannte Formate kommt es erst in Paket 4 dazu.
- Wer man ist, steht in einem Skill (Eintrag), nie im Code.
- 2026-10-28, Paul: Menü „…“ der Detailseite in dieser Reihenfolge: Anpinnen,
  Verknüpfen, In Chat öffnen, Typ ändern, Archivieren, Teilen, Löschen.
  „In Chat öffnen“ legt einen neuen Chat an, in dem der Eintrag schon als
  Erwähnung steht. Gleiche Reihenfolge auf Android
  (`docs/etappen-schichtplan-android.md` dort).
- Erwähnungen (Chip) stehen **in der Eingabekarte** über dem Textfeld, die
  Karte wächst um eine Zeile; nicht als eigene Leiste darüber. Grund: Der
  Chip gehört zur Nachricht, die man gerade schreibt, und wird mit ihr
  gesendet; in der eigenen Sprechblase steht er danach oben, der Text
  darunter. Das X am Chip entfernt ihn. Gleiche Darstellung für @ und für
  „In Chat öffnen“.
- 2026-10-28, in Paket 2 nach Vorschlag umgesetzt, bis Paul anders
  entscheidet:
  1. Abwesend (`ABW`) im Plan: weglassen, kein Termin.
  2. Vergangene Tage der Planwoche: im Entwurf sichtbar, aber abgewählt.
  3. Ziel: nur Paralist-Termine `termin`, gleiches Format wie Android;
     iPhone-Kalender zurückgestellt.
- 2026-10-28, Paket 3: Die festen Felder des Schichtplan-Skills stehen als
  Kopf-Felder der Notiz (`schicht_name`, `schicht_titel`, `schicht_abwesend`,
  `schicht_pause`, `schicht_erinnerung`, siehe `docs/chat.md`); Android
  bewahrt unbekannte Kopf-Felder (sortierte Extras). Die Einstellung
  `shift_plan_name` aus Paket 2 entfällt.
- 2026-10-28, Paket 4: Kürzel-Zuordnung als Kopf-Feld `schicht_kuerzel`
  (`F=06:00-14:00; S=14:00-22:00; N=22:00-06:00`); damit lesen schon die
  Regeln Pläne mit Kürzeln, das Modell kommt nur bei unbekanntem Aufbau und
  nur mit `.vision` dazu.

## Befund aus einem echten Plan (Test am Mac, 2026-10-28)

Ein Handyfoto eines ausgedruckten Wochenplans hinter Folie, Ausgabe aus einem
Zeiterfassungssystem: Kopf mit Zeitraum und KW, eine Zeile je Person
(„Nachname, Vorname“ und Personalnummer), je Tag die Spalten `Std.` und
`Zeit`. Vision lieferte eine Tabelle mit 16 Zeilen; die gesuchte Zeile kam
vollständig und richtig heraus. Gefundene Eigenheiten, die die Regeln und die
Tests abdecken müssen:

- Zeitraum oben als Text, ein Punkt kam als „、“ an
  (`26.10.2026-01、11.2026`). Die Tagesköpfe „Mo 26.10“ liefern die Tage ein
  zweites Mal, ohne Jahr.
- Erste Kopfzeile teils zusammengezogen („Fr 30.10 ⏎ Sa 31.10“), die zweite
  (`Std. | Zeit` je Tag) sauber. Tage daher über die Spaltenpaare zuordnen.
- Zellwerte: `HH:MM-HH:MM`, `ABW`, `f` (frei), `-`, leer. Nicht jedes `f`
  wurde erkannt, leer heißt also ebenfalls frei.
- Störungen: angehängte Zeichen (`06:00-13:00/`), handschriftliche Zusätze
  in der Zelle (`06:00-13:15 ⏎ 000042g`).
- Namen am Bildrand verlieren den ersten Buchstaben, Personalnummern beginnen
  mit `p` statt `0`; einmal rutschte die Personalnummer in die nächste Zeile.
- `Std.` passt zur Zeit abzüglich Pause (7:25 h minus 30 min = 6,92). Das
  ist eine Kontrolle, ob die Zeit richtig gelesen wurde.

Das echte Foto und echte Namen kommen nicht ins Repo. Testdaten werden mit
erfundenen Namen und denselben Eigenheiten nachgebaut.

## Grenzen

- Handschrift, starke Spiegelung oder schräge Fotos können Zellen kosten.
  Der Dokumentenscanner (VisionKit) richtet das Bild gerade.
- Paket 1 bis 3 kennen nur Pläne mit einer Zeile je Person und Uhrzeiten in
  den Zellen. Pläne mit Kürzeln (F/S/N) brauchen die Zuordnung im Skill.
- Das Bild direkt ans Modell (`Transcript.ImageAttachment`) gibt es erst ab
  iOS 27 und nur auf Geräten, deren Modell `.vision` meldet.

## Prompt

```
Lies zuerst CLAUDE.md, docs/chat.md, docs/etappen-lokale-modelle.md und docs/etappen-schichtplan.md (Ziel, Entscheidungen, Befund, Grenzen). Du arbeitest die Pakete nacheinander ab. Jedes Paket ist eine eigene Etappe: bauen → swift test grün → tools/deploy_ipad.sh → Review im Chat (Problem, Lösung, Begründung, Skizze vorher/nachher, Risiken) → warten auf „commit“ → nach Commit fragen „TestFlight-Build hochladen?“. Erst danach das nächste Paket. Je Paket höchstens drei Rückfragen; die offenen Entscheidungen aus docs/etappen-schichtplan.md vor Paket 2 klären. Keine Extras. docs/chat.md um den Abschnitt „Bilder und Schichtplan“ erweitern und aktuell halten. Logik ohne Oberfläche nach ParalistCore mit Tests (Swift Testing). Alle Texte über L.s/L.f in Localizable.xcstrings und tools/strings_ios.json, acht Sprachen. Maße/Farben/Schrift in Theme/, Symbole in AppIcons. Keine echten Namen, Personalnummern oder Fotos in Code, Tests, Doku oder Commits.

Grundsatz: Nur Apple-Bausteine auf dem Gerät (Vision, VisionKit, FoundationModels). Kein Netz, keine Fremdmodelle, kein Private Cloud Compute.

━━━━━━━━━━━━━━━━━━━━
PAKET 1 – Bild in den Chat, Tabelle lesen
━━━━━━━━━━━━━━━━━━━━
- Eingabekarte: Knopf für Bild mit Menü Fotos (PhotosPicker), Kamera, Dokument scannen (VisionKit). Ein Bild je Nachricht, Vorschau über dem Textfeld mit X. Senden geht auch mit Bild ohne Text.
- Bild unter anhaenge/ wie Dateianhänge (Hash), die Nachricht im Thread-JSON bekommt optional "anhang" (Hash). Format bleibt 1, fehlt das Feld, gibt es kein Bild. Blase zeigt das Bild als Vorschau, Tipp öffnet Quick Look. Chat löschen entfernt verwaiste Bilder.
- App: DocumentReader ruft RecognizeDocumentsRequest auf (Sprachen nach App-Sprache) und übergibt reine Daten an ParalistCore: ScannedDocument (Text gesamt, Tabellen als Zeilen von Zellen-Strings).
- Kern: ScannedDocument kürzen und als knappen Kontext für das Modell formatieren (Budget aus ChatBudget), damit „was steht auf dem Bild?“ schon funktioniert.
- Prüfen: Bild aus Fotos, Kamera und Scanner; Thread neu laden; hell und dunkel; Zeit der Erkennung auf beiden iPhones in docs/chat.md.

━━━━━━━━━━━━━━━━━━━━
PAKET 2 – Schichtplan erkennen, Termine als Entwurf
━━━━━━━━━━━━━━━━━━━━
- Kern ShiftPlan (reine Funktionen, Tests mit nachgebauten Tabellen aus dem Befund):
  · Zeitraum aus Kopftext (Trenner tolerant: . , 、 Leerzeichen; Bereich mit - oder –; KW mit Jahr) und aus den Tagesköpfen; beide abgleichen, Jahr ergänzen, Jahreswechsel.
  · Spaltenpaare Std./Zeit den sieben Tagen zuordnen, auch wenn die obere Kopfzeile zusammengezogen ist.
  · Eigene Zeile finden: Name aus dem Skill, Groß/Klein und Akzente egal, „Nachname, Vorname“ und „Vorname Nachname“, fehlender erster Buchstabe, Personalnummer nur als Zusatz mit Toleranz (p/0, O/0).
  · Zellen lesen: HH:MM-HH:MM (auch HH.MM, Störzeichen und Zusätze ignorieren), ABW, f, -, leer. Ende vor Beginn = über Mitternacht.
  · Kontrolle mit Std.: Dauer minus Pause (Standard 30 min ab 6 h, 45 min ab 9 h) gegen Std. mit kleiner Toleranz; Abweichung markiert den Tag.
  · Titel: aus dem Skill, sonst der häufigste Titel vergangener Termine mit gleicher Start- oder Endzeit, sonst der Text „Arbeit“ aus den Strings.
  · Dubletten: vorhandener Termin am selben Tag mit Überschneidung und gleichem Titel → „schon da“, abgewählt.
- Ablauf: Beim Senden mit Bild läuft die Erkennung vor dem Modell. Ist es ein Schichtplan und die Zeile gefunden, hängt die App den Entwurf direkt an die Antwort; das Modell bekommt eine kurze Zusammenfassung und schreibt nur den Antworttext. Kein Tool-Aufruf nötig, damit es auch ohne Apple Intelligence klappt (dann ohne Antworttext, nur Karte).
- Zeile nicht gefunden oder kein Skill: Karte „Welche Zeile bist du?“ mit den Namen aus der Tabelle; die Wahl legt den Skill an (Paket 3) bzw. bis dahin eine Einstellung.
- ChatDraftKind neu "termine": Zeilen mit Haken, Tag, Beginn, Ende, Titel, Hinweis (schon da, vergangen, Std. passt nicht). Bearbeiten-Blatt mit Zeiten. Anlegen erzeugt termin-Einträge (start, ende) in der Inbox, Karte zeigt „Angelegt“ mit Chips. Grenzen in ChatDrafts (höchstens 14 Termine, Zeitraum höchstens 31 Tage).
- Prüfen: Plan der laufenden und der nächsten Woche, Nachtschicht, Dublette, abweichende Std.; Demo-Schalter -screen chatplan; hell und dunkel.

━━━━━━━━━━━━━━━━━━━━
PAKET 3 – Skills, @ und In Chat öffnen
━━━━━━━━━━━━━━━━━━━━
- Skill = Notiz, die mit dem Tag „Skill“ (Eintragstyp tag) verknüpft ist. Freier Text für das Modell, dazu feste Felder im Kopf für die Regeln (Name im Plan, Titel, Abwesend anlegen ja/nein, Pause, Erinnerung vor Beginn). Vorher prüfen, dass Android unbekannte Kopf-Felder unverändert lässt; sonst Felder als Zeilen im Text mit festen Schlüsseln.
- „Welche Zeile bist du?“ aus Paket 2 legt den Skill „Schichtplan“ an oder ergänzt ihn. Ein vorhandener Skill gilt automatisch, ohne @.
- @ in der Eingabe: Vorschlagsliste über der Tastatur (Skills zuerst, dann Einträge, Suche wie in ChatLinkSheet). Auswahl setzt einen Chip in die Eingabekarte über dem Textfeld (Karte wächst um eine Zeile, X entfernt den Chip); die Nachricht speichert optional "erwaehnt" (IDs, höchstens 10) und zeigt die Chips oben in der eigenen Sprechblase. Erwähnte Einträge gehen wie Verknüpfte als knapper Kontext an das Modell, Skills als Anweisung; erwähnte Einträge werden beim Senden auch mit dem Thread verknüpft (verknuepft), damit sie auf der Detailseite unter „Chats“ stehen.
- Detailseite, Menü „…“ (EntryToolbar): neue Reihenfolge Anpinnen, Verknüpfen, In Chat öffnen, Typ ändern, Archivieren, Teilen, Trennstrich, Löschen. „In Chat öffnen“ (Symbol AppIcons.chat) öffnet Route.chat mit einem neuen, noch nicht gespeicherten Thread, in dessen Eingabekarte der Eintrag als Chip steht; Fokus im Textfeld. Der Chat entsteht wie bisher erst mit der ersten Nachricht. Gilt für alle Typen, auch Medien (Foto, Video, Audio) und Dateien; bei Bildern bekommt das Modell zusätzlich den Tabellen- oder Textinhalt aus Paket 1.
- Prüfen: Skill anlegen, ändern, löschen; @ mit Suche; In Chat öffnen von Notiz, Foto und Termin; Rechts-nach-links; Android-Import einer Skill-Notiz.

━━━━━━━━━━━━━━━━━━━━
PAKET 4 – Unbekannte Formate (ab iOS 27, nur mit .vision)
━━━━━━━━━━━━━━━━━━━━
- Erkennt ShiftPlan keinen Plan, das Modell meldet aber .vision: Bild als ImageAttachment plus Tabellentext ans Modell, Ausgabe als @Generable-Struktur (Zeitraum, Schichten mit Tag, Beginn, Ende). Danach dieselben Kernregeln (Kontrolle, Titel, Dubletten) und dieselbe Entwurfskarte.
- Ohne .vision bleibt es beim Tabellentext.
- Prüfen: Plan mit Kürzeln und Kürzel-Zuordnung im Skill; Zeit bis zur Karte auf beiden iPhones in docs/chat.md.

Starte mit Paket 1.
```

## Zurückgestellt

Eintrag in den iPhone-Kalender (EventKit), Bild aus dem Teilen-Menü direkt in
einen Chat, mehrere Bilder je Nachricht, Fremdmodelle für Bilder (MLX,
llama.cpp). Erst wieder aufgreifen, wenn Paul es ausdrücklich will.
