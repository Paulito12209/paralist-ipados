// Zusammenhang: Sources/ParalistCore/Library/LinkPicker.swift, TestSupport.swift
import Foundation
import Testing
@testable import ParalistCore

struct LinkPickerTests {
    @Test func tabsNeverShowOwnCategory() {
        #expect(!LinkPicker.tabs(for: .area).contains(.areas))
        #expect(LinkPicker.tabs(for: .area).contains(.projects))
        #expect(!LinkPicker.tabs(for: .project).contains(.projects))
        #expect(LinkPicker.tabs(for: .project).contains(.areas))
        #expect(LinkPicker.tabs(for: .bookmark).contains(.resources))
    }

    @Test func tabsFollowFixedOrderWithoutOwnCategory() {
        #expect(LinkPicker.tabs(for: .note) == [.areas, .projects, .tags, .tasks, .events, .resources, .decks, .flashcards])
        #expect(LinkPicker.tabs(for: .flashcard) == [.areas, .projects, .tags, .tasks, .notes, .events, .resources, .decks])
        #expect(LinkPicker.tabs(for: .deck) == [.areas, .projects, .tags, .tasks, .notes, .events, .resources, .flashcards])
        #expect(LinkPicker.tabs(for: .tag) == LinkTab.allCases)
        #expect(LinkPicker.tabs(for: .file).contains(.resources))
    }

    @Test func flashcardSeesDecksButNoOtherCards() {
        let card = Entry("k", .flashcard, "Vorderseite", epoch, epoch)
        let all = [
            card,
            Entry("o", .flashcard, "Andere Karte", epoch, epoch),
            Entry("d", .deck, "Französisch", epoch, epoch),
            Entry("n", .note, "Notiz", epoch, epoch),
        ]
        #expect(LinkPicker.entries(.decks, for: card, in: all).map(\.id) == ["d"])
        #expect(LinkPicker.entries(.flashcards, for: card, in: all).isEmpty)
        #expect(Set(LinkPicker.suggestions(for: card, in: all).map(\.id)) == ["d", "n"])
        let deck = all[2]
        #expect(LinkPicker.entries(.flashcards, for: deck, in: all).map(\.id).sorted() == ["k", "o"])
        #expect(LinkPicker.entries(.decks, for: deck, in: all).isEmpty)
    }

    @Test func tagsMayLinkTags() {
        let tag = Entry("t", .tag, "Familie", epoch, epoch)
        let all = [tag, Entry("u", .tag, "Freunde", epoch, epoch)]
        #expect(LinkPicker.entries(.tags, for: tag, in: all).map(\.id) == ["u"])
    }

    @Test func entriesSkipSelfOwnTypeAndArchived() {
        let me = Entry("a", .bookmark, "Mein Link", epoch, epoch)
        let all = [
            me,
            Entry("b", .bookmark, "Anderer Link", epoch, epoch),
            Entry("c", .file, "Datei", epoch, epoch),
            Entry("d", .document, "Alt", epoch, epoch) { $0.archived = true },
        ]
        #expect(LinkPicker.entries(.resources, for: me, in: all).map(\.id) == ["c"])
    }

    @Test func suggestionsPreferSharedWordsAndPlaces() {
        let me = Entry("p", .project, "Paralist Release", epoch, epoch) { $0.places = ["area"] }
        let all = [
            me,
            Entry("x", .task, "Einkaufen", epoch, Date(timeIntervalSince1970: 50)),
            Entry("y", .task, "Release vorbereiten", epoch, epoch),
            Entry("z", .note, "Idee", epoch, epoch) { $0.places = ["area"] },
            Entry("q", .project, "Paralist Release zwei", epoch, epoch),
        ]
        let ids = LinkPicker.suggestions(for: me, in: all).map(\.id)
        #expect(ids == ["z", "y", "x"])
    }

    @Test func suggestionsRespectLimit() {
        let me = Entry("n", .note, "Notiz", epoch, epoch)
        let all = [me] + (0..<20).map { Entry("t\($0)", .task, "Aufgabe \($0)", epoch, epoch) }
        #expect(LinkPicker.suggestions(for: me, in: all, limit: 5).count == 5)
    }

    @Test func searchCoversAllTabsOrOne() {
        let me = Entry("m", .bookmark, "Stelle", epoch, epoch)
        let all = [
            me,
            Entry("a", .tag, "Jobsuche", epoch, epoch),
            Entry("b", .project, "Jobsuche 2026", epoch, Date(timeIntervalSince1970: 50)),
            Entry("c", .note, "Einkauf", epoch, epoch),
            Entry("d", .tag, "Jobs alt", epoch, epoch) { $0.archived = true },
        ]
        #expect(LinkPicker.matching("job", tabs: LinkPicker.tabs(for: .bookmark), for: me, in: all).map(\.id) == ["b", "a"])
        #expect(LinkPicker.matching("job", tabs: [.tags], for: me, in: all).map(\.id) == ["a"])
        #expect(LinkPicker.matching("  ", tabs: [.tags], for: me, in: all).isEmpty)
    }

    @Test func onlyPlainTabsOfferCreating() {
        #expect(LinkTab.tags.creates == .tag)
        #expect(LinkTab.projects.creates == .project)
        #expect(LinkTab.decks.creates == .deck)
        #expect(LinkTab.events.creates == nil)
        #expect(LinkTab.resources.creates == nil)
    }
}
