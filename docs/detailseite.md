<!-- Zusammenhang: Paralist/Entry/EntryPage.swift, Paralist/Entry/EntryCanvasPanel.swift, Paralist/Entry/EntryToolbar.swift, Paralist/Entry/EntryHero.swift, Paralist/Entry/CoverStage.swift, Paralist/Entry/CoverMotifLayer.swift, Paralist/Entry/CoverChrome.swift, Paralist/Entry/CoverVideo.swift, Paralist/Entry/EntryCover.swift (CoverTitleVeil, CanvasSheet), Paralist/Entry/EdgePicker.swift, Paralist/Entry/EntryBodyEditor.swift, Paralist/Entry/EntryBlocks.swift (EntryRelations, LinkAddMenu, PlusFrameKey), Paralist/Entry/EntryActions.swift, Paralist/Entry/EntryPickers.swift, Paralist/Entry/EntryMetaRow.swift, Paralist/Entry/EntryInfoSheet.swift, Paralist/Entry/CanvasCard.swift, ParalistCore/Sources/ParalistCore/Library/EntryFacts.swift, ParalistCore/Sources/ParalistCore/Library/EntryParent.swift, ParalistCore/Sources/ParalistCore/Library/PlacePicker.swift, Paralist/Entry/LinkSheet.swift (EntryPlaceSheet), Paralist/Entry/EntryDestination.swift, Paralist/Pages/MediaPage.swift, Paralist/Pages/OverviewEdge.swift, Paralist/Pages/OverviewSections.swift, Paralist/Pages/OverviewSwitchSheet.swift, Paralist/Pages/OverviewTabsPage.swift, ParalistCore/Sources/ParalistCore/Library/OverviewLayout.swift, ParalistCore/Sources/ParalistCore/Library/OverviewScope.swift, Paralist/Shell/Router.swift, Paralist/Shell/DetailHost.swift, Paralist/Shell/SplitRootView.swift, Paralist/Shell/SplitParts.swift, Paralist/Shell/RouterSplit.swift, docs/ipad.md, Paralist/Shell/RouteDestination.swift, ParalistCore/Sources/ParalistCore/Library/BarCollapse.swift, Paralist/Shell/CreateOverlay.swift, Paralist/Shell/AppSheets.swift (CreateSheets), ParalistCore/Sources/ParalistCore/Library/CoverTransition.swift, ParalistCore/Sources/ParalistCore/Library/EdgePicker.swift, Paralist/Theme/Dimens.swift, Paralist/Theme/EntryBarDimens.swift, ParalistCore/Sources/ParalistCore/Library/TabBarLayout.swift, Paralist/Theme/CanvasOpenDimens.swift, Paralist/Pages/FolderStage.swift (PinnedCardShell), Paralist/Theme/Palette.swift, docs/etappen-cover-uebergang.md -->

# Detailseite: Bereiche, Ansichten, Edge Picker

Stand: 2026-10-29. Vorlage für den Edge Picker ist das
Instagram-Karussell „How I made the edge picker in my app, 72pt“ von
kalypsodesigns. Vorlage für die Cover-Ansicht ist der Vollbild-Player von
Spotify.

**Derzeit ist der Edge Picker auf der Detailseite ausgeblendet und
abgeschaltet** (`EdgePicker.shownOnDetail = false` in ParalistCore). Der Code
bleibt; die Abschnitte zum Picker unten beschreiben das Verhalten, wenn der
Schalter wieder `true` ist. Kalender und Übersicht sind nicht betroffen.

## Begriffe

| Begriff | Bedeutung |
|---|---|
| Kopfzeile | Navigationsleiste oben ohne Liquid Glass: Chevron nach unten, Kategorie mittig (eine Zeile, am Ende „…“), Favorit, Menü (in der geteilten Ansicht stattdessen Erweitern-Knopf `SplitExpandButton` und Seitenleisten-Knopf `SplitSideButton`; Favorit und Menü wandern in die Aktionsleiste), Symbole und Kategorie in `Palette.onSurface` (hell schwarz, dunkel hell); in Detail-, Text- und Cover-Ansicht identisch |
| Aktionsleiste | Nur in der geteilten Ansicht (`router.split`): Zeile zwischen Infozeile und Canvas-Blatt (`EntryActionBar`), links die Glas-Pille „Zur Coveransicht“ (`ipad_to_cover`), rechts Favoriten-Stern und Drei-Punkte-Menü in Glas-Kreisen (`EntryFavoriteButton`, `EntryMoreMenu`, wiederverwendet aus der Kopfzeile). Die Pille setzt `canvas = .cover`, dieselbe Animation wie das Ziehen nach unten; Maße in `EntryActionDimens`. In der Coveransicht steht über dem Titel die Pille „Zur Detailansicht“ (`ipad_to_detail`, `CoverChrome`), sie ruft `settle(to: .detail)`. Ihr Rahmen (`actionFrame`) ist vom Tipp-auf-Cover ausgenommen, damit Tippen auf die Leiste kein Video startet |
| Cover-Bereich | Oberer Abschnitt unter der Kopfzeile, 16:9, läuft unter die Kopfzeile; darunter, ebenfalls auf dem Verlauf, Titel und Infozeile mit Schleier |
| Canvas-Bereich | Karte unter Titel und Infozeile, oben 28 pt runde Ecken mit Griff, wie das Blatt bei Solcard |
| Bottom-Zeile | Schwebende Zeile unten nach dem Vorbild der Safari-Leiste: Liquid-Glass-Knopf „Schließen“, links ein runder Zurück-Knopf (Text- und Verknüpfungen-Ansicht, verschachtelte Einträge), bei Lesezeichen, Medien, Deck und Karte rechts ein runder Icon-Knopf, bei offenen Aufgaben rechts der Erledigt-Knopf; klappt beim Scrollen nach unten zu einer kleinen Kapsel ein |
| Edge Picker | Kerbe am rechten Rand, wechselt zwischen den Ansichten; auf der Detailseite derzeit ausgeblendet, Code bleibt |
| Ansicht | Cover, Aktionen, Text oder Verknüpfungen (`EntryCanvas`) |

## Öffnen und Schließen

- Ein Eintrag aus Übersicht, Listen, Aufgaben, Kalender, Medien, Suche usw.
  öffnet als Vollbild-Deckblatt von unten nach oben (`Router.detail`,
  `DetailHost`), in jedem Reiter gleich.
- Wird aus einer offenen Detailseite ein weiterer Eintrag geöffnet
  (Verknüpfung, Karte im Deck), schiebt er normal von rechts herein
  (`Router.detailPath`). Zurück per Wischgeste vom linken Rand oder über den
  runden Zurück-Knopf links in der Bottom-Zeile (eine Ebene,
  `detailPath.removeLast()`). Der erste Eintrag des Deckblatts hat dort
  keinen Zurück-Knopf, nur „Schließen“.
- Das Deckblatt verhält sich wie ein Bottom Sheet: Es öffnet von unten nach
  oben und schließt immer nach unten, nie zur Seite. Alle Gesten nutzen
  denselben Weg (`Router.detailDrop`, `Router.dropDetail`): die Seite rückt
  nach unten, darunter ist die Reiterseite zu sehen.
- In der Cover-Ansicht schließt ein Wischen von oben nach unten (mehr als
  80 pt, `swipeThreshold`) das Deckblatt.
- Wischen von links nach rechts, überall auf der Seite und in jeder Ansicht
  (Cover, Detail, Text), geht genau eine Ebene zurück. Auf dem ersten Eintrag
  zieht es die Seite nach unten statt nach rechts: Fortschritt (Weg ÷ Breite)
  × Höhe. Ab 35 % der Breite (Weg oder Schwung, `swipeBackShare`) schließt sie
  nach unten, sonst federt sie zurück nach oben (`DetailHost`, bei
  „Bewegung reduzieren“ ohne Mitziehen). Verschachtelte Einträge gehen
  unverändert zum vorherigen Eintrag zurück: am Rand die System-Geste,
  sonst ein Pop nach dem Loslassen; der erste Eintrag bleibt stehen.
- Das Chevron nach unten oben links schließt in allen Ansichten, auch im Cover, das ganze Deckblatt und
  bringt zurück in den Reiter, in dem man gestartet ist, ebenso „Schließen“
  in der Bottom-Zeile. Oben gibt es keinen Zurück-Pfeil.
- Direkt ins Cover öffnen Datei und Dokument mit Bild oder Video
  (`EntryDestination`). Alles andere öffnet in der Detail-Ansicht (früher
  „Aktionen“). Audio und PDF folgen, sobald das Cover sie zeigen kann.
