// Zusammenhang: Planning/TodayDigest.swift, Planning/WeekBriefing.swift, TestSupport.swift
import Foundation
import Testing
@testable import ParalistCore

struct TodayDigestTests {
    private let today = Day(year: 2026, month: 10, day: 21)

    private func event(_ id: String, _ start: String, end: String? = nil, allDay: Bool = false, _ configure: (inout Entry) -> Void = { _ in }) -> Entry {
        Entry(id, .event, id, epoch, epoch) {
            $0.start = at(start)
            $0.end = end.map(at)
            $0.allDay = allDay
            $0.status = .open
            configure(&$0)
        }
    }

    private func task(_ id: String, _ due: Day?, _ configure: (inout Entry) -> Void = { _ in }) -> Entry {
        Entry(id, .task, id, epoch, epoch) {
            $0.due = due
            $0.status = .open
            configure(&$0)
        }
    }

    private func ids(_ digest: TodayDigest) -> [String] { digest.items.map(\.entry.id) }

    @Test func eventsFirstAllDayThenByTime() {
        let rows = [
            event("e-late", "2026-10-21T16:00:00+02:00"),
            event("e-early", "2026-10-21T08:30:00+02:00"),
            event("e-day", "2026-10-21T00:00:00+02:00", allDay: true),
            task("t-today", today),
        ]
        let digest = TodayDigest.build(rows, today: today, zone: berlin)
        #expect(ids(digest) == ["e-day", "e-early", "e-late", "t-today"])
        #expect(digest.more == 0)
    }

    @Test func timeOnlyWhenEventStartsToday() {
        let rows = [
            event("e-now", "2026-10-21T09:00:00+02:00"),
            event("e-span", "2026-10-20T09:00:00+02:00", end: "2026-10-22T10:00:00+02:00"),
            event("e-day", "2026-10-21T00:00:00+02:00", allDay: true),
        ]
        let digest = TodayDigest.build(rows, today: today, zone: berlin)
        #expect(digest.items.contains(.event(rows[0], time: at("2026-10-21T09:00:00+02:00"))))
        #expect(digest.items.contains(.event(rows[1], time: nil)))
        #expect(digest.items.contains(.event(rows[2], time: nil)))
    }

    @Test func skipsOtherDaysDoneArchivedAndUndatedTasks() {
        let rows = [
            event("e-tomorrow", "2026-10-22T09:00:00+02:00"),
            event("e-done", "2026-10-21T09:00:00+02:00") { $0.status = .done },
            event("e-archived", "2026-10-21T09:00:00+02:00") { $0.archived = true },
            task("t-tomorrow", today.adding(days: 1)),
            task("t-none", nil),
            task("t-done", today) { $0.status = .done },
            task("t-archived", today) { $0.archived = true },
            Entry("p-today", .project, "P", epoch, epoch) { $0.due = today },
        ]
        #expect(TodayDigest.build(rows, today: today, zone: berlin).isEmpty)
    }

    @Test func overdueTasksFirstAndMarked() {
        let rows = [
            task("t-today", today),
            task("t-old", today.adding(days: -5)),
            task("t-yesterday", today.adding(days: -1)) { $0.status = .inProgress },
        ]
        let digest = TodayDigest.build(rows, today: today, zone: berlin)
        #expect(ids(digest) == ["t-old", "t-yesterday", "t-today"])
        #expect(digest.items[0] == .task(rows[1], overdue: true))
        #expect(digest.items[2] == .task(rows[0], overdue: false))
    }

    @Test func limitsToFiveAndCountsTheRest() {
        let rows = (1...4).map { event("e-\($0)", "2026-10-21T0\($0):00:00+02:00") } + (1...4).map { task("t-\($0)", today.adding(days: -$0)) }
        let digest = TodayDigest.build(rows, today: today, zone: berlin)
        #expect(digest.items.count == TodayDigest.limit)
        #expect(ids(digest) == ["e-1", "e-2", "e-3", "e-4", "t-4"])
        #expect(digest.more == 3)
    }
}
