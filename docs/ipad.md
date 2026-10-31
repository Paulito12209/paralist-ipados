<!-- Zusammenhang: Paralist/Shell/SplitRootView.swift, Paralist/Shell/SplitTopBar.swift, Paralist/Theme/SplitBarDimens.swift, Paralist/Pages/OverviewOptionParts.swift, ParalistCore/Sources/ParalistCore/Library/OverviewInline.swift, Paralist/Shell/SplitParts.swift (SplitExpandButton, SplitHandle), Paralist/Entry/EntryToolbar.swift, Paralist/Shell/CategoryPanel.swift, Paralist/Shell/RootView.swift, Paralist/Shell/Router.swift, Paralist/Shell/RouterSplit.swift, Paralist/Shell/DetailHost.swift, Paralist/Pages/MenuPage.swift, Paralist/Shell/AppSheets.swift, Paralist/Shell/CreateOverlay.swift, Paralist/Shell/RouteDestination.swift, Paralist/Theme/SplitDimens.swift, Paralist/Theme/CategoryDimens.swift, Paralist/Theme/Palette.swift, Paralist/App/ParalistApp.swift, Paralist/App/LaunchOptions.swift, ParalistCore/Sources/ParalistCore/Library/SplitLayout.swift, ParalistCore/Sources/ParalistCore/Library/TabBarOrder.swift, ParalistCore/Tests/ParalistCoreTests/SplitLayoutTests.swift, docs/detailseite.md -->

# iPad: geteilte Ansicht

Auf dem iPad zeigt Paralist ein eigenes Layout aus zwei abgerundeten
Containern: links der Hauptcontainer mit den Reiterseiten (2/3), rechts die
Seite (1/3) mit Kategorien, Sammlungen und Einträgen. Kein `TabView`, kein
`NavigationSplitView`, keine Systemleiste. Es sind nie mehr als zwei Bereiche
zu sehen: Hauptcontainer und rechte Seite, Menü und Hauptcontainer, eine
erweiterte Detailseite allein oder Detailseite und verknüpfte Seite.

## Breitenregel

`SplitLayout.sideWidth` (ParalistCore) liefert die Breite der rechten Seite
oder `nil`:

- Seite = max(320 pt, Breite / 3), Hauptcontainer = Rest.
- Wäre der Hauptcontainer schmaler als 440 pt (schmale Stage-Manager-Fenster,
  Slide Over), gibt die Funktion `nil` zurück und die App zeigt das
  iPhone-Layout unverändert (`RootView.phone`).
- Das Menü-Panel ist `SplitLayout.panelWidth` breit: ein Drittel des
  Fensters, mindestens 320 pt.
- Zwischen zwei Containern sitzt ein senkrechter Ziehgriff (`SplitHandle`).
  Er verschiebt die Grenze; `SplitLayout.leadingWidth` hält links mindestens
  `SplitLayout.mainMinimum` (ein Drittel, mindestens 320 pt) für den
  Hauptcontainer bzw. 320 pt für die Detailseite und rechts 320 pt. Start
  ist 2/3 zu 1/3, bei Detail und Verknüpfung 50/50. Die Breite gilt, solange
  die App läuft.
- Die Container enden 16 pt über dem unteren Geräterand (`SplitDimens.bottom`,
  ohne zusätzlichen Sicherheitsabstand).
- Die Werte stehen in `Theme/SplitDimens.swift`.
- `RootView` misst die Fensterbreite und setzt `router.split`. Nur auf dem iPad
  (`userInterfaceIdiom == .pad`); auf dem iPhone bleibt `split` immer `false`.

## Aufbau

- Fensterhintergrund `Palette.window` (etwas dunkler als `background`, im
  Dunkelmodus Schwarz) läuft unter die Statusleiste.
- Hauptcontainer (`SplitMain`): oben die Leiste `SplitTopBar` im Container,
  links runder Glas-Knopf Menü (`XoolMenu`, `router.toggleMenu`), mittig eine
  Liquid-Glass-Pille mit den Reitern als Text (ohne Icons) und der Lupe,
  rechts runder Glas-Knopf `sidebar.right` (`router.toggleSide`) für die
  rechte Seite. Der aktive Reiter hat eine silberblaue Fläche
  (`Palette.padTabActive`).
  Die Pille bekommt nur den Platz zwischen den beiden Knöpfen
  (`ViewThatFits`): Reiternamen, wenn sie passen, sonst Icons (aktiver
  gefüllt), bei ganz wenig Platz Icons in einer waagrechten Scrollfläche.
  Die Knöpfe werden nie überdeckt oder abgeschnitten.
- Übersicht: Ist der Hauptcontainer mindestens halb so breit wie das Fenster
  (`OverviewInline.showsOptions`), stehen die drei Edge-Picker-Optionen als
  schlichte Icons links neben dem Plus der Sortierzeile und der Edge Picker
  am Rand entfällt; schmaler bleibt der Edge Picker wie auf dem iPhone.
