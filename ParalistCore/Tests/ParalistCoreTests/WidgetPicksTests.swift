// Zusammenhang: Library/WidgetPicks.swift, Links/IncomingLink.swift, TestSupport.swift
import Foundation
import Testing
@testable import ParalistCore

struct WidgetPicksTests {
    private func entry(_ id: String, _ type: EntryType, _ title: String, _ minute: Int, _ configure: (inout Entry) -> Void = { _ in }) -> Entry {
        Entry(id, type, title, epoch, epoch.addingTimeInterval(Double(minute) * 60), configure)
    }

    @Test func ordersAreasThenProjectsThenRest() {
        let rows = [
            entry("note-1", .note, "Notiz", 9),
            entry("proj-1", .project, "Projekt", 1),
            entry("area-1", .area, "Bereich", 0),
            entry("deck-1", .deck, "Deck", 8),
        ]
        #expect(WidgetPicks.candidates(rows).map(\.id) == ["area-1", "proj-1", "note-1", "deck-1"])
    }

    @Test func markedFirstThenRecentlyUpdated() {
        let rows = [
            entry("proj-old", .project, "A", 1),
            entry("proj-new", .project, "B", 5),
            entry("proj-pin", .project, "C", 0) { $0.pinned = true },
            entry("proj-fav", .project, "D", 0) { $0.favorite = true },
            entry("task-new", .task, "E", 9),
            entry("task-fav", .task, "F", 2) { $0.favorite = true },
        ]
        #expect(WidgetPicks.candidates(rows).map(\.id) == ["proj-fav", "proj-pin", "proj-new", "proj-old", "task-fav", "task-new"])
    }

    @Test func leavesOutCardsAndArchive() {
        let rows = [
            entry("card-1", .flashcard, "Karte", 1),
            entry("note-1", .note, "Alt", 2) { $0.archived = true },
            entry("file-1", .file, "Datei", 3),
        ]
        #expect(WidgetPicks.candidates(rows).map(\.id) == ["file-1"])
        #expect(!WidgetPicks.allowed(rows[0]))
        #expect(!WidgetPicks.allowed(rows[1]))
    }

    @Test func searchIgnoresCaseAccentsAndSpaces() {
        let rows = [
            entry("note-1", .note, "Café Übersicht", 1),
            entry("note-2", .note, "Einkauf", 2),
        ]
        #expect(WidgetPicks.candidates(rows, matching: "  cafe ubers ").map(\.id) == ["note-1"])
        #expect(WidgetPicks.candidates(rows, matching: "EINKAUF").map(\.id) == ["note-2"])
        #expect(WidgetPicks.candidates(rows, matching: "   ").count == 2)
        #expect(WidgetPicks.candidates(rows, matching: "nichts").isEmpty)
    }

    @Test func stopsAtFifty() {
        let rows = (0..<80).map { entry("note-\(1000 + $0)", .note, "Notiz \($0)", $0) }
        let picks = WidgetPicks.candidates(rows)
        #expect(picks.count == WidgetPicks.limit)
        #expect(picks.first?.id == "note-1079")
    }

    @Test func countsChildrenWithoutArchive() {
        let rows = [
            entry("proj-1", .project, "P", 0),
            entry("note-1", .note, "A", 1) { $0.places = ["proj-1"] },
            entry("note-2", .note, "B", 2) { $0.places = ["proj-1", "area-1"] },
            entry("note-3", .note, "C", 3) { $0.places = ["proj-1"]; $0.archived = true },
            entry("note-4", .note, "D", 4) { $0.places = ["area-1"] },
        ]
        #expect(WidgetPicks.childCount("proj-1", in: rows) == 2)
        #expect(WidgetPicks.childCount("area-1", in: rows) == 2)
        #expect(WidgetPicks.childCount("none-1", in: rows) == 0)
    }

    @Test func entryLinkRoundTrips() throws {
        let url = try #require(IncomingLink.entryURL("abc-123"))
        #expect(url.absoluteString == "paralist-ipad://eintrag/abc-123")
        #expect(IncomingLink.parse(url) == .entry("abc-123"))
        #expect(IncomingLink.entryURL("../x") == nil)
        #expect(IncomingLink.entryURL("AB") == nil)
    }
}
