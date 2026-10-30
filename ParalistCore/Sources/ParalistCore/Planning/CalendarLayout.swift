// Zusammenhang: Planning/WeekGrid.swift, Model/Day.swift, Model/EntryStatus.swift, Paralist/Pages/CalendarPage.swift, Paralist/Pages/CalendarStrip.swift, Paralist/Pages/CalendarStripRow.swift
import Foundation

public enum CalendarMode: String, CaseIterable, Sendable {
    case day
    case week
    case month

    public func days(around day: Day) -> [Day] { self == .day ? [day] : Week.of(day).days }
    public var swipeDays: Int { self == .day ? 1 : 7 }

    public func anchor(_ day: Day) -> Day {
        switch self {
        case .day: return day
        case .week: return Week.of(day).monday
        case .month: return Day(year: day.year, month: day.month, day: 1)
        }
    }
}

public enum MonthGrid {
    public static func weeks(year: Int, month: Int) -> [Week] {
        let first = Week.of(Day(year: year, month: month, day: 1))
        let last = Week.of(Day(year: year, month: month, day: Day.length(of: month, in: year)))
        var weeks: [Week] = []
        var week = first
        while week.monday <= last.monday {
            weeks.append(week)
            week = week.next()
        }
        return weeks
    }

    public static func isInside(_ day: Day, year: Int, month: Int) -> Bool { day.year == year && day.month == month }
}

public extension Day {
    func moved(toYear year: Int, month: Int) -> Day {
        Day(year: year, month: month, day: min(day, Day.length(of: month, in: year)))
    }
}

public struct StripItem: Hashable, Sendable, Identifiable {
    public let id: String
    public let labelKey: String

    public init(id: String, labelKey: String) {
        self.id = id
        self.labelKey = labelKey
    }
}

public enum CalendarStrip {
    public static func items(_ rows: [Entry], day: Day, zone: TimeZone) -> [StripItem] {
        let allDay = rows.filter { $0.allDay && $0.start.map { Day.of($0, in: zone) == day } == true }
        let due = rows.filter { $0.due == day && $0.type != .event && !($0.allDay && $0.start != nil) }
        return allDay.map { StripItem(id: $0.id, labelKey: labelKey($0, fallback: "cal_all_day")) }
            + due.map { StripItem(id: $0.id, labelKey: labelKey($0, fallback: "cal_due")) }
    }

    public static func labelKey(_ entry: Entry, fallback: String) -> String {
        guard let status = entry.status, status != .open else { return fallback }
        return EntryStatus.label(status, for: entry.type)
    }
}