- Die übergeordnete Liste (Eingang, Projekt, Arbeitsbereich) steht als Auswahl unter den
  Hauptknöpfen (`PlaceRow`), nicht in der Kopfzeile, bei allen Kategorien. Die
  Pille ist mittig und links wie rechts höchstens 32 pt vom Rand entfernt
  (`entryPlaceInset`); lange Titel werden mit „…“ gekürzt, der Chevron bleibt. Sie
  zeigt genau einen Eintrag: zu welchem Eintrag dieser gehört (`orte` im Kopf,
  immer höchstens eine ID). Sie öffnet dieselbe Auswahl mit Reitern wie
  „Verknüpfen“ (`EntryPlaceSheet`, Regeln in `PlacePicker` in ParalistCore);
  ein Tipp ersetzt die Zugehörigkeit und schließt das Blatt, erneuter Tipp oder
  „Eingang“ hebt sie auf. Verknüpfungen bleiben davon unberührt. Reiter je
  Kategorie: Arbeitsbereich nur Tags („Nicht zugeordnet“); Projekt „Eingang“,
  Arbeitsbereiche, Tags; Tag nur Tags („Nicht zugeordnet“), wie ein Ordner im
  Ordner, aber keiner, der schon darunter hängt; alle anderen Kategorien
  „Eingang“ und alle Reiter. Das Blatt (`LinkPickerSheet`, auch in
  Erstellen und Teilen) hat einen einheitlichen Hintergrund ohne
  Trennlinien und eine Suche, die ohne Reiter über alle Reiter sucht. Unter
  den Reitern steht in jedem Reiter außer Termine und Ressourcen die Zeile
  „Neuer Tag“, „Neues Projekt“ usw. (`LinkCreateRow`, `LinkTab.creates`): ein
  Tipp öffnet ein Titelfeld mit Haken rechts, der Haken legt den Eintrag nur
  mit Titel an und wählt ihn sofort aus. In der Teilen-Erweiterung steht unter
  „Ablegen in“ die Zeile „Verknüpfungen“ mit demselben Blatt zur
  Mehrfachauswahl; der gewählte Ablageort steht dort nicht zur Wahl, und wird
  ein Verknüpfter als Ablageort gewählt, fällt er aus den Verknüpfungen
  (`ComposerDraft.links`). Die Detailseite des übergeordneten Eintrags
  zeigt seine Einträge oben in den Verknüpfungen (`AppModel.related`). Die Infozeile hat
  Typ-Symbol, „Erstellt am …“ · „Geändert am …“, dann „mehr“, keinen Link- oder
  Medien-Eintrag. Bei allen Kategorien und in allen Ansichten gleich.

## iPad

Ab ausreichender Fensterbreite (Regel siehe `docs/ipad.md`) liegt die
Detailseite nicht als Vollbild-Deckblatt, sondern in der rechten Seite (1/3,
mindestens 320 pt) neben dem Hauptcontainer.

- `DetailHost(inline: true)` zeigt `router.detail`. Ohne Detail steht dort der
  Stapel mit den Kategorien (`sidePath`).
- Ein Tipp links ersetzt das Detail (`Router.open`). Ein Link aus der
  Detailseite heraus (Verknüpfung, Karte, Erwähnung, Lernen) öffnet die
  verknüpfte Seite daneben (`Router.push(_:from:)`): Hauptcontainer zu,
  Detailseite links, Verknüpfung rechts (`DetailHost(pane: .linked)`), 50/50
  mit Ziehgriff. Nie mehr als zwei Seiten.
- Oben links neben dem Schließen-Pfeil sitzt der Knopf Erweitern bzw.
  Verkleinern (`SplitExpandButton`); er fehlt, solange eine Verknüpfung offen
  ist.
- `.chat` und `.study` öffnen ebenfalls rechts. Ihre Wurzel hat links oben
  einen Schließen-Pfeil.
- „Schließen“ in der Bottom-Zeile und der Pfeil oben schließen den eigenen
  Container (`closePane`). Das Herunterziehen des Covers (`detailDrop`) und
  das Wegwischen nach rechts entfallen; Zurück in verschachtelten Ebenen und
  das Blättern der Medien (`MediaPager`, nur links) bleiben.
- Passt die Seite nicht (Hauptcontainer unter 440 pt), gilt das
  iPhone-Verhalten mit Vollbild-Deckblatt; ein offenes Detail bleibt beim
  Wechsel erhalten.

## Ansichten

Reihenfolge im Picker von oben nach unten. Start ist **Aktionen**
(auch Detail-Ansicht genannt). Ausnahme: Aus der Medien-Seite öffnet ein
Eintrag direkt im **Cover** (`Route.cover`), Hochziehen führt dann zu
Aktionen. Detail und Cover sind eine Seite, siehe „Übergang Detail und
Cover“.

In der ganzen App gibt es nur einen Videoplayer, den eigenen aus
`CoverVideo.swift`. Kein System-Player und kein Quick Look für Bilder und
Videos. Quick Look bleibt nur für andere Dateien (PDF, Text usw.).

| Ansicht | Symbol | Inhalt |
|---|---|---|
| Cover | eigene Zeichnung `XoolPageShape` (Rahmen, darunter zwei Linien) | Vollbild, siehe unten |
| Aktionen | `hand.tap` | Cover-Bereich, darunter im Canvas, siehe „Aufbau der Detail-Ansicht“ |
| Text | `text.alignleft` | Cover-Bereich mit Titel und Infozeile, in der Karte Texteditor mit sofortiger Tastatur, darunter „Text entfernen“ |
| Verknüpfungen | `AppIcons.link` (eigene Zeichnung) | Cover-Bereich mit Titel und Infozeile, in der Karte nur der Verknüpfungen-Container mit Plus (ohne Knöpfe, Listen-Pille, Text und Chats) |

Reihenfolge im Canvas ist überall gleich wie bei YouTube: **Titel zuerst,
dann Infozeile.**

Die Text-Ansicht speichert beim Verlassen des Feldes und beim Wechsel der
Ansicht. Ein Tipp auf den Text im Text-Container bearbeitet ihn direkt dort
(siehe Punkt 8), die Seite bleibt in der Detail-Ansicht. In die Text-Ansicht
führt nur der Pfeil im Text-Container (bzw. der Edge Picker); sie zeigt den
Text ohne Tastatur und Cursor, erst ein Tipp ins Feld fokussiert. Zurück zur
Detail-Ansicht führt der Zurück-Knopf links in der Bottom-Zeile.

## Cover und Übergang

Aufbau der Seite mit `cover` (0 bis 1), Zieh-Geste in beide Richtungen,
Cover-Ansicht, Bilder, Spotify: siehe `docs/cover.md`.

## Aufbau der Detail-Ansicht

Im ganzen Canvas 16 pt Einzug links und rechts (`Dimens.entryInset`), wie bei
YouTube. Vorlage für Karte und Knöpfe ist die Karten-Seite von Solcard.

1. **Im Cover-Bereich**, unter dem 16:9-Teil: Titel (DM Sans 20 semibold,
   `Typo.entryTitle`, eine Zeile, 14 pt unter dem 16:9-Teil, `EntryTitleLine`).
   Ein Tipp öffnet das Info-Blatt groß mit dem Titel zum Bearbeiten und offener
   Tastatur. Ist er zu lang, blendet er rechts über 48 pt aus
   (`entryTitleFade`), kein „…“. Darunter die Infozeile (13 pt,
   `Typo.entryMeta`): Typ-Symbol (Tipp ändert den Typ), „Erstellt am …“ ·
   „Geändert am …“, am Ende „mehr“ (öffnet das Info-Blatt). 14 pt darunter
   beginnt die Karte (`entryMetaBottom`). Der 16:9-Teil wird dadurch nicht größer.
2. **Schleier** hinter Titel und Infozeile (`CoverTitleVeil`): beginnt 120 pt
   über dem Titelblock im 16:9-Teil (`entryTitleVeilLead`) und läuft weich
   (fünf Stufen, 0 → 8 → 35 → 70 → 90 % `Palette.surface`, dunkel im
   Dunkelmodus, weiß im Hellmodus) bis zur Karte, darunter wachsende
   Unschärfe. So bleibt die Schrift in `onSurface` lesbar, hell also schwarz.
3. **Karte** (`CanvasSheet`): `surfaceContainer`, oben 28 pt runde Ecken
   (`entrySheetRadius`), feiner Rand, mittig oben der Griff (36 × 5 pt, 8 pt
   vom Rand, `Palette.entryGrabber`). Hinter den runden Ecken liegt dieselbe
   Fläche wie das Ende des Schleiers (90 % `surface`), damit dort nie der
   Verlauf durchscheint. Sie läuft bis zum Seitenende.
4. 28 pt unter der Oberkante die **drei Hauptknöpfe** (`EntryActionButtons`):
   Kreise 56 pt (`surfaceHigh`, Rand `cardStroke`), Symbol 20 pt, Beschriftung
   13 pt darunter, je 96 pt breit, mittig.
   - links **Status** (alle Kategorien außer Tag, siehe „Status je
     Kategorie“; Symbol und Name, öffnet die Status-Auswahl mit nur den
     Werten der Kategorie), bei Tags die **Art** (Tag, Person, Ort),
   - Mitte **Verknüpfen**: natives Menü „Neuer Eintrag“ / „Verknüpfen“
     (`LinkAddMenu`),
   - rechts **Erinnerung** (Glocke gefüllt und in `Palette.level`, silberblau,
     sobald eine künftige Erinnerung gesetzt ist, sonst Umriss in `onSurface`).
