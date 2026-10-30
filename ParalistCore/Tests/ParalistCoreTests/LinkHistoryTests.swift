// Zusammenhang: Library/LinkHistory.swift, Library/EntryLibrary.swift
import Foundation
import Testing
@testable import ParalistCore

final class LinkHistoryTests {
    private let root = temporaryDirectory()
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    deinit { try? FileManager.default.removeItem(at: root) }

    private func bookmark(_ id: String, _ url: String) -> Entry {
        Entry(id, .bookmark, id, now, now) { $0.url = url }
    }

    @Test func recordKeepsFirstAndLastTime() {
        var history = LinkHistory()
        let added = history.record("https://www.example.com/a/", at: now)
        let same = history.record("https://example.com/a", at: now)
        let later = history.record("http://example.com/a", at: now.addingTimeInterval(60))
        #expect(added && !same && later)
        #expect(history.links.count == 1)
        let record = history.links["example.com/a"]
        #expect(record?.first == now)
        #expect(record?.last == now.addingTimeInterval(60))
        #expect(record?.url == "https://www.example.com/a/")
        let missing = history.record(nil, at: now)
        let blank = history.record("  ", at: now)
        #expect(!missing && !blank)
    }

    @Test func knowsMatchesSmallDifferences() {
        var history = LinkHistory()
        history.record("https://www.youtube.com/watch?v=AbC1", at: now)
        #expect(history.knows("http://youtube.com/watch?v=AbC1#t=3"))
        #expect(!history.knows("https://youtube.com/watch?v=abc1"))
        #expect(!history.knows(""))
    }

    @Test func mergeIsAUnion() {
        var a = LinkHistory()
        a.record("https://a.de", at: now)
        a.record("https://both.de", at: now)
        var b = LinkHistory()
        b.record("https://b.de", at: now)
        b.record("https://both.de", at: now.addingTimeInterval(-60))
        let merged = a.merged(with: b)
        #expect(merged.links.count == 3)
        #expect(merged.links["both.de"]?.first == now.addingTimeInterval(-60))
        #expect(merged.links["both.de"]?.last == now)
    }

    @Test func savedLinkIsFoundDespiteSmallDifferences() {
        let entry = bookmark("a", "https://www.youtube.com/watch?v=AbC1")
        #expect(LinkHistory.saved("http://youtube.com/watch?v=AbC1#t=3", in: [entry])?.id == "a")
        #expect(LinkHistory.saved("https://YouTube.com/watch/?v=AbC1", in: [entry])?.id == "a")
        #expect(LinkHistory.saved("https://youtube.com/watch?v=abc1", in: [entry]) == nil)
    }

    @Test func trailingSlashAndArchiveAreHandled() {
        var entry = bookmark("b", "https://example.com/blog/")
        #expect(LinkHistory.saved("https://example.com/blog", in: [entry])?.id == "b")
        entry.archived = true
        #expect(LinkHistory.saved("https://example.com/blog", in: [entry]) == nil)
        #expect(LinkHistory.saved("", in: [entry]) == nil)
    }

    @discardableResult
    private func save(_ url: String, in library: EntryLibrary) throws -> Entry {
        var entry = library.newEntry(.bookmark, title: url)
        entry.url = url
        return try library.save(entry)
    }

    @Test func savedLinksSurviveDeletionAndRestart() throws {
        let library = EntryLibrary(root: root, clock: FixedClock(now))
        let saved = try save("https://example.com/x", in: library)
        #expect(library.links.knows("https://example.com/x"))
        #expect(library.moveToTrash(saved.id))
        library.deleteForever([saved.id])
        let reopened = EntryLibrary(root: root, clock: FixedClock(now))
        reopened.rebuild()
        #expect(reopened.links.knows("https://example.com/x"))
        #expect(LinkHistory.saved("https://example.com/x", in: reopened.all) == nil)
    }

    @Test func rebuildAddsExistingAndTrashedLinks() throws {
        let first = EntryLibrary(root: root, clock: FixedClock(now))
        try save("https://example.com/live", in: first)
        let gone = try save("https://example.com/gone", in: first)
        #expect(first.moveToTrash(gone.id))
        try FileManager.default.removeItem(at: root.appendingPathComponent("linkverlauf.json"))
        let library = EntryLibrary(root: root, clock: FixedClock(now))
        library.rebuild()
        #expect(library.links.knows("https://example.com/live"))
        #expect(library.links.knows("https://example.com/gone"))
    }

    @Test func twoLibrariesDoNotOverwriteEachOther() throws {
        let app = EntryLibrary(root: root, clock: FixedClock(now))
        let share = EntryLibrary(root: root, clock: FixedClock(now))
        try save("https://share.de", in: share)
        try save("https://app.de", in: app)
        let later = EntryLibrary(root: root, clock: FixedClock(now))
        #expect(later.links.knows("https://share.de"))
        #expect(later.links.knows("https://app.de"))
    }
}
