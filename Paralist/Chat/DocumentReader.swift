// Zusammenhang: ParalistCore Chat/ScannedDocument.swift, Chat/ChatEngine.swift (scan), App/AppPrefs.swift (language), docs/chat.md
import Foundation
import OSLog
import ParalistCore
import Vision

enum DocumentReader {
    private static let log = Logger(subsystem: "app.paralist", category: "chat")

    static func read(_ url: URL, language: String) async -> ScannedDocument? {
        var request = RecognizeDocumentsRequest()
        let wanted = Locale.Language(identifier: language)
        if request.supportedRecognitionLanguages.contains(wanted) {
            request.textRecognitionOptions.recognitionLanguages = [wanted]
        }
        let started = ContinuousClock.now
        guard let observation = try? await request.perform(on: url).first else {
            log.info("document scan found nothing after \(ContinuousClock.now - started)")
            return nil
        }
        let document = observation.document
        let tables = document.tables.map { table in
            ScannedTable(rows: table.rows.map { row in row.map { $0.content.text.transcript } })
        }
        let result = ScannedDocument(text: document.text.transcript, tables: tables)
        log.info("document scan took \(ContinuousClock.now - started): \(tables.count) tables, \(result.text.count) characters")
        return result
    }
}
