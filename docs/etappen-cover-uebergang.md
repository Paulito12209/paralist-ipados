<!-- Zusammenhang: docs/detailseite.md, Paralist/Entry/EntryPage.swift, Paralist/Entry/CoverStage.swift, Paralist/Entry/EntryHero.swift, Paralist/Entry/EntryCover.swift, Paralist/Entry/EdgePicker.swift, Paralist/Shell/DetailHost.swift, Paralist/Theme/Dimens.swift (cover*, edge*, Motion), ParalistCore/Sources/ParalistCore/Library/EdgePicker.swift -->
# Etappen: Übergang Detail ↔ Cover, Bilder im Cover, Edge Picker

Plan vom 2026-10-22, am selben Tag in sechs Etappen umgesetzt. Stand danach:
`docs/cover.md` und `docs/detailseite.md`. Abweichungen vom Plan: Motiv
und Einbettungen liegen in einer eigenen Ebene über dem Canvas
(`CoverMotifLayer`), damit Spotify, YouTube und der Hinweis-Knopf tippbar
bleiben; Einbettungen stecken in einer deaktivierten ScrollView, weil ein
WKWebView direkt unter der Kopfzeile deren Bereich schwarz färbt; klappt man
den Picker selbst über einem Plus aus, bleibt er offen; die Schwellen für
Einrasten und Chrome liegen im Kern statt in `Dimens`; zwei Demo-Fotos und
`-screen photo` kamen dazu.

## Ziel

Die Detailseite soll sich wie der Vollbild-Player von Spotify anfühlen:

1. Detail- und Cover-Ansicht sind **eine** Seite. Zieht man die Detail-Ansicht
   oben über den Rand, rutscht der Canvas mit dem Finger nach unten, der
   Cover-Bereich wächst dabei zur Cover-Ansicht. Fällt der Canvas unten aus dem
   Bild, ist man im Cover. Von unten nach oben gewischt kommt der Canvas
   genauso wieder herauf. Beide Richtungen folgen dem Finger und rasten beim
   Loslassen ein.
2. Bilder sehen im Cover aus wie Videos: gleiche Bühne, gleicher
   Hintergrund, gleiche Kopf- und Titelzeile, gleicher Tipp zum Ein- und
   Ausblenden. Hochkant-Bilder stehen mittig mit gleichen Rändern.
3. Der Edge Picker ist beim Öffnen eingeklappt und zeigt sich nur, wenn er
   gebraucht wird. Er verdeckt nie das Plus eines Containers und steht in
   allen Ansichten an genau derselben Stelle; er bewegt sich nie senkrecht,
   nur waagerecht beim Ein- und Ausklappen.

## Stand heute (warum es ruckelt)

- `EntryPage.content` tauscht zwei getrennte Hierarchien: `coverStage` (voll)
  gegen `scroll` (ScrollView mit `EntryHero` als erstes Element), Übergang
  `.transition(.opacity)`. Nichts bewegt sich, es blendet nur um.
- Das Cover-Motiv wird zweimal gebaut (16:9-Band in `EntryCover`, Bühne in
  `CoverStage`), mit unterschiedlichen Größen, Hintergründen (Kategorieverlauf
  bzw. Silber/Schwarz) und Ankern. Dadurch springt das Bild beim Wechsel.
- Der Wechsel ins Cover löst beim Überziehen um 110 pt sofort aus
  (`coverPull`), ohne Vorschau, ohne Zurücknehmen.
- Der Picker startet ausgeklappt (`pickerTucked = false`) und liegt rechts
  unten genau dort, wo Plus-Knöpfe der Container stehen.
- Der Picker steht in Detail und Cover verschieden hoch: in Detail 24 pt über
  der Bottom-Zeile (52 pt), im Cover 24 pt über der Titelzeile (`coverRow`,
  mindestens 76 pt, mit jeder Titelzeile mehr). Er rutscht also beim Wechsel
  um 24 pt und mehr nach oben.

## Modell: ein Fortschritt `t`

Eine Zahl `t` in 0 … 1 beschreibt die Seite. `t = 0` ist die Detail-Ansicht,
`t = 1` das Cover. Alles dazwischen ist der Übergang, den der Finger oder
die Animation fährt.

