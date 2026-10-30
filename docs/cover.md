<!-- Zusammenhang: docs/detailseite.md, docs/etappen-cover-uebergang.md, Paralist/Entry/EntryPage.swift, Paralist/Entry/EntryHero.swift, Paralist/Entry/EntryCanvasPanel.swift, Paralist/Entry/CoverStage.swift, Paralist/Entry/CoverMotifLayer.swift, Paralist/Entry/CoverChrome.swift, Paralist/Entry/CoverHeaderVeil.swift, Paralist/Entry/CoverVideo.swift, Paralist/Entry/SpotifyPlayer.swift, Paralist/Entry/YouTubePlayer.swift, ParalistCore/Sources/ParalistCore/Library/CoverTransition.swift, Paralist/Theme/Dimens.swift (cover*) -->

# Detailseite: Cover und Übergang

Stand: 2026-10-29. Begriffe, Ansichten, Edge Picker und Bottom-Zeile stehen
in `docs/detailseite.md`. Vorlage für die Cover-Ansicht ist der
Vollbild-Player von Spotify.

## Übergang Detail und Cover

Die Detailseite ist **eine** Hierarchie. Eine Zahl `cover` in `EntryPage`
(0 bis 1, im Kern `t`) beschreibt, wo sie steht: 0 ist die Detail-Ansicht,
1 das Cover, dazwischen der Übergang, den der Finger oder die Animation
fährt. Die Geometrie dazu liegt in `ParalistCore` (`CoverTransition`, reine
Funktionen mit Tests).

```
ZStack (EntryHero)
├─ CoverStage          Verlauf, oberer Fade, Titelzeile; immer Vollbild, unten
├─ EntryCanvasPanel    ScrollView: oben durchsichtig bis zur Unterkante des
│                      16:9-Teils, dann Titel mit Schleier und die Karte, als Ganzes um
│                      canvasOffset(t) nach unten geschoben
└─ CoverMotifLayer     Motiv (Emblem, Logo, Bild, Video, Einbettung) und
                       Hinweis-Knopf, über dem Canvas, an dessen Kante maskiert
```

- Der Canvas liegt über der Bühne. Beim Scrollen schiebt er sich über das
  Cover, das Cover bleibt stehen; das Motiv wird an der Canvas-Kante
  abgeschnitten, der Verlauf scheint hinter dem Titel durch den Schleier.
- `band` = Kopfzeile plus 16:9 der Breite. `canvasOffset(t)` = `t · (Höhe −
  band)`. Das Motiv steht bei t = 0 im Band (Fit in 16:9 unter der
  Kopfzeile), bei t = 1 in der Bühne (siehe Cover-Ansicht), dazwischen
  linear gemischt (`motifFrame`). Emblem bleibt 64 pt, Logo 96 pt.
- Bottom-Zeile (und Edge Picker, wenn eingeschaltet) blenden mit `detailChrome(t)` aus (1 bei 0,
  0 ab 0,35). Titelzeile und Fades blenden mit `coverChrome(t)` ein (0 bis
  0,65, 1 bei 1).
- Spotify und YouTube sind ein WKWebView in einer deaktivierten ScrollView,
  weil ein WKWebView direkt unter der Kopfzeile deren Bereich schwarz
  färbt. Spotify lädt bei t = 1 die hohe Variante (352 pt), sonst die
  kompakte (152 pt).
- Es gibt einen Player für Band und Cover (`CoverVideo`); ein im Band
  gestartetes Video läuft im Cover weiter. Play/Pause aus Titelzeile und
  Bottom-Zeile laufen über `playRequest`.


## Wischen zwischen Ansichten

- **Detail → Cover:** Steht der Canvas oben, zieht ein Finger nach unten die
  Seite mit: der Canvas folgt 1:1, der Cover-Bereich wächst zur Bühne
  (`cover` aus `CoverTransition.progress`). Die ScrollView ist dabei
  gesperrt. Loslassen: über 35 % des Wegs (`snapShare`) oder mit mehr als
  600 pt/s Schwung (`snapVelocity`) in Zielrichtung rastet es im Cover ein,
  sonst springt es zurück (`settle`, Animation `Motion.dock`).
