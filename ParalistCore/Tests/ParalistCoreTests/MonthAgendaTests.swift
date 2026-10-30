// Zusammenhang: Planning/MonthAgenda.swift
import Foundation
import Testing
@testable import ParalistCore

struct MonthAgendaTests {
    private let zone = TimeZone(identifier: "Europe/Berlin")!

    @Test func monthsWrapAroundYears() {
        let months = MonthAgenda.months(around: Day(year: 2026, month: 1, day: 15), before: 1, after: 12)
        #expect(months.first == MonthKey(year: 2025, month: 12))
        #expect(months[1] == MonthKey(year: 2026, month: 1))
        #expect(months.last == MonthKey(year: 2027, month: 1))
        #expect(MonthKey(year: 2026, month: 2).last == Day(year: 2026, month: 2, day: 28))
    }

    @Test func dayListsAllDayThenTimedThenDue() {
        let day = Day(year: 2026, month: 10, day: 26)
        let morning = day.at(hour: 9, in: zone)
        let noon = day.at(hour: 12, in: zone)
        var allDay = Entry(id: "a", type: .event, title: "A", created: noon, updated: noon)
        allDay.start = noon
        allDay.allDay = true
        var late = Entry(id: "l", type: .event, title: "L", created: noon, updated: noon)
        late.start = noon
        var early = Entry(id: "e", type: .event, title: "E", created: noon, updated: noon)
        early.start = morning
        var task = Entry(id: "t", type: .task, title: "T", created: noon, updated: noon)
        task.due = day
        var other = Entry(id: "o", type: .event, title: "O", created: noon, updated: noon)
        other.start = day.adding(days: 1).at(hour: 9, in: zone)
        #expect(MonthAgenda.ids([task, late, other, allDay, early], day: day, zone: zone) == ["a", "e", "l", "t"])
    }
}