- Reiter in der Pille: Übersicht, Aufgaben, Kalender fest, dahinter weitere
  Reiter aus `tabOrder` (`TabBarOrder.padTabs`, `AppTab.pad`). `router.shows`
  richtet sich in der geteilten Ansicht nach dieser Liste.
- Darunter dieselben `TabStacks` wie auf dem iPhone, ohne `SectionHeader`
  (Suche sitzt in der Pille, das Konto im Menü-Kopf) und ohne Verlauf unter
  der Statusleiste. Unten rechts der runde Glas-„+“ (`router.openCreate`), im
  Reiter Medien die `MediaBar` darüber. `tabBarFloor` und `tabBarReserve`
  liefern `SplitDimens.floor`.
- Rechte Seite (`SplitSide`, `router.sideOpen`, beim Start offen): ohne
  offenen Eintrag ein `NavigationStack` auf `router.sidePath` mit dem
  `CategoryPanel` („Kategorien“) als Wurzel; mit Eintrag `DetailHost(inline:
  true)`.
- Menü: Der Menü-Knopf schiebt das Menü-Panel (`MenuPage`) von links herein,
  über die volle Höhe ohne runde Ecken. Der Hauptcontainer rückt nach rechts
  und nimmt die restliche Breite, die rechte Seite klappt solange zu.
- `appSheets`, `CreateOverlay` und `NoticeBar` hängen am ganzen Fenster; das
  Erstellen-Blatt ist auf `SplitDimens.createWidth` begrenzt.

## Navigation

| Aufruf | Verhalten in der geteilten Ansicht |
|---|---|
| `router.open(route)` | Reiter aus der Pille wählen den Reiter. `.entry`, `.cover`, `.chat`, `.study` öffnen rechts als Detail. Alles andere (Sammlungen, Einstellungen, Papierkorb, nicht gezeigte Reiter …) ersetzt den Stapel rechts (`sidePath = [route]`). In jedem Fall schließt das Menü und die rechte Seite geht auf |
| `router.push(route, from: pane)` | Aus einer Detailseite heraus öffnen `.entry`, `.cover`, `.chat`, `.study` als verknüpfte Seite (`router.linked`): der Hauptcontainer klappt zu, die Detailseite steht links, die Verknüpfung rechts. Aus der linken Seite ersetzt ein weiterer Link die rechte; aus der rechten rückt die rechte nach links und der Link öffnet rechts. Andere Routen schieben im jeweiligen Container (`detailPath` bzw. `linkedPath`) |
| `router.toggleExpanded(pane)` | Knopf oben rechts in der Detailseite (`SplitExpandButton`): Detail füllt die ganze Breite (`router.expanded`), nochmal tippen holt den Hauptcontainer zurück. Bei zwei Detailseiten klappt die andere zu und wird geparkt (`router.parked`); nochmal tippen stellt das Paar wieder her |
| `router.toggleDetailSide(pane)` | Seitenleisten-Knopf oben rechts in der Detailseite (`SplitSideButton`): Hauptcontainer klappt zu, die Detailseite steht links, rechts das Kategorien-Panel (`router.detailSide`, `SplitCategories`). Nochmal tippen: Detail allein in voller Breite. Bei zwei Detailseiten bleibt die gedrückte, die andere schließt. Aus dem Panel geöffnete Sammlungen ersetzen den Stapel rechts, Einträge öffnen als verknüpfte Seite |
| `router.closePane(pane)` | Schließen links: die verknüpfte Seite rückt nach links in die rechte Seite, der Hauptcontainer kommt zurück. Schließen rechts: die Detailseite bleibt erweitert. Ohne Verknüpfung wie `closeDetail` |
| `router.openMedia(id, among:)` | Wie `open(.cover)`, mit Medienliste für das Blättern |
| `router.closeDetail()` | Leert Detail und Verknüpfung, rechts erscheint wieder der Stapel mit den Kategorien |

- Chats und Lernen laufen rechts. Ihre Wurzel hat links oben einen
  Schließen-Pfeil (`DetailRootClose`); Löschen eines Threads und „Fertig“ im
  Lernen schließen ihren Container (`router.leave`).
- Welcher Container einen Link auslöst, steht in `\.detailPane`
  (`DetailHost(pane:)`).
- Das Wisch-nach-unten-Schließen und der Versatz des Deckblatts (`detailDrop`)
  gibt es rechts nicht. Schließen über „Schließen“ in der Bottom-Zeile.
- Suche, Composer, Briefing, Konto und Import bleiben Sheets bzw. Overlays
  über dem ganzen Fenster; was sie öffnen, landet rechts.

## Bedienung prüfen

Startargumente (nur Demo): `-demo -screen overview|menu|split -orientation landscape`
(`portrait` ebenso). `-orientation` fordert die Ausrichtung über
`UIWindowScene.requestGeometryUpdate` an und zeigt den Bildschirm eine
Sekunde später. Weitere Bildschirme (`chat`, `deck`, `entry` …) landen im
iPad-Layout rechts.