- **Cover → Detail:** dieselbe Geste nach oben, der Canvas kommt von unten
  herauf.
- Die Geste zählt nur senkrecht, nicht auf dem Picker, nicht auf Spotify und
  YouTube (der WebView nimmt sie). Tipp aufs Bild (und der Picker, solange
  er eingeschaltet ist) fahren denselben Weg animiert.
- Haptik: `sensoryFeedback(.selection)`, wenn das Einrastziel während des
  Zugs wechselt.
- Reduce Motion: kein Mitführen, Entscheidung beim Loslassen, Umschalten ohne
  Animation.
- Zwischen Aktionen, Text und Verknüpfungen gibt es noch keine Wischgeste.


## Schließen und Blättern bei Bild und Video

- Die Detailseite öffnet als Vollbild von unten. Bild- und Video-Dateien
  (`EntryDestination.bare`) schließen immer nach unten: Wischen nach unten im
  Cover zieht die ganze Seite mit (`Router.detailDrop`) und schließt ab
  `swipeThreshold` nach unten (`Router.dropDetail`); die Zurück-Wischgeste
  von links nach rechts schiebt die Seite ebenfalls nach unten statt zur
  Seite. Das gilt für alle Einträge auf der ersten Ebene des Deckblatts.
- Nur aus Medien geöffnet (`Router.openMedia`, Warteschlange `mediaQueue` aus
  den gerade gefilterten Bildern und Videos) wechselt waagerechtes Wischen im
  Cover zum vorigen oder nächsten Bild (`MediaPager`, Logik in
  `ParalistCore` `MediaPaging`). Der Nachbar erscheint als Vorschau an seiner
  Cover-Position, am Ende der Reihe federt es zurück. Wischen vom linken Rand
  (`swipeBackEdge`) bleibt Zurück und schließt nach unten. Aus Listen oder
  der Suche geöffnet gibt es kein Blättern.


## Cover-Ansicht

Dateien `CoverStage.swift` (Bühne, Fades, Titelzeile), `CoverMotifLayer.swift`
(Motiv), `CoverChrome.swift` (Titelzeile). Vorlage ist der Vollbild-Player
von Spotify.

- Hintergrund über die ganze Höhe: der Kategorieverlauf (`CoverArtwork`), bei
  Spotify in Spotify-Grün, bei YouTube in `Palette.mediaVideo`. Mit
  Einstellung „Schwarz“ bei Bild, Video und Einbettung nur Schwarz. Einen
  silbernen Verlauf gibt es nicht mehr.
- Motiv mittig, vertikal bei 3/7 der Höhe (`coverAnchor`): Emblem, Logo,
  Querbild, YouTube (16:9 über die volle Breite), Spotify (352 pt hoch).
  Video quer und quadratisch: volle Breite im eigenen Seitenverhältnis bei
  `coverAnchor`. Video hochkant: füllt die Höhe, links und rechts
  abgeschnitten (`resizeAspectFill`).
- **Bild hochkant** (Verhältnis unter 1): in die ganze Bühne eingepasst,
  waagerecht mittig, oben und unten gleiche Ränder (`imagePlacement`). Die
  Kopfzeile läuft über den oberen Rand; der Fade hält sie lesbar.
- Video als Anhang: eigener Player (`CoverVideo.swift`, `AVPlayerLayer`),
  keine System-Steuerung. Startet nicht von selbst, läuft aus dem Band weiter.
  Am Ende springt es auf den Anfang und hält an.