```
                 t = 0                 t ≈ 0,5                t = 1
            ┌──────────┐           ┌──────────┐           ┌──────────┐
 Kopfzeile  │˅ Datei ♡⋯│           │˅ Datei ♡⋯│           │˅ Datei  ⋯│
            │░░┌────┐░░│           │░░░░░░░░░░│           │░░░░░░░░░░│
 Cover-     │░░│Bild│░░│           │░┌──────┐░│           │┌────────┐│
 Bereich    │░░└────┘░░│           │░│ Bild │░│           ││  Bild  ││
            ├──────────┤           │░└──────┘░│           │└────────┘│
            │Info      │           │░░░░░░░░░░│           │░░░░░░░░░░│
 Canvas     │Titel     │           ├──────────┤           │░░░░░░░░░░│
            │──────────│           │Info      │           │░░░░░░░░░░│
            │Optionen ▐│           │Titel     │           │▒▒▒▒▒▒▒▒▒▒│
            │  (×)[Voll│           │──────────│           │Titel    ▶│
            └──────────┘           └──────────┘           └──────────┘
            Picker: Rand            Picker, Bottom-Zeile    Titelzeile, Fade
            Bottom-Zeile da         ausgeblendet            Picker erst nach Tipp
```

Von rechts nach links gelesen ist es der Weg zurück (Wischen von unten nach
oben im Cover). Es gibt keinen zweiten Übergang, nur `t` in die andere
Richtung.

### Aufbau der Seite (eine Hierarchie)

```
ZStack
├─ CoverStage (t)            Hintergrund + Motiv, immer Vollbild, unterste Ebene
├─ EntryCanvasPanel (t)      ScrollView mit Canvas, oben durchsichtig bis
│                            bandBottom, als Ganzes um canvasOffset(t) nach unten
├─ Chrome Detail (t)         Bottom-Zeile, Edge Picker: Deckkraft fällt auf 0
└─ Chrome Cover (t)          Titelzeile, Fades, Play/Checkbox: Deckkraft steigt
```

- Der Canvas liegt **über** der Bühne, nicht mehr in derselben ScrollView wie
  das Cover. Beim normalen Scrollen schiebt sich der Canvas über das Cover
  (wie bei Spotify die Lyrics über das Albumbild); das Cover bleibt stehen.
  Der obere, durchsichtige Teil der ScrollView (`contentMargins(.top,
  bandBottom)`) lässt die Bühne sehen.
- Tipps auf das Motiv im Cover-Bereich (Bild → Cover, Play beim Video) kommen
  an einem Overlay über der ScrollView an, das nur bei Scroll-Offset 0 und
  `t == 0` trifft (`allowsHitTesting`). Wischen geht durch das Overlay an die
  ScrollView.
- `CoverStage` bekommt `t` und interpoliert die Lage des Motivs zwischen
  „Band“ und „Bühne“. Hintergrund in beiden Zuständen derselbe
  Kategorieverlauf (`CoverArtwork`), damit nichts umspringt; bei Einstellung
  „Schwarz“ Schwarz. Der silberne Verlauf aus `CoverStage` entfällt.

### Geometrie (ParalistCore, `CoverTransition`, reine Funktionen mit Tests)

| Funktion | Ergebnis |
|---|---|
| `band(width, topInset)` | Höhe des Cover-Bereichs: `topInset + width / mediaRatio` |
| `canvasOffset(t, height, band)` | `t * (height - band)`: 0 in Detail, Canvas ganz unten im Cover |
| `motifFrame(t, kind, ratio, size, topInset)` | Rechteck des Motivs, lineare Mischung aus Band-Lage (Fit in 16:9 unter der Kopfzeile) und Bühnen-Lage (siehe Bilder unten); Emblem 64 → 128 pt, Logo 96 → 96 pt |
| `detailChrome(t)` | Deckkraft Bottom-Zeile und Picker: 1 bei t ≤ 0, 0 ab t ≥ 0,35 |
| `coverChrome(t)` | Deckkraft Titelzeile, Fades: 0 bis t ≤ 0,65, 1 bei t = 1 |
| `progress(drag, height, band, from)` | `t` aus dem Fingerweg: Detail → Cover `drag / (height - band)`, Cover → Detail umgekehrt, geklemmt 0 … 1 |
| `settle(t, velocity, from)` | Ziel 0 oder 1: über 35 % des Weges (`coverSnapShare`) oder Schwung über 600 pt/s (`coverSnapVelocity`) in die Zielrichtung, sonst zurück |
| `imagePlacement(ratio, stage)` | Lage eines Bildes in der Bühne, siehe nächster Abschnitt |

### Gesten

- **Detail → Cover:** Eigene `DragGesture` als `simultaneousGesture` an der
  ScrollView. Sie zählt nur, wenn die ScrollView oben steht (Offset ≤ 0,
  gelesen über `onScrollGeometryChange`) und der Finger nach unten geht.
  Sobald `t > 0`, ist `scrollDisabled(true)`, damit kein Gummiband mitläuft;
  der Canvas folgt 1:1 dem Finger über `canvasOffset`. Loslassen:
  `settle` entscheidet, Animation `Motion.dock` zum Ziel.