5. 16 pt darunter, mittig wie „Added to wallet“ bei Solcard, die
   übergeordnete Liste als Pille im Stil der Listen-Auswahl (`CanvasPicker`,
   `PlaceRow`; genau ein übergeordneter Eintrag).
6. Bei Aufgabe, Projekt und Termin (`EntryType.hasDate`) die
   **Datumszeile** im Container-Stil (`EntryDateCard`, 56 pt, 12 pt unter der
   Pille): links Datum (`calendar`, leer „Datum“), rechts Uhrzeit (`clock`,
   leer „Uhrzeit“, bei Aufgabe und Projekt erst nach dem Datum wählbar), beide
   Hälften gleich breit mit 1 pt Trennlinie. Datum öffnet `DateSheet` bzw. bei
   Terminen `EventTimeSheet` (auch über die Uhrzeit-Hälfte, die Spanne
   „15:00–16:00“ oder „Ganztägig“ zeigt); Uhrzeit öffnet `TimeSheet`.
   **Erinnerungsleiste** (`EntryReminderCard`, 12 pt darunter bzw. unter der
   Pille, alle Kategorien): nur bei künftigen Erinnerungen, eine Zeile je
   Erinnerung (56 pt, 1 pt Trennlinie), Container-Stil. Links gefüllte Glocke
   in `onSurfaceVariant` (farbig nur der Hauptknopf oben), dann Datum und Uhrzeit (`L.dateTime`); Tipp öffnet das
   Erinnerungs-Blatt. Rechts ohne Notiz der kleine Chip „+ Notiz“ (28 pt,
   `reminderNoteChip`), der ein einzeiliges Textblatt öffnet. Mit Notiz fällt
   der Chip weg, die Notiz steht in 12 pt `muted` unter Datum und Uhrzeit
   (30 pt eingerückt, `reminderNoteIndent`); Tipp darauf bearbeitet sie, leer
   speichern löscht sie. Gespeichert wird je Erinnerung im Kopf als
   `erinnerung_notiz_<Unix-Sekunden>` (Android liest und schreibt unbekannte
   Schlüssel unverändert mit); wird die Erinnerung entfernt, fällt die Notiz
   mit weg (`Entry.setReminders`). In der Mitteilung steht der Titel des
   Eintrags, darunter die Notiz statt „Erinnerung“, auch nach „Später“.
7. Anhang (außer Bild und Video).
8. **Text**: Ohne Text ein Schalter im Container-Stil „Text hinzufügen“
   (`EntryTextToggle`). Einschalten blendet den Schalter aus und zeigt an
   seiner Stelle den Text-Container (bleibt bis zum Verlassen der Seite, auch
   leer). Der Text-Container hat den Kopf Symbol + „Text“, rechts den runden
   Pfeil nach oben rechts (`CanvasOpenButton`, 32 pt Glas, 44 pt
   Trefferfläche, 12 pt vom oberen und rechten Rand wie auf der angepinnten
   Karte, siehe Maße), der in die Text-Ansicht wechselt wie „Text“ im Edge
   Picker (ohne Tastatur). Inhalt 160 pt hoch (`entryTextBox`), leer der
   Hinweis „Details“. Ist der Text länger, steht unten mittig „Mehr anzeigen“
   über einem Verlauf (`entryTextFade`); der Tipp vergrößert den Container auf
   den ganzen Text plus zwei Zeilen. Jeder andere Tipp auf den Text oder den
   Hinweis bearbeitet den Text **direkt im Container**: derselbe Editor wie in
   der Text-Ansicht (`EntryBodyEditor` mit `inCard`, Markdown als Rohtext),
   Cursor am Ende, Tastatur offen. Die Seite bleibt in der Detail-Ansicht mit
   Hauptknöpfen und Listen-Pille; beim Schreiben wächst der Container mit dem
   Text, der Canvas scrollt die Cursorzeile über die Leiste (`caretAnchor`).
   Über der Tastatur steht wie in der Text-Ansicht `BodyKeyboardBar` statt der
   Bottom-Zeile. Zuklappen in der Leiste oder Wegziehen der Tastatur beendet
   die Bearbeitung, speichert und zeigt den Text wieder gerendert.
9. Beim Kartendeck der Karten-Container (`DeckSection`), nur wenn das Deck
   Karten hat. Ein leeres Deck zeigt „Dieses Deck hat noch keine Karten.“ im
   Info-Blatt.
10. Verknüpfungen-Container: Kopf Symbol + „Verknüpfungen“ + Anzahl, rechts
   der Pfeil nach oben rechts, der in die Verknüpfungen-Ansicht wechselt. Kein
   Plus mehr; hinzugefügt wird über den mittleren Hauptknopf. Einträge im
   Bereich (bei Projekt, Arbeitsbereich und Tag) plus verknüpfte ohne Doppelte;
   der Eintrag aus der Listen-Auswahl erscheint hier nie.
11. Chats-Container: nur wenn Chats mit diesem Eintrag verknüpft sind
   (`ChatList.linked`), Kopf Symbol + Name + Anzahl, neueste oben, Tipp öffnet
   den Thread (`Route.chat`). Verknüpft wird im Thread über „…“ › Verknüpfen.

Zugehörigkeit und Verknüpfung sind getrennt. Verknüpfen ändert nie, wohin
ein Eintrag gehört. Der eigene übergeordnete Eintrag und die eigenen Einträge
stehen nicht in der Verknüpfen-Auswahl (`LinkPlace.linkable`). Eine Verknüpfung
zwischen einem Eintrag und dem Eintrag, zu dem er gehört, ist doppelt und wird
beim Start auf beiden Seiten entfernt (`EntryLibrary.dropPlaceLinks`), ebenso
beim Ändern der Pille.

Die Uhrzeit steht im Kopf als `faellig_zeit` (HH:mm), Android liest und
schreibt den Schlüssel unverändert mit; ohne Datum gibt es keine Uhrzeit.

## Status je Kategorie

Jede Kategorie außer Tag hat einen Status (`EntryStatus.options` in
ParalistCore, Kopf-Schlüssel `status` wie bisher, Start immer „Offen“; `tagart`
bleibt die Art des Tags). Werte und Wortwahl (`EntryStatus.label`):

| Kategorie | Werte |
|---|---|
| Aufgabe | Offen, In Arbeit, Erledigt |
| Projekt | Offen, In Arbeit, Abgeschlossen (`erledigt`) |
| Termin | Offen, In Arbeit, Stattgefunden (`erledigt`), Verschoben, Abgesagt |
| Arbeitsbereich | Offen, Geschlossen |
| Notiz | Unfertig (`offen`), Gelesen |
| Dokument | Unfertig (`offen`), In Arbeit, Gelesen |
| Lesezeichen | Offen, Gelesen / Angehört (Spotify) / Angesehen (YouTube), Geteilt |
| Datei | Offen, Angesehen (Bild) / Abgespielt (Video) / Angehört (Audio) / Gelesen (sonst), Geteilt |
| Kartendeck | Offen, Gelernt |
| Karteikarte | Offen, Schwer, Gut, Leicht |

Von selbst gesetzt: Teilen → Geteilt; Bewerten beim Lernen → Schwer (auch
„Nochmal“), Gut, Leicht; am Ende einer Lernrunde wird das Deck „Gelernt“,
sobald jede Karte mindestens einmal bewertet wurde (`finishStudy`); ändert sich
der Beginn eines offenen Termins, wird er „Verschoben“. Ein fremder Wert wird
beim Setzen oder beim Typwechsel verworfen (`EntryStatus.valid`).

**Termin-Verlauf:** Jedes Verschieben (alter und neuer Beginn) und jedes
Absagen landet mit Zeitpunkt in `nutzung.json` (`UsageData.eventChanges`,
nur auf dem Gerät). Das Info-Blatt zeigt bei Terminen die Zeile „Verschoben“
mit Anzahl und den Abschnitt „Verlauf“ („Verschoben am …“ mit neuem Beginn,
„Abgesagt am …“), neueste zuerst.

## Container

Text-, Verknüpfungen- und Chats-Container im Stil von Solcard
(`CanvasCard`, `.canvasCard()`): 20 pt Radius, leichter Verlauf von oben
`Palette.cardTop` nach unten `cardBottom`, 1 pt Rand `cardStroke`, 16 pt
Innenabstand, 12 pt Abstand zwischen den Containern (`canvasCardGap`). Kopf
(`CanvasCardHead`, 48 pt): Symbol, Name, Anzahl, rechts der Pfeil
(`AppIcons.openCanvas`), Vorlage „Top products“ mit Pfeil oben rechts.

## Info-Blatt („mehr“)

Blatt von unten mit Griff (`EntryInfoSheet`, `.medium` und `.large`), Vorlage
ist „Beschreibung“ bei YouTube:

- Kopf „Info“ links, X rechts, Trennlinie.
- Ganzer Titel, bearbeitbar (`EntryTitle`, Tipp darauf). Beim Bearbeiten
  wird das Blatt groß, scrollt zum Titel und zeigt über der Tastatur die
  Titel-Leiste (`TitleKeyboardBar`: Kopieren, Neu schreiben, Zuklappen).
  Gespeichert wird bei Fertig, Zuklappen oder Verlassen des Feldes.
