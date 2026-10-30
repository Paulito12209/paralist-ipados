// Zusammenhang: Sources/ParalistCore/Library/LinkPlace.swift, Sources/ParalistCore/Library/EntryLibrary.swift (setLinked, dropPlaceLinks), Sources/ParalistCore/Library/PlacePicker.swift
import Foundation
import Testing
@testable import ParalistCore

final class LinkPlaceTests {
    private let root = temporaryDirectory()
    private let clock = StepClock(at("2026-10-23T12:00:00Z"))

    deinit { try? FileManager.default.removeItem(at: root) }

    private func makeLibrary() -> EntryLibrary {
        EntryLibrary(root: root, ids: CountingIds("lp"), clock: clock)
    }

    private func entry(_ id: String, _ type: EntryType) -> Entry {
        Entry(id: id, type: type, title: id, created: at("2026-10-20T12:00:00Z"), updated: at("2026-10-20T12:00:00Z"))
    }

    @Test func linkingNeverMovesAnEntry() throws {
        let library = makeLibrary()
        let project = try library.save(library.newEntry(.project, title: "Umzug"))
        let task = try library.save(library.newEntry(.task, title: "Kartons"))
        try library.setLinked(task.id, project.id, linked: true)
        #expect(library.entry(task.id)?.places == [])
        #expect(library.entry(task.id)?.links == [project.id])
        #expect(library.entry(project.id)?.links == [task.id])
        #expect(library.list(.inbox).map(\.id) == [task.id])
        #expect(library.inPlace(project.id).isEmpty)
    }

    @Test func linkingFlashcardToDeckSetsDeck() throws {
        let library = makeLibrary()
        let deck = try library.save(library.newEntry(.deck, title: "Französisch"))
        let card = try library.save(library.newEntry(.flashcard, title: "le chat"))
        try library.setLinked(deck.id, card.id, linked: true)
        #expect(library.entry(card.id)?.deck == deck.id)
        #expect(library.entry(deck.id)?.deck == nil)
        #expect(library.inDeck(deck.id).map(\.id) == [card.id])
    }

    @Test func existingDeckStaysAndOnlyDecksCount() {
        var card = entry("card-a", .flashcard)
        card.deck = "deck-a"
        #expect(LinkPlace.adopted(card, linkedTo: entry("deck-b", .deck)).deck == "deck-a")
        #expect(LinkPlace.deck(for: .flashcard, linkedTo: entry("note-a", .note)) == nil)
        #expect(LinkPlace.deck(for: .note, linkedTo: entry("deck-b", .deck)) == nil)
        var archived = entry("deck-c", .deck)
        archived.archived = true
        #expect(LinkPlace.deck(for: .flashcard, linkedTo: archived) == nil)
    }

    @Test func linkableLeavesOutOwnerAndOwnEntries() {
        var task = entry("task-a", .task)
        task.places = ["proj-a"]
        var note = entry("note-a", .note)
        note.places = ["task-a"]
        let other = entry("note-b", .note)
        let project = entry("proj-a", .project)
        #expect(LinkPlace.linkable(for: task, in: [task, note, other, project]).map(\.id) == ["task-a", "note-b"])
    }

    @Test func repairDropsLinksToTheOwnerOnBothSides() throws {
        var task = entry("task-a", .task)
        task.places = ["proj-a"]
        task.links = ["proj-a", "note-a"]
        var project = entry("proj-a", .project)
        project.links = ["task-a"]
        var note = entry("note-a", .note)
        note.links = ["task-a"]
        var oneSided = entry("task-b", .task)
        oneSided.places = ["proj-b"]
        var other = entry("proj-b", .project)
        other.links = ["task-b"]
        let clean = entry("task-c", .task)
        let fixed = LinkPlace.repaired([task, project, note, oneSided, other, clean])
        #expect(fixed.map(\.id) == ["task-a", "proj-a", "proj-b"])
        #expect(fixed[0].links == ["note-a"])
        #expect(fixed[0].places == ["proj-a"])
        #expect(fixed[1].links == [])
        #expect(fixed[2].links == [])

        let library = makeLibrary()
        for e in [task, project, note] { try library.store.write(e) }
        library.rebuild()
        #expect(library.dropPlaceLinks() == 2)
        #expect(library.entry("task-a")?.links == ["note-a"])
        #expect(library.entry("task-a")?.updated == task.updated)
        #expect(library.entry("note-a")?.links == ["task-a"])
        #expect(library.dropPlaceLinks() == 0)
    }
}
