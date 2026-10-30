// Zusammenhang: Sources/ParalistCore/Library/EntryParent.swift, Sources/ParalistCore/Markdown/EntryCodec.swift
import Foundation
import Testing
@testable import ParalistCore

struct EntryParentTests {
    private let zone = TimeZone(identifier: "Europe/Berlin")!
    private let at = Date(timeIntervalSince1970: 1_790_000_000)

    private func entry(_ id: String, _ type: EntryType) -> Entry {
        Entry(id: id, type: type, title: id, created: at, updated: at)
    }

    @Test func everyTypeButAreaHasParent() {
        for type in EntryType.allCases {
            #expect(EntryParent.applies(to: type) == (type != .area))
        }
    }

    @Test func projectsOnlyGoIntoAreas() {
        let containers = [entry("p1", .project), entry("p2", .project), entry("a1", .area)]
        #expect(EntryParent.candidates(for: entry("p1", .project), among: containers).map(\.id) == ["a1"])
        #expect(EntryParent.candidates(for: entry("t", .task), among: containers).map(\.id) == ["p1", "p2", "a1"])
    }

    @Test func parsesAndFormatsTime() {
        #expect(DueTime.parse("07:05")?.description == "07:05")
        #expect(DueTime.parse("24:00") == nil)
        #expect(DueTime.parse("7:05") == nil)
        #expect(DueTime.parse("") == nil)
        #expect(DueTime.of(Day(year: 2026, month: 11, day: 3).at(hour: 14, minute: 30, in: zone), in: zone)?.description == "14:30")
    }

    @Test func timeNeedsDate() {
        var e = entry("t", .task)
        e.setDueTime(DueTime(hour: 9, minute: 0))
        #expect(e.extras[Entry.dueTimeKey] == nil)
        e.setDue(Day(year: 2026, month: 11, day: 3))
        e.setDueTime(DueTime(hour: 9, minute: 15))
        #expect(e.dueTime?.description == "09:15")
        #expect(e.dueDate(in: zone) == Day(year: 2026, month: 11, day: 3).at(hour: 9, minute: 15, in: zone))
        e.setDue(nil)
        #expect(e.dueTime == nil)
        #expect(e.extras[Entry.dueTimeKey] == nil)
    }

    @Test func dateWithoutTimeIsNoon() {
        var e = entry("t", .task)
        e.setDue(Day(year: 2026, month: 11, day: 3))
        #expect(e.dueTime == nil)
        #expect(e.dueDate(in: zone) == Day(year: 2026, month: 11, day: 3).at(hour: 12, in: zone))
    }

    @Test func timeSurvivesFile() throws {
        var e = entry("abcd-1234", .task)
        e.setDue(Day(year: 2026, month: 11, day: 3))
        e.setDueTime(DueTime(hour: 18, minute: 45))
        let text = EntryCodec.encode(e)
        #expect(text.contains("faellig_zeit"))
        let back = try EntryCodec.decode(text)
        #expect(back.dueTime?.description == "18:45")
        #expect(back.due == e.due)
    }
}