- Kacheln in der Typfarbe (18 %): „Erstellt“, „Geändert“ (nur wenn mindestens
  eine Minute nach dem Erstellen geändert) und „Wörter“ (nur mit Text,
  `EntryFacts.words`). Was fehlt, fällt weg; die übrigen teilen sich die Breite.
- Abschnitt „Link“ nur bei Einträgen mit Link (`EntryFacts.source`): Chip
  „Quelle des Eintrags“ mit dem Link in Festbreitenschrift (eine Zeile, Mitte
  gekürzt, markierbar) und Pille „Kopieren“ rechts; Meldung „Link kopiert“.
- Abschnitt „Fotodetails“, „Videodetails“, „Audiodetails“, „Dateidetails“ oder
  „Details“ (`EntryFacts.kind`) mit Zeilen Datum, Aufrufe, Geteilt, bei
  Anhängen Größe.

Aufrufe zählt jedes Öffnen der Detailseite (`UsageData.opened`), Geteilt jedes
abgeschlossene Teilen (`UsageData.shared`). Beides liegt nur auf dem Gerät in
`nutzung.json`, nicht im Eintrag; Android kennt die Zahlen nicht.

## Teilen

„Teilen“ im Menü der Kopfzeile bei Einträgen mit Anhang (Foto, Video, Audio,
Datei; geteilt wird die Datei mit Originalnamen) oder mit Link. Öffnet das
System-Teilen-Blatt (`ShareSheet`); nur ein abgeschlossenes Teilen zählt.

## Inhalt kopieren

„Inhalt kopieren“ im Menü der Kopfzeile, direkt unter „Teilen“, sobald Titel
oder Text da ist; öffnet ein natives Untermenü (Chevron nach rechts):
- „Nur Titel“ (nur mit Titel, `EntryFacts.title`); Meldung „Titel kopiert“.
- „Titel und Text“: Titel und Text als Markdown, durch eine Leerzeile getrennt
  (`EntryFacts.content`); Meldung „Inhalt kopiert“.

## Verknüpfung hinzufügen

Der mittlere Hauptknopf „Verknüpfen“ öffnet ein natives Menü (`LinkAddMenu`,
feste Reihenfolge): oben „Neuer Eintrag“, darunter „Verknüpfen“. In der
Verknüpfungen-Ansicht steht dasselbe Menü als Plus im Kopf des Containers,
ohne Verknüpfungen dort die Option „Verknüpfung hinzufügen“ (direkt die Auswahl).

- „Neuer Eintrag“ öffnet dasselbe Erstellen-Panel wie das Plus der Tab-Leiste
  (`Router.openCreate(link:)`), hier über dem Deckblatt (`CreateOverlay`
  und `CreateSheets` in `DetailHost`). Was dort entsteht (Typ über den
  Composer, Foto, Video, Audio, Datei), gehört zum aktuellen Eintrag: die
  Pille „Ablegen in“ im Composer steht schon darauf (`ComposerDraft.linkTo`
  nach den Regeln von `PlacePicker`). Nur wenn diese Regeln es nicht erlauben
  (z. B. Projekt unter einer Aufgabe, Arbeitsbereiche), bleibt die Pille auf
  „Eingang“ und der neue Eintrag wird in beide Richtungen verknüpft
  (`ComposerDraft.link`, danach `AppModel.saveCreated`). Eine neue Karteikarte
  aus einem Kartendeck kommt in dieses Deck. Die Detailseite bleibt offen, der
  neue Eintrag erscheint in den Verknüpfungen. Solange das Panel offen ist, ist die
  Zurück-Wischgeste aus.
- „Verknüpfen“ öffnet wie bisher die Auswahl vorhandener Einträge:

Bottom Sheet (`LinkSheet`) mit Reitern oben: zuerst „Vorschläge“, dann
Arbeitsbereiche, Projekte, Tags, Aufgaben, Notizen, Termine, Ressourcen
(Lesezeichen, Dateien, Dokumente), Kartendecks, Karteikarten (`LinkTab`).
Dieselbe Auswahl (`LinkPickerSheet`) öffnet im Composer die Pille „Ablegen in“
unten rechts neben dem Diktierknopf, ebenso die Zeile „Ablegen in“ im
Teilen-Fenster (`ParalistShare/ShareView`), dort mit „Eingang“ oben bei den Vorschlägen und nur einem Ziel:
der gewählte Eintrag wird wie auf der Detailseite der eine übergeordnete
Eintrag (`ComposerDraft.pick`); ein Projekt kommt so in einen Arbeitsbereich, bei
Arbeitsbereichen fehlt der Knopf. Die Reiter folgen denselben Regeln wie die
Pille auf der Detailseite (`PlacePicker.tabs`). Bei Karteikarten fehlen dort die Decks; das Deck wählt
der eigene Chip oben neben der Kategorie (`ComposerDraft.chooseDeck`). Die eigene
Kategorie erscheint nie, weder als Reiter noch als Eintrag
(`LinkPicker` in ParalistCore). Ausnahme: Tags verknüpfen auch andere Tags.
Eine Karteikarte ohne Deck, die mit einem Kartendeck verknüpft wird, kommt in
dieses Deck (`deck` im Kopf, `LinkPlace.deck`). Vorschläge: gemeinsame Wörter im Titel und
gleiche Liste zuerst, sonst zuletzt geändert, höchstens 12. Eine eigene
Deck-Auswahl gibt es nicht mehr.

## Cover-Bereich und Canvas in Aktionen und Text

- Unter dem 16:9-Teil liegen Titel und Infozeile mit Schleier noch auf dem
  Verlauf, darunter die Karte mit runden Ecken und Griff, bei allen Kategorien.
- Der Kategorieverlauf (`CoverArtwork`) liegt als Bühne hinter dem Canvas
  (`CoverStage`): bei t = 0 so hoch wie der Cover-Bereich, darunter eine
  gespiegelte Kopie, die nach unten ausblendet; bei t = 1 über die ganze
  Höhe. Bei Bild, Video und Einbettung mit Einstellung „Schwarz“ ist die
  Bühne schwarz statt des Verlaufs.
- Der Kategorieverlauf hat unten keinen hellen Schein mehr (`CoverArtwork`
  mit `glow: false` auf der Detailseite, das Widget behält ihn). Hell oder
  dunkel wird es nur durch den Schleier hinter dem Titel (`CoverTitleVeil`).
- Tipps im Cover-Bereich (Bild öffnet das Cover, Video spielt oder hält an)
  kommen über eine Tipp-Geste der ganzen Seite an, nur wenn der Canvas oben
  steht; Spotify und YouTube nehmen Tipps selbst entgegen.
- Alle Kategorien haben denselben Aufbau, auch Karteikarte und Kartendeck:
  Cover-Bereich mit Kategorieverlauf und Emblem, Titel mit Schleier, Karte, Edge
  Picker, Bottom-Zeile.

## Wann der Edge Picker sichtbar ist

**Derzeit nie.** Mit `EdgePicker.shownOnDetail = false` wird die Kerbe nicht
eingehängt: kein 12-pt-Rand, keine Trefferfläche, kein Ausklappen per Tipp
auf eine leere Canvas-Stelle, kein Einblenden per Tipp aufs Cover, keine
Gesten. Der Zustand (`pickerTucked`, `pickerShown`, `expandedAt`,
`PlusFrameKey`) läuft weiter, löst aber nichts aus. Die Ansichten erreicht
man ohne Picker so: Cover per Herunterziehen, Tipp aufs Bild oder Video-Tipp
im Cover-Bereich, zurück per Hochziehen; Text-Ansicht über den Pfeil im
Text-Container; Verknüpfungen über den Pfeil im Verknüpfungen-Container;
zurück zur Detail-Ansicht über den Zurück-Knopf der Bottom-Zeile. Mit dem Schalter auf
`true` gilt:

- Bei allen Kategorien.
- **Beim Öffnen eingeklappt**, in jeder Ansicht: nur 12 pt am rechten Rand
  (`edgePeek`). Er schiebt sich beim Öffnen nicht herein.
- **Ausklappen** nur auf Wunsch: Tipp auf den sichtbaren Rand (32 pt
  Trefferfläche, `edgePeekHit`) oder auf eine leere Stelle im Canvas.
- **Einklappen von selbst**, sobald etwas anderes passiert: Scrollen im
  Canvas um mehr als 8 pt ab der Lage beim Ausklappen (`edgeTuckScroll`),
  eine erledigte Option oder ein geschlossenes Sheet (Verknüpfung, Datum,
  Erinnerung, Text), Wechsel in Text oder Verknüpfungen. Ein Wechsel in
  Aktionen über den Picker lässt ihn offen.
- **Knöpfe frei halten:** Text- und Verknüpfungen-Container melden den Rahmen
  ihres Pfeils bzw. Plus (`PlusFrameKey`, `PlusFrameReporter`). Rutscht einer
  unter den ausgeklappten Picker, klappt der Picker ein. Klappt man ihn selbst aus, während das Plus schon darunter
  liegt, bleibt er offen. Der Picker bewegt sich nie senkrecht.
