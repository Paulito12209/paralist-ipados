<!-- Zusammenhang: ParalistWidgets/ParalistWidgetsBundle.swift, ParalistWidgets/EntryWidget.swift, ParalistWidgets/PickEntryIntent.swift, Paralist/Intents/EntryEntity.swift, ParalistWidgets/EntryProvider.swift, ParalistWidgets/EntryWidgetView.swift, Paralist/Entry/CoverArtwork.swift, ParalistWidgets/Info.plist, ParalistWidgets/ParalistWidgets.entitlements, ParalistCore/Sources/ParalistCore/Library/WidgetPicks.swift, ParalistCore/Sources/ParalistCore/Links/IncomingLink.swift, Paralist/App/ParalistApp.swift, Paralist/Theme/Dimens.swift (WidgetDimens), project.yml, tools/deploy_ipad.sh -->

# Widget „Schnellzugriff“

Stand: 2026-10-21.

## Ziel

Ein Widget für Home- und Sperrbildschirm öffnet genau einen Eintrag
(Arbeitsbereich, Projekt, Aufgabe, Dokument, Lesezeichen, Notiz, Termin,
Datei, Kartendeck). Jedes Widget hat sein eigenes Ziel, mehrere nebeneinander
sind möglich. Ein Tipp öffnet die Detailseite, auch wenn die App beendet ist.

## Bedienung

1. Widget hinzufügen (Paralist → „Schnellzugriff“).
2. Gedrückt halten → „Widget bearbeiten“ → Parameter „Eintrag“.
3. Liste mit Suche nach Titel. Reihenfolge: Arbeitsbereiche, Projekte, dann
   alles andere. In jeder Gruppe Markierte (angeheftet oder Favorit) zuerst,
   sonst zuletzt geändert. Höchstens 50 Treffer. Karteikarten und
   Archiviertes sind nicht wählbar. Die Suche ignoriert Groß/Klein und
   Akzente und trimmt Leerzeichen.

## Darstellung

Home-Bildschirm (klein und mittel) im Stil der Cover-Ansicht:

```
┌──────────────────┐
│   Cover-Verlauf  │  Verlauf (CoverArtwork) über die volle Höhe
│      [Emblem]    │  Emblem in Typfarbe, Mitte der oberen 4/7 plus 1/8 der Höhe
│                  │
│░░░░░░░░░░░░░░░░░░│  weicher Schleier über den unteren 3/7
│ Projekt          │  Typname klein, dezent
│ Umzug nach …     │  Titel größer, 1 Zeile mit „…“
│ 3 Verknüpfungen  │  Zusatzzeile nur in Mittel
└──────────────────┘
```

Der Schleier ist im Hellen weiß und im Dunkeln dunkel (`Palette.surface`).
Die Schrift folgt dem Kontrast: `onSurface` für den Titel,
`onSurfaceVariant` für Typname und Zusatzzeile.

| Größe | Inhalt |
|---|---|
| systemSmall | Verlauf, Emblem, Typname und Titel (1 Zeile) |
| systemMedium | wie klein, dazu die Zusatzzeile |
| accessoryRectangular | Symbol und Typname, darunter Titel (1 Zeile) |
| accessoryCircular | Hintergrund und Symbol |
| accessoryInline | nur Titel |

Zusatzzeile (Medium): Arbeitsbereich/Projekt → „n Verknüpfungen“ (nicht archivierte
Einträge darin, `widget_links_count`); Aufgabe → Status · Fälligkeit; Termin → Beginn oder
Fälligkeit; Lesezeichen → Domain; sonst Vorschau, wenn vorhanden.

Farbe aus `TypeLook.of(entry)`, Symbol und Typname aus
`TypeLook.of(entry.type)`. Emblem und Typname sind `widgetAccentable`.
Verlauf und Schleier liegen im `containerBackground`; in getönter oder
klarer Darstellung blendet iOS sie aus. Auf dem Sperrbildschirm gibt es
keine Farben. Leerer Titel → „Ohne Titel“. Maße in `WidgetDimens`.

Zustände: nichts gewählt → `widget_empty`; Eintrag gelöscht, archiviert oder
Karteikarte → `widget_missing` (auch als Wert im Bearbeiten-Dialog). Galerie
und Platzhalter zeigen das Beispielprojekt `widget_sample` mit 12 Verknüpfungen.

## Aufbau

- Ziel `ParalistWidgets` (WidgetKit-Erweiterung, `app.paralist.ipad.widgets`,
  App-Gruppe `group.app.paralist.ipad`), in `Paralist` eingebettet. Nutzt Theme,
  Icons, `TypeLook`, `L`, `AppPaths`, Texte und Schrift der App mit.
- `PickEntryIntent.swift`: `PickEntryIntent` (Parameter `entry`).
- `Paralist/Intents/EntryEntity.swift` (App und Widget): `EntryEntity`,
  `EntryQuery` (Suche und Vorschläge über `WidgetPicks.candidates`),
  `EntryData` (Sprache, Einträge lesen). Siri nutzt dieselbe Entity, siehe
  `docs/siri.md`.
- `EntryProvider.swift`: liest über `EntryData.entries()`,
  Zeitleiste mit einem Eintrag, Policy `.never`. Sprache wie die App über
  `app_language`.
- `EntryWidgetView.swift`: Ansichten je Größe, `widgetURL` mit
  `IncomingLink.entryURL(id)` → `paralist-ipad://eintrag/<id>`; die App öffnet
  das über `IncomingLinks.handle`.
- Aktualisierung: Die App ruft beim Wechsel in den Hintergrund
  `WidgetCenter.shared.reloadAllTimelines()`.
- Logik im Kern: `Library/WidgetPicks.swift` mit Tests in
  `WidgetPicksTests.swift`.
- Signierung: `tools/deploy_ipad.sh` meldet sich wie `tools/testflight.sh`
  mit dem lokalen API-Schlüssel an. Die App-ID `app.paralist.ipad.widgets` braucht
  die Fähigkeit App Groups mit `group.app.paralist.ipad`.

## Prüfliste

- [ ] Widget klein und mittel auf dem Home-Bildschirm hinzufügen
- [ ] „Widget bearbeiten“ → Eintrag wählen, Suche (Groß/Klein, Akzente)
- [ ] Reihenfolge und Grenzen der Liste (keine Karteikarten, kein Archiv)
- [ ] Tipp öffnet die Detailseite, auch bei beendeter App
- [ ] Zwei Widgets mit verschiedenen Zielen
- [ ] Hell und Dunkel, getönte Darstellung
- [ ] Sperrbildschirm: rechteckig, rund, Zeile
- [ ] Eintrag löschen → Hinweis „nicht mehr da“

## Stand

Gebaut, Kern-Tests grün. Im Simulator geprüft: Galerie, Auswahlliste, mittleres Widget hell und dunkel, Tipp öffnet die Detailseite aus beendetem Zustand. Gerätetest steht aus (Signierung).