- **Cover → Detail:** Dieselbe Geste auf der Bühne, Finger nach oben, `t`
  fällt von 1. Ersetzt den heutigen Schwellen-Wischer (`swipeThreshold`).
  Wischen nach unten im Cover schließt weiter das Deckblatt.
- **Picker, Tipp, Bottom-Zeile „Vollbild“:** setzen `t` animiert auf 0 oder 1,
  derselbe Weg, dieselbe Kurve.
- **Reduce Motion:** `accessibilityReduceMotion` → keine Bewegung, nur
  Überblenden zwischen t = 0 und t = 1 (wie heute).
- Haptik: `sensoryFeedback(.selection)`, wenn das Ziel von `settle` während
  des Ziehens wechselt.
- Medien-Seite öffnet weiter direkt bei `t = 1`, Datei/Dokument mit Bild oder
  Video ebenso (`EntryDestination`).

## Bilder im Cover (wie Video)

```
   Quer (Chrome an)       Quer (Chrome aus)      Hochkant (Chrome an)
   ┌──────────┐           ┌──────────┐           ┌──────────┐
   │˅ Datei  ⋯│           │          │           │˅ Datei  ⋯│
   │░░░░░░░░░░│           │          │           │▒▒┌────┐▒▒│
   │┌────────┐│           │┌────────┐│           │  │    │  │
   ││  Bild  ││           ││  Bild  ││           │  │Bild│  │
   │└────────┘│           │└────────┘│           │  │    │  │
   │░░░░░░░░░░│           │          │           │  │    │  │
   │░░░░░░░░░░│           │          │           │  │    │  │
   │▒▒▒▒▒▒▒▒▒▒│           │          │           │▒▒│    │▒▒│
   │Titel     │           │          │           │▓▓└────┘▓▓│
   └──────────┘           └──────────┘           │Titel     │
   Verlauf, Fades          nur Schwarz + Bild     └──────────┘
   Titel, Picker/Tipp                             Ränder oben = unten
```

- **Lage:** Quer und quadratisch (Verhältnis ≥ 1): volle Breite, Mitte bei
  3/7 der Höhe (`coverAnchor`), wie Video. Hochkant (Verhältnis < 1):
  `scaledToFit` in die ganze Bühne, waagerecht mittig, oben und unten gleiche
  Ränder (bei passendem Verhältnis 0). Video hochkant bleibt `aspectFill`.
- **Chrome aus** (Tipp aufs Bild): nur Schwarz und Bild. Kopfzeile, oberer
  Fade, Titelzeile, Titel-Fade, Picker weg. Entspricht „Video läuft“.
- **Chrome an** (nächster Tipp): Hintergrund ist der Kategorieverlauf
  (`CoverArtwork`, derselbe wie im Cover-Bereich), oben Fade 160 pt
  (`coverTopFade`) für die Kopfzeile, unten der Titel-Fade (`coverFadeLead`),
  Titelzeile, Picker. Entspricht „Video pausiert“ plus eingeblendetem Picker.
  Beim Öffnen des Covers ist Chrome an.
- Ein Zustand `chrome` für Bild und Video statt `coverPlaying || pickerShown`:
  Video-Start setzt `chrome = false`, Pause `chrome = true`, Tipp schaltet um.
  Bei pausiertem Video bleibt die heutige Regel (Kopf- und Titelzeile immer,
  Tipp schaltet nur den Picker), damit sich dort nichts ändert.
- Einstellung „Schwarz“: Hintergrund immer Schwarz, Fades bleiben.
- Während `t` zwischen 0 und 1 liegt, ist Chrome immer an (nichts flackert).

## Edge Picker: wann sichtbar

```
   Öffnen (eingeklappt)     Tipp auf Rand / Leerstelle     Container mit Plus
   ┌──────────┐             ┌──────────┐                   ┌──────────┐
   │ Info     │             │ Info     │                   │ Info     │
   │ Titel    │             │ Titel   ╭┤                   │ Titel    │
   │ ───────  │             │ ─────── │▪│                  │ ───────  │
   │ Optionen │             │ Optionen│○│                  │Verkn. (+)│
   │          ▐             │         ╰┤                   │ ▫ A      ▐
   │ (×)[Akt.]│             │ (×)[Akt.]│                   │ (×)[Akt.]│
   └──────────┘             └──────────┘                   └──────────┘
   12 pt Rand (edgePeek)    ausgeklappt                    bleibt eingeklappt,
                                                           Plus frei
```

