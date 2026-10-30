// Zusammenhang: Sources/ParalistCore/Chat/ScannedDocument.swift, Sources/ParalistCore/Chat/ChatPrompt.swift (withImage, imageMark), Sources/ParalistCore/Chat/ChatAttachments.swift, Sources/ParalistCore/Chat/ChatThread.swift (attachment), TestSupport.swift
import Foundation
import Testing
@testable import ParalistCore

struct ScannedDocumentTests {
    private let now = at("2026-10-21T10:00:00Z")

    private func plan() -> ScannedDocument {
        let rows: [[String]] = [
            ["Name", "Mo 26.10", "", "Di 27.10", ""],
            ["", "Std.", "Zeit", "Std.", "Zeit"],
            ["Muster, Erika", "6.92", "06:00-13:00/", "", "ABW"],
            ["Beispiel, Max", "", "f", "7.5", "13:00-21:00\n000042g"],
            ["", "", "", "", ""],
        ]
        return ScannedDocument(text: "Wochenplan 26.10.2026-01、11.2026\nKW 44\nName\nMuster, Erika\n06:00-13:00/\nABW\nHandschrift am Rand", tables: [ScannedTable(rows: rows)])
    }

    @Test func formatListsTablesRowWiseAndKeepsOnlyLooseText() {
        let out = ScannedContext.format(plan())
        #expect(out.hasPrefix("table 1 (5 rows):\n  Name | Mo 26.10 |  | Di 27.10 | \n   | Std. | Zeit | Std. | Zeit\n"))
        #expect(out.contains("  Muster, Erika | 6.92 | 06:00-13:00/ |  | ABW\n"))
        #expect(out.contains("  Beispiel, Max |  | f | 7.5 | 13:00-21:00 000042g"))
        #expect(!out.contains("  |  |  |  | "))
        #expect(out.hasSuffix("other text:\nWochenplan 26.10.2026-01、11.2026\nKW 44\nHandschrift am Rand"))
        #expect(!out.contains("\nMuster, Erika\n"))
    }

    @Test func formatWithoutTablesGivesPlainTextAndRespectsTheBudget() {
        let doc = ScannedDocument(text: "  Erste Zeile \n\n Zweite Zeile ")
        #expect(ScannedContext.format(doc) == "text:\nErste Zeile\nZweite Zeile")
        #expect(ScannedContext.format(doc, limit: 12) == "text:\nErste…")
        #expect(ScannedContext.format(ScannedDocument(text: " \n")).isEmpty)
        #expect(ScannedDocument(text: " ", tables: [ScannedTable(rows: [])]).isEmpty)
        #expect(!plan().isEmpty)
    }

    @Test func formatCutsRowsColumnsAndCells() {
        let wide = (0..<ScannedContext.maxColumns + 2).map { "c\($0)" }
        let rows = (0..<ScannedContext.maxRows + 3).map { _ in wide }
        let out = ScannedContext.format(ScannedDocument(text: "", tables: [ScannedTable(rows: rows)]), limit: 100_000)
        #expect(out.hasPrefix("table 1 (43 rows):\n"))
        #expect(out.hasSuffix("  (3 more rows)"))
        #expect(!out.contains("c16"))
        #expect(out.contains("c15"))
        let long = ScannedContext.format(ScannedDocument(text: "", tables: [ScannedTable(rows: [[String(repeating: "x", count: 60)]])]))
        #expect(long == "table 1 (1 rows):\n  " + String(repeating: "x", count: ScannedContext.cellChars - 1) + "…")
        let four = (0..<4).map { ScannedTable(rows: [["t\($0)"]]) }
        let many = ScannedContext.format(ScannedDocument(text: "", tables: four))
        #expect(many.contains("table 3") && !many.contains("table 4"))
    }

    @Test func promptWrapsTheQuestionAroundTheImage() {
        let with = ChatPrompt.withImage("  Was steht auf dem Bild? ", image: "table 1 (1 rows):\n  a | b")
        #expect(with.hasPrefix("The user attached a photo."))
        #expect(with.contains("\n  a | b\n\nQuestion: Was steht auf dem Bild?"))
        let silent = ChatPrompt.withImage("", image: "text:\nHallo")
        #expect(silent.hasSuffix("No question was asked. Say in one or two sentences what the photo contains and offer to help with it."))
        let blank = ChatPrompt.withImage("Und?", image: "")
        #expect(blank.hasPrefix("The user attached a photo, but no readable text or table was found in it."))
        #expect(blank.hasSuffix("Question: Und?"))
    }

