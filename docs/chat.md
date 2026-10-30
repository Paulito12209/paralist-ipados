<!-- Zusammenhang: docs/etappen-widget-siri-chat.md (Paket 3), docs/etappen-schichtplan.md, Paralist/Chat/* (inkl. ChatMascot*, DocumentReader, ChatImage*), ParalistCore/Sources/ParalistCore/Chat/*, ParalistCore/Sources/ParalistCore/Backup/*, Paralist/App/AppModel.swift (applyChatDraft), Paralist/App/DemoSeed.swift, Paralist/Pages/MenuPage.swift, Paralist/Entry/EntryBlocks.swift, docs/detailseite.md -->
# Chat

## Ziel

Fragen zu den eigenen Paralist-Daten in einer Unterhaltung stellen. Alles
bleibt auf dem Gerät: kein Netz, keine Cloud, kein Private Cloud Compute,
keine Fremdmodelle, keine Schlüssel.

## Bedienung

- Menü → **Chats** öffnet die Chat-Liste.
- Oben ein Ordner wie bei Aufgaben mit der Zahl der angezeigten Chats. Gibt es
  angepinnte Chats, liegt der neueste rechts daneben; Wischen nach links holt
  ihn nach vorn, der Pfeil öffnet ihn.
- Darunter die Sortierzeile mit Regler (Zuletzt geändert, Erstellt, Titel;
  Reihenfolge) und, sobald es welche gibt, Filterreiter Alle, Angepinnt,
  Verknüpft. Angepinnte Chats stehen immer oben.
- Liste: Titel, Pin-Zeichen, letzte Nachricht (ohne Markdown-Zeichen), Uhrzeit
  oder Datum.
- Ist Chats kein Reiter, steht unten die Seitenleiste: links Menü (wechselt
  direkt zu einer anderen Seite), Mitte Suche, rechts Plus für einen neuen
  Chat. Ein Tipp auf die Suche zeigt über der Tastatur dieselbe Such-Pille mit
  X wie die Suche; Menü und Plus bleiben unter der Tastatur. Die Liste filtert
  sofort (Titel und alle Nachrichten, Wortanfänge, Groß/Klein egal) und rollt
  so weit hoch, dass die Sortierzeile oben steht. X leert die Suche und bringt
  Menü und Plus zurück; Wischen in der Liste schließt nur die Tastatur.
  Als Reiter sucht die Kopfzeile, gefiltert auf Chats.
- Am Listenende **Neuer Chat**. Der Chat wird erst mit der ersten Nachricht
  gespeichert, leere Chats entstehen nicht.
- Wischen nach links: **Chat löschen** (mit Rückfrage, endgültig, kein
  Papierkorb). Wischen nach rechts oder langes Drücken: **Anpinnen** bzw.
  **Pin lösen** und **Umbenennen**. Der Pin steht als `angepinnt: true` im
  JSON des Threads (fehlt, wenn nicht angepinnt).
- Thread-Seite: Verlauf, unten die Eingabe als Karte wie der Composer
  (`ComposerDimens`). Ohne Denkstufe einzeilig: Textfeld links, runder Knopf
  rechts. Stößt der Text an den Knopf (oder enthält einen Umbruch), wechselt
  die Karte auf zwei Zeilen: Textfeld oben, darunter rechts der Knopf (mit
  Denkstufe immer so). Das Feld wächst bis 280 pt und scrollt dann. Der Knopf zeigt bei leerem Feld die
  Wellenform (Diktat, Text landet im Feld), mit Text den Pfeil zum Senden und
  während einer Antwort Stopp. Eigene Nachrichten als Blase rechts, Antworten
  links als Markdown (`MarkdownText`). Menü „…“ oben rechts: Verknüpfen,
  Umbenennen, Löschen.
- Titel: Ohne eigenen Titel wird die erste Zeile der ersten Frage genommen
  (Markdown entfernt, höchstens 40 Zeichen, an einer Wortgrenze gekürzt).
- Leerer Thread: drei Vorschläge („Was steht diese Woche an?“, „Fasse Projekt
  … zusammen“ mit dem zuletzt geänderten Projekt, „Welche Aufgaben sind
  überfällig?“). Ein Tipp schickt die Frage ab.
- Antworten erscheinen gestreamt. Einträge, die das Modell über die Tools
  gefunden und in der Antwort beim Titel genannt hat, stehen als Chips unter
  der Antwort; ein Tipp öffnet die Detailseite.
- **Anlegen lassen:** Auf Bitte („Erstelle mir 10 Karteikarten Französisch“,
  „Plane drei Aufgaben für nächste Woche“, „Schreib eine Notiz dazu“) bereitet
  das Modell einen Entwurf vor. Unter der Antwort steht eine Karte mit Art,
  Anzahl, Ziel-Deck (neu oder vorhanden) und den ersten fünf Punkten, dazu
  **Anlegen**, **Bearbeiten** und **Verwerfen**. Nichts wird ohne „Anlegen“
  gespeichert. Bearbeiten öffnet ein Blatt (Deckname, Karten, Aufgaben mit
  Datum, Notiztext; Zeilen löschen und hinzufügen). Nach dem Anlegen zeigt die
  Karte „Angelegt“ mit Chips zum Deck, zu den Aufgaben oder zur Notiz. Neue
  Einträge landen in der Inbox; Karteikarten gehen in ein Deck gleichen Namens
  (Groß/Klein und Akzente egal, nicht archiviert), sonst in ein neues Deck.
- **Verknüpfen:** Ein Thread lässt sich mit beliebigen Einträgen aller Typen
  verknüpfen (Auswahl mit Suche und Typfilter, verknüpfte oben). Die
  verknüpften Einträge stehen als Chips oben im Thread, gehen als knapper
  Kontext an das Modell und zeigen auf ihrer Detailseite den Abschnitt „Chats“.
- **Ohne Modell:** Gerät ohne Apple Intelligence → Hinweis, Chats bleiben
  lesbar, Eingabe gesperrt, der Menüpunkt bleibt. Apple Intelligence aus →
  Hinweis mit Weg und Knopf „Einstellungen öffnen“. Modell lädt noch → Hinweis.
- **Pl.AI und Einführung:** Das Maskottchen heißt Pl.AI (P und L aus
  Paralist, AI, dazu „play“). Bis man es kennt (`chat_hint_seen` fehlt),
  führen blaue Punkte hin: am Menü-Knopf und an der Menüzeile Chats, oder am
  Reiter Chats, wenn Chats in der Leiste steht. In der Chat-Liste pulsiert
  ein Ring um das Plus unten und um „Neuer Chat“. Im leeren neuen Chat hüpft
  Pl.AI begeistert und stellt sich in einer Sprechblase vor (lokal, nichts
  verlässt das Gerät) mit „OK“; die Tastatur bleibt dabei zu, damit die
  Vorschläge sichtbar sind. „OK“ oder die erste gesendete Frage setzen
  `chat_hint_seen`, danach verschwinden Punkte, Ringe und Begrüßung. Logik in
  `ParalistCore/Chat/ChatHint.swift` mit Tests; Simulator `-screen chatnew`.
- **Sprechblasen:** Eigene Nachrichten rechts in Blau mit Spitze unten
  rechts, Antworten links in Grau mit Spitze unten links (Markdown, Blase
  passt sich der Breite an). Chips und Entwurfskarten stehen unter der Blase.
- **Maskottchen:** Über der Eingabekarte lebt eine kleine blaue Blase mit
  zwei weißen Augen (ohne Pupillen) und einem Mund. Sie ist immer da, auch
  zwischen den Fragen. Gesichter: neutral, froh (Bogenaugen), begeistert
  (offener Mund), müde (halbe Lider), wütend (schräge Lider, Mundwinkel
  unten), überrascht (runder Mund), tot (X-Augen). Blick wandert, blinzelt.
  - **Während einer Antwort** (`working`): lebhaft nach `MascotScript`
    (schaut, läuft hin und her, hüpft, freut sich, wird müde; nie dieselbe
    Stimmung zweimal hintereinander). Der frühere Platzhalter „…“ entfällt.
  - **Ruhe** (`calm`): dieselben Stimmungen, langsamer und öfter sitzend.
    Nach 5 bis 10 Stimmungen spielt es eine Szene aus `MascotScenes`, passend
    zum Thema der letzten Antwort (Entwürfe und genannte Einträge, dazu die
    Verknüpfungen des Threads): bei **Karteikarten** ploppt rechts eine Karte
    auf, es schaut sie an und zerreißt sie begeistert (zwei Hälften fallen)
    oder schubst sie wütend aus dem Bild; bei **Projekten** schwebt rechts
    eine Rakete heran, es mustert sie mehrmals und jubelt (Hüpfer, Rakete
    startet nach oben) oder wird böse, rammt sie und sie fliegt im Bogen nach
    rechts hinaus; bei **Aufgaben** ist es sehr froh (zwei Hüpfer, Wackeln,
    breites Grinsen). Nie dieselbe Szene zweimal hintereinander; ohne Thema
    nur Stimmungen. Bei „Bewegung reduzieren“ keine Szenen, kein Laufen und
    Hüpfen, nur Augen und Gesicht.
  - **Fehler** (Inhalt abgelehnt, Unterhaltung zu lang, Sprache nicht
    unterstützt, sonstiges): es kippt um (liegt mit X-Augen auf der Seite),
    daneben eine Sprechblase mit dem Text und „Erneut versuchen“. Beim
    allgemeinen Fehler ist der Text einer von vier Sprüchen („Ich kann nicht
    mehr. Versuch es später noch mal.“ …), nie derselbe wie beim letzten Mal;
    die anderen Fehler behalten ihren erklärenden Text. Nach **Stoppen**
    liegt es nicht, sondern schaut müde und die Blase sagt „Antwort
    gestoppt.“. Erneut versuchen richtet es wieder auf.
  - Der Verlauf scrollt nach, wenn die Bühne wächst oder eine Nachricht
    dazukommt. Der Stopp-Knopf steht nur, solange das Modell schreibt.

## Bilder und Schichtplan

Stand: alle vier Pakete der Etappe `docs/etappen-schichtplan.md` (Bild in den
Chat und Tabelle lesen, Schichtplan erkennen und Termine als Entwurf, Skills
mit @ und In Chat öffnen, unbekannte Formate über das Modell ab iOS 27).

- **Bild senden:** Links in der Eingabekarte ein runder Knopf mit Menü
  **Fotos** (PhotosPicker), **Kamera** (UIImagePickerController) und
  **Dokument scannen** (VisionKit, richtet die Seite gerade; nur die erste
  Seite). Ein Bild je Nachricht; die Vorschau (48 pt, X zum Entfernen) steht
  in der Karte über dem Textfeld. Senden geht auch ohne Text. Ohne Kamera
  (Simulator) kommt der Hinweis „Kamera nicht verfügbar“.
- **Ablage:** Das Bild läuft durch `AttachmentImporter` wie Dateianhänge
  (bereinigt, höchstens 4096 px, JPEG oder PNG) und liegt unter
  `anhaenge/<SHA-256>`. Die Nachricht im Thread-JSON bekommt `anhang` mit dem
  Hash; Format bleibt 1, fehlt das Feld, gibt es kein Bild. Ein ungültiger
  Hash macht die Datei unlesbar (wie bei `verknuepft`). Die Blase zeigt das
  Bild (höchstens 220 pt) über dem Text, ein Tipp öffnet Quick Look. Die
  Chat-Liste zeigt für eine Nachricht nur mit Bild „Bild“.
- **Aufräumen:** Chat löschen und das X an der Vorschau entfernen Bilder, die
  kein anderer Chat und kein Eintrag (auch nicht im Papierkorb) mehr nutzt
  (`ChatAttachments.orphans`). Beim Import einer Sicherung werden die Hashes
  im Chat wie bei Einträgen auf die bereinigten Dateien umgeschrieben; fehlt
  das Bild, fällt es weg, eine Nachricht nur aus Bild fällt mit.
- **Lesen:** Beim Antworten ruft `DocumentReader` Vision
  (`RecognizeDocumentsRequest`, Sprache nach App-Sprache, wenn Vision sie
  kennt) für das jüngste Bild des Threads auf und gibt reine Daten an den
  Kern: `ScannedDocument` (Text gesamt, Tabellen als Zeilen von
  Zellen-Strings). `ScannedContext.format` macht daraus knappen Kontext
  (Tabellen zeilenweise, Zellen mit `|`, leere Zellen bleiben leer, höchstens
  3 Tabellen, 40 Zeilen, 16 Spalten, 40 Zeichen je Zelle, Rest als „other
  text“ ohne die Tabellenzellen, insgesamt 1 500 Zeichen). Hängt das Bild an
  der aktuellen Frage, steht der Kontext im Prompt (`ChatPrompt.withImage`,
  ohne Frage: kurz sagen, was drauf ist); stammt es aus einer früheren
  Nachricht und die Sitzung ist neu, steht er in den Anweisungen. Im Verlauf
  steht `[image]` vor der Nachricht. Ergebnisse werden je Hash im Speicher
  gemerkt, nicht auf Platte. Kein Text gefunden → das Modell soll das sagen
  statt zu raten. Dauer der Erkennung steht im Log (Subsystem `app.paralist`,
  Kategorie `chat`).
- **Zeit der Erkennung** (Testbild 1800×900 px, Tabelle mit 5 Zeilen und 8
  Spalten, erfundene Namen): Simulator iOS 26.1 auf dem Mac 1,9 s, Vision
  direkt am Mac 0,9 s. iPhone 17 Pro und iPhone SE: noch zu messen
  (Logeintrag `document scan took …`, Subsystem `app.paralist`).
- **Simulator:** Fotos geht über die Beispielbilder, der Kamera-Knopf öffnet
  auf iOS 26.1 eine graue Kamera, der Scanner meldet mit eigenem Hinweis,
  dass keine Medien erfasst werden können. Der iOS-27-Simulator hängt beim
  Start in `UNUserNotificationCenter` (Umgebung, nicht Paralist); UI-Prüfung
  daher auf iOS 26.1.
- **Schichtplan erkennen** (`ParalistCore/Chat/ShiftPlan*.swift`, reine
  Funktionen mit Tests aus dem nachgebauten Befund): Beim Senden mit Bild
  läuft vor dem Modell `ShiftPlanReader.read` über die gelesenen Tabellen.
  Kopfzeile mit `Std.`/`Zeit` je Tag (oder, ohne sie, eine Spalte je
  Tageskopf); Tagesköpfe `Mo 26.10` auch zusammengezogen in einer Zelle;
  Zeitraum aus dem Text (`26.10.2026-01.11.2026`, Trenner `.` `,` `、`
  Leerzeichen; `KW 44/2026`), sonst Jahr so ergänzt, dass Datum und
  Wochentag zusammenpassen und nahe an heute liegen (Jahreswechsel). Eigene
  Zeile über den Namen aus dem Skill-Feld `schicht_name`: Groß/Klein und
  Akzente egal, „Nachname, Vorname“ oder
  „Vorname Nachname“, fehlender erster Buchstabe erlaubt, Personalnummer nur
  als Zusatz (`p`/`O` zählen als `0`). Zellen: `HH:MM-HH:MM` (auch `HH.MM`,
  Störzeichen und Zusätze egal), `ABW` (kein Termin), `f`, `-`, leer (frei);
  Ende vor Beginn heißt über Mitternacht. Kontrolle: Dauer minus Pause (30
  min ab 6 h, 45 min ab 9 h, oder die Pause aus dem Skill) gegen `Std.` mit
  0,1 h Toleranz. `ABW`-Tage landen in `ShiftPlan.absences`.
- **Termin-Entwurf** (`ChatDraftKind.events`, JSON `termine`): Titel aus dem
  Skill (Paket 3), sonst der häufigste Titel vorhandener Termine mit gleicher
  Beginn- oder Endzeit, sonst „Arbeit“. Je Schicht eine Zeile mit Haken,
  Tag, Beginn–Ende und Hinweis: **Schon da** (vorhandener Termin gleichen
  Titels überschneidet sich, abgewählt), **Vergangen** (Tag vor heute,
  abgewählt), **Std. passt nicht** (Kontrolle schlägt fehl, bleibt gewählt).
  Höchstens 14 Termine, Zeitraum höchstens 31 Tage. Bearbeiten-Blatt mit
  Titel, Datum, Beginn und Ende je Zeile. **Anlegen** erzeugt `termin`-Einträge
  (`start`, `ende`, über Mitternacht endet der Termin am Folgetag) in der
  Inbox, die Karte zeigt „Angelegt“ mit Chips. Der Entwurf hängt ohne
  Tool-Aufruf an der Antwort: das Modell bekommt nur eine Zusammenfassung
  (`ChatPrompt.withPlan`) und schreibt den Antworttext; scheitert das Modell
  oder fehlt es, kommt die Karte mit „Hier ist mein Entwurf.“ trotzdem.
- **Welche Zeile bist du?** Fehlt der Skill oder passt keine Zeile, zeigt die
  Karte die Namen aus der Tabelle als Knöpfe (`namen` im JSON). Die Wahl
  legt den Skill „Schichtplan“ an oder trägt den Namen dort ein, liest den
  Plan erneut und ersetzt die Karte durch den Termin-Entwurf.
- **Skills** (`ParalistCore/Chat/Skills.swift`): Ein Skill ist eine nicht
  archivierte Notiz, die mit dem Tag **Skill** (Eintragstyp `tag`, Titel
  `Skill`, Groß/Klein egal; Verknüpfung in eine der beiden Richtungen)
  verknüpft ist. Der Text der Notiz geht als Anweisung an das Modell, wenn
  der Skill mit @ erwähnt wird. Der Skill **Schichtplan** gilt beim Erkennen
  eines Plans automatisch, ohne @; er trägt feste Felder im Kopf der Notiz,
  die Android unverändert lässt (unbekannte Kopf-Felder bleiben erhalten):
  `schicht_name` (Name im Plan), `schicht_titel` (Titel der Termine),
  `schicht_abwesend` (`true`: `ABW` wird ganztägiger Termin „Abwesend“),
  `schicht_pause` (Minuten statt der Standardpause), `schicht_erinnerung`
  (Minuten vor Beginn, setzt `erinnerungen` an den Terminen),
  `schicht_kuerzel` (Kürzel für Zellen, z. B. `F=06:00-14:00; S=14:00-22:00;
  N=22:00-06:00`, Groß/Klein beachten, höchstens 20; ein kleines `f` bleibt
  frei). Erkannt wird
  der Schichtplan-Skill an `schicht_name` (sonst an einem `schicht_`-Feld).
  Die Karte „Welche Zeile bist du?“ legt Tag und Notiz an, wenn sie fehlen
  (Titel und Text aus `skill_shift_title`/`skill_shift_text`), und schreibt
  nur `schicht_name`; die anderen Felder pflegt man im Kopf der Notiz.
- **@ und Erwähnungen:** Beginnt das letzte Wort in der Eingabe mit `@`,
  erscheint über der Eingabekarte eine Zeile mit Vorschlägen (Skills zuerst
  mit Funkel-Symbol, dann Einträge, Suche nach Wortanfängen wie beim
  Verknüpfen, höchstens 8). Ein Tipp entfernt das `@`-Wort und setzt einen
  Chip in die Eingabekarte über dem Textfeld (X entfernt ihn, höchstens 10).
  Beim Senden speichert die Nachricht `erwaehnt` (IDs), die Chips stehen oben
  in der eigenen Sprechblase, eine Nachricht ohne Text gibt dem Chat den
  Titel des ersten erwähnten Eintrags, die Einträge werden mit dem Thread verknüpft
  (`verknuepft`, Abschnitt „Chats“ auf der Detailseite) und die Sitzung des
  Modells beginnt neu. Erwähnte Einträge gehen wie Verknüpfte als knapper
  Kontext in den Prompt (`ChatPrompt.withMentions`), Skills als Anweisung;
  bei Bildern kommt der auf dem Gerät gelesene Text dazu.
- **In Chat öffnen:** Menü „…“ der Detailseite in der Reihenfolge Anpinnen,
  Verknüpfen, In Chat öffnen, Typ ändern, Archivieren, Teilen, Löschen.
  „In Chat öffnen“ schließt die Detailseite, öffnet einen neuen, noch nicht
  gespeicherten Chat (`Router.openChat`, `chatSeed`) mit dem Eintrag als
  Chip in der Eingabekarte und Fokus im Textfeld; der Chat entsteht erst mit
  der ersten Nachricht. Gilt für alle Typen.
- **Unbekannte Formate (ab iOS 27, nur mit `.vision`):** Erkennen die
  Regeln keinen Plan (keine `Std.`/`Zeit`-Köpfe, keine Tagesköpfe), fragt
  `ChatVision` (`Chat/ChatEngineVision.swift`) das Modell, wenn
  `SystemLanguageModel.default.capabilities` die Fähigkeit `vision` meldet:
  eigene Sitzung mit Anweisung (`ShiftPlanModel.instructions`, nennt den
  Namen aus dem Skill oder bittet nur um die Namen), Prompt aus dem
  Tabellentext von Vision plus dem Bild als `Attachment<ImageAttachmentContent>`,
  Ausgabe als `@Generable`-Struktur (`ModelPlanOutput`: ist es ein Plan,
  Namen, eigene Schichten mit Tag `YYYY-MM-DD`, Beginn, Ende, Std., abwesende
  Tage). `ShiftPlanModel.plan` prüft die Antwort im Kern (Daten auch als
  `TT.MM.JJJJ`, höchstens ein Jahr um heute, Zeitraum höchstens 31 Tage, ein
  Eintrag je Tag, Zeiten gültig) und baut denselben `ShiftPlan`; danach
  gelten dieselben Regeln (Kontrolle, Titel, Dubletten, Vergangenes) und
  dieselbe Entwurfskarte, ohne Skill die Karte „Welche Zeile bist du?“.
  Ohne `.vision` oder unter iOS 26 bleibt es beim Tabellentext für die
  normale Antwort. Dauer im Log: `vision plan took …` (Subsystem
  `app.paralist`, Kategorie `chat`). Das Bild direkt ans Modell gibt es nur
  hier; die normale Antwort bekommt weiter nur den gelesenen Text.
- **Zeit bis zur Karte** (Modellweg): iPhone 17 Pro und iPhone SE noch zu
  messen (Log `vision plan took …`); im Simulator nicht messbar (iOS 26.1
  ohne `.vision`, iOS-27-Simulator hängt beim Start).
- **Demo:** `-screen chatplan` zeigt einen Chat mit Termin-Entwurf aus einem
  nachgebauten Plan der laufenden Woche (erfundene Namen); die Demo-Daten
  enthalten den Tag „Skill“ und die Skill-Notiz „Schichtplan“. `-text "@Sch"`
  füllt im Demo-Modus die Eingabe vor (für die Vorschlagszeile im
  Simulator, wo Tastatureingaben nicht ankommen).

## Aufbau

- `ParalistCore/Chat/ChatThread.swift`: `ChatThread`, `ChatMessage`,
  `ChatRole` (`nutzer`, `modell`), `ChatTitle` (Auto-Titel, Umbenennen).
- `ParalistCore/Chat/ChatCodec.swift`: JSON lesen und schreiben, Prüfungen.
- `ParalistCore/Chat/ChatStore.swift`: Ordner `chats/`, eine Datei je Thread.
- `ParalistCore/Chat/ChatList.swift`: Sortierung, Suche, Vorschau.
- `ParalistCore/Chat/ChatView.swift`: `ChatViewSetting` (Sortierung und
  Reihenfolge der Liste, in den Einstellungen als `chat_view`), `ChatFilter`
  (Alle, Angepinnt, Verknüpft), angepinnter Chat für den Ordner.
- `ParalistCore/Chat/ChatTools.swift`: Auswahl und Kürzung für die Tools
  (Suche höchstens 10, Text höchstens 1200 Zeichen, Aufgaben höchstens 15) und
  der Kontext verknüpfter Einträge je Typ (höchstens 1500 Zeichen).
- `ParalistCore/Chat/ChatPrompt.swift`: Anweisungen (App-Sprache, Datum,
  knapp, nichts erfinden, Einträge beim Titel nennen), Verlaufskürzung
  (neueste zuerst, ältere als Liste der Fragen zusammengefasst) und
  `ChatMentions` (genannte Einträge für die Chips).
- `Paralist/Chat/ChatEngine.swift`: Verfügbarkeit, eine `LanguageModelSession`
  je Thread, Streaming, Fehlerzuordnung (iOS 26 `GenerationError`, iOS 27
  `LanguageModelError`). Ist das Kontextfenster voll, startet eine neue
  Session mit stark gekürztem Verlauf und die Frage läuft einmal neu.
- `Paralist/Chat/ChatEngineTools.swift`: die Tools `searchEntries`,
  `readEntry`, `listTasks` (today/week/overdue), `weekOverview`, nur lesend,
  auf einer Momentaufnahme der Einträge (`AppModel.chatSnapshot`).
- `ParalistCore/Chat/ChatDrafts.swift`: `ChatDraft` (Art `karteikarten`,
  `aufgaben`, `notiz`; Status `offen`, `angelegt`, `verworfen`), Bereinigung
  der Tool-Argumente (höchstens 20 Karten, 10 Aufgaben, 3 Entwürfe je Antwort,
  Kürzung, Doppelte und Leere raus, Fälligkeit nur ab gestern bis zehn Jahre
  voraus), Deck-Abgleich, Umwandlung in Einträge und die Rückmeldung an das
  Modell.
- `Paralist/Chat/ChatEngineWriteTools.swift`: die Tools `createFlashcards`,
  `createTasks`, `createNote`. Sie speichern nichts, sondern legen über
  `ChatData.draft` einen Entwurf an, der mit der Antwort zurückkommt.
- `Paralist/Chat/ChatDraftCard.swift`, `ChatDraftSheet.swift`,
  `ChatDraftEventRows.swift`: Vorschau-Karte, Bearbeiten-Blatt, Zeilen mit
  Haken und Namensknöpfe für Termine. Gespeichert wird in
  `AppModel.applyChatDraft`.
- `ParalistCore/Chat/Skills.swift`, `ChatMentionQuery.swift`: Skill-Tag und
  Skill-Notizen, feste Felder des Schichtplan-Skills, Anweisungstext;
  `@`-Wort in der Eingabe und Vorschläge. `Paralist/Chat/ChatMentionParts.swift`:
  Chips in der Eingabekarte und die Vorschlagszeile.
- `ParalistCore/Chat/ShiftPlanModel.swift`, `Paralist/Chat/ChatEngineVision.swift`:
  Anweisung und Prompt für das Modell, Prüfung der Modellantwort, Bild als
  Anhang ab iOS 27 mit `.vision`.
- `ParalistCore/Chat/ShiftPlan.swift`, `ShiftPlanHeader.swift`,
  `ShiftPlanRows.swift`, `ChatEventDrafts.swift`: Schichtplan lesen
  (Zeitraum, Spalten, eigene Zeile, Zellen, Stundenkontrolle) und daraus den
  Termin-Entwurf bauen (Titel, Dubletten, Vergangenes, Einträge, Zusammenfassung
  für das Modell).
- `Paralist/Chat/ChatModel.swift`: beobachtbarer Zustand, hängt an
  `AppModel.chats`, lädt bei `reload()` und nach dem Import neu; Senden,
  Stoppen, Erneut, Verknüpfen.
- `ParalistCore/Chat/ChatMascot.swift`: `MascotMood`, `MascotBeat`,
  `MascotScript` (nächste Stimmung mit Richtung und Dauer, ruhig oder
  lebhaft, Spruchwahl ohne Wiederholung), `MascotTopic`, `MascotScene` und
  `MascotScenes` (Themen aus Entwürfen und Eintragstypen, Szenenwahl ohne
  Wiederholung, Abstand), mit Tests.
- `Paralist/Chat/ChatMascotView.swift`: Zeichnung (Körper, weiße Augen mit
  animiertem Lid und Schräge, Bogen- und X-Augen, Mund als animierbare Form
  mit Krümmung, Öffnung und Breite, `SpeechBubble`). `ChatMascotProps.swift`:
  Karteikarte (zwei Hälften mit Rissnaht) und Rakete. `ChatMascotActor.swift`:
  beobachtbarer Zustand (Gesicht, Blick, Position, Requisite) und die
  Schleife, die Stimmungen und Szenen abfährt; `ChatMascotScenes.swift`: die
  Szenen als Schrittfolgen. `ChatMascotStage.swift`: die Bühne über der
  Eingabe (Keyframes für Hüpfen und Laufen, Sturz, Sprechblase). Maße in
  `MascotDimens`, Farben `Palette.mascot*`.
- `Paralist/Chat/ChatListPage.swift`, `ChatThreadPage.swift`,
  `ChatThreadParts.swift`, `ChatBubble.swift`, `ChatInputBar.swift`,
  `ChatLinkSheet.swift`: Oberfläche. Chats-Abschnitt der Detailseite in
  `Entry/EntryBlocks.swift`.
- Simulator: `-screen chatwait` zeigt das wartende Maskottchen, `-screen
  chatfail` den Sturz (Demo-Schalter `ChatModel.demoWaiting`/`demoFailed`);
  `-mascot flashcards,project,tasks` erzwingt Szenen-Themen im Demo-Modus.
- `Paralist/Chat/ChatBubble.swift`: `ChatBubbleShape` mit Spitze rechts oder
  links (spiegelt sich bei Rechts-nach-links-Sprachen).
- Routen `Route.chats` und `Route.chat(id)`, Menüpunkt in `MenuPage`,
  Symbol `AppIcons.chat`, Maße in `ChatDimens`.

### Dateiformat

`chats/<id>.json`, UTF-8, gleiche ID-Regeln wie Einträge:

```json
{
  "erstellt" : "2026-10-21T10:00:00Z",
  "format" : 1,
  "geaendert" : "2026-10-21T10:01:30Z",
  "id" : "abcdefghijklmnopqrst",
  "nachrichten" : [
    { "id" : "…", "rolle" : "nutzer", "text" : "Was steht an?", "zeit" : "2026-10-21T10:00:00Z" },
    { "id" : "…", "rolle" : "modell", "text" : "…", "zeit" : "2026-10-21T10:01:30Z" }
  ],
  "titel" : "Was steht an?",
  "verknuepft" : [ "id-eines-eintrags" ]
}
```

Optional an einer Nachricht: `anhang` (SHA-256 eines Bildes unter `anhaenge/`)
und `erwaehnt` (höchstens 10 Eintrags-IDs, siehe „Bilder und Schichtplan“).

Optional: `verknuepft` (höchstens 50 Eintrags-IDs) am Thread und `eintraege`
(höchstens 12 IDs für die Chips) an einer Antwort. Fehlen sie, ist die Liste
leer; gelöschte Einträge werden beim Anzeigen übergangen. Optional
`angepinnt` (`true`); fehlt es, ist der Chat nicht angepinnt.

Optional an einer Antwort: `entwuerfe` (höchstens 3), je Entwurf `id`, `art`
(`karteikarten`, `aufgaben`, `notiz`, `termine`), `status`, `titel`, `text`,
`punkte` (je `vorne`, `hinten`, `faellig`; bei Terminen dazu `beginn` und
`ende` als `HH:MM`, `gewaehlt: false` für abgewählte Zeilen und `hinweis`
`schon_da`, `vergangen` oder `stunden`), `namen` (Zeilen zur Auswahl, wenn die
eigene nicht gefunden wurde) und `angelegt` (IDs für die Chips nach dem
Anlegen):

```json
"entwuerfe" : [ {
  "art" : "karteikarten", "id" : "…", "status" : "offen", "titel" : "Französisch",
  "punkte" : [ { "hinten" : "der Hund", "vorne" : "le chien" } ]
} ]
```

Unbekannte Schlüssel werden beim Lesen übergangen, neue Felder lassen sich also
später ergänzen. Kaputte oder falsch benannte Dateien zeigt die Liste nicht an.

### Sicherung

Chats sind Teil der `.paralist`-Sicherung (Ordner `chats/`). Beim Import gewinnt
der neuere Stand (`geaendert`), lokale Chats werden nie gelöscht, kaputte
Chat-Dateien werden übersprungen, ohne den Import zu stoppen. Die
Sicherheitskopie vor dem Import enthält die Chats ebenfalls. Android kennt den
Ordner nicht und zählt ihn beim Import nur als ignoriert.

## Modell

Apples On-Device-Modell über FoundationModels (`SystemLanguageModel.default`).
Im iOS-27-SDK wählt das System selbst die beste lokale Variante fürs Gerät
(`core3` oder `coreAdvanced3`); auswählen lässt sie sich nicht, nur abfragen.
`.contentTagging` ist nur für Schlagworte, `PrivateCloudComputeLanguageModel`
läuft in der Cloud und bleibt draußen. Grenzen: nur Geräte mit Apple
Intelligence, kleines Kontextfenster (unter iOS 26 fest 4096 Tokens, ab iOS 27
je Gerät), nicht jede App-Sprache wird unterstützt. Begründung der Wahl siehe
`docs/etappen-widget-siri-chat.md`.

**Denkstufe:** Schnell (`reasoningLevel` `light`, Standard), Ausgewogen
(`moderate`), Gründlich (`deep`), gewählt im Menü links neben dem Knopf der
Eingabe, mit kurzem Hinweis je Stufe. Gilt für alle Chats ab der nächsten
Nachricht, gespeichert als `chat_thinking` (`ChatThinking` im Kern). Der Picker
erscheint nur, wenn das Modell die Fähigkeit `reasoning` meldet (ab iOS 27);
sonst läuft die Anfrage ohne Stufe. Offen aus Paket 2 der Etappe lokale
Modelle: Empfehlung je Gerät und Info-Zeile in den Einstellungen.

## Prüfliste

- [x] Menüpunkt „Chat“ öffnet die Liste (Simulator)
- [x] Neuer Chat: Fokus im Feld, Senden speichert, Titel aus erster Frage (Simulator)
- [x] Feld wächst mehrzeilig, ist nach dem Senden leer (Simulator)
- [x] Wischen löschen mit Rückfrage (Simulator)
- [x] Hinweis ohne Modell, hell und dunkel (Simulator)
- [x] Zurück-Wischgeste vom Thread zur Liste (Simulator)
- [ ] Umbenennen über Wischen, langes Drücken und Menü „…“
- [ ] Suche in der Liste
- [ ] Sicherung exportieren und auf zweitem Gerät importieren, Chats kommen mit
- [ ] Am iPad: Tastatur, Diktat, Autokorrektur beim Senden
- [ ] Antwort mit Tools am iPad mit Apple Intelligence (Woche, überfällig, Projekt)
- [x] Chips unter der Antwort öffnen die Detailseite (Simulator iOS 27)
- [x] Verknüpfen, Chip oben im Thread, Abschnitt „Chats“ auf der Detailseite (Simulator iOS 27, Aufgabe)
- [ ] Verknüpfen mit Projekt, Deck und Karteikarte am iPad
- [ ] Stoppen während der Antwort, danach „Erneut versuchen“
- [ ] Langer Thread: Kontext voll → Antwort kommt trotzdem (neue Session)
- [ ] Entwurf Karteikarten: Karte, Bearbeiten, Anlegen, Chip öffnet das Deck
- [ ] Entwurf Aufgaben mit Datum, Entwurf Notiz, Verwerfen
- [ ] Karteikarten in vorhandenes Deck gleichen Namens
- [ ] iPad ohne Apple Intelligence: Hinweis, Eingabe gesperrt, Chats lesbar
- [ ] Apple Intelligence aus: Hinweis mit Knopf „Einstellungen öffnen“
- [x] Bild aus Fotos senden, Vorschau mit X, Blase zeigt es, Quick Look, Liste zeigt „Bild“, hell und dunkel (Simulator iOS 26.1)
- [x] Chat mit Bild löschen entfernt die Datei unter anhaenge/ (Simulator)
- [x] Vision liest die Tabelle des Testbilds vollständig (Simulator, Log)
- [ ] Kamera und Scanner am iPad, „Was steht auf dem Bild?“ mit Antwort, Zeit der Erkennung
- [ ] Thread nach App-Neustart: Bild bleibt, Frage zum früheren Bild
- [x] Schichtplan: Entwurfskarte mit Haken, Hinweisen und Bearbeiten-Blatt, Anlegen erzeugt Termine (Simulator iOS 26.1, `-screen chatplan`)
- [x] Schichtplan-Foto senden: Karte „Welche Zeile bist du?“, Wahl ergibt den Entwurf (Simulator)
- [ ] Plan der laufenden und der nächsten Woche, Nachtschicht, Dublette, abweichende Std. am iPad mit echtem Foto
- [x] Vorhandener Skill „Schichtplan“ gilt automatisch: Foto senden ergibt direkt den Entwurf (Simulator); Anlegen von Tag und Notiz über „Welche Zeile bist du?“ nur in Kern-Tests
- [x] @ mit Suche, Chip in der Eingabe, Chips in der Sprechblase, Verknüpfung im Thread (Simulator)
- [x] In Chat öffnen von Notiz, Foto und Termin (Simulator)
- [ ] Skill ändern und löschen, Rechts-nach-links, Android-Import einer Skill-Notiz
- [x] Plan mit Kürzeln (F/S/N) über `schicht_kuerzel` im Skill (Kern-Tests)
- [ ] Unbekanntes Format über das Modell am iPad mit iOS 27 und `.vision`, Zeit bis zur Karte auf dem iPad

## Stand

Teil 3a auf main. Teil 3b gebaut, Kern-Tests grün. Im iOS-27-Simulator geprüft:
Vorschläge, Antwort über das Tool (`listTasks`), Chip unter der Antwort öffnet
die Detailseite, Verknüpfen mit Chip oben im Thread und Abschnitt „Chats“ auf
der Detailseite. Im Simulator dauert eine Antwort rund zwei Minuten, am iPhone
deutlich weniger. Im Simulator mit iOS 26.1 scheitert jede Antwort an Apples
Sicherheitsmodell (`promptTemplateNotFound`); das liegt an der Umgebung, nicht
an Paralist, und wird dort als „Das hat nicht geklappt“ mit „Erneut versuchen“
angezeigt.

Teil 4 (schreibende Tools mit Entwurf) gebaut, Kern-Tests grün, App-Build für
den Simulator erfolgreich. Noch nicht im Simulator oder am iPhone gesehen; die
Demo-Daten (`-demo -screen chat`) zeigen einen Karteikarten-Entwurf.

Schichtplan Paket 1 (Bild in den Chat, Tabelle lesen) auf main, im Simulator
iOS 26.1 geprüft, auf dem iPhone 17 Pro installiert, dort noch nicht bedient.
Paket 2 (Schichtplan erkennen, Termine als Entwurf) und Paket 3 (Skills, @
und In Chat öffnen) auf main; Regeln aus dem nachgebauten Befund getestet.
Paket 4 (unbekannte Formate über das Modell, Kürzel im Skill) gebaut,
Kern-Tests grün; der Modellweg braucht ein iPhone mit iOS 27 und `.vision`
und ist nur im Kern (Prüfung der Antwort) getestet. Im Simulator scheitert
die Modellantwort weiter an der Umgebung, die Entwurfskarte kommt dann
trotzdem.
