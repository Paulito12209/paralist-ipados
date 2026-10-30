// Zusammenhang: Model/EntryChanges.swift, Model/Entry.swift, Model/EntryType.swift
import Foundation
import Testing
@testable import ParalistCore

struct EntryChangesTests {
    private let base = Entry("a-1", .bookmark, "Seite", epoch, epoch) {
        $0.url = "https://example.org"
        $0.places = ["p-1"]
        $0.body = "Text\n"
    }

    @Test func bookmarkToNoteKeepsLinkAndText() {
        let note = EntryChanges.withType(base, .note)
        #expect(note.type == .note)
        #expect(note.url == "https://example.org")
        #expect(note.body == "Text\n")
        #expect(note.places == ["p-1"])
        #expect(note.status == .open)
    }

    @Test func taskGetsOpenStatusAndLosesItAgain() {
        let task = EntryChanges.withType(base, .task).with { $0.due = Day(year: 2026, month: 10, day: 20) }
        #expect(task.status == .open)
        let event = EntryChanges.withType(task, .event)
        #expect(event.status == .open)
        #expect(event.due == nil)
        let tag = EntryChanges.withType(event, .tag)
        #expect(tag.status == nil)
    }

    @Test func containerDropsPlaces() {
        #expect(EntryChanges.withType(base, .project).places == [])
        #expect(EntryChanges.withType(base, .bookmark) == base)
    }

    @Test func linksToggleWithoutSelfOrDuplicates() {
        let linked = EntryChanges.withLink(base, "b-2", linked: true)
        #expect(linked.links == ["b-2"])
        #expect(EntryChanges.withLink(linked, "b-2", linked: true).links == ["b-2"])
        #expect(EntryChanges.withLink(base, "a-1", linked: true) == base)
        #expect(EntryChanges.withLink(linked, "b-2", linked: false).links == [])
    }

    @Test func withoutReferencesStripsLinksPlacesAndDeck() {
        let entry = base.with {
            $0.links = ["x-1", "x-2"]
            $0.places = ["p-1"]
            $0.deck = "d-1"
        }
        let cleaned = EntryChanges.withoutReferences(entry, ["x-2", "p-1", "d-1"])
        #expect(cleaned.links == ["x-1"])
        #expect(cleaned.places == [])
        #expect(cleaned.deck == nil)
        #expect(EntryChanges.withoutReferences(entry, ["nix"]) == entry)
    }
}

struct TaskStatusTests {
    @Test func readsAllKeys() {
        #expect(TaskStatus.fromKey("offen") == .open)
        #expect(TaskStatus.fromKey("laufend") == .inProgress)
        #expect(TaskStatus.fromKey("erledigt") == .done)
        #expect(TaskStatus.fromKey("fertig") == nil)
    }

    @Test func onlyDoneCountsAsDone() {
        let base = Entry("a", .task, "t", epoch, epoch)
        #expect(!base.with { $0.status = .inProgress }.isDone)
        #expect(base.with { $0.status = .done }.isDone)
    }

    @Test func everyTypeButTagHasStatus() {
        #expect(EntryType.allCases.filter { !$0.hasStatus } == [.tag])
        #expect(Set(EntryType.allCases.filter(\.hasDate)) == [.task, .event, .project])
    }
}