- **Übergang:** Deckkraft folgt `detailChrome(t)`; im Cover ist er weg.
- **Cover:** zunächst ausgeblendet. Ein Tipp aufs Cover blendet ihn mit dem
  übrigen Chrome ein oder aus (siehe Cover-Ansicht). Beim Wechsel ins Cover
  und beim Start eines Videos ist er wieder ausgeblendet.
- Einblenden und Ausblenden im Cover: von rechts hereinschieben mit
  Überblendung.

## Optionen im Edge Picker

Derzeit ohne Wirkung auf der Detailseite (Picker ausgeblendet). Der Picker wächst mit: immer Cover und Aktionen, mit Text oder in der
Text-Ansicht zusätzlich Text, mit Verknüpfungen (Einträge im Bereich oder
verknüpfte) oder in der Verknüpfungen-Ansicht zusätzlich Verknüpfungen,
immer als letzte Option (`EdgePicker.options`). Die Kerbe wächst nicht über
drei Optionen hinaus (280 pt, `EdgePicker.visible`), mit zwei ist sie 48 pt
niedriger (`EdgePicker.height`). Mit zwei Optionen sitzen beide senkrecht
mittig in der Kerbe, bei drei gilt die Regel mit 16 pt zum runden Ende. Bei
vier steht die gewählte Option immer in der Mitte, die Liste rutscht beim
Wechsel durch die Kerbe, die vierte ist oben oder unten nur angedeutet.
Nicht gewählte Symbole blenden zum Rand hin leicht aus: voll bis eine
Schrittweite (45 pt) von der Mitte, dann linear bis 50 % Deckkraft am Rand
der Kerbe (`EdgePicker.fade`, `faintest`).

## Text-Ansicht

In der Karte nur der Text in einem Innen-Container, der die ganze restliche
Höhe füllt (mindestens 240 pt, `entryTextViewMin`), darunter (nur mit Text) der eingeschaltete
Schalter „Text entfernen“. Ausschalten fragt nach („Text entfernen?“,
destruktiv), löscht dann den ganzen Text und wechselt zurück zu Aktionen.
Keine Knöpfe, keine Listen-Pille. Beim Wechsel in die Text-Ansicht klappt der Edge
Picker ein. Ebenso beim Wechsel in die Verknüpfungen-Ansicht, damit das Plus frei ist.
In der Bottom-Zeile steht links der runde Zurück-Knopf (`AppIcons.canvasReturn`),
der Tastatur schließt und mit `Motion.page` in die Detail-Ansicht wechselt.

**Erledigt-Knopf bei Aufgaben:** Solange eine Aufgabe nicht erledigt ist, steht
rechts neben „Schließen“ ein runder Glas-Knopf mit dem Haken-Symbol des Status
„Erledigt“, aber grau und blass (`Palette.openTask`, 60 %, `entryBarDoneFaded`).
Ein Tipp färbt ihn grün (`Palette.done`, kurz größer, Haptik), nach 0,45 s wird
die Aufgabe erledigt (der Status-Knopf oben wird grün), nach weiteren 0,45 s
verschwindet der Knopf und „Schließen“ wird wieder breit. Wird die Aufgabe
wieder auf einen anderen Status gesetzt, erscheint der Knopf erneut.

Bei offener Tastatur (Text oder Titel) rutschen Bottom-Zeile und Edge Picker
nicht mit hoch, sie bleiben unten unter der Tastatur; der Edge Picker ist dann
ganz ausgeblendet und nicht erreichbar. Beim Text steht über der Tastatur die
Leiste `BodyKeyboardBar`: links „Rückgängig“ (nur wenn es etwas gibt, ein
Schritt je Wort oder Löschung, `EditHistory`), „Wort entfernen“ (Wort vor dem
Cursor, `TextEdits.deleteWord`), rechts der runde Knopf zum Zuklappen. Über
der Leiste bleibt eine Zeile Platz (28 pt, `caretGap`), damit die Cursorzeile
nie direkt an der Leiste klebt. Liegt die Cursorzeile beim Öffnen der Tastatur
oder beim Schreiben hinter Leiste oder Tastatur, scrollt die Seite so weit
hoch, dass sie mit dieser Zeile Abstand über der Leiste steht (`caretAnchor`
in `EntryBodyEditor`, gemessen am Text bis zum Cursor). Beim Titel steht die Titel-Leiste im Info-Blatt. Beide Leisten haben keinen
Schleier dahinter; Schrift und Symbole in `Palette.onSurface` (hell schwarz),
auch „Wort entfernen“ und „Neu schreiben“.

## Einklappen in der Detail-Ansicht

Eingeklappt sind nur 12 pt am Rand zu sehen (`edgePeek`). Ein Tipp auf eine
leere Stelle im Canvas (neben den Optionen, unter dem Inhalt, auch in der
Verknüpfungen-Ansicht) klappt ihn aus oder wieder ein; ein Tipp auf den
sichtbaren Rand (32 pt Trefferfläche, `edgePeekHit`) klappt ihn aus. Wann er
von selbst einklappt, steht unter „Wann der Edge Picker sichtbar ist“.

## Position

- Rechts am Bildschirmrand, unten ausgerichtet.
- In allen Ansichten dieselbe Höhe: Unterkante der Kerbe 72 pt über dem
  unteren sicheren Bereich (`Dimens.edgePickerBottom` = `edgePickerLift` 24
  + `entryBarHeight` 48 = 72). In Aktionen, Text und Verknüpfungen sind das 24 pt
  über der Bottom-Zeile, im Cover derselbe Platz ohne Bottom-Zeile. Nichts
  hängt an der Titelzeile des Covers.
- Im Cover rückt die Titelzeile nur bei sichtbarem Picker um 64 pt
  (`edgeNotchWidth`) nach links. Solange der Picker ausgeblendet ist, entfällt
  der Versatz: die Titelzeile hat rechts wie links 24 pt (`coverRowInset`).
- Die ganze Kerbe ist 2 pt zum Rand verschoben (`edgeShift`), weil der Bauch
  der Form optisch über die Mitte hinausragt.

## Edge Picker im Kalender

`EdgePickerView` ist allgemein (Optionen, Beschriftung, Symbol von außen).
Der Kalender nutzt dieselbe Kerbe für Tag, Woche und Monat
(`Pages/CalendarEdge.swift`) mit Fließ-Leuchten im Hintergrund
(`EdgeNotchBackground`, `Palette.edgeGlow`). Er klappt 3 s nach dem
Ausklappen oder einem Wechsel von selbst ein (`Dimens.edgeAutoTuck`), dann
sind nur 12 pt am Rand zu sehen. Eingeklappt läuft derselbe Verlauf wie
ausgeklappt, in derselben Farbe und Stärke (`Palette.edgeGlow`,
`edgeGlowOpacity`), nur sehr langsam von oben nach unten, ein Durchlauf in 12 s
(`Dimens.edgeBeacon*`). Darunter liegt dieselbe Farbe ganz schwach als
Grundton (`edgeBeaconBase`), damit der Rand nie ganz dunkel wird und immer
erkennbar bleibt. In der Detailseite
leuchtet er nicht.
Im Kalender stehen die drei Symbole fest und gleichmäßig verteilt in der
Kerbe (`spread`, `EdgePicker.spread`), die Kerbe ist 16 pt niedriger
(`Dimens.calendarNotchHeight`). Nach einem Wechsel zeigt die Pille 1,2 s
lang den Namen um 90° gedreht („Täglich“, „Wöchentlich“, „Monatlich“,
`Dimens.edgeAnnounce`), die anderen Symbole sind solange ausgeblendet.

## Edge Picker in der Übersicht

Die Übersicht nutzt dieselbe Kerbe wie der Kalender (`Pages/OverviewEdge.swift`):
gleiche Höhe, Leuchten, Ansage, Einklappen 3 s nach dem Ausklappen oder einer
Aktion. Anders als im Kalender klappt er nie von selbst aus, auch nicht bei der
Rückkehr zur Übersicht (aus einer Sammlung, einem Eintrag oder einem anderen
Reiter); nur ein Tipp auf den Rand öffnet ihn, und der wird genau einmal
ausgeführt (`handled`). Beim ersten Mal steht links neben dem Rand ein Hinweis
(`overview_edge_hint`: Listen und Sammlungen als Reiter nebeneinander, gemerkt in
`overview_tabs_hint_seen`), er verschwindet beim Tipp auf ihn oder auf den Rand.

Drei Optionen von oben nach unten:

1. **Regler** (`XoolSlidersIcon`, wie bei den Aufgaben): öffnet „Anpassen“ (`ViewSheet`) für die
   Liste des Tabs. Bei einem Eintrag gelten eigene Einstellungen je Eintrag
   (`view_entries`).
2. **Wechseln** (`dots.and.line.vertical.and.pointer.arrow.rectangle`, hüpft
   beim Ausklappen, `.symbolEffect(.bounce)`): Blatt „Wechseln“ mit den Quellen
   des Tabs (untereinander: aller sichtbaren Tabs), oben zwei Reiter
   **Listen | Sammlungen** (dazu **Einträge**, sobald ein Tab Einträge als
   Quelle hat), umschaltbar per Tipp und per Wischen. Tipp zeigt die Quelle im
   Tab, Halten und Ziehen ordnet, „Hinzufügen oder entfernen“ öffnet die
   Auswahl (Sammlungen, Listen, Einträge mit Suche). Oben rechts „Tabs“.
   Dasselbe Blatt öffnet ein Tipp auf den aktiven Reiter bzw. den Gruppenkopf.