Regeln, alle in `EntryPage` (Zustand `pickerTucked`):

1. **Start eingeklappt**, bei jedem Öffnen der Detailseite, in jeder
   Ansicht. Kein Hereinschieben beim Öffnen.
2. **Ausklappen** nur auf Wunsch: Tipp auf den sichtbaren Rand (32 pt
   Trefferfläche) oder auf eine leere Stelle im Canvas.
3. **Einklappen** von selbst, sobald der Nutzer etwas anderes tut:
   - Scrollen im Canvas (ab 8 pt Bewegung),
   - eine Option erledigt oder ein Sheet geschlossen (wie heute),
   - Wechsel in Text oder Verknüpfungen (wie heute),
   - Wechsel in Aktionen über den Picker **bleibt ausgeklappt**, damit man
     mehrfach umschalten kann.
4. **Plus frei halten:** Liegt der Picker ausgeklappt über dem Plus eines
   Containers (Verknüpfungen, Chats; Rechteck-Schnitt der Rahmen, gemessen
   über `onGeometryChange` im Canvas-Koordinatenraum), klappt er ein. Er
   rutscht nie nach oben oder unten. Während des Scrollens gilt ohnehin
   Regel 3, also ist der Fall selten.
5. **Übergang:** Deckkraft fällt mit `detailChrome(t)` auf 0, im Cover ist er
   weg. Im Cover zeigt ihn erst der Tipp (Chrome an), eingeklappt gibt es dort
   nicht.
6. **Tastatur:** wie heute ganz ausgeblendet.

### Feste Position

Der Picker hat in Detail, Text, Verknüpfungen und Cover **eine** Höhe:
Unterkante der Kerbe 76 pt über dem unteren sicheren Bereich
(`edgePickerLift` 24 + `entryBarHeight` 52, neu als `Dimens.edgePickerBottom`).
Das ist die heutige Detail-Position. Nichts hängt mehr an `coverRow`.

```
   Detail                     Cover (Picker nach Tipp)
   ┌──────────┐               ┌──────────┐
   │          │               │░░░░░░░░░░│
   │         ╭┤ ─┐            │░░░░░░░░ ╭┤ ─┐  gleiche Höhe
   │ Text    │▪│ │            │░░░░░░░░ │▪│ │
   │         │○│ │ 280        │░░░░░░░░ │○│ │
   │         ╰┤ ─┘            │▒▒▒▒▒▒▒▒ ╰┤ ─┘
   │          │ 24            │▓Titel ▶  │     Titelzeile rückt 64 pt
   │ (×)[Akt.]│ 52            │          │     nach links, solange der
   └──────────┘               └──────────┘     Picker sichtbar ist
```

Im Cover liegt die Titelzeile in derselben Zone. Damit Titel und Play-Knopf
nie unter der Kerbe liegen, bekommt die Titelzeile `padding(.trailing,
edgeNotchWidth)`, solange der Picker sichtbar ist, animiert mit `Motion.dock`
zusammen mit dem Einblenden. Ohne Picker (Chrome aus, Video läuft) steht sie
wie heute über die volle Breite.

## Etappen

### 1. Kern

`ParalistCore/Sources/ParalistCore/Library/CoverTransition.swift` mit den
Funktionen aus der Tabelle oben, Tests in
`ParalistCore/Tests/ParalistCoreTests/CoverTransitionTests.swift`: Band,
Offset, Motiv-Rechteck an t = 0, 0,5, 1 für Emblem, Logo, Bild quer, Bild
hochkant, Video; `settle` mit Weg und Schwung in beide Richtungen;
`imagePlacement` quer und hochkant mit gleichen Rändern. `swift test` grün.

### 2. Eine Hierarchie

`EntryPage` auf `t` umbauen (`@State private var cover: CGFloat`), Bühne
hinter dem Canvas, Canvas als ScrollView mit durchsichtigem Kopf, Overlay für
Tipps im Band, Chrome-Deckkräfte aus dem Kern. `EntryCover` (16:9-Band mit
gespiegeltem Verlauf) entfällt, `CanvasBackdrop` bleibt. `EntryPage` ist mit
346 Zeilen fast voll: Toolbar nach `EntryToolbar.swift`, ScrollView-Teil nach
`EntryCanvasPanel.swift`, Bottom-Zeile nach `EntryBottomBar.swift`.
Picker und Bottom-Zeile setzen `t` animiert. Prüfen: t = 0 und t = 1 sehen aus
wie heute (Screenshots `entry`, `bookmark`, Medien).

### 3. Gesten

