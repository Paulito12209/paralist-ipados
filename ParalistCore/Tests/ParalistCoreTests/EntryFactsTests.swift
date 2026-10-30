// Zusammenhang: Sources/ParalistCore/Library/EntryFacts.swift, Sources/ParalistCore/Library/Usage.swift
import Foundation
import Testing
@testable import ParalistCore

struct EntryFactsTests {
    @Test func wordsSkipMarkdownMarks() {
        #expect(EntryFacts.words("") == 0)
        #expect(EntryFacts.words("# Titel\n\n- eins **zwei**\n- 3 Punkte") == 5)
        #expect(EntryFacts.words("  Hallo   Welt \n") == 2)
    }

    @Test func kindFollowsAttachment() {
        var e = Entry(id: "a", type: .file, title: "", created: at("2026-10-01T10:00:00Z"), updated: at("2026-10-01T10:00:00Z"))
        #expect(EntryFacts.kind(e) == .entry)
        e.attachment = Attachment(hash: String(repeating: "a", count: 64), name: "bild.jpg", mime: "image/jpeg", size: 10)
        #expect(EntryFacts.kind(e) == .photo)
        e.attachment = Attachment(hash: String(repeating: "a", count: 64), name: "film.mp4", mime: "video/mp4", size: 10)
        #expect(EntryFacts.kind(e) == .video)
    }

    @Test func editedNeedsAMinute() {
        var e = Entry(id: "a", type: .note, title: "", created: at("2026-10-01T10:00:00Z"), updated: at("2026-10-01T10:00:30Z"))
        #expect(!EntryFacts.edited(e))
        e.updated = at("2026-10-02T10:00:00Z")
        #expect(EntryFacts.edited(e))
    }

    @Test func sourceIgnoresBlankLinks() {
        var e = Entry(id: "a", type: .bookmark, title: "", created: at("2026-10-01T10:00:00Z"), updated: at("2026-10-01T10:00:00Z"))
        #expect(EntryFacts.source(e) == nil)
        e.url = "  "
        #expect(EntryFacts.source(e) == nil)
        e.url = " https://example.com/a \n"
        #expect(EntryFacts.source(e) == "https://example.com/a")
    }

    @Test func contentJoinsTitleAndBody() {
        var e = Entry(id: "a", type: .note, title: " Titel ", created: at("2026-10-01T10:00:00Z"), updated: at("2026-10-01T10:00:00Z"))
        #expect(EntryFacts.content(e) == "Titel")
        #expect(EntryFacts.title(e) == "Titel")
        e.body = "\nErste Zeile\n\n- Punkt\n"
        #expect(EntryFacts.content(e) == "Titel\n\nErste Zeile\n\n- Punkt")
        e.title = ""
        #expect(EntryFacts.content(e) == "Erste Zeile\n\n- Punkt")
        #expect(EntryFacts.title(e).isEmpty)
    }

    @Test func sharesAreCountedAndForgotten() {
        var usage = UsageData()
        usage.recordOpened("a", at: at("2026-10-01T10:00:00Z"))
        usage.recordOpened("a", at: at("2026-10-02T10:00:00Z"))
        usage.recordShared("a")
        #expect(usage.views("a") == 2)
        #expect(usage.shares("a") == 1)
        #expect(usage.shares("b") == 0)
        usage.forget("a")
        #expect(usage.views("a") == 0)
        #expect(usage.shares("a") == 0)
    }

    @Test func oldUsageFileStillLoads() throws {
        let old = #"{"opened":{},"searches":[]}"#
        let usage = try JSONDecoder().decode(UsageData.self, from: Data(old.utf8))
        #expect(usage.shared.isEmpty)
    }
}