3. **Anordnung**: Symbol zeigt den Zustand (Tab-Ansicht oder
   Gruppenansicht), ein Tipp schaltet um. Die Pille steht in Ruhe hier; nach
   Regler oder Wechseln springt sie zurück.

## Tabs der Übersicht

Unter den Kacheln stehen Tabs (`OverviewLayout`, gespeichert als JSON in
`overview_tabs`). Ein Tab hat einen Namen, Quellen und eine aktive Quelle.
Quellen gibt es in drei Arten (`OverviewSource.category`):

- **Sammlungen** (`ListKind.collections`): Eingang, Angepinnt, Favoriten,
  Ressourcen, Archiv, Alle.
- **Listen** (`ListKind.lists`): Notizen, Aufgaben, Termine, Lesezeichen,
  Dateien, Tags, Karteikarten, Projekte, Arbeitsbereiche.
- **Einträge** (`eintrag:<id>`; zeigt alles, was darin abgelegt ist, über alle
  Stufen, dazu Verknüpfungen, ohne Archiv, `OverviewScope.contents`).

Sammlungen und Listen werden als `liste:<art>` gespeichert.

- Zwei Tabs sind vorgegeben (Ids `listen` und `markiert`), nicht löschbar,
  nur ausblendbar, mit allen Sammlungen und Listen als Quellen (mindestens
  eine bleibt). Standard: Tab-Ansicht, sichtbar nur **Eingang**, dahinter
  **Angepinnt** ausgeblendet. Ihr Name ist immer der Name der gewählten
  Quelle. Einmalig (Oktober 2026, `defaults_reset_2026_10`) wurden alle auf
  diesen Standard und auf Sortierung nach Erstellung zurückgesetzt.
- **Eigene Tabs** („+“ unter „Tabs“: „Reiter aus Liste, Sammlung oder
  Eintrag“): löschbar. Höchstens 10 Tabs, je 30 Quellen. Umbenennen (Stift,
  höchstens 40 Zeichen) gibt es nur für Tabs, deren gewählte Quelle ein
  Eintrag ist; sonst zeigt der Tab den Namen der Quelle.
- Blatt „Tabs“: je Zeile Symbol, Name und darunter klein die Art („Liste“,
  „Sammlung“, „Eintrag“), rechts Stift (nur Eintrag), Auge, Ziehgriff.
  Darunter „Reiter zeigen“ (Icon und Name, nur Name, nur Icon) und
  „Einträge je Abschnitt“ mit Pfeil zu einer eigenen Seite: „Alle“
  (Standard) oder „Individuell“ mit Schieberegler über 5, 10, 15, 20, 25,
  50, 100 (`OverviewSectionLimit.steps`, Start 10); beides auch in den
  Einstellungen unter „Übersicht“ (`OverviewTabOptions`, `OverviewLimitPage`).
- Mindestens ein Tab bleibt sichtbar; bliebe keiner, erscheint der erste.
- Reiter (`OverviewTabLabel`): Symbol der Quelle, Name der Quelle, Anzahl,
  ohne Pille und ohne Pfeil, Schrift 15 medium. Ein Reiter allein oder ein
  Gruppenkopf: grau (`Palette.muted`). Ab zwei Reitern in der Tab-Ansicht:
  aktiver Reiter mit Symbol und Name in `Palette.level` und Punkt darunter,
  die anderen in `Palette.subtle` mit 75 % Deckkraft (`idleTab`, im
  Dunkelmodus dadurch dunkler, im Hellmodus heller).
- Darunter die Sortierzeile (`OverviewSortRow`): „Zuletzt erstellt“ o. Ä.
  links, rechts ein runder Plus-Knopf: Liste wie bisher (Aufgaben mit
  Schnelleingabe), Eintrag: neue Notiz darin abgelegt oder, wenn er nichts
  aufnehmen kann, mit ihm verknüpft. Kein Plus bei Alle, Angepinnt,
  Favoriten, Archiv.
- Abstände: Reiterzeile 32 pt unter den Kacheln (`listTop`), 36 pt hoch,
  8 pt bis zur Sortierzeile (`listGap`), in beiden Ansichten gleich.
- Köpfe bleiben beim Scrollen oben hängen, in beiden Ansichten
  (`PinnedSection`): Reiterzeile bzw. Gruppenkopf mit Sortierzeile und Plus.
  Der undurchsichtige Grund endet 8 pt unter dem Plus (`headTail`), darunter
  läuft ein Übergang aus (`pinnedFade`).
- Anlegen auf drei Wegen: Plus gegenüber dem Listennamen, Zeile „Neue …“
  direkt unter dem letzten Eintrag (Aufgaben: Schnelleingabe in dieser Zeile,
  Einträge als Quelle: „Neue Notiz“) und Tipp auf die freie Fläche darunter
  (Tab-Ansicht und Gruppenansicht mit nur einer Gruppe: bis zum unteren
  Seitenrand, ohne Navigationsleiste; Gruppenansicht mit mehreren Gruppen:
  80 pt, `groupFill`, danach beginnt die nächste Gruppe). Tab mit genau einer Quelle und ohne Einträge zeigt
  „Keine Einträge“ (`overview_no_entries`). Kein Emblem in der Übersicht; bei leerem Tab steht unter der
  Zeile mittig nur der Info-Knopf (`EmptyInfoButton`). Hinweis: bei Listen
  der bisherige Text, bei Einträgen `overview_empty_tap`.
- Info-Knopf am Emblem (`EmptyHint`, überall in der App): öffnet einen Dialog
  mit dem Hinweis und „Verstanden“ (Knopf bleibt) oder „Nicht mehr anzeigen“
  (Knopf verschwindet überall, `empty_info_hidden`).
- **Tab-Ansicht** (Reiter nebeneinander): Reiter immer linksbündig, 20 pt
  Abstand (`tabGap`), bei Platzmangel seitlich scrollbar (Name höchstens
  180 pt). Tipp auf einen anderen Reiter wählt ihn, Tipp auf den aktiven
  öffnet „Wechseln“; Wischen über die Liste wechselt den Reiter.
- **Gruppenansicht** (Reiter untereinander): jeder Tab als
  Gruppenkopf, nicht einklappbar; Tipp öffnet „Wechseln“. Bei „Individuell“
  je Abschnitt höchstens so viele Einträge, darunter „Alle n anzeigen“ klein
  und grau (`Palette.subtle`, öffnet die Liste bzw. den Eintrag). Ab dem
  zweiten Abschnitt steht der Kopf 10 pt unter dem Ende des vorigen
  (`groupTop`), ein leerer Abschnitt behält seine 80 pt Tippfläche.
- Übernahme: Bei fehlendem `overview_tabs` gelten die bisherige Wahl
  (`marked_list`, `overview_list`) und die Anordnung aus `overview_layout`.
  Gespeichertes JSON ohne `v` (vor Version 2) bekommt in den vorgegebenen
  Tabs die fehlenden Sammlungen und Listen hinten angehängt; Sichtbarkeit,
  Reihenfolge und Wahl bleiben. Neu im JSON: `v` (jetzt 3), `zeigen`, `je`
  (fehlt bei „Alle“; Werte aus Version 2 gelten als „Alle“).

Nur Einstellung, kein Dateiformat.

## Maße

Alle Werte in pt. Kerbe in `Dimens`, Pille und Raster in `ParalistCore`
`EdgePicker`.