Zieh-Geste in beide Richtungen, `scrollDisabled` bei `t > 0`, `settle`,
Haptik, Reduce Motion. Alte Schalter `coverPull` und `swipeThreshold`
(nur noch fürs Schließen nach unten) aufräumen. Zurück-Wischgeste im
`DetailHost` und Wischen nach unten zum Schließen weiter prüfen.

### 4. Bilder im Cover

`imagePlacement` in `CoverStage`, Zustand `chrome` für Bild und Video,
Kategorieverlauf statt Silber, Schwarz-Modus. Hochkant- und Querbild, hell
und dunkel prüfen.

### 5. Edge Picker

Regeln 1 bis 5 in `EntryPage`, Messen der Plus-Rahmen in `EntryRelations`
(und Chats-Container), feste Position `Dimens.edgePickerBottom` (76) statt
`edgePickerLift + coverRow`, Titelzeile im Cover mit Platz für die Kerbe.

### 6. Doku und Abschluss

`docs/detailseite.md` nachziehen (Abschnitte Öffnen, Wischen, Cover-Ansicht,
Edge Picker, Dateien), Screenshot-Workflow, Review im Chat.

## Dateien

| Datei | Änderung |
|---|---|
| `ParalistCore/.../Library/CoverTransition.swift` | neu, Geometrie und Einrasten |
| `ParalistCore/Tests/.../CoverTransitionTests.swift` | neu |
| `Paralist/Entry/EntryPage.swift` | `t`, Gesten, Picker-Regeln; wird geteilt |
| `Paralist/Entry/EntryCanvasPanel.swift`, `EntryToolbar.swift`, `EntryBottomBar.swift` | neu, aus `EntryPage` herausgelöst |
| `Paralist/Entry/CoverStage.swift` | nimmt `t`, Motiv-Rechteck aus dem Kern, Bild-Lage, `chrome`, Kategorieverlauf |
| `Paralist/Entry/EntryHero.swift` | nur noch Medienwahl, reicht `t` durch |
| `Paralist/Entry/EntryCover.swift` | Band entfällt, `CanvasBackdrop`, `CoverEmblem`, `CoverLogo`, `CoverRatioHint` bleiben |
| `Paralist/Entry/EntryBlocks.swift` | Plus-Rahmen melden |
| `Paralist/Theme/Dimens.swift` | `coverSnapShare`, `coverSnapVelocity`, `edgePickerBottom`; `coverSilverEdge`, `coverPull` weg |
| `Paralist/Theme/Palette.swift` | `mediaSilver` weg, falls sonst unbenutzt |
| `docs/detailseite.md` | nachziehen |

## Risiken

- **ScrollView gegen eigene Geste:** Beim ersten Zug nach unten kann die
  ScrollView ein, zwei Punkte Gummiband zeigen, bevor `scrollDisabled`
  greift. Falls das sichtbar bleibt: Rückfall auf die Gummiband-Variante
  (Offset der ScrollView treibt `t`, Loslassen über 110 pt animiert den Rest).
  Dann folgt der Canvas dem Finger nur gedämpft, die Animation bleibt aber
  eine.
- **Liquid-Glass-Knöpfe** in Bottom-Zeile und Overlay: eigene Gesten ohne
  `.interactive()` und mit `highPriorityGesture`, sonst schluckt das Glas sie.
- **Hochkant-Video** und **YouTube/Spotify** im Übergang: Einbettungen werden
  nicht skaliert, nur verschoben (WebView-Neuaufbau vermeiden); YouTube bleibt
  16:9 bei voller Breite.
- **Geometrie-Messungen** (Plus-Rahmen, Titel-Unterkante) laufen über
  `onGeometryChange`; bei langen Listen keine Schleifen durch gegenseitige
  Abhängigkeit (Picker verschiebt nichts im Canvas).
- Android-Gegenstück fehlt weiterhin.

## Offene Entscheidungen (vor Etappe 2)

1. Hintergrund im Cover bei Bild und Video: Kategorieverlauf wie im
   Cover-Bereich (Vorschlag, nötig für den nahtlosen Übergang) oder weiter
   Silber/Schwarz.
2. Scrollen im Canvas: Cover bleibt stehen, Canvas schiebt sich darüber
   (Vorschlag, wie Spotify) oder Cover scrollt wie heute mit weg.
3. Picker nach Wechsel über den Picker selbst: bleibt ausgeklappt (Vorschlag)
   oder klappt nach jedem Wechsel ein.

## Lies zuerst

`CLAUDE.md`, `docs/detailseite.md`, dann diese Datei. Etappen in der
Reihenfolge, nach jeder Etappe `swift test`, Review im Chat, Commit erst auf
„commit“.
