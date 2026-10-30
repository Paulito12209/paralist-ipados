// Zusammenhang: Sources/ParalistCore/Library/ComposerDraft.swift
import Foundation
import Testing
@testable import ParalistCore

struct ComposerDraftTests {
    private let zone = TimeZone(identifier: "Europe/Berlin")!
    private let base = Entry(id: "abcd-1234", type: .note, title: "", created: Date(timeIntervalSince1970: 1_790_000_000), updated: Date(timeIntervalSince1970: 1_790_000_000))

    @Test func normalizesUrls() {
        #expect(ComposerDraft.normalizeUrl(" example.org/x ") == "https://example.org/x")
        #expect(ComposerDraft.normalizeUrl("http://a.de") == "http://a.de")
        #expect(ComposerDraft.normalizeUrl("ftp://a.de") == nil)
        #expect(ComposerDraft.normalizeUrl("a b.de") == nil)
        #expect(ComposerDraft.normalizeUrl("") == nil)
        #expect(ComposerDraft.hostOf("https://www.youtube.com/watch?v=x") == "youtube.com")
    }

    @Test func bookmarkFallsBackToHostAsTitle() {
        var draft = ComposerDraft(type: .bookmark)
        draft.url = "youtu.be/dQw4w9WgXcQ"
        draft.confirmUrl()
        #expect(draft.urlConfirmed)
        let entry = draft.build(base, zone: zone)
        #expect(entry?.title == "youtu.be")
        #expect(entry?.url == "https://youtu.be/dQw4w9WgXcQ")
        #expect(entry?.type == .bookmark)
    }

    @Test func invalidBookmarkUrlBlocksSaving() {
        var draft = ComposerDraft(type: .bookmark)
        draft.url = "zwei wörter.de"
        draft.confirmUrl()
        #expect(draft.urlError)
        #expect(draft.build(base, zone: zone) == nil)
    }

    @Test func eventGetsTimesAndOffsetReminder() {
        var draft = ComposerDraft(type: .event)
        draft.title = "Termin"
        draft.date = Day(year: 2026, month: 10, day: 20)
        draft.minute = 14 * 60
        let entry = draft.build(base, zone: zone)!
        #expect(entry.start == Instants.parse("2026-10-20T12:00:00Z"))
        #expect(entry.end == Instants.parse("2026-10-20T13:00:00Z"))
        #expect(!entry.allDay)
        #expect(entry.reminders == [Instants.parse("2026-10-20T11:45:00Z")!])
        #expect(entry.status == .open)
    }

    @Test func allDayEventAndTaskDue() {
        var event = ComposerDraft(type: .event)
        event.date = Day(year: 2026, month: 10, day: 20)
        event.eventOffset = .none
        let e = event.build(base, zone: zone)!
        #expect(e.allDay)
        #expect(e.end == nil)
        #expect(e.reminders.isEmpty)
        var task = ComposerDraft(type: .task)
        task.date = Day(year: 2026, month: 10, day: 21)
        task.body = "Text  \n\n"
        task.showBody = true
        let t = task.build(base, zone: zone)!
        #expect(t.due == Day(year: 2026, month: 10, day: 21))
        #expect(t.start == nil)
        #expect(t.body == "Text\n")
    }

    @Test func bodyFieldOpensOnlyOnRequestExceptForFlashcards() {
        for type in EntryType.allCases where type != .flashcard {
            #expect(!ComposerDraft(type: type).showsBody)
        }
        #expect(ComposerDraft(type: .flashcard).showsBody)
        var document = ComposerDraft(type: .document)
        document.showBody = true
        #expect(document.showsBody)
    }

    @Test func newEntryCarriesTheLinkToItsOrigin() {
        var draft = ComposerDraft(type: .task)
        draft.title = "Neu"
        draft.link = "proj-1"
        #expect(draft.build(base, zone: zone)?.links == ["proj-1"])
        draft.link = base.id
        #expect(draft.build(base, zone: zone)?.links == [])
        draft.link = nil
        #expect(draft.build(base, zone: zone)?.links == [])
    }