| Wert | Größe | Ort |
|---|---|---|
| Kerbe Breite | 64 | `Dimens.edgeNotchWidth` |
| Kerbe Höhe (drei oder mehr Optionen) | 280 | `Dimens.edgeNotchHeight` |
| Kurvenlänge oben und unten | 96 | `Dimens.edgeNotchCurve` |
| Schatten-Deckkraft | 0.16, Radius 12, x −2 | `Dimens.edgeShadow` |
| Pille Höhe in Ruhe | 46 | `EdgePicker.pill` |
| Pille Höhe beim Ziehen | 96 | `EdgePicker.pillWide` |
| Pille Breite | 40 | `EdgePicker.pillWidth` |
| Symbolgröße | 20, semibold | `EdgePicker.icon` |
| Abstand Pille zu Symbol | 12, bleibt bei 46 und 96 gleich | `EdgePicker.gap` |
| Ab hier ist es Ziehen statt Tippen | 8 | `EdgePicker.dragStart` |
| Abstand über Bottom-Zeile | 24 | `Dimens.edgePickerLift` |
| Unterkante über sicherem Bereich, alle Ansichten | 72 | `Dimens.edgePickerBottom` |
| Scrollweg bis zum Einklappen | 8 | `Dimens.edgeTuckScroll` |
| Abstand äußerste Option zum runden Ende | 16 | `Dimens.edgeEndGap` |
| Höhe Bottom-Zeile | 48 (Safari 48) | `Dimens.entryBarHeight` |
| Unterkante Bottom-Zeile über dem Bildschirmrand | 22 mit Home-Indikator, 8 ohne (wie Tab-Leiste, Stand 2026-10-29) | `router.tabBarLift` (`TabBarLayout.lift`) |
| Bottom-Zeile Außenabstand links und rechts | 34 (Safari 34) | `Dimens.entryBarInset` |
| Bottom-Zeile Abstand Knopf zu „Schließen“ | 8 (Safari 7,5) | `Dimens.entryBarGap` |
| Runde Knöpfe Durchmesser, Höhe „Schließen“ | 48 (Safari 48) | `Dimens.entryBarCircle` |
| Schrift „Schließen“ ausgeklappt / eingeklappt | DM Sans 17 / 15 semibold | `entryBarFont`, `entryBarPillFont` |
| Eingeklappte Kapsel Breite mindestens × Höhe | 133 × 32 (Safari 133 × 32) | `entryBarPillWidth`, `entryBarPillHeight` |
| Eingeklappte Kapsel Innenabstand seitlich | 20 | `entryBarPillPad` |
| Eingeklappte Kapsel Unterkante über dem Bildschirmrand | 14 auf allen Geräten (Safari 14); Absenken 16 mit Home-Indikator, 2 ohne | `entryBarPillRest`, `router.entryPillDrop` (`TabBarLayout.pillDrop`) |
| Ausblenden Zurück und Icon: Skalierung | 0,6 | `entryBarHiddenScale` |
| Scrollweg bis zum Ein- bzw. Ausklappen | 24 ab letztem Richtungswechsel | `entryBarCollapseScroll` |
| Inhalt Text-Container | 160 | `Dimens.entryTextBox` |
| Text-Ansicht mindestens | 240 | `Dimens.entryTextViewMin` |
| Pfeil-Knopf im Container: Abstand oben und rechts | 12 = 16 × 20 / 26, gerundet | `Dimens.canvasOpenEdge` |
| Zurück-Wisch: Mindestweg | 16 | `Dimens.swipeBackStart` |
| Zurück-Wisch: Randzone der System-Geste | 24 | `Dimens.swipeBackEdge` |
| Zurück-Wisch: Anteil der Breite zum Schließen | 0.35 | `Dimens.swipeBackShare` |
| Pfeil-Knopf im Container: Versatz gegenüber Kopfzeile | x 0, y 2 | `Dimens.canvasOpenShift` |
| Vorlage angepinnte Karte: Radius, Abstand, Knopf | 26, 16, 36 | `TaskDimens.pinRadius`, `pinPad`, `iconCircle` |
| Container: Radius, Knopf (Trefferfläche) | 20, 32 (44) | `canvasCardRadius`, `canvasOpenCircle`, `canvasOpenHit` |

Abstand Mitte Pille zu Mitte Nachbarsymbol: `pill / 2 + gap + icon / 2`,
also 45 in Ruhe und 70 beim Ziehen. Weitere Symbole folgen im Raster
`icon + gap` = 32.

Die gewählte Option steht in der Mitte der Kerbe. Ist die erste oder letzte
Option gewählt, rutscht die Liste so weit, dass diese Option 16 pt vom
sichtbaren runden Ende der Kerbe entfernt ist, statt in der Mitte zu stehen.
Das runde Ende liegt auf der Achse der Pille bei halber Kurvenlänge (48 pt
vom oberen bzw. unteren Rand der Kerbe). Die gewählte Option beginnt also
64 pt unter dem oberen Rand bzw. endet 64 pt über dem unteren Rand
(`EdgePicker.shift`, Spielraum `reach` = 76 pt ab der Mitte; gilt bei
genau drei Optionen). Bei der
mittleren Option rutscht nichts.

## Form der Kerbe

`EdgeNotchShape`: rechte Kante gerade am Bildschirmrand. Oben und unten je
eine S-Kurve, die über 96 pt vom Rand nach innen läuft, dazwischen eine
senkrechte Gerade. Beide Kontrollpunkte liegen auf halber Kurvenlänge, damit
die Kurve weich wie in der Vorlage ausläuft. Die Form ist `nonisolated`, weil
SwiftUI sie außerhalb des Hauptthreads zeichnet.

## Farben

| Teil | Hell | Dunkel | Ort |
|---|---|---|---|
| Kerbe | `#FFFFFF` | `#0A0B0D` | `Palette.edgePicker` |
| Aktive Pille | `#4D72AD` | `#A9C9FF` | `Palette.level`, wie Erstellen-Button |
| Symbol und Text in der Pille | `#FFFFFF` | `#101418` | `Palette.onLevel` |
| Inaktive Symbole | Vordergrund | Vordergrund | `Palette.onSurface` |

**Kein Liquid Glass** an der Kerbe. Fester Hintergrund, damit Gesten
zuverlässig ankommen und die Form klar bleibt.

## Bedienung

- **Tippen** auf ein Symbol wählt den nächstgelegenen Platz.
- **Ziehen** ab 8 pt: Pille wächst auf 96 pt und zeigt den Namen der Ansicht
  senkrecht. Die Liste rutscht durch die Kerbe und rastet beim Loslassen ein.
- Das Symbol unter der Pille ist ausgeblendet, damit es nicht durchscheint.
- Die Geste hängt mit Vorrang an der Kerbe, damit Scrollen sie nicht schluckt.
- VoiceOver: einstellbares Element, hoch und runter wechselt die Ansicht.
- Animation: `Motion.dock` für Picker, `Motion.page` für Ansichtswechsel.

## Bottom-Zeile je Kategorie

Nur in der Detail-, Text- und Verknüpfungen-Ansicht, nicht im Cover
(`EntryBottomBar`). Vorbild ist die Leiste von Safari in iOS 26 (Maße auf
einem 402 pt breiten iPhone abgemessen, siehe Maßtabelle). Hauptknopf ist
**„Schließen“** (`create_close`): Liquid-Glas-Kapsel
(`glassEffect(.regular.interactive(), in: Capsule())`, Text in der
Akzentfarbe), DM Sans 17 semibold, ohne Symbol, 48 pt hoch, füllt die Breite
zwischen den runden Knöpfen (34 pt Außenabstand, `entryBarInset`).
Zeilenhöhe 48 pt (`entryBarHeight`). Die Höhe über dem Bildschirmrand folgt
derselben Regel wie die Tab-Leiste (Stand 2026-10-29): `EntryBottomBar` setzt
`.padding(.bottom, router.tabBarLift)` (`TabBarLayout.lift`). Mit
Home-Indikator taucht die Zeile 12 pt in den sicheren Bereich, die Unterkante
liegt 22 pt über dem Bildschirmrand; ohne Home-Indikator (iPhone SE) bleiben
8 pt Abstand. Er schließt das ganze Deckblatt (`Router.closeDetail`).
Kategorieabhängige Textaktionen gibt es nicht; Status und Text erreicht man
über Hauptknöpfe und Container im Canvas, Lernen und Import über den
Icon-Knopf.

Hat der Eintrag etwas zu öffnen, abzuspielen oder zu lernen, steht rechts
außen ein runder Glas-Knopf nur mit Symbol (48 pt, `entryBarCircle`,
`glassEffect` im Kreis, Symbol `Palette.onSurface`, 8 pt Abstand,
`entryBarGap`).

Links steht derselbe runde Knopf als **Zurück** (`AppIcons.canvasReturn`,
Bedienungshilfe `back`), nach einer Regel (`EntryPage.backAction`):

1. In der Text- oder Verknüpfungen-Ansicht schließt er die Tastatur und
   wechselt in die Detail-Ansicht (`canvas = .actions`, `Motion.page`).
2. In der Detail-Ansicht eines verschachtelten Eintrags (aus einer
   Detailseite geöffnet, liegt in `Router.detailPath`, `EntryPage(nested:)`
   über `RouteDestinations`) geht er eine Ebene zurück
   (`detailPath.removeLast()`, wie die Wischgeste).
3. Sonst gibt es ihn nicht: der erste Eintrag des Deckblatts hat in der
   Detail-Ansicht nur „Schließen“ (und rechts ggf. das Icon).

Reihenfolge: Zurück, Schließen, Icon.

