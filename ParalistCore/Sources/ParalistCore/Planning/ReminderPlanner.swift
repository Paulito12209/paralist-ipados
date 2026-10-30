// Zusammenhang: Model/Entry.swift, Paralist/Reminders/ReminderScheduler.swift, Paralist/Entry/ReminderSheet.swift
import Foundation

public enum ReminderKind: String, Sendable { case event, due, custom }

public struct PlannedReminder: Hashable, Sendable {
    public let entryId: String
    public let at: Date
    public let kind: ReminderKind
}

public enum QuickReminder: CaseIterable, Sendable { case tonight, lateTonight, tomorrowMorning, weekEnd, weekStart }

public enum EventOffset: Int, CaseIterable, Sendable {
    case none = -1, min5 = 5, min15 = 15, hour1 = 60, day1 = 1_440

    public func before(_ start: Date) -> Date? { rawValue < 0 ? nil : start.addingTimeInterval(-Double(rawValue) * 60) }
}

public enum ReminderPlanner {
    public static let dueHour = 9
    public static let maxPerEntry = 20

    public static func plan(_ entry: Entry, now: Date, zone: TimeZone) -> [PlannedReminder] {
        if entry.archived { return [] }
        var planned: [PlannedReminder] = []
        for at in entry.reminders.filter({ $0 > now }).sorted().prefix(maxPerEntry) {
            planned.append(PlannedReminder(entryId: entry.id, at: at, kind: entry.type == .event ? .event : .custom))
        }
        if let due = entry.due, entry.type == .task || entry.type == .project, !entry.isDone {
            let today = Day.of(now, in: zone)
            let day = due > today ? due : nextDueDay(today, now, zone)
            let at = day.at(hour: dueHour, in: zone)
            if at > now && !planned.contains(where: { $0.at == at }) {
                planned.append(PlannedReminder(entryId: entry.id, at: at, kind: .due))
            }
        }
        return planned.sorted { $0.at < $1.at }
    }

    private static func nextDueDay(_ today: Day, _ now: Date, _ zone: TimeZone) -> Day {
        today.at(hour: dueHour, in: zone) > now ? today : today.adding(days: 1)
    }

    public static let quickLead: TimeInterval = 30 * 60

    public static func quickChoices(now: Date, zone: TimeZone) -> [(QuickReminder, Date)] {
        let today = Day.of(now, in: zone)
        let earliest = now.addingTimeInterval(quickLead)
        var choices: [(QuickReminder, Date)] = []
        func add(_ kind: QuickReminder, _ at: Date) {
            if at >= earliest && !choices.contains(where: { $0.1 == at }) { choices.append((kind, at)) }
        }
        let evening = today.at(hour: 18, in: zone)
        if evening >= earliest {
            add(.tonight, evening)
        } else {
            add(.lateTonight, today.at(hour: 22, in: zone))
        }
        add(.tomorrowMorning, today.adding(days: 1).at(hour: 8, in: zone))
        let sunday = today.adding(days: (7 - today.weekday) % 7).at(hour: 18, in: zone)
        add(.weekEnd, sunday >= earliest ? sunday : today.adding(days: (7 - today.weekday) % 7 + 7).at(hour: 18, in: zone))
        var toMonday = (8 - today.weekday) % 7
        if toMonday == 0 { toMonday = 7 }
        add(.weekStart, today.adding(days: toMonday).at(hour: 8, in: zone))
        return choices
    }
}
