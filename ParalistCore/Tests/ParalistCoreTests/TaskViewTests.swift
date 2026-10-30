// Zusammenhang: Sources/ParalistCore/Library/TaskView.swift, TestSupport.swift
import Foundation
import Testing
@testable import ParalistCore

struct TaskViewTests {
    private let today = Day(year: 2026, month: 10, day: 24)
    private let noon = Day(year: 2026, month: 10, day: 24).at(hour: 12, in: berlin)

    private func task(_ id: String, created: Double, _ configure: (inout Entry) -> Void = { _ in }) -> Entry {
        Entry(id, .task, id, Date(timeIntervalSince1970: created), Date(timeIntervalSince1970: created)) { e in
            e.status = .open
            configure(&e)
        }
    }

    private var rows: [Entry] {
        [
            task("alt", created: 100),
            task("neu", created: 300) { $0.due = Day(year: 2026, month: 10, day: 20) },
            task("laufend", created: 200) { $0.status = .inProgress; $0.due = Day(year: 2026, month: 10, day: 30) },
            task("heute", created: 150) { $0.status = .done; $0.doneAt = noon.addingTimeInterval(-3600) },
            task("gestern", created: 250) { $0.status = .done; $0.doneAt = noon.addingTimeInterval(-86400) },
            task("archiv", created: 400) { $0.archived = true; $0.status = .done },
            task("pin", created: 50) { $0.pinned = true },
        ]
    }

    private func ids(_ setting: TaskViewSetting, archive: Bool = false) -> [String] {
        setting.arrange(rows, archive: archive, today: today, zone: berlin).flatMap(\.1).map(\.id)
    }

    @Test func defaultShowsDoneTasksOnlyOnTheirDay() {
        #expect(ids(TaskViewSetting()) == ["pin", "neu", "laufend", "alt", "heute"])
        #expect(ids(TaskViewSetting(done: .always)) == ["pin", "neu", "laufend", "alt", "gestern", "heute"])
    }

    @Test func archiveHoldsArchivedEntriesAndHiddenDoneTasks() {
        let note = Entry("notiz", .note, "notiz", Date(timeIntervalSince1970: 500), Date(timeIntervalSince1970: 500)) { $0.archived = true }
        let ids = TaskViewSetting().archive(rows + [note], today: today, zone: berlin).map(\.id)
        #expect(ids == ["notiz", "archiv", "gestern"])
        #expect(TaskViewSetting(done: .always).archive(rows, today: today, zone: berlin).map(\.id) == ["archiv"])
    }

    @Test func sameDayHidesYesterdaysDoneTask() {
        #expect(ids(TaskViewSetting(done: .sameDay)) == ["pin", "neu", "laufend", "alt", "heute"])
        #expect(ids(TaskViewSetting(done: .never)) == ["pin", "neu", "laufend", "alt"])
        #expect(ids(TaskViewSetting(done: .week)) == ["pin", "neu", "laufend", "alt", "gestern", "heute"])
        let old = noon.addingTimeInterval(-8 * 86400)
        #expect(!DoneVisibility.week.shows(doneAt: old, today: today, zone: berlin))
        #expect(!DoneVisibility.sameDay.shows(doneAt: nil, today: today, zone: berlin))
    }

    @Test func archiveShowsArchivedAndHiddenDoneTasks() {
        #expect(ids(TaskViewSetting(done: .always), archive: true) == ["archiv"])
        #expect(ids(TaskViewSetting(), archive: true) == ["archiv", "gestern"])
        #expect(ids(TaskViewSetting(done: .never), archive: true) == ["archiv", "gestern", "heute"])
        #expect(TaskViewSetting.active(rows).map(\.id) == ["alt", "neu", "laufend", "pin"])
        #expect(TaskViewSetting.pinned(rows).map(\.id) == ["pin"])
    }

    @Test func dueSortPutsUndatedTasksLast() {
        #expect(ids(TaskViewSetting(sort: .due, done: .never)) == ["pin", "neu", "laufend", "alt"])
        #expect(ids(TaskViewSetting(sort: .due, ascending: false, done: .never)) == ["pin", "laufend", "neu", "alt"])
        #expect(ids(TaskViewSetting(sort: .title, done: .never)) == ["pin", "alt", "laufend", "neu"])
    }

    @Test func statusGroupsFollowConfiguredOrder() {
        let groups = TaskViewSetting(grouping: .status, done: .always).arrange(rows, archive: false, today: today, zone: berlin)
        #expect(groups.map(\.0) == [.open, .inProgress, .done])
        #expect(groups[2].1.map(\.id) == ["gestern", "heute"])
        let reversed = TaskViewSetting(grouping: .status, groupOrder: [.done, .inProgress]).arrange(rows, archive: false, today: today, zone: berlin)
        #expect(reversed.map(\.0) == [.done, .inProgress, .open])
    }

    @Test func groupOrderCanBeMoved() {
        let moved = TaskViewSetting().moveGroup(from: 2, to: 0)
        #expect(moved.groupOrder == [.done, .open, .inProgress])
        #expect(TaskViewSetting().moveGroup(from: 0, to: 3).groupOrder == [.inProgress, .done, .open])
        #expect(TaskViewSetting.completed([.learned, .done, .done]) == [.done, .open, .inProgress])
    }

    @Test func doneFallsBackToDefaultUntilCustomized() {
        let stored = TaskViewSetting(sort: .title, done: .never)
        #expect(stored.adoptingDefaultDone(unlessCustomized: false).done == .sameDay)
        #expect(stored.adoptingDefaultDone(unlessCustomized: false).sort == .title)
        #expect(stored.adoptingDefaultDone(unlessCustomized: true) == stored)
    }

    @Test func settingRoundTripsThroughText() {
        let setting = TaskViewSetting(sort: .due, ascending: false, grouping: .status, groupOrder: [.inProgress, .open, .done], done: .week)
        #expect(TaskViewSetting.decode(setting.encoded) == setting)
        #expect(TaskViewSetting.decode(nil) == TaskViewSetting())
        #expect(TaskViewSetting.decode("kaputt") == TaskViewSetting())
        #expect(TaskViewSetting().encoded == "erstellt;ab;keine;offen,laufend,erledigt;tag")
    }
}