**Einklappen beim Scrollen** (wie Safari): Wird der Canvas nach unten
gescrollt (Inhalt wandert nach oben) und wächst der Scroll-Stand seit dem
letzten Richtungswechsel um 24 pt (`entryBarCollapseScroll`), schrumpft die
Zeile zu einer kleinen Glas-Kapsel in der Mitte (mindestens 133 × 32 pt,
DM Sans 15 semibold, 20 pt Innenabstand), die nur „Schließen“ zeigt und
auf allen Geräten mit der Unterkante 14 pt über dem Bildschirmrand landet
(`entryBarPillRest`, Safari-Maß). Wie weit sie dafür absinkt, rechnet
`TabBarLayout.pillDrop` aus sicherem Bereich, `tabBarLift`, Zeilen- und
Kapselhöhe (`Router.entryPillDrop`): mit Home-Indikator 16 pt, auf dem SE 2 pt.
Die Unterkante der Zeile zählt dabei höchstens 22 pt über dem Rand
(`TabBarDimens.clearance`), damit ein ungewöhnlich großer sicherer Bereich die
Kapsel nicht weiter absenkt; der Wert ist nie negativ. Zurück und Icon blenden mit Deckkraft und Skalierung auf
0,6 aus (`Motion.dock`, bei „Bewegung reduzieren“ nur Deckkraft, ohne
Animation). Zurück nach oben um dieselben 24 pt oder Scroll-Stand 0 klappt
sie wieder aus. Das Nachfedern am unteren Ende zählt nicht (Stand wird auf
das Scroll-Ende begrenzt). Ein Tipp auf die kleine Kapsel schließt wie der
große Knopf. Beim Öffnen, beim Wechsel der Ansicht und nach dem Schließen
der Tastatur ist sie ausgeklappt. Bei offener Tastatur steht wie bisher die
Tastaturleiste statt der Bottom-Zeile. Die Zeilenhöhe bleibt in beiden
Zuständen 48 pt, damit sich der Inhalt nicht verschiebt. Logik in
`BarCollapse` (ParalistCore, Tests `BarCollapseTests`).

```
Erster Eintrag, Detail:    [          Schließen         ] (▶)
Verschachtelt / Text:  (‹) [        Schließen       ] (▶)
Eingeklappt:                      ( Schließen )
```

| Fall | Icon-Knopf rechts | Wirkung | Bedienungshilfe |
|---|---|---|---|
| Kartendeck ohne Karten | `square.and.arrow.down` (`AppIcons.importCards`) | öffnet „Karten importieren“ für dieses Deck | `fc_import` |
| Kartendeck mit Karten | `graduationcap` (`AppIcons.study`) | Lernrunde des Decks | `fc_study` |
| Karteikarte in einem vorhandenen Deck | `graduationcap` (`AppIcons.study`) | Lernrunde des Decks | `fc_study` |
| Spotify-Link | `play.fill` / `pause.fill` | spielt im Spotify-Player im Cover-Bereich | `entry_audio_play` / `entry_audio_pause` |
| YouTube-Link | `play.fill` / `pause.fill` | spielt im Cover-Bereich der Detailseite | `entry_video_play` / `entry_video_pause` |
| Lesezeichen sonst mit URL | `arrow.up.right` (`AppIcons.openArrow`) | öffnet den Link | `entry_link_open_web` |
| Anhang Video | `play.fill` / `pause.fill` | spielt im Cover-Bereich, kein Wechsel ins Cover | `entry_video_play` / `entry_video_pause` |
| Anhang sonst ohne Bild (PDF, Text, Audio usw.) | `doc.text.magnifyingglass` (`AppIcons.openFile`) | Quick Look | `entry_file_open` |
| Anhang Bild | keiner (Tipp aufs Bild führt ins Cover) | | |
| alle anderen, auch Arbeitsbereich | keiner, nur „Schließen“ | | |

Im Cover-Bereich der Aktionen-Ansicht zeigt ein Video das erste Bild ohne
Steuerung mit dem runden Play-Knopf darüber. Ein Tipp aufs Video oder den
Knopf spielt es direkt dort ab bzw. pausiert; während es läuft, ist der Knopf
ausgeblendet. Ein Tipp aufs Bild wechselt ins Cover.

In der Cover-Ansicht gibt es keine Bottom-Zeile.

## Dateien

| Datei | Aufgabe |
|---|---|
| `Paralist/Entry/EntryPage.swift` | Zustand `cover`, Zieh- und Tipp-Geste, Picker-Regeln hinter `EdgePicker.shownOnDetail`, Bottom-Zeile einhängen, `barCollapsed` (`BarCollapse`), Zurück-Regel `backAction`, `nested` |
| `Paralist/Entry/EntryCanvasPanel.swift` | ScrollView mit Canvas (Infozeile, Titel, Optionen, Text, Verknüpfungen) |
| `Paralist/Entry/EntryActionBar.swift`, `EntryMoreMenu.swift` | Aktionsleiste der geteilten Ansicht, Pille Cover/Detail, Favoriten-Knopf und Drei-Punkte-Menü |
| `Paralist/Entry/EntryToolbar.swift` | Kopfzeile und Bottom-Zeile (Zurück, „Schließen“, Icon-Knopf; aus- und eingeklappt) |
| `Paralist/Theme/EntryBarDimens.swift` | Maße der Bottom-Zeile nach Safari (`entryBarInset`, `entryBarGap`, `entryBarCircle`, `entryBarPill*` mit `entryBarPillRest`, `entryBarCollapseScroll`) |
| `ParalistCore/.../Library/TabBarLayout.swift` | `lift` (Höhe der Bottom-Zeile wie Tab-Leiste) und `pillDrop` (Absenken der Kapsel), Tests `TabBarLayoutTests` |
| `ParalistCore/.../Library/BarCollapse.swift` | Wann die Bottom-Zeile ein- und ausklappt (Tests `BarCollapseTests`) |
| `Paralist/Theme/CanvasOpenDimens.swift` | Lage des Pfeil-Knopfs im Container (`canvasOpenEdge`, `canvasOpenShift`), `entryTextViewMin` |
| `Paralist/Entry/EntryHero.swift` | Medienwahl, legt Bühne, Canvas und Motiv übereinander |
| `Paralist/Entry/CoverStage.swift` | Bühne: Verlauf, Schwarz, oberer Fade, Titelzeile; `CoverMedia` |
| `Paralist/Entry/CoverMotifLayer.swift` | Motiv über dem Canvas, Player, Einbettungen, Hinweis-Knopf |
| `Paralist/Entry/CoverChrome.swift` | Titelzeile des Covers mit Fade, Play/Pause, Checkbox |
| `Paralist/Entry/CoverVideo.swift` | Einziger Videoplayer der App und Play/Pause-Knopf |
| `Paralist/Entry/EdgePicker.swift` | Kerbenform, Pille, Gesten (auf der Detailseite derzeit nicht eingehängt) |
| `Paralist/Entry/EntryCover.swift` | `CoverTitleVeil`, `CanvasSheet`, Emblem, Logo, Hinweis-Knopf |
| `Paralist/Pages/MediaPage.swift` | Medien-Seite, öffnet Einträge im Cover |
| `Paralist/Entry/EntryBodyEditor.swift` | Texteditor der Text-Ansicht und im Text-Container (`inCard`) |
| `Paralist/Entry/EntryMetaRow.swift` | Infozeile mit „mehr“ |
| `Paralist/Entry/EntryInfoSheet.swift` | Info-Blatt mit Kacheln und Details |
| `Paralist/Entry/CanvasCard.swift` | Container-Stil im Canvas |
| `ParalistCore/.../Library/EntryFacts.swift` | Wörter, Art des Anhangs, „geändert“ |
| `Paralist/Entry/EntryPickers.swift` | `CanvasPicker`, `PlaceRow` (Liste, Datum, Uhrzeit) |
| `Paralist/Entry/LinkSheet.swift` | `LinkPickerSheet`, `EntryPlaceSheet` (Auswahl mit Reitern) |
| `Paralist/Entry/EntryActions.swift` | Hauptknöpfe, Container-Kopf mit Pfeil, Text-Schalter |
| `ParalistCore/.../Library/EntryParent.swift` | Wer welche übergeordnete Liste wählen darf, Uhrzeit `faellig_zeit` |
| `Paralist/Entry/EntryBlocks.swift` | Text- und Verknüpfungen-Container, Menü „Neuer Eintrag“/„Verknüpfen“, Knopf-Rahmen, `saveCreated` |
| `Paralist/Shell/CreateOverlay.swift`, `Shell/AppSheets.swift` | Erstellen-Panel und Sheets, auch über dem Deckblatt |
| `ParalistCore/.../Library/CoverTransition.swift` | Band, Canvas-Offset, Motiv-Rechtecke, Chrome-Deckkräfte, Fortschritt, Einrasten |
| `ParalistCore/.../Library/EdgePicker.swift` | `EntryCanvas`, Schalter `shownOnDetail`, Raster, Einrast-Logik |
| `ParalistCore/Tests/.../CoverTransitionTests.swift` | Tests der Übergangs-Geometrie |
| `ParalistCore/Tests/.../EdgePickerTests.swift` | Tests der Raster- und Einrast-Logik |

## Offene Punkte

- Edge Picker später neu in die Detailseite integrieren, passend zum Umbau
  nach Spotify-Logik (Schalter `EdgePicker.shownOnDetail`).
- Bearbeiten im Text-Container setzt den Cursor ans Ende, nicht an die
  getippte Stelle (der Container zeigt gerendertes Markdown).
- Wischen auf Spotify- und YouTube-Flächen scrollt den Canvas nicht und zieht
  nicht ins Cover, weil der WebView die Geste nimmt.
- Im Schwarz-Modus sind die Fades weiter aus `surfaceContainer`, hell also
  hellgrau über Schwarz.
- Aktionen für Notiz und Termin festlegen.
- Wischgeste zwischen Aktionen und Text.
- Gegenstück in `paralist-android` fehlt noch.

