// Zusammenhang: Planning/WeekGrid.swift, Planning/TodayDigest.swift, Model/Entry.swift, Paralist/Pages/BriefingPage.swift
import Foundation

public struct BriefingDay: Hashable, Sendable {
    public let date: Day
    public let events: [Entry]
}

public struct DatedEntry: Hashable, Sendable {
    public let entry: Entry
    public let date: Day
    public let overdue: Bool
}

public struct WeekBriefing: Sendable {
    public let week: Week
    public let days: [BriefingDay]
    public let deadlines: [DatedEntry]
    public let tasks: [DatedEntry]
    public let created: [Entry]
    public let createdCounts: [EntryType: Int]

    public var eventCount: Int { days.reduce(0) { $0 + $1.events.count } }
    public var isEmpty: Bool { eventCount == 0 && deadlines.isEmpty && tasks.isEmpty && created.isEmpty }
}

public enum WeekBriefingBuilder {
    public static func weekFor(_ today: Day) -> Week {
        let week = Week.of(today)
        return today.weekday > 5 ? week.next() : week
    }

    public static func build(_ entries: [Entry], week: Week, today: Day, zone: TimeZone) -> WeekBriefing {
        let alive = entries.filter { !$0.archived }
        func inWeek(_ day: Day?) -> Bool { day.map { $0 >= week.monday && $0 <= week.sunday } ?? false }
        let days = week.days.map { day in
            BriefingDay(date: day, events: alive.filter { $0.type == .event && $0.start != nil && spans($0, day, zone) }
                .sorted { a, b in
                    if a.allDay != b.allDay { return a.allDay }
                    return (a.start ?? .distantPast) < (b.start ?? .distantPast)
                })
        }
        let currentWeek = inWeek(today)
        let tasks = alive.filter { $0.type == .task && !$0.isDone && $0.due != nil }
            .filter { inWeek($0.due) || (currentWeek && $0.due! < today) }
            .map { DatedEntry(entry: $0, date: $0.due!, overdue: $0.due! < today) }
            .sorted { $0.date < $1.date }
        let deadlines = alive.filter { $0.type == .project && $0.due != nil && inWeek($0.due) }
            .map { DatedEntry(entry: $0, date: $0.due!, overdue: $0.due! < today) }
            .sorted { $0.date < $1.date }
        let created = alive.filter { $0.type.isContainer || $0.type == .bookmark || $0.type == .document || $0.type == .file }
            .filter { inWeek(Day.of($0.created, in: zone)) }
            .sorted { $0.created > $1.created }
        var counts: [EntryType: Int] = [:]
        for e in created { counts[e.type, default: 0] += 1 }
        return WeekBriefing(week: week, days: days, deadlines: deadlines, tasks: tasks, created: created.filter { !$0.type.isContainer }, createdCounts: counts)
    }

    static func spans(_ entry: Entry, _ day: Day, _ zone: TimeZone) -> Bool {
        let start = Day.of(entry.start!, in: zone)
        let end = entry.end.map { Day.of($0, in: zone) } ?? start
        return day >= start && day <= end
    }
}
