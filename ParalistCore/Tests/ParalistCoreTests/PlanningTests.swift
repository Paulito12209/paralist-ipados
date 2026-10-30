// Zusammenhang: Planning/ReminderPlanner.swift, Planning/WeekBriefing.swift, Planning/WeekGrid.swift, Model/Day.swift
import Foundation
import Testing
@testable import ParalistCore

struct ReminderPlannerTests {
    private let now = at("2026-10-16T10:00:00Z")

    private func entry(_ type: EntryType, reminders: [Date] = [], due: Day? = nil, done: Bool = false) -> Entry {
        Entry("e-1", type, "T", now, now) {
            $0.reminders = reminders
            $0.due = due
            $0.status = type == .task ? (done ? .done : .open) : nil
        }
    }

    @Test func pastRemindersFromImportAreDropped() {
        let past = (1...500).map { now.addingTimeInterval(-Double($0) * 3600) }
        #expect(ReminderPlanner.plan(entry(.note, reminders: past), now: now, zone: berlin).isEmpty)
    }

    @Test func futureRemindersAreCappedAndSorted() {
        let future = (1...40).map { now.addingTimeInterval(Double($0) * 3600) }.shuffled()
        let planned = ReminderPlanner.plan(entry(.event, reminders: future), now: now, zone: berlin)
        #expect(planned.count == ReminderPlanner.maxPerEntry)
        #expect(planned == planned.sorted { $0.at < $1.at })
        #expect(planned.first?.kind == .event)
    }

    @Test func dueTaskRemindsAtNineOnDueDay() {
        let planned = ReminderPlanner.plan(entry(.task, due: Day(year: 2026, month: 10, day: 20)), now: now, zone: berlin)
        #expect(planned.map(\.at) == [at("2026-10-20T07:00:00Z")])
        #expect(planned.count == 1)
        #expect(planned.first?.kind == .due)
    }

    @Test func overdueTaskRemindsOncePerDayAndDoneTaskNever() {
        let overdueDay = Day(year: 2026, month: 10, day: 1)
        let overdue = ReminderPlanner.plan(entry(.task, due: overdueDay), now: now, zone: berlin)
        #expect(overdue.map(\.at) == [at("2026-10-17T07:00:00Z")])
        let earlier = at("2026-10-16T05:00:00Z")
        #expect(ReminderPlanner.plan(entry(.task, due: overdueDay), now: earlier, zone: berlin).map(\.at) == [at("2026-10-16T07:00:00Z")])
        #expect(ReminderPlanner.plan(entry(.task, due: overdueDay, done: true), now: now, zone: berlin).isEmpty)
    }

    @Test func clockSetBackDoesNotBreakPlanning() {
        let setBack = at("2020-01-01T00:00:00Z")
        let planned = ReminderPlanner.plan(entry(.event, reminders: [now]), now: setBack, zone: berlin)
        #expect(planned.count == 1)
        #expect(planned.first!.at > setBack)
    }

    @Test func quickChoicesAreInTheFuture() {
        let choices = ReminderPlanner.quickChoices(now: now, zone: berlin)
        let byKind = Dictionary(uniqueKeysWithValues: choices.map { ($0.0, $0.1) })
        #expect(byKind.count == 4)
        #expect(choices.allSatisfy { $0.1 > now })
        #expect(byKind[.tonight] == at("2026-10-16T16:00:00Z"))
        #expect(byKind[.weekEnd] == at("2026-10-18T16:00:00Z"))
        #expect(byKind[.weekStart] == at("2026-10-19T06:00:00Z"))
    }

    @Test func lateEveningOffersTonightAt22() {
        let evening = at("2026-10-29T19:12:00Z")
        let choices = ReminderPlanner.quickChoices(now: evening, zone: berlin)
        #expect(choices.map(\.0) == [.lateTonight, .tomorrowMorning, .weekEnd, .weekStart])
        #expect(choices[0].1 == at("2026-10-29T21:00:00Z"))
        #expect(choices[1].1 == at("2026-10-30T07:00:00Z"))
    }

    @Test func nightOffersNothingForToday() {
        let night = at("2026-10-29T20:45:00Z")
        let choices = ReminderPlanner.quickChoices(now: night, zone: berlin)
        #expect(choices.first?.0 == .tomorrowMorning)
        #expect(!choices.contains { $0.0 == .tonight || $0.0 == .lateTonight })
    }

