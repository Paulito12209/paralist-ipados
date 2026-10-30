// Zusammenhang: Store/EntryStore.swift, Store/TrashRules.swift, Store/Ids.swift, Store/StorageMove.swift, Markdown/EntryCodec.swift
import Foundation
import Testing
@testable import ParalistCore

final class EntryStoreTests {
    private let now = at("2026-10-16T12:00:00Z")
    private let root = temporaryDirectory()
    private let files = FileManager.default

    deinit { try? FileManager.default.removeItem(at: root) }

    private func makeStore() -> EntryStore { EntryStore(root: root, clock: FixedClock(now)) }

    private func entry(_ id: String, _ title: String = "Titel") -> Entry {
        Entry(id, .note, title, now.addingTimeInterval(-60), now.addingTimeInterval(-60)) { $0.body = "Text\n" }
    }

    private func put(_ text: String, _ name: String, in store: EntryStore) throws {
        try Data(text.utf8).write(to: store.entriesDir.appendingPathComponent(name))
    }

    @Test func savesLoadsAndScans() throws {
        let store = makeStore()
        let saved = try store.save(entry("note-1", "Erste"))
        #expect(saved.updated == now)
        #expect(store.load("note-1")?.title == "Erste")
        try store.save(entry("note-2", "Zweite"))
        let scan = store.scan()
        #expect(scan.entries.map(\.id) == ["note-1", "note-2"])
        #expect(scan.broken.isEmpty)
        #expect(!files.fileExists(atPath: store.entriesDir.appendingPathComponent(".note-1.tmp").path))
    }

    @Test func skipsBrokenFilesAndReportsThem() throws {
        let store = makeStore()
        try store.save(entry("good-1"))
        try put("---\nid: kaputt-1\ntyp: virus\n---\n", "kaputt-1.md", in: store)
        try put("---\nid: anders-1\ntyp: notiz\nerstellt: 2026-10-01T08:00:00Z\n---\n", "fremd-1.md", in: store)
        try put("---\nid: riesig-1\n" + String(repeating: "x", count: 1_100_000), "riesig-1.md", in: store)
        let scan = store.scan()
        #expect(scan.entries.map(\.id) == ["good-1"])
        #expect(Set(scan.broken.map(\.name)) == ["kaputt-1.md", "fremd-1.md", "riesig-1.md"])
    }

    @Test func refusesPathLikeIds() throws {
        let store = makeStore()
        try Data(EntryCodec.encode(entry("secret")).utf8).write(to: root.appendingPathComponent("secret.md"))
        #expect(store.load("../secret") == nil)
        #expect(!store.exists("../secret"))
        #expect(throws: EntryParseError.self) { try store.fileFor("a/b") }
    }

    @Test func trashIsUndoable() throws {
        let store = makeStore()
        try store.save(entry("note-9", "Weg"))
        #expect(store.moveToTrash("note-9"))
        #expect(store.load("note-9") == nil)
        #expect(store.restoreFromTrash("note-9")?.title == "Weg")
        #expect(!store.moveToTrash("note-9x"))
    }

    @Test func trashListsDeletesForeverAndPurgesOldFiles() throws {
        let store = makeStore()
        try store.save(entry("note-1", "Alt"))
        try store.save(entry("note-2", "Neu"))
        #expect(store.moveToTrash("note-1"))
        try files.moveItem(
            at: store.trashDir.appendingPathComponent(TrashRules.fileName(now, id: "note-1")),
            to: store.trashDir.appendingPathComponent(TrashRules.fileName(now.addingTimeInterval(-31 * 86_400), id: "note-1"))
        )
        #expect(store.moveToTrash("note-2"))
        let listed = store.listTrash()
        #expect(listed.map(\.entry.id) == ["note-2", "note-1"])
        #expect(listed[0].entry.title == "Neu")
        #expect(listed[0].deletedAt == now)
        #expect(store.purgeTrash(now: now) == ["note-1"])
        #expect(store.listTrash().map(\.entry.id) == ["note-2"])
        #expect(store.deleteFromTrash("note-2"))
        #expect(!store.deleteFromTrash("note-2"))
        #expect(store.listTrash().isEmpty)
        #expect(store.restoreFromTrash("note-2") == nil)
    }
}

struct SecureIdsTests {
    @Test func idsAreValidAndUnique() {
        let generator = SecureIds()
        let ids = (1...500).map { _ in generator.next() }
        #expect(ids.allSatisfy { EntryCodec.isValidId($0) && $0.count == 20 })
        #expect(Set(ids).count == 500)
    }
}

struct TrashRulesTests {
    private let deleted = at("2026-10-01T10:00:00Z")

    @Test func expiresAfterThirtyDays() {
        #expect(!TrashRules.isExpired(deleted, now: deleted.addingTimeInterval(29 * 86_400)))
        #expect(TrashRules.isExpired(deleted, now: deleted.addingTimeInterval(30 * 86_400)))
        #expect(TrashRules.daysLeft(deleted, now: deleted) == 30)
        #expect(TrashRules.daysLeft(deleted, now: deleted.addingTimeInterval(29 * 86_400 + 3_600)) == 1)
        #expect(TrashRules.daysLeft(deleted, now: deleted.addingTimeInterval(31 * 86_400)) == 0)
    }

    @Test func fileNamesRoundTrip() throws {
        let name = TrashRules.fileName(deleted, id: "note-7")
        let parsed = try #require(TrashRules.parseFileName(name))
        #expect(parsed.0 == deleted)
        #expect(parsed.1 == "note-7")
        #expect(TrashRules.parseFileName("kaputt.md") == nil)
        #expect(TrashRules.parseFileName("123-note.txt") == nil)
        #expect(TrashRules.parseFileName("123-.md") == nil)
    }
}

@Suite struct StorageMoveTests {
    @Test func movesOldFolderWhenNewIsMissing() throws {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let old = base.appendingPathComponent("alt/paralist", isDirectory: true)
        let new = base.appendingPathComponent("gruppe/paralist", isDirectory: true)
        try FileManager.default.createDirectory(at: old.appendingPathComponent("eintraege"), withIntermediateDirectories: true)
        try "x".write(to: old.appendingPathComponent("eintraege/a.md"), atomically: true, encoding: .utf8)
        #expect(StorageMove.moveIfNeeded(from: old, to: new))
        #expect(FileManager.default.fileExists(atPath: new.appendingPathComponent("eintraege/a.md").path))
        #expect(!FileManager.default.fileExists(atPath: old.path))
        #expect(!StorageMove.moveIfNeeded(from: old, to: new))
        try? FileManager.default.removeItem(at: base)
    }

    @Test func keepsExistingNewFolder() throws {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let old = base.appendingPathComponent("alt", isDirectory: true)
        let new = base.appendingPathComponent("neu", isDirectory: true)
        try FileManager.default.createDirectory(at: old, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: new, withIntermediateDirectories: true)
        #expect(!StorageMove.moveIfNeeded(from: old, to: new))
        #expect(FileManager.default.fileExists(atPath: old.path))
        try? FileManager.default.removeItem(at: base)
    }

}
