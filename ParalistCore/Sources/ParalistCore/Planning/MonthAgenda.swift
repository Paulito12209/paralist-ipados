// Zusammenhang: Planning/CalendarLayout.swift (MonthGrid, CalendarStrip), Model/Day.swift, Paralist/Pages/CalendarMonth.swift, Paralist/App/AppModel.swift (calendar(month:))
import Foundation

public struct MonthKey: Hashable, Comparable, Sendable, Identifiable {
    public let year: Int
    public let month: Int

    public init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }

    public static func of(_ day: Day) -> MonthKey { MonthKey(year: day.year, month: day.month) }

    public var id: Int { year * 12 + month - 1 }
    public var first: Day { Day(year: year, month: month, day: 1) }
    public var last: Day { Day(year: year, month: month, day: Day.length(of: month, in: year)) }

    public func moved(by months: Int) -> MonthKey {
        let index = id + months
        let year = Int((Double(index) / 12).rounded(.down))
        return MonthKey(year: year, month: index - year * 12 + 1)
    }

    public static func < (a: MonthKey, b: MonthKey) -> Bool { a.id < b.id }
}

public enum MonthAgenda {
    public static func months(around day: Day, before: Int, after: Int) -> [MonthKey] {
        let center = MonthKey.of(day)
        return (-before...after).map { center.moved(by: $0) }
    }

    public static func ids(_ rows: [Entry], day: Day, zone: TimeZone) -> [String] {
        let allDay = Set(rows.filter(\.allDay).map(\.id))
        let strip = CalendarStrip.items(rows, day: day, zone: zone).map(\.id)
        let timed = rows.filter { !$0.allDay && $0.start.map { Day.of($0, in: zone) == day } == true }
            .sorted { ($0.start ?? .distantPast) < ($1.start ?? .distantPast) }
            .map(\.id)
        return strip.filter { allDay.contains($0) } + timed + strip.filter { !allDay.contains($0) }
    }
}
