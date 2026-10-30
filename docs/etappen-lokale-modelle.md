<!-- Zusammenhang: CLAUDE.md, docs/etappen-widget-siri-chat.md (Paket 3), docs/chat.md, Paralist/Chat/ChatEngine.swift, Paralist/Chat/ChatEngineTools.swift, ParalistCore/Sources/ParalistCore/Chat/* -->
# Etappen: Paralist bereit für lokale Sprachmodelle

Prompt für eine neue Sitzung auf dem Mac (Umgebung paralist-ios). Text ab
„Lies zuerst“ vollständig einfügen. Erst starten, wenn Chat Teil 3b
(FoundationModels, Tools, Verknüpfen) committet ist.

## Ziel und Entscheidung

Paralist soll gut für Sprachmodelle vorbereitet sein, aber vorerst nur mit
Apples lokalen Modellen. Keine Fremdmodelle, kein Download, kein Hugging Face,
kein Netz. Einfache Funktion vor Auswahl und Vergleich.

Entscheidung von Paul (2026-10-21): nur Apples On-Device-Modelle. Alles, was
das SDK anbietet, soll wählbar sein; Paralist zeigt ehrlich, was auf dem
jeweiligen Gerät gut läuft, und wählt ab Werk die schnellste Stufe.

### Was das iOS-27-SDK bietet (geprüft im SDK)

- `SystemLanguageModel.default` ist das allgemeine lokale Modell. Die Variante
  (`core3` oder `coreAdvanced3`) wählt das System je Gerät; eine App kann sie
  nur lesen (`variant.displayName`), nicht wählen.
- `contextSize` liefert die Kontextgröße des Geräts (vor iOS 27 fest 4096),
  `tokenCount(for:)` zählt Token für Anweisungen, Prompt, Tools und Verlauf.
- `ContextOptions.ReasoningLevel` mit `light`, `moderate`, `deep` steuert, wie
  lange das Modell nachdenkt. Alle drei Stufen sind wählbar, `light` ist
  Standard; `deep` bekommt auf schwächeren Geräten bzw. bei `core3` einen
  Hinweis, dass Antworten lange dauern können.
- Das Protokoll `LanguageModel` und `LanguageModelCapabilities` (`toolCalling`,
  `reasoning`, `vision` …) sind Apples eigene Austauschschicht. Paralist baut
  darauf auf statt auf ein eigenes Backend-Protokoll.
- `PrivateCloudComputeLanguageModel` läuft nicht lokal und bleibt
  ausgeschlossen.

### Bestandsaufnahme (Stand Teil 3b)

Schon modell-neutral: Daten, Suche, Woche und Kürzung in `ParalistCore`
(`ChatTools`, `ChatPrompt`, `ChatMentions`) als reine Funktionen mit Tests;
`chats/` als JSON, neue Felder ohne Formatbruch möglich.

Noch fest verdrahtet: `ChatEngine` nutzt fest `.default`, das Kontextbudget ist
in Zeichen (`ChatPrompt.historyChars`) statt in Token und nicht an die
Gerätegröße gebunden; Tool-Beschreibungen stehen nur im App-Code.

### Grenzen

- Nur Geräte mit Apple Intelligence; die Variante hängt am Gerät.
- `moderate` und `deep` antworten langsamer und brauchen mehr Akku.
- Kommt in einem späteren SDK eine wählbare Variante oder ein weiteres lokales
  Apple-Modell dazu, gehört es in dieselbe Auswahl mit demselben Hinweis.
- Kontext bleibt klein, Kürzung bleibt nötig.

## Prompt

```
Lies zuerst CLAUDE.md, docs/chat.md und docs/etappen-lokale-modelle.md (Einleitung: SDK, Bestandsaufnahme, Grenzen). Du arbeitest zwei Pakete nacheinander ab. Jedes Paket ist eine eigene Etappe: bauen → swift test grün → tools/deploy_ipad.sh → Review im Chat (Problem, Lösung, Begründung, Skizze vorher/nachher, Risiken) → warten auf „commit“ → nach Commit fragen „TestFlight-Build hochladen?“. Erst danach das nächste Paket. Je Paket höchstens drei Rückfragen. Keine Extras über den Umfang hinaus. docs/chat.md um den Abschnitt „Modell“ erweitern und aktuell halten. Logik ohne Oberfläche gehört nach ParalistCore mit Tests (Swift Testing). Alle Texte über L.s/L.f in Localizable.xcstrings und tools/strings_ios.json, acht Sprachen. Maße/Farben/Schrift in Theme/.

Grundsatz: Nur Apples lokale Modelle (SystemLanguageModel). Kein Netz, keine Fremdmodelle, kein Download, kein Private Cloud Compute. Alle lokalen Optionen wählbar, mit Hinweis je Gerät.

━━━━━━━━━━━━━━━━━━━━
PAKET 1 – Budget nach Gerät (für Nutzer unsichtbar)
━━━━━━━━━━━━━━━━━━━━
- ChatEngine liest contextSize des Modells und gibt es als Token-Budget weiter. Im Kern ChatBudget mit Tests: Budget auf Anweisungen, Verknüpftes, Verlauf, Tool-Ausgaben und Antwort verteilen (feste Anteile, Mindestwerte, Obergrenzen). ChatPrompt.history und ChatTools.context nehmen das Budget statt fester Zeichenzahlen; Token grob aus Zeichen schätzen, in der App bei Bedarf mit tokenCount(for:) nachprüfen.
- Tool-Beschreibungen (Name, Zweck, Parameter) als Daten in ParalistCore (ChatToolSpec), die FoundationModels-Tools übernehmen sie. Kein JSON-Schema, keine Tool-Erkennung aus Text.
- Prüfen: Antworten unverändert, langer Thread läuft nicht mehr in contextSizeExceeded; Messwert „Zeit bis zum ersten Wort“ vorher/nachher auf beiden iPhones in docs/chat.md.

━━━━━━━━━━━━━━━━━━━━
PAKET 2 – Denkstufe und Modell-Info
━━━━━━━━━━━━━━━━━━━━
- Einstellung „Antworten“ mit drei Stufen: Schnell (reasoningLevel light, Standard), Ausgewogen (moderate), Gründlich (deep). Gilt für alle Chats, wirkt ab der nächsten Nachricht. Nur zeigen, wenn das Modell die Fähigkeit reasoning meldet.
- Hinweis je Stufe nach Gerät: Empfehlung als reine Funktion in ParalistCore mit Tests (Eingaben: Variante, Kontextgröße, Stromsparmodus, thermalState → empfohlen / langsam / nicht empfohlen mit Grund). Nichts wird gesperrt, nur erklärt.
- Info-Zeile in den Einstellungen: Modell verfügbar oder nicht (mit Grund), Variante (variant.displayName), Kontextgröße. Prüfe im SDK, ob sich die Variante oder ein weiteres lokales Apple-Modell wählen lässt; wenn ja, gehört es in dieselbe Auswahl mit Hinweis. Kein Vergleich.
- Prüfen: hell und dunkel, alle Stufen auf beiden iPhones, Zeit bis zum ersten Wort je Stufe in docs/chat.md.

Starte mit Paket 1.
```

## Zurückgestellt

Fremdmodelle (llama.cpp/MLX, Download, Import), Modell je Chat und Vergleich
von Antworten. Erst wieder aufgreifen, wenn Paul es ausdrücklich will.