    @Test func flashcardLinkedToDeckBecomesDeckCard() {
        let deck = Entry(id: "deck-1", type: .deck, title: "Französisch", created: base.created, updated: base.updated)
        var draft = ComposerDraft(type: .flashcard)
        draft.title = "le chat"
        draft.body = "die Katze"
        draft.linkTo(deck)
        let card = draft.build(base, zone: zone)
        #expect(card?.type == .flashcard)
        #expect(card?.deck == "deck-1")
        #expect(card?.links == [])
        #expect(card?.places == [])
        #expect(card?.body == "die Katze\n")
        draft.linkTo(nil)
        #expect(draft.build(base, zone: zone)?.deck == nil)
        draft.linkTo(deck)
        draft.type = .note
        #expect(draft.build(base, zone: zone)?.deck == nil)
    }

    @Test func newEntryFromDetailPageBelongsToItsOrigin() {
        let project = Entry(id: "proj-1", type: .project, title: "Umzug", created: base.created, updated: base.updated)
        let note = Entry(id: "note-1", type: .note, title: "Notiz", created: base.created, updated: base.updated)
        let task = Entry(id: "task-1", type: .task, title: "Kartons", created: base.created, updated: base.updated)
        var draft = ComposerDraft(type: .task)
        draft.title = "Neu"
        draft.linkTo(project)
        #expect(draft.places == ["proj-1"])
        #expect(draft.link == nil)
        #expect(draft.target == "proj-1")
        #expect(draft.deck == nil)
        #expect(draft.build(base, zone: zone)?.places == ["proj-1"])
        #expect(draft.build(base, zone: zone)?.links == [])
        draft.linkTo(note)
        #expect(draft.places == ["note-1"])
        #expect(draft.link == nil)
        var sub = ComposerDraft(type: .project)
        sub.linkTo(task)
        #expect(sub.places == [])
        #expect(sub.link == "task-1")
        #expect(sub.target == nil)
        var area = ComposerDraft(type: .area)
        area.linkTo(project)
        #expect(area.places == [])
        #expect(area.link == "proj-1")
    }

    @Test func pickKeepsTheOriginLink() {
        let task = Entry(id: "task-1", type: .task, title: "Kartons", created: base.created, updated: base.updated)
        let area = Entry(id: "area-1", type: .area, title: "Wohnen", created: base.created, updated: base.updated)
        var draft = ComposerDraft(type: .project)
        draft.linkTo(task)
        draft.pick(area)
        #expect(draft.places == ["area-1"])
        #expect(draft.link == "task-1")
    }

    @Test func linksNeverHoldThePlace() {
        let tag = Entry(id: "tag-1", type: .tag, title: "Jobs", created: base.created, updated: base.updated)
        let note = Entry(id: "note-1", type: .note, title: "Idee", created: base.created, updated: base.updated)
        var old = note
        old.id = "note-2"
        old.archived = true
        var draft = ComposerDraft(type: .bookmark)
        draft.toggleLink("tag-1")
        draft.toggleLink("note-1")
        #expect(draft.links == ["tag-1", "note-1"])
        draft.pick(tag)
        #expect(draft.links == ["note-1"])
        draft.toggleLink("tag-1")
        #expect(draft.links == ["note-1"])
        #expect(draft.linkable(in: [tag, note, old]).map(\.id) == ["note-1"])
        draft.toggleLink("note-1")
        #expect(draft.links.isEmpty)
    }