- **Chrome** ist Kopfzeile, oberer Fade (160 pt, `coverTopFade`, bei Bild,
  Video und YouTube) und Titelzeile mit Fade und Knopf. Der Edge Picker ist
  derzeit auch im Cover ausgeblendet (`EdgePicker.shownOnDetail = false`); ein
  Tipp blendet ihn nicht ein, die Titelzeile rückt nicht nach links.
  Beim Öffnen des Covers ist Chrome an. Bild- und
  Video-Dateien öffnen dagegen ohne Chrome (nur Schwarz und Motiv,
  `EntryPage(bare:)`); erst ein Tipp zeigt Verlauf, Kopfzeile und Titelzeile. Ein Tipp aufs Cover:
  bei Bild oder laufendem Video schaltet er Chrome (aus: nur Schwarz und
  Motiv), sonst bleibt Chrome an (mit Picker schaltete dieser Tipp den
  Picker). Video-Start blendet Chrome aus, Pause wieder ein. Kein
  Ausblenden nach Zeit.
- Ist die Titelzeile beim Abspielen eingeblendet, nimmt sie wie bei Spotify
  unabhängig vom Modus die dunklen Farben. Bei Pause wieder hell oder dunkel
  je nach Modus.
- Rechts neben dem Titel ein runder Play/Pause-Knopf bei Video, YouTube und
  Spotify, 48 pt Kreis und Trefferfläche (`coverPlay`), Symbol 20 pt,
  senkrecht mittig zum Titel. Titelzeile mit 24 pt Abstand links, rechts und
  zum unteren Rand des sicheren Bereichs (`coverRowInset`). Bei Aufgabe und
  Projekt die runde Checkbox, bei Video rechts davon der Play-Knopf.
- Reicht ein Bild oder Video bis unter die Kopfzeile (hochkant), liegt
  statt des oberen Fades ein weicher Schleier dahinter (`CoverHeaderVeil`):
  Unschärfe und `surfaceContainer`, voll bis zur Mitte der Kopfzeile,
  dann weich auslaufend und 8 pt unter der Kopfzeile zu Ende (der
  obere sichere Bereich enthält die Kopfzeile schon)
  (`coverVeilTail`, `coverVeilShade`). Liegt die
  Kopfzeile auf dem Verlauf, gibt es keinen Schleier.
- Kopfzeile: links Chevron nach unten (schließt das Deckblatt), Mitte die
  Kategorie, rechts Favorit und die drei Punkte. Die Zurück-Wischgeste geht
  dort nicht.
- Unten die Titelzeile: Titel in `headlineMedium`, höchstens 5 Zeilen, dann
  „…“. Hinter der Titelzeile ein Fade von unten nach oben, der mit der
  Titelhöhe wächst und höchstens 56 pt über den Titel hinausläuft
  (`coverFadeLead`).
- Bild und Video mit anderem Seitenverhältnis als 16:9 zeigen im Band den
  Hinweis-Knopf (`CoverRatioHint`, Wahl zwischen Farbverlauf und Schwarz),
  unabhängig vom Motiv immer 16 pt vom rechten Geräterand und 12 pt über der
  Oberkante des Canvas (`coverHintEdge`, `coverHintLift`); im Cover ist er
  ausgeblendet.


## Spotify

Spotify-Links (`open.spotify.com/track|album|playlist|episode|show|artist`,
auch `intl-xx` und `spotify:`-URIs, `SpotifyLinks` in ParalistCore) zeigen
statt Logo den offiziellen Spotify-Einbett-Player (`SpotifyPlayer`, IFrame-API).
Im Cover-Bereich 152 pt hoch, in der Cover-Ansicht 352 pt, Hintergrund der
Kategorieverlauf in Spotify-Grün (`Palette.mediaSpotify`). Play/Pause unten
und neben dem Titel steuert den Player, der Zustand kommt vom Player zurück.
Ohne Spotify-Anmeldung spielt der Player nur 30-Sekunden-Vorschauen. Der
Player speichert Cookies dauerhaft, damit eine spätere Anmeldung erhalten
bleibt; eine Anmeldung aus der App heraus gibt es noch nicht.
