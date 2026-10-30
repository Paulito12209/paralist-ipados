// Zusammenhang: Library/EntryLibrary.swift, Library/ListKind.swift, Library/Usage.swift, Store/EntryStore.swift, Flashcards/ReviewLog.swift
import Foundation
import Testing
@testable import ParalistCore

final class EntryLibraryTests {
    private let root = temporaryDirectory()
    private let clock = StepClock(at("2026-10-16T12:00:00Z"))

    deinit { try? FileManager.default.removeItem(at: root) }

    private func makeLibrary(_ prefix: String = "id") -> EntryLibrary {
        EntryLibrary(root: root, ids: CountingIds(prefix), clock: clock)
    }

    @Test func inboxHoldsUnplacedNonContainers() throws {
        let t0 = at("2026-10-16T10:00:00Z")
        func entry(_ id: String, _ type: EntryType, places: [String] = [], pinned: Bool = false, age: Double = 0) -> Entry {
            Entry(id, type, id, t0, t0.addingTimeInterval(-age)) {
                $0.places = places
                $0.pinned = pinned
            }
        }
        let library = makeLibrary()
        for e in [
            entry("task-1", .task),
            entry("note-1", .note, places: ["proj-1"]),
            entry("proj-1", .project),
            entry("note-2", .note, pinned: true, age: 100),
            entry("link-1", .bookmark, age: 10),
        ] {
            try library.store.write(e)
        }
        library.rebuild()
        #expect(library.list(.inbox).map(\.id) == ["note-2", "task-1", "link-1"])
        #expect(library.containers.map(\.id) == ["proj-1"])
    }

    @Test func entryCreatedFromLinksIsLinkedBothWays() throws {
        let library = makeLibrary()
        let project = try library.save(library.newEntry(.project, title: "Projekt"))
        var draft = ComposerDraft(type: .note)
        draft.title = "Notiz"
        draft.link = project.id
        let built = draft.build(library.newEntry(.note, title: ""), zone: .current)
        let note = try library.save(#require(built))
        try library.setLinked(note.id, project.id, linked: true)
        #expect(library.entry(note.id)?.links == [project.id])
        #expect(library.entry(project.id)?.links == [note.id])
    }

    @Test func savedEntriesAppearInInboxAndSearch() throws {
        let library = makeLibrary()
        let project = try library.save(library.newEntry(.project, title: "Umzug"))
        try library.save(library.newEntry(.task, title: "Kartons kaufen"))
        try library.save(library.newEntry(.note, title: "Adresse").with { $0.places = [project.id] })
        #expect(library.list(.inbox).map(\.title) == ["Kartons kaufen"])
        #expect(library.containers.map(\.title) == ["Umzug"])
        #expect(library.search("karton").map(\.title) == ["Kartons kaufen"])
    }

    @Test func indexRebuildsFromFiles() throws {
        let first = makeLibrary()
        try first.save(first.newEntry(.task, title: "A"))
        try first.save(first.newEntry(.task, title: "B"))
        let second = makeLibrary()
        #expect(second.all.isEmpty)
        #expect(second.rebuild() == 2)
        #expect(second.byType(.task).count == 2)
    }

    @Test func doneToggleAndTrashUpdateIndex() throws {
        let library = makeLibrary()
        let task = try library.save(library.newEntry(.task, title: "Erledigen"))
        #expect(try library.setDone(task.id, true)?.status?.key == "erledigt")
        #expect(library.entry(task.id)?.status == .done)
        #expect(library.moveToTrash(task.id))
        #expect(library.all.isEmpty)
        #expect(library.trash().map(\.entry.id) == [task.id])
        #expect(library.restore(task.id)?.title == "Erledigen")
        #expect(library.all.count == 1)
    }

    @Test func usageAndSearchesAreRecorded() throws {
        let library = makeLibrary()
        let a = try library.save(library.newEntry(.note, title: "Alpha"))
        let b = try library.save(library.newEntry(.note, title: "Beta"))
        library.recordOpened(a.id)
        library.recordOpened(b.id)
        library.recordOpened(a.id)
        #expect(library.usage.recent.map(\.id) == [a.id, b.id])
        library.recordSearch("  alpha   beta ")
        library.recordSearch("x")
        #expect(library.usage.recentSearches.map(\.query) == ["x", "alpha beta"])
        library.forgetSearch("x")
        #expect(library.usage.recentSearches.map(\.query) == ["alpha beta"])
        #expect(library.search("alp").map(\.title) == ["Alpha"])
        #expect(library.search("alp OR drop table").isEmpty)
        let reloaded = makeLibrary()
        #expect(reloaded.usage.recent.map(\.id) == [a.id, b.id])
    }

    @Test func reviewsUpdateStateAndSurviveRebuild() throws {
        let library = makeLibrary("card")
        let deck = try library.save(library.newEntry(.deck, title: "Spanisch"))
        let card = try library.save(library.newEntry(.flashcard, title: "hola").with {
            $0.deck = deck.id
            $0.body = "hallo\n"
        })
        #expect(library.candidates(deck: deck.id).map(\.state.phase) == [.new])
        let state = try #require(try library.review(card.id, .good))
        #expect(state.reps == 1)
        #expect(library.cardStates[card.id]?.phase == .review)
        let rebuilt = makeLibrary("card")
        rebuilt.rebuild()
        #expect(rebuilt.cardStates[card.id]?.reps == 1)
        #expect(rebuilt.candidates(deck: deck.id).count == 1)
        #expect(rebuilt.reviewEvents[card.id]?.count == 1)
    }

    @Test func pinnedAndFavoriteListsSplitMarkedEntries() throws {
        let pinned = Entry("p", .note, "P", at("2026-10-16T12:00:00Z"), at("2026-10-16T12:00:00Z")) { $0.pinned = true }
        let favorite = Entry("f", .note, "F", at("2026-10-16T12:00:00Z"), at("2026-10-16T12:00:00Z")) { $0.favorite = true }
        let archived = Entry("a", .note, "A", at("2026-10-16T12:00:00Z"), at("2026-10-16T12:00:00Z")) { $0.pinned = true; $0.archived = true }
        #expect(ListKind.pinned.includes(pinned) && !ListKind.pinned.includes(favorite) && !ListKind.pinned.includes(archived))
        #expect(ListKind.favorites.includes(favorite) && !ListKind.favorites.includes(pinned))
        #expect(ListKind.marked.includes(pinned) && ListKind.marked.includes(favorite))
    }
}