    @Test func pickSetsOneOwnerOfAnyKind() {
        let project = Entry(id: "proj-1", type: .project, title: "Umzug", created: base.created, updated: base.updated)
        let tag = Entry(id: "tag-1", type: .tag, title: "Wichtig", created: base.created, updated: base.updated)
        let deck = Entry(id: "deck-1", type: .deck, title: "Französisch", created: base.created, updated: base.updated)
        var draft = ComposerDraft(type: .task)
        draft.pick(project)
        #expect(draft.places == ["proj-1"])
        #expect(draft.link == nil)
        #expect(draft.target == "proj-1")
        draft.pick(tag)
        #expect(draft.places == ["tag-1"])
        #expect(draft.link == nil)
        #expect(draft.isPicked("tag-1"))
        #expect(!draft.isPicked("proj-1"))
        #expect(draft.build(base, zone: zone)?.places == ["tag-1"])
        #expect(draft.build(base, zone: zone)?.links == [])
        draft.pick(tag)
        #expect(draft.target == nil)
        draft.type = .flashcard
        draft.chooseDeck("deck-1")
        draft.pick(deck)
        #expect(draft.target == nil)
        draft.pick(project)
        #expect(draft.places == ["proj-1"])
        #expect(draft.deck == "deck-1")
        let card = draft.build(base, zone: zone)
        #expect(card?.deck == "deck-1")
        #expect(card?.places == ["proj-1"])
        draft.pick(nil)
        #expect(draft.target == nil)
        #expect(draft.deck == "deck-1")
        draft.chooseDeck("deck-1")
        #expect(draft.deck == nil)
    }

    @Test func dateRowOpensWithTodayAndTaskTimeBecomesDueTime() {
        let now = Day(year: 2026, month: 10, day: 25).at(hour: 9, minute: 30, in: zone)
        var draft = ComposerDraft(type: .task)
        draft.title = "Anrufen"
        draft.openDate(now: now, zone: zone)
        #expect(draft.date == Day(year: 2026, month: 10, day: 25))
        #expect(draft.minute == nil)
        #expect(ComposerDraft.nextHour(now, zone: zone) == 600)
        draft.setTime(Day(year: 2026, month: 10, day: 25).at(hour: 10, in: zone), zone: zone)
        #expect(draft.minute == 600)
        let task = draft.build(base, zone: zone)
        #expect(task?.due == Day(year: 2026, month: 10, day: 25))
        #expect(task?.dueTime == DueTime(hour: 10, minute: 0))
        draft.setTime(nil, zone: zone)
        #expect(draft.build(base, zone: zone)?.dueTime == nil)
        draft.clearDate()
        #expect(draft.date == nil)
        #expect(draft.build(base, zone: zone)?.due == nil)
    }

    @Test func eventTimesKeepTheirLengthWhenMoved() {
        let now = Day(year: 2026, month: 10, day: 25).at(hour: 9, minute: 30, in: zone)
        var draft = ComposerDraft(type: .event)
        draft.openDate(now: now, zone: zone)
        #expect(draft.minute == 600)
        #expect(draft.end(zone: zone) == Day(year: 2026, month: 10, day: 25).at(hour: 11, in: zone))
        draft.setEnd(Day(year: 2026, month: 10, day: 25).at(hour: 12, in: zone), zone: zone)
        draft.setTime(Day(year: 2026, month: 10, day: 25).at(hour: 14, in: zone), zone: zone)
        #expect(draft.end(zone: zone) == Day(year: 2026, month: 10, day: 25).at(hour: 16, in: zone))
        draft.setDay(Day(year: 2026, month: 10, day: 27), zone: zone)
        #expect(draft.start(zone: zone) == Day(year: 2026, month: 10, day: 27).at(hour: 14, in: zone))
        #expect(draft.end(zone: zone) == Day(year: 2026, month: 10, day: 27).at(hour: 16, in: zone))
        draft.setTime(nil, zone: zone)
        #expect(draft.build(base, zone: zone)?.allDay == true)
    }

    @Test func dictatedLinkLosesSpacesAndCase() {
        var draft = ComposerDraft(type: .bookmark)
        draft.dictateUrl("Spiegel .de")
        #expect(draft.urlConfirmed)
        #expect(draft.url == "https://spiegel.de")
        var empty = ComposerDraft(type: .bookmark)
        empty.dictateUrl("   ")
        #expect(!empty.urlConfirmed)
    }

    @Test func projectGoesIntoAreaAndAreaHasNoPlace() {
        let area = Entry(id: "area-1", type: .area, title: "Gesundheit", created: base.created, updated: base.updated)
        var project = ComposerDraft(type: .project)
        project.title = "Marathon"
        #expect(project.hasPlace)
        project.pick(area)
        #expect(project.places == ["area-1"])
        #expect(project.build(base, zone: zone)?.places == ["area-1"])
        #expect(!ComposerDraft(type: .area).hasPlace)
    }
}
