// Zusammenhang: Model/Day.swift, Planning/WeekBriefing.swift, Paralist/Pages/CalendarPage.swift
import Foundation

public struct Week: Hashable, Sendable {
    public let monday: Day

    public init(monday: Day) { self.monday = monday }

    public static func of(_ day: Day) -> Week { Week(monday: day.adding(days: -(day.weekday - 1))) }

    public var days: [Day] { (0...6).map { monday.adding(days: $0) } }
    public var sunday: Day { monday.adding(days: 6) }
    public func next() -> Week { Week(monday: monday.adding(days: 7)) }
    public func previous() -> Week { Week(monday: monday.adding(days: -7)) }

    public var isoWeek: Int {
        let thursday = monday.adding(days: 3)
        let firstOfYear = Day(year: thursday.year, month: 1, day: 1)
        return (thursday.epochDay - firstOfYear.epochDay) / 7 + 1
    }

    public var isoYear: Int { monday.adding(days: 3).year }

    public static func all(isoYear year: Int) -> [Week] {
        var week = Week.of(Day(year: year, month: 1, day: 4))
        var weeks: [Week] = []
        while week.isoYear == year {
            weeks.append(week)
            week = week.next()
        }
        return weeks
    }

    public func focus(today: Day) -> Day { days.contains(today) ? today : monday }
}

public struct TimedBlock: Hashable, Sendable {
    public let id: String
    public let startMinute: Int
    public let endMinute: Int
}

public enum WeekGrid {
    public static let hourMinutes = 60
    public static let dayMinutes = 24 * 60
    public static let minBlockMinutes = 30

    public static func dayRange(_ day: Day, zone: TimeZone) -> (Date, Date) {
        (day.startOfDay(in: zone), day.adding(days: 1).startOfDay(in: zone))
    }

    public static func blockFor(id: String, start: Date, end: Date?, day: Day, zone: TimeZone) -> TimedBlock? {
        let (dayStart, dayEnd) = dayRange(day, zone: zone)
        let realEnd = end ?? start.addingTimeInterval(Double(hourMinutes * 60))
        guard start < dayEnd, realEnd > dayStart else { return nil }
        let from = max(start, dayStart)
        let to = min(realEnd, dayEnd)
        let startMinute = Int(from.timeIntervalSince(dayStart) / 60)
        let endMinute = min(max(Int(to.timeIntervalSince(dayStart) / 60), startMinute + minBlockMinutes), dayMinutes)
        return TimedBlock(id: id, startMinute: startMinute, endMinute: endMinute)
    }

    public static func nowMinute(_ now: Date, zone: TimeZone, day: Day) -> Int? {
        guard Day.of(now, in: zone) == day else { return nil }
        return Int(now.timeIntervalSince(day.startOfDay(in: zone)) / 60)
    }

    public static func hourLabel(_ hour: Int) -> String { String(format: "%02d:00", hour) }

    public static func timeLabel(_ date: Date, zone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0)
    }
}
