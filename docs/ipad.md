<!-- Zusammenhang: Paralist/Shell/SplitRootView.swift, Paralist/Shell/SplitTopBar.swift, Paralist/Shell/SplitPanes.swift, Paralist/Shell/SplitParts.swift, Paralist/Shell/CategoryPanel.swift, Paralist/Shell/RootView.swift, Paralist/Shell/Router.swift, Paralist/Shell/RouterSplit.swift, Paralist/Shell/DetailHost.swift, Paralist/Shell/MenuDrawer.swift, Paralist/Shell/AppSheets.swift, Paralist/Shell/CreateOverlay.swift, Paralist/Shell/RouteDestination.swift, Paralist/Theme/SplitDimens.swift, Paralist/Theme/CategoryDimens.swift, Paralist/Theme/Palette.swift, Paralist/App/LaunchOptions.swift, ParalistCore/Sources/ParalistCore/Library/SplitLayout.swift, ParalistCore/Tests/ParalistCoreTests/SplitLayoutTests.swift, docs/detailseite.md -->

# iPad: geteilte Ansicht

Auf dem iPad zeigt Paralist ein eigenes Layout nach Art von Spotify und App
Store: oben eine schwebende Leiste, darunter zwei abgerundete Container,
links die Reiterseite, rechts die Detailseite. Kein `TabView`, kein
`NavigationSplitView`, keine Systemleiste.

## Breitenregel

`SplitLayout.listWidth` (ParalistCore) liefert die Breite der Liste oder
`nil`:

- Liste = max(320 pt, Fensterbreite / 3), Detail = Rest.
- Wäre das Detail schmaler als 440 pt (schmale Stage-Manager-Fenster, Slide
  Over), gibt die Funktion `nil` zurück und die App zeigt das iPhone-Layout
  unverändert (`RootView.phone`).
- Gerechnet wird mit der Breite ohne Ränder (`SplitDimens.margin`, `gap`).
- Die Werte 320 und 440 stehen in `Theme/SplitDimens.swift`.
- `RootView` misst die Fensterbreite und setzt `router.split`. Nur auf dem iPad
  (`userInterfaceIdiom == .pad`); auf dem iPhone bleibt `split` immer `false`.
- Beim Wechsel zwischen den Layouts bleiben `router.detail` und
  `router.detailPath` erhalten: Das Deckblatt wechselt zwischen Vollbild
  und rechter Spalte.

## Aufbau

- Fensterhintergrund `Palette.window` (etwas dunkler als `background`, im
  Dunkelmodus Schwarz) läuft unter die Statusleiste; die Container heben sich
  davon ab. Die Statusleiste folgt Hell/Dunkel.
- Obere Zeile (`SplitTopBar`, Höhe `SplitDimens.topBar`): links runder
  Glas-Knopf Menü (`XoolMenu`, `router.openMenu`), mittig eine Liquid-Glass-
  Pille mit den sichtbaren Reitern (`tabOrder`) und der Lupe
  (`router.searchOpen`), aktiver Reiter mit Fläche wie im App Store. Passt die
  Pille mit Namen nicht, zeigt sie nur Icons (`ViewThatFits`). Rechts runder
  Glas-Knopf `sidebar.right`: blendet im rechten Container das
  `CategoryPanel` ein (`router.panelOpen`); ist ein Eintrag offen, schließt er
  ihn und zeigt die Kacheln.
- Container (`splitPane`, Radius `SplitDimens.radius`, Abstand `gap`): links
  `SplitListPane` mit denselben `TabStacks` wie auf dem iPhone (je Reiter ein
  `NavigationStack` mit `sectionChrome` und `routeDestinations`,
  `SectionHeader` mit Statistik, Suche, Konto, Systemleiste aus). Unten rechts
  der runde Glas-„+“ (`XoolPlus`, `router.openCreate`), im Reiter Medien die
  `MediaBar` darüber. `tabBarFloor` und `tabBarReserve` liefern
  `SplitDimens.floor`, damit Listen unter dem Plus enden.
