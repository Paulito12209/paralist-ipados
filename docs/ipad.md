<!-- Zusammenhang: Paralist/Shell/SplitRootView.swift, Paralist/Shell/SplitParts.swift, Paralist/Shell/SplitToolbar.swift, Paralist/Shell/RootView.swift, Paralist/Shell/Router.swift, Paralist/Shell/DetailHost.swift, Paralist/Shell/AppSheets.swift, Paralist/Shell/CreateOverlay.swift, Paralist/Shell/RouteDestination.swift, Paralist/Theme/SplitDimens.swift, Paralist/App/LaunchOptions.swift, ParalistCore/Sources/ParalistCore/Library/SplitLayout.swift, ParalistCore/Tests/ParalistCoreTests/SplitLayoutTests.swift, docs/detailseite.md -->

# iPad: geteilte Ansicht

Auf dem iPad zeigt Paralist links die Liste und rechts die Detailseite.
Darüber sitzt die native Reiterleiste von iPadOS 26 (Liquid Glass,
`TabView` mit `.sidebarAdaptable`), ein Reiter je sichtbarem `AppTab`
(Reihenfolge und Auswahl wie auf dem iPhone, `TabBarOrder`).

## Breitenregel

`SplitLayout.listWidth` (ParalistCore) liefert die Breite der Liste oder
`nil`:

- Liste = max(320 pt, Fensterbreite / 3), Detail = Rest.
- Wäre das Detail schmaler als 440 pt (schmale Stage-Manager-Fenster, Slide
  Over), gibt die Funktion `nil` zurück und die App zeigt das iPhone-Layout
  unverändert (`RootView.phone`).
- Die Werte 320 und 440 stehen in `Theme/SplitDimens.swift`.
- `RootView` misst die Fensterbreite und setzt `router.split`. Nur auf dem iPad
  (`userInterfaceIdiom == .pad`); auf dem iPhone bleibt `split` immer `false`.
- Beim Wechsel zwischen den Layouts bleiben `router.detail` und
  `router.detailPath` erhalten: Das Deckblatt wechselt zwischen Vollbild
  und rechter Spalte.

## Aufbau

- Pro Reiter ein `NavigationSplitView(columnVisibility:)` mit zwei Spalten
  (`.balanced`). Seitenleiste: `NavigationStack(path:)` der Liste mit
  `navigationSplitViewColumnWidth(listWidth)`; Detail: `DetailHost(inline: true)`
  oder der Platzhalter „Wähle links einen Eintrag aus“ (`ipad_detail_empty`),
  wenn `router.detail == nil`. Das System zeichnet Trennlinie und
  Seitenleisten-Knopf; wer die Liste ausblendet, bekommt das Detail in voller
  Breite. Der Zustand liegt in `router.columns` und bleibt beim Reiterwechsel.
- Die schwebende `AppTabBar` und die frühere Glas-Knopfzeile unten entfallen.
  Die Listen-Spalte zeigt eine native Navigationsleiste (`SplitToolbar`): links
  Menü, rechts Statistik, Suche, Konto und (durch einen festen Abstand getrennt)
  Erstellen. Im Reiter Medien steht davor ein Menü mit Foto, Video, Audio und
  Dateien (statt der `MediaBar`). Die `SectionHeader` im Seiteninhalt
  entfällt in der geteilten Ansicht (`!router.split`), der Seitentitel bleibt.
- `menuDrawer`, `appSheets`, `CreateOverlay` und `NoticeBar` hängen am ganzen
  Fenster. Das Erstellen-Blatt ist auf `SplitDimens.createWidth` begrenzt.
  Die `NoticeBar` sitzt unten mit `SplitDimens.margin` Abstand.
- `tabBarFloor` und `tabBarReserve` liefern in der geteilten Ansicht
  `SplitDimens.margin`, da unten keine eigene Leiste liegt.
- Die native Reiterleiste bleibt auf Unterseiten sichtbar
  (`hidesPhoneTabBar`).
- Die Suche öffnet über den Knopf in der Leiste (`router.searchOpen`), kein
  eigener Suchreiter.

## Navigation

| Aufruf | Verhalten in der geteilten Ansicht |
|---|---|
| `router.open(route)` | Ersetzt das Detail (`detail = route`, `detailPath = []`) für `.entry`, `.cover`, `.chat`, `.study`; alles andere (Listen, Einstellungen, Papierkorb …) geht auf den Stapel des Reiters links |
| `router.push(route)` | Schiebt auf `detailPath`, wenn ein Detail offen ist; sonst wie `open` |
| `router.openMedia(id, among:)` | Wie `open(.cover)`, mit Medienliste für das Blättern |
| `router.closeDetail()` | Leert die rechte Spalte, Platzhalter erscheint |

`push` benutzen Aufrufstellen innerhalb der Detailseite: Verknüpfungen und
Chats in `Entry/EntryBlocks.swift`, Karten in `Flashcards/DeckSection.swift`,
Erwähnungen in `Chat/ChatThreadParts.swift`, „Lernen“ in
`Entry/EntryToolbar.swift`. Alles, was links, in der Suche, im Briefing, in
Benachrichtigungen, Siri oder URLs passiert, benutzt `open` und ersetzt das
Detail. Auf dem iPhone verhalten sich beide wie bisher (`open` hängt bei
offenem Deckblatt an `detailPath`).

- Chatliste links, Thread rechts; die Lern-Sitzung läuft rechts. Beide
  Wurzeln in der rechten Spalte haben links oben einen Schließen-Pfeil
  (`DetailRootClose`); Löschen eines Threads und „Fertig“ im Lernen leeren
  die Spalte (`router.leave`).
- Das Wisch-nach-unten-Schließen und der Versatz des Deckblatts (`detailDrop`)
  gibt es rechts nicht. Schließen über „Schließen“ in der Bottom-Zeile.
  Zurück in verschachtelten Ebenen und Blättern der Medien bleiben.
- Suche, Composer, Briefing, Konto und Import bleiben Sheets bzw. Overlays
  über dem ganzen Fenster; was sie öffnen, landet rechts.

## Bedienung prüfen

Startargumente (nur Demo): `-demo -screen split -orientation landscape`
(`portrait` ebenso). `-orientation` fordert die Ausrichtung über
`UIWindowScene.requestGeometryUpdate` an und zeigt den Bildschirm eine
Sekunde später. Weitere Bildschirme (`chat`, `deck`, `entry` …) landen im
iPad-Layout rechts.
