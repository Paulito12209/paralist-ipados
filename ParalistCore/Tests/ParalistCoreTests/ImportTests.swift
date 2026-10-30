// Zusammenhang: Sources/ParalistCore/Backup/ImportPlanner.swift, Sources/ParalistCore/Backup/ImportApplier.swift, Sources/ParalistCore/Backup/BackupWriter.swift, ZipFixtures.swift
import Foundation
import Testing
@testable import ParalistCore

struct ImportTests {
    private let now = at("2026-10-16T12:00:00Z")

    private func world() -> (EntryStore, ReviewLog) {
        let root = temporaryDirectory()
        return (EntryStore(root: root, clock: FixedClock(now)), ReviewLog(root: root))
    }

    private func plan(_ store: EntryStore, _ log: ReviewLog, _ zip: URL) throws -> ImportPlan {
        let staged = try SafeUnzip.extract(zip, to: temporaryDirectory().appendingPathComponent("st"))
        return try ImportPlanner(store: store, reviews: log) { data, _ in data }.plan(staged, now: now)
    }

    private func applier(_ store: EntryStore, _ log: ReviewLog, _ hook: @escaping () throws -> Void = {}) -> ImportApplier {
        ImportApplier(store: store, reviews: log, safetyDir: temporaryDirectory(), beforeEachWrite: hook)
    }

    @Test func newerWinsOlderIsIgnoredAndNothingIsDeleted() throws {
        let (store, log) = world()
        try store.write(Entry("same-1", .note, "Lokal alt", now.addingTimeInterval(-9_000_000), at("2026-10-05T10:00:00Z")))
        try store.write(Entry("keep-1", .note, "Lokal neu", now.addingTimeInterval(-9_000_000), at("2026-10-15T10:00:00Z")))
        try store.write(Entry("only-1", .note, "Nur lokal", now, now))
        let zip = ZipFixtures.zip([
            ZipFixtures.entry("same-1", "Import neuer"),
            ZipFixtures.entry("keep-1", "Import älter"),
            ZipFixtures.entry("new-1", "Ganz neu"),
            ("eintraege/bad-1.md", Data("---\nid: bad-1\ntyp: virus\n---\n".utf8)),
        ])
        let p = try plan(store, log, zip)
        #expect(p.entriesTotal == 4)
        #expect(p.newEntries == 1)
        #expect(p.updatedEntries == 1)
        #expect(p.unchangedEntries == 1)
        #expect(p.broken.map(\.name) == ["bad-1.md"])
        _ = try applier(store, log).apply(p, now: now)
        #expect(store.load("same-1")?.title == "Import neuer")
        #expect(store.load("keep-1")?.title == "Lokal neu")
        #expect(store.load("new-1")?.title == "Ganz neu")
        #expect(store.load("only-1")?.title == "Nur lokal")
        #expect(!store.exists("bad-1"))
    }

    @Test func executablesDisguisedAsImagesAreNeverStored() throws {
        let (store, log) = world()
        let apk = Data([0x50, 0x4B, 0x03, 0x04] + [UInt8](repeating: 0, count: 100))
        let apkHash = SHA256.hex(apk)
        let html = Data("<html><script>alert(1)</script>".utf8)
        let png = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A] + [UInt8](repeating: 0, count: 32))
        let zip = ZipFixtures.zip([
            ("anhaenge/\(apkHash)", apk),
            ("anhaenge/\(SHA256.hex(html))", html),
            ("anhaenge/\(SHA256.hex(png))", png),
            ZipFixtures.entry("file-1", "urlaub.jpg", extra: "anhang_hash: \(apkHash)\nanhang_name: urlaub.jpg\nanhang_typ: image/jpeg\n"),
        ])
        let p = try plan(store, log, zip)
        #expect(p.attachmentsRejected == 2)
        #expect(p.attachmentsToAdd.count == 1)
        #expect(p.imagesTotal == 1)
        #expect(p.toWrite.count == 1)
        #expect(p.toWrite.first?.attachment == nil)
        _ = try applier(store, log).apply(p, now: now)
        #expect(store.attachmentFile(apkHash) == nil)
        let stored = try FileManager.default.contentsOfDirectory(atPath: store.attachmentsDir.path).filter { !$0.hasPrefix(".") }
        #expect(stored.count == 1)
    }

    @Test func exportImportRoundTripMergesReviewsAndCountsDuplicates() throws {
        let (source, sourceLog) = world()
        let png = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A] + [UInt8](repeating: 0, count: 16))
        let hash = SHA256.hex(png)
        try png.write(to: source.attachmentsDir.appendingPathComponent(hash))
        try source.write(Entry("card-1", .flashcard, "hola", now, now) { $0.body = "hallo\n" })
        try sourceLog.append(ReviewEvent(cardId: "card-1", at: now.addingTimeInterval(-86_400), rating: .good))
        let zip = temporaryDirectory().appendingPathComponent("export.paralist")
        let stats = try BackupWriter.write(store: source, reviews: sourceLog, to: zip, now: now)
        #expect(stats == ExportStats(entries: 1, attachments: 1, reviewLogs: 1, chats: 0))
        let (target, targetLog) = world()
        try png.write(to: target.attachmentsDir.appendingPathComponent(hash))
        try targetLog.append(ReviewEvent(cardId: "card-1", at: now.addingTimeInterval(-3_600), rating: .again))
        let p = try plan(target, targetLog, zip)
        #expect(p.attachmentsPresent == 1)
        #expect(p.attachmentsToAdd.isEmpty)
        let result = try applier(target, targetLog).apply(p, now: now)
        #expect(FileManager.default.fileExists(atPath: result.safetyCopy.path))
        #expect(target.load("card-1")?.title == "hola")
        #expect(targetLog.read("card-1", now: now).count == 2)
    }

    @Test func failureRollsBackEverything() throws {
        let (store, log) = world()
        try store.write(Entry("same-1", .note, "Original", now, at("2026-10-01T10:00:00Z")))
        let zip = ZipFixtures.zip([
            ZipFixtures.entry("same-1", "Überschrieben", updated: "2026-10-12T10:00:00Z"),
            ZipFixtures.entry("new-1", "Neu"),
            ZipFixtures.entry("new-2", "Neu 2"),
        ])
        let p = try plan(store, log, zip)
        var writes = 0
        struct Full: Error {}
        #expect(throws: Full.self) {
            _ = try applier(store, log) {
                writes += 1
                if writes == 3 { throw Full() }
            }.apply(p, now: now)
        }
        #expect(store.load("same-1")?.title == "Original")
        #expect(!store.exists("new-1"))
        #expect(!store.exists("new-2"))
    }

    @Test func importedPastRemindersNeverFire() throws {
        let (store, log) = world()
        let past = (1...500).map { "  - \(Instants.format(now.addingTimeInterval(-Double($0) * 3_600)))\n" }.joined()
        let p = try plan(store, log, ZipFixtures.zip([ZipFixtures.entry("rem-1", "Alt", extra: "erinnerungen:\n\(past)")]))
        _ = try applier(store, log).apply(p, now: now)
        let entry = try #require(store.load("rem-1"))
        #expect(entry.reminders.count == 500)
        #expect(ReminderPlanner.plan(entry, now: now, zone: berlin).isEmpty)
    }
}
