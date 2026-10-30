// Zusammenhang: Planning/CalendarLayout.swift, Planning/WeekGrid.swift
import Foundation
import Testing
@testable import ParalistCore

struct CalendarLayoutTests {
    private let zone = TimeZone(identifier: "Europe/Berlin")!

    private func entry(_ id: String, _ type: EntryType) -> Entry {
        Entry(id: id, type: type, title: id, created: Date(timeIntervalSince1970: 0), updated: Date(timeIntervalSince1970: 0))
    }

    @Test func novemberTwentySixHasSixRowsFromOctoberTwentySix() {
        let weeks = MonthGrid.weeks(year: 2026, month: 11)
        #expect(weeks.count == 6)
        #expect(weeks.first?.monday == Day(year: 2026, month: 10, day: 26))
        #expect(weeks.last?.sunday == Day(year: 2026, month: 12, day: 6))
        #expect(weeks.first?.isoWeek == 44)
    }

    @Test func februaryStartingOnMondayHasFourRows() {
        let weeks = MonthGrid.weeks(year: 2027, month: 2)
        #expect(weeks.count == 4)
        #expect(weeks.first?.monday == Day(year: 2027, month: 2, day: 1))
        #expect(MonthGrid.isInside(Day(year: 2027, month: 2, day: 28), year: 2027, month: 2))
        #expect(!MonthGrid.isInside(Day(year: 2027, month: 3, day: 1), year: 2027, month: 2))
    }

    @Test func movingToShorterMonthClampsDay() {
        #expect(Day(year: 2026, month: 10, day: 31).moved(toYear: 2026, month: 11) == Day(year: 2026, month: 11, day: 30))
        #expect(Day(year: 2026, month: 10, day: 26).moved(toYear: 2026, month: 11) == Day(year: 2026, month: 11, day: 26))
        #expect(Day(year: 2024, month: 1, day: 30).moved(toYear: 2025, month: 2) == Day(year: 2025, month: 2, day: 28))
    }

    @Test func modeDaysAndSwipe() {
        let day = Day(year: 2026, month: 10, day: 28)
        #expect(CalendarMode.day.days(around: day) == [day])
        #expect(CalendarMode.week.days(around: day).count == 7)
        #expect(CalendarMode.week.days(around: day).first == Day(year: 2026, month: 10, day: 26))
        #expect(CalendarMode.week.anchor(day) == Day(year: 2026, month: 10, day: 26))
        #expect(CalendarMode.day.anchor(day) == day)
        #expect(CalendarMode.day.swipeDays == 1 && CalendarMode.week.swipeDays == 7)
        #expect(CalendarMode.month.anchor(day) == Day(year: 2026, month: 10, day: 1))
    }

    @Test func stripShowsStatusInsteadOfDueWhenSet() {
        let day = Day(year: 2026, month: 10, day: 22)
        var open = entry("open", .task); open.due = day
        var done = entry("done", .task); done.due = day; done.status = .done
        var running = entry("running", .task); running.due = day; running.status = .inProgress
        var stillOpen = entry("stillOpen", .task); stillOpen.due = day; stillOpen.status = .open
        var party = entry("party", .event); party.allDay = true; party.start = day.startOfDay(in: zone)
        var heldParty = entry("held", .event); heldParty.allDay = true; heldParty.start = day.at(hour: 9, in: zone); heldParty.status = .done
        var other = entry("other", .task); other.due = day.adding(days: 1)
        var timed = entry("timed", .event); timed.start = day.at(hour: 10, in: zone)
        let items = CalendarStrip.items([open, done, running, stillOpen, party, heldParty, other, timed], day: day, zone: zone)
        #expect(items.map(\.id) == ["party", "held", "open", "done", "running", "stillOpen"])
        #expect(items.map(\.labelKey) == ["cal_all_day", "status_held", "cal_due", "status_done", "status_in_progress", "cal_due"])
    }
}