    @Test func instructionsAndHistoryMentionEarlierImages() {
        let today = Day.parse("2026-10-21")!
        let plain = ChatPrompt.instructions(language: "German", today: today, linked: "", history: "")
        #expect(!plain.contains("photo"))
        let withImage = ChatPrompt.instructions(language: "German", today: today, linked: "", history: "User: [image] Plan", image: "text:\nPlan")
        #expect(withImage.hasSuffix("Earlier in this conversation:\nUser: [image] Plan\n\nThe user shared a photo earlier in this conversation. Text read from it on the device:\ntext:\nPlan"))
        let hash = String(repeating: "a", count: 64)
        let messages = [
            ChatMessage(id: "msg-1", role: .user, text: "", at: now, attachment: hash),
            ChatMessage(id: "msg-2", role: .assistant, text: "Ein Plan.", at: now),
            ChatMessage(id: "msg-3", role: .user, text: "Danke", at: now),
        ]
        #expect(ChatPrompt.history(messages) == "User: [image] \nAssistant: Ein Plan.\nUser: Danke")
    }

    @Test func threadsKeepImageOnlyMessagesAndDropBadHashes() {
        let hash = String(repeating: "b", count: 64)
        var thread = ChatThread(id: "chat-1", created: now)
        thread.append(ChatMessage(id: "msg-1", role: .user, text: "  ", at: now, attachment: hash))
        #expect(thread.messages.count == 1)
        #expect(thread.title.isEmpty)
        #expect(thread.latestImage == hash)
        thread.append(ChatMessage(id: "msg-2", role: .user, text: "", at: now, attachment: "kein-hash"))
        #expect(thread.messages.count == 1)
        thread.append(ChatMessage(id: "msg-3", role: .user, text: "Was ist das?", at: now, attachment: "kein-hash"))
        #expect(thread.messages.last?.attachment == nil)
        #expect(thread.title == "Was ist das?")
        #expect(thread.attachments == [hash])
        let data = try! ChatCodec.encode(thread)
        #expect(String(decoding: data, as: UTF8.self).contains("\"anhang\" : \"\(hash)\""))
        #expect(try! ChatCodec.decode(data) == thread)
        let bad = String(decoding: data, as: UTF8.self).replacingOccurrences(of: hash, with: "../x")
        #expect(throws: EntryParseError.self) { try ChatCodec.decode(Data(bad.utf8)) }
    }

    @Test func remapDropsEmptyMessagesWhoseImageIsGone() {
        let gone = String(repeating: "c", count: 64)
        let kept = String(repeating: "d", count: 64)
        let fresh = String(repeating: "e", count: 64)
        var thread = ChatThread(id: "chat-1", created: now, messages: [
            ChatMessage(id: "msg-1", role: .user, text: "", at: now, attachment: gone),
            ChatMessage(id: "msg-2", role: .user, text: "Text bleibt", at: now, attachment: gone),
            ChatMessage(id: "msg-3", role: .user, text: "", at: now, attachment: kept),
        ])
        thread.remapAttachments { $0 == kept ? fresh : nil }
        #expect(thread.messages.map(\.id) == ["msg-2", "msg-3"])
        #expect(thread.messages.map(\.attachment) == [nil, fresh])
    }

    @Test func orphansIgnoreImagesStillUsedElsewhere() {
        let a = String(repeating: "a", count: 64), b = String(repeating: "b", count: 64), c = String(repeating: "c", count: 64)
        let other = ChatThread(id: "chat-2", created: now, messages: [ChatMessage(id: "msg-1", role: .user, text: "", at: now, attachment: b)])
        #expect(ChatAttachments.orphans([a, b, c, a, "x"], threads: [other], inUse: [c]) == [a])
        let root = temporaryDirectory()
        let store = ChatStore(root: root)
        try! FileManager.default.createDirectory(at: store.attachmentsDir, withIntermediateDirectories: true)
        try! Data("bild".utf8).write(to: store.attachmentsDir.appendingPathComponent(a))
        #expect(store.attachmentFile(a) != nil)
        #expect(store.deleteAttachments([a, b, "../x"]) == 1)
        #expect(store.attachmentFile(a) == nil)
    }
}