- Rechts: `SplitPanes` (Detail), `CategoryPanel` oder `SplitPlaceholder`.
- Breites Detail: Knopf `sidebar.left` in der Kopfzeile des Details
  (`WideToggle`, `router.detailWide`). Dann entfällt die obere Zeile, links
  steht die Icon-Leiste `SplitRail` (Breite `SplitDimens.rail`): Menü oben,
  Reiter-Icons senkrecht, Suche, Plus unten. Ein Reiter-Icon stellt das
  normale Layout her und wählt den Reiter (`leaveRail`).
- Zwei Detailseiten: `router.push` aus einer Detailseite setzt
  `router.second`. Die Reiterseite schrumpft zur Icon-Leiste, die erste
  Detailseite steht links, die verknüpfte rechts, beide als Container.
  Dazwischen ein verschiebbarer Trenner (`SplitDimens.divider`), Anteil in
  `router.paneShare` (Start 0,5), jede Seite mindestens `minPane` (320 pt);
  Rechnung in `SplitLayout.panes`/`drag`. Das ✕ der zweiten Seite
  (`closeSecond`) stellt das normale Layout her; weitere Pushes ersetzen die
  zweite Seite.
- Menü-Schublade (`menuDrawer`) kommt wie auf dem iPhone von links über die
  volle Höhe, ohne runde Ecken am Inhalt. `appSheets`, `CreateOverlay` und
  `NoticeBar` hängen am ganzen Fenster; das Erstellen-Blatt ist auf
  `SplitDimens.createWidth` begrenzt.

## Navigation

| Aufruf | Verhalten in der geteilten Ansicht |
|---|---|
| `router.open(route)` | Ersetzt das Detail (`detail = route`, `detailPath = []`) für `.entry`, `.cover`, `.chat`, `.study`; alles andere (Listen, Einstellungen, Papierkorb …) geht auf den Stapel des Reiters links |
| `router.push(route)` | Öffnet `.entry`, `.cover`, `.chat`, `.study` als zweite Detailseite (`second`), wenn ein Detail offen ist; sonst wie `open` |
| `router.openMedia(id, among:)` | Wie `open(.cover)`, mit Medienliste für das Blättern |
| `router.closeDetail()` | Leert den rechten Container samt zweiter Seite, Platzhalter erscheint |
| `router.closeSecond()` | Schließt nur die zweite Detailseite |

`push` benutzen Aufrufstellen innerhalb der Detailseite: Verknüpfungen und
Chats in `Entry/EntryBlocks.swift`, Karten in `Flashcards/DeckSection.swift`,
Erwähnungen in `Chat/ChatThreadParts.swift`, „Lernen“ in
`Entry/EntryToolbar.swift`. Alles, was links, in der Suche, im Briefing, in
Benachrichtigungen, Siri oder URLs passiert, benutzt `open` und ersetzt das
Detail. Auf dem iPhone verhalten sich beide wie bisher (`open` hängt bei
offenem Deckblatt an `detailPath`).

- Chatliste links, Thread rechts; die Lern-Sitzung läuft rechts. Beide
  Wurzeln im rechten Container haben links oben einen Schließen-Pfeil
  (`DetailRootClose`, auf der zweiten Seite ✕); Löschen eines Threads und
  „Fertig“ im Lernen leeren den Container bzw. schließen die zweite Seite
  (`router.leave`).
- Das Wisch-nach-unten-Schließen und der Versatz des Deckblatts (`detailDrop`)
  gibt es rechts nicht. Schließen über „Schließen“ in der Bottom-Zeile.
  Zurück in verschachtelten Ebenen und Blättern der Medien bleiben.
- Suche, Composer, Briefing, Konto und Import bleiben Sheets bzw. Overlays
  über dem ganzen Fenster; was sie öffnen, landet rechts.

## Bedienung prüfen

Startargumente (nur Demo): `-demo -screen split|pair|wide|panel -orientation landscape`
(`portrait` ebenso). `-orientation` fordert die Ausrichtung über
`UIWindowScene.requestGeometryUpdate` an und zeigt den Bildschirm eine
Sekunde später. Weitere Bildschirme (`chat`, `deck`, `entry` …) landen im
iPad-Layout rechts.

`pair` öffnet zwei Detailseiten nebeneinander, `wide` ein Detail auf voller
Breite, `panel` die Kacheln rechts.
