// Zusammenhang: Planning/SpokenParser.swift, Planning/SpokenDates.swift, Planning/SpokenTimes.swift, Planning/SpokenWords.swift, Planning/SpokenRefinement.swift, Planning/DayPeriods.swift, Library/ComposerDraft.swift, Paralist/Composer/ComposerDictation.swift, Paralist/Intents/NewEntryIntent.swift, Tests/ParalistCoreTests/SpokenEventTests.swift
import Foundation

public struct SpokenEvent: Hashable, Sendable {
    public var title: String
    public var day: Day?
    public var startMinute: Int?
    public var endDay: Day?
    public var endMinute: Int?
    public var allDay = false
    public var reminder = false

    public static let roundMinutes = 15

    public init(title: String, day: Day? = nil, startMinute: Int? = nil, endDay: Day? = nil, endMinute: Int? = nil, allDay: Bool = false) {
        self.title = title
        self.day = day
        self.startMinute = startMinute
        self.endDay = endDay
        self.endMinute = endMinute
        self.allDay = allDay
    }

    public static func parse(_ text: String, now: Date, zone: TimeZone, periods: DayPeriods = .standard, baseDay: Day? = nil, baseMinute: Int? = nil) -> SpokenEvent {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let c = calendar.dateComponents([.hour, .minute], from: now)
        return parse(text, today: Day.of(now, in: zone), nowMinute: (c.hour ?? 0) * 60 + (c.minute ?? 0), periods: periods, baseDay: baseDay, baseMinute: baseMinute)
    }

    public static func parse(_ text: String, today: Day, nowMinute: Int, periods: DayPeriods = .standard, baseDay: Day? = nil, baseMinute: Int? = nil) -> SpokenEvent {
        var parser = SpokenParser(String(text.prefix(Limits.maxTitleChars * 4)))
        parser.run(today: today)
        if var s = parser.start, s.pm == nil, let e = parser.end, let pm = e.pm, s.hour <= e.hour {
            s.pm = pm
            parser.start = s
        }
        var start = parser.start.map { $0.minuteOfDay(parser.period) }
        if start == nil, let period = parser.period { start = periods[period] }
        var day = parser.day ?? baseDay
        if start == nil, parser.sameTime {
            start = baseMinute ?? rounded(nowMinute)
        }
        if start == nil, let baseMinute, baseDay != nil, parser.day == nil, parser.inMinutes == nil { start = baseMinute }
        if start == nil, let offset = parser.inMinutes {
            let total = rounded(nowMinute + offset)
            if parser.day == nil { day = today.adding(days: total / 1440) }
            start = total % 1440
        }
        var end: Int?
        if let e = parser.end, let s = start {
            var m = e.minuteOfDay(parser.period)
            if m <= s, e.pm == nil, e.hour < 12, m + 720 > s { m += 720 }
            end = m == s ? nil : m
        } else if let minutes = parser.duration, let s = start {
            end = s + minutes
        }
        if parser.allDay {
            start = nil
            end = nil
        }
        if day == nil, let s = start { day = s > nowMinute ? today : today.adding(days: 1) }
        var event = SpokenEvent(title: parser.title, day: day, startMinute: day == nil ? nil : start, allDay: parser.allDay)
        event.reminder = parser.reminder
        if let day, let s = start, var m = end {
            var extra = m < s ? 1 : 0
            extra += m / 1440
            m %= 1440
            event.endDay = day.adding(days: extra)
            event.endMinute = m
        }
        return event
    }

    static func rounded(_ minute: Int) -> Int {
        let step = roundMinutes
        return (minute + step / 2) / step * step
    }
}
