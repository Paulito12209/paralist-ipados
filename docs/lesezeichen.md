<!-- Zusammenhang: Paralist/Composer/ComposerSheet.swift, Paralist/Composer/ComposerParts.swift (ComposerPasteButton), Paralist/App/ClipboardMemory.swift, Paralist/App/AppModel.swift, ParalistCore/Sources/ParalistCore/Library/ClipboardHint.swift, ParalistCore/Sources/ParalistCore/Library/LinkHistory.swift, ParalistCore/Sources/ParalistCore/Library/EntryLibrary.swift, ParalistShare/ShareModel.swift -->

# Lesezeichen: Einfügen und Link-Verlauf

Stand: 2026-10-26.

## Einfügen nur im Composer

- Kein Zwischenablage-Hinweis auf Übersichts- oder anderen Seiten.
- Im Composer für Lesezeichen sitzt oben rechts die native Einsetzen-Taste
  (`PasteButton`, kein Systemdialog). Sie nimmt echte URLs und Text an; aus
  Text wird der erste `http(s)`-Link gezogen (`SharedText.parse`).
- Die Taste pulsiert nur, wenn seit dem letzten Mal ein neuer Link kopiert
  wurde (`ClipboardHint`, höchstens zwölf Stunden alt, nicht von einem
  anderen Gerät). Nach Einsetzen, Speichern, Schließen des Composers, Löschen
  eines Lesezeichens oder Kopieren aus Paralist gilt diese Kopie als erledigt.
  Ein Zähler, der nach einem Neustart des Geräts kleiner ist, gilt ebenfalls
  als erledigt.
- iOS zeigt den Inhalt der Zwischenablage erst nach dem Tippen. Deshalb wird
  der Link beim Einsetzen geprüft: Gibt es ihn schon als Lesezeichen, öffnet
  Paralist dieses statt eines Duplikats. War er früher gespeichert und ist
  inzwischen gelöscht, kommt ein kurzer Hinweis und er wird normal eingesetzt.

## Link-Verlauf `linkverlauf.json`

- Im Datenordner neben `nutzung.json`, nicht im Backup. Android liest und
  schreibt dieselbe Datei im selben Format (seit 2026-10-27).
- Jeder gespeicherte Link landet dort mit erstem und letztem Zeitpunkt,
  Schlüssel ist der vereinfachte Link (ohne `www.`, Schema, Anker und
  Schrägstrich am Ende). Einträge werden nie entfernt, auch nicht beim
  Löschen oder Leeren des Papierkorbs.
- Beim Laden der Bibliothek kommen vorhandene und gelöschte Einträge dazu.
  App und Teilen-Erweiterung mischen beim Schreiben mit dem Stand auf der
  Platte, damit keiner den anderen überschreibt.
