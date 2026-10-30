// Zusammenhang: Planning/CalendarChrome.swift, Planning/WeekGrid.swift
import Foundation
import Testing
@testable import ParalistCore

struct CalendarChromeTests {
    private func scroll(_ chrome: CalendarChrome, _ offset: Double, _ delta: Double, max: Double = 1000) -> CalendarChrome {
        chrome.scrolled(offset: offset, delta: delta, maxOffset: max, step: 4, jump: 200, endSlack: 2)
    }

    @Test func downwardScrollCollapsesHeaderAndBar() {
        #expect(scroll(CalendarChrome(), 300, 10) == CalendarChrome(collapsed: true, compact: true))
    }

    @Test func upwardScrollShowsHeaderAgain() {
        #expect(scroll(CalendarChrome(collapsed: true, compact: true), 300, -10) == CalendarChrome())
    }

    @Test func topAlwaysExpands() {
        #expect(scroll(CalendarChrome(collapsed: true, compact: true), 0, 10) == CalendarChrome())
    }

    @Test func endShowsFullBarWithSearch() {
        let end = CalendarChrome(collapsed: true, compact: false)
        #expect(scroll(CalendarChrome(collapsed: true, compact: true), 999, 10) == end)
        #expect(scroll(end, 1040, -12) == end)
        #expect(scroll(end, 1000, -8) == end)
    }

    @Test func tinyAndHugeDeltasKeepState() {
        let state = CalendarChrome(collapsed: true, compact: true)
        #expect(scroll(state, 300, -3) == state)
        #expect(scroll(state, 300, -250) == state)
    }

    @Test func layoutChangeAtEndKeepsEndState() {
        let end = CalendarChrome(collapsed: true, compact: false)
        #expect(end.scrolled(offset: 900, delta: -40, maxOffset: 960, maxShift: -40, step: 4, jump: 200, endSlack: 2) == end)
    }

    @Test func shortContentNeverCountsAsEnd() {
        #expect(scroll(CalendarChrome(), 5, 10, max: 0) == CalendarChrome(collapsed: true, compact: true))
    }
}

struct WeekListTests {
    @Test func yearWith53Weeks() {
        let weeks = Week.all(isoYear: 2026)
        #expect(weeks.count == 53)
        #expect(weeks.first?.monday == Day(year: 2025, month: 12, day: 29))
        #expect(weeks.last?.isoWeek == 53)
    }

    @Test func yearStartingInWeekOne() {
        let weeks = Week.all(isoYear: 2025)
        #expect(weeks.count == 52)
        #expect(weeks.first?.monday == Day(year: 2024, month: 12, day: 30))
        #expect(weeks.map(\.isoWeek) == Array(1...52))
    }

    @Test func isoYearFollowsThursday() {
        #expect(Week.of(Day(year: 2027, month: 1, day: 1)).isoYear == 2026)
        #expect(Week.of(Day(year: 2024, month: 12, day: 31)).isoYear == 2025)
    }

    @Test func focusPrefersToday() {
        let week = Week.of(Day(year: 2026, month: 10, day: 21))
        #expect(week.focus(today: Day(year: 2026, month: 10, day: 21)) == Day(year: 2026, month: 10, day: 21))
        #expect(week.focus(today: Day(year: 2026, month: 11, day: 3)) == Day(year: 2026, month: 10, day: 19))
    }
}