    @Test func sundayDropsDuplicates() {
        let sunday = at("2026-11-01T09:00:00Z")
        let choices = ReminderPlanner.quickChoices(now: sunday, zone: berlin)
        #expect(choices.map(\.0) == [.tonight, .tomorrowMorning])
        #expect(choices[0].1 == at("2026-11-01T17:00:00Z"))
    }
}

struct WeekBriefingTests {
    private let now = at("2026-10-14T08:00:00Z")
    private let today = Day(year: 2026, month: 10, day: 14)

    private func entry(_ id: String, _ type: EntryType, start: String? = nil, end: String? = nil, due: Day? = nil, done: Bool = false, created: Date? = nil, archived: Bool = false) -> Entry {
        let made = created ?? now
        return Entry(id, type, id, made, made) {
            $0.start = start.map(at)
            $0.end = end.map(at)
            $0.due = due
            $0.status = type == .task ? (done ? .done : .open) : nil
            $0.archived = archived
        }
    }

    @Test func weekSwitchesToNextFromSaturday() {
        #expect(WeekBriefingBuilder.weekFor(Day(year: 2026, month: 10, day: 16)).monday == Day(year: 2026, month: 10, day: 12))
        #expect(WeekBriefingBuilder.weekFor(Day(year: 2026, month: 10, day: 17)).monday == Day(year: 2026, month: 10, day: 19))
    }

    @Test func collectsEventsTasksDeadlinesAndCreated() {
        let week = WeekBriefingBuilder.weekFor(today)
        let entries = [
            entry("ev-1", .event, start: "2026-10-15T08:00:00Z", end: "2026-10-16T09:00:00Z"),
            entry("ev-2", .event, start: "2026-10-25T08:00:00Z"),
            entry("task-1", .task, due: Day(year: 2026, month: 10, day: 16)),
            entry("task-2", .task, due: Day(year: 2026, month: 10, day: 1)),
            entry("task-3", .task, due: Day(year: 2026, month: 10, day: 16), done: true),
            entry("proj-1", .project, due: Day(year: 2026, month: 10, day: 13)),
            entry("link-1", .bookmark, created: at("2026-10-12T10:00:00Z")),
            entry("area-1", .area, created: at("2026-10-13T10:00:00Z")),
            entry("old-1", .bookmark, created: at("2026-09-01T10:00:00Z")),
            entry("arch-1", .task, due: Day(year: 2026, month: 10, day: 15), archived: true),
        ]
        let briefing = WeekBriefingBuilder.build(entries, week: week, today: today, zone: berlin)
        #expect(briefing.eventCount == 2)
        #expect(briefing.days[3].events.map(\.id) == ["ev-1"])
        #expect(briefing.days[4].events.map(\.id) == ["ev-1"])
        #expect(briefing.tasks.map(\.entry.id) == ["task-2", "task-1"])
        #expect(briefing.tasks[0].overdue)
        #expect(briefing.deadlines.map(\.entry.id) == ["proj-1"])
        #expect(briefing.deadlines[0].overdue)
        #expect(briefing.created.map(\.id) == ["link-1"])
        #expect(briefing.createdCounts == [.project: 1, .area: 1, .bookmark: 1])
    }
}

struct WeekGridTests {
    @Test func weekStartsOnMondayWithIsoNumber() {
        let week = Week.of(Day(year: 2026, month: 10, day: 16))
        #expect(week.monday == Day(year: 2026, month: 10, day: 12))
        #expect(week.isoWeek == 42)
        #expect(week.days.count == 7)
        #expect(week.next().isoWeek == 43)
    }

    @Test func blocksAreClampedToTheDay() throws {
        let day = Day(year: 2026, month: 10, day: 16)
        let block = try #require(WeekGrid.blockFor(id: "e", start: at("2026-10-16T08:00:00Z"), end: at("2026-10-16T09:30:00Z"), day: day, zone: berlin))
        #expect(block.startMinute == 600)
        #expect(block.endMinute == 690)
        let overnight = try #require(WeekGrid.blockFor(id: "e", start: at("2026-10-16T21:30:00Z"), end: at("2026-10-17T01:00:00Z"), day: day, zone: berlin))
        #expect(overnight.endMinute == 1440)
        #expect(WeekGrid.blockFor(id: "e", start: at("2026-10-17T08:00:00Z"), end: nil, day: day, zone: berlin) == nil)
        let tiny = try #require(WeekGrid.blockFor(id: "e", start: at("2026-10-16T08:00:00Z"), end: at("2026-10-16T08:05:00Z"), day: day, zone: berlin))
        #expect(tiny.endMinute == 630)
    }
}
