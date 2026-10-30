// Zusammenhang: Library/PinLimit.swift, Library/EntryLibrary.swift, TestSupport.swift
import Foundation
import Testing
@testable import ParalistCore

struct PinLimitTests {
    private let t0 = at("2026-10-16T10:00:00Z")

    private func entry(_ id: String, _ type: EntryType = .note, places: [String] = [], pinned: Bool = true, age: Double = 0, archived: Bool = false) -> Entry {
        Entry(id, type, id, t0, t0.addingTimeInterval(-age)) {
            $0.places = places
            $0.pinned = pinned
            $0.archived = archived
        }
    }

    @Test func clampsToRange() {
        #expect(PinLimit.clamp(0) == 1)
        #expect(PinLimit.clamp(2) == 2)
        #expect(PinLimit.clamp(9) == 3)
        #expect(PinLimit.standard == 1)
    }

    @Test func oldestPinInSamePlaceIsDisplaced() {
        let all = [entry("a", places: ["p"], age: 50), entry("b", places: ["p"], age: 10), entry("c", places: ["q"], age: 90)]
        let new = entry("n", places: ["p"])
        #expect(PinLimit.displaced(by: new, among: all + [new], limit: 1) == ["a", "b"])
        #expect(PinLimit.displaced(by: new, among: all + [new], limit: 2) == ["a"])
        #expect(PinLimit.displaced(by: new, among: all + [new], limit: 3).isEmpty)
    }

    @Test func inboxAndContainerListsCountSeparately() {
        let all = [entry("i", age: 5), entry("proj", .project, age: 5), entry("area", .area, age: 5)]
        #expect(PinLimit.displaced(by: entry("n"), among: all, limit: 1) == ["i"])
        #expect(PinLimit.displaced(by: entry("p2", .project), among: all, limit: 1) == ["proj"])
    }

    @Test func ignoresUnpinnedArchivedAndSelf() {
        let all = [entry("a", places: ["p"], pinned: false), entry("b", places: ["p"], archived: true), entry("n", places: ["p"])]
        #expect(PinLimit.displaced(by: entry("n", places: ["p"]), among: all, limit: 1).isEmpty)
        #expect(PinLimit.displaced(by: entry("n", places: ["p"], pinned: false), among: [entry("a", places: ["p"])], limit: 1).isEmpty)
    }

    @Test func everyPlaceOfTheEntryIsChecked() {
        let all = [entry("a", places: ["p"], age: 5), entry("b", places: ["q"], age: 5), entry("c", places: ["p", "q"], age: 1)]
        #expect(PinLimit.displaced(by: entry("n", places: ["p", "q"]), among: all, limit: 1) == ["a", "c", "b"])
    }

    @Test func libraryUnpinsWithoutTouchingTimestamps() throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let library = EntryLibrary(root: root, ids: CountingIds("id"), clock: StepClock(at("2026-10-16T12:00:00Z")))
        let old = entry("note-old", places: ["proj-p"], age: 100)
        try library.store.write(old)
        library.rebuild()
        let fresh = try library.save(entry("note-new", places: ["proj-p"]))
        let released = library.enforcePinLimit(for: fresh, limit: 1)
        #expect(released.map(\.id) == ["note-old"])
        #expect(library.entry("note-old")?.pinned == false)
        #expect(library.entry("note-old")?.updated == old.updated)
        #expect(library.store.load("note-old")?.pinned == false)
        #expect(library.entry("note-new")?.pinned == true)
    }
}
