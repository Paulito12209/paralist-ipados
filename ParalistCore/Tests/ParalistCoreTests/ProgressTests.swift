// Zusammenhang: Planning/XpLog.swift, Flashcards/ReviewLog.swift, Model/Entry.swift
import Foundation
import Testing
@testable import ParalistCore

struct XpLogTests {
    private let today = Day(year: 2026, month: 10, day: 16)
    private let t = at("2026-10-16T10:00:00Z")

    @Test func pointsComeFromEventsOnly() {
        let entries = [
            Entry("p-1", .project, "P", t.addingTimeInterval(-86_400), t),
            Entry("t-1", .task, "T", t, t) {
                $0.status = .done
                $0.doneAt = t
            },
            Entry("n-1", .note, "N", t, t) { $0.extras = ["punkte": "9999"] },
        ]
        let reviews = [[ReviewEvent(cardId: "c", at: t, rating: .good), ReviewEvent(cardId: "c", at: t.addingTimeInterval(-3 * 86_400), rating: .again)]]
        let log = XpLog.build(entries, reviews: reviews)
        #expect(XpLog.total(log) == 5 + 1 + 2 + 1 + 2)
        #expect(XpLog.totalsByKind(log) == [.created: 7, .done: 2, .reviewed: 2])
        #expect(XpLog.perDay(log, days: 7, today: today, zone: berlin) == [0, 0, 0, 1, 0, 5, 5])
        #expect(XpLog.streak(log, today: today, zone: berlin) == 2)
    }

    @Test func levelsProgress() {
        #expect(XpLog.level(0).level == 1)
        #expect(XpLog.level(20).level == 2)
        let info = XpLog.level(35)
        #expect(info.level == 2)
        #expect(info.progress == 0.5)
        #expect(XpLog.level(1_000_000).level == XpLog.levels.count)
        #expect(XpLog.level(1_000_000).progress == 1)
    }
}
