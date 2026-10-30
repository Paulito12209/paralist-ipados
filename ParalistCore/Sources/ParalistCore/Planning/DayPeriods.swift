// Zusammenhang: Planning/SpokenEvent.swift, Planning/SpokenParser.swift, Paralist/App/AppPrefs.swift, Paralist/Pages/SettingsPage.swift, Tests/ParalistCoreTests/SpokenEventTests.swift
import Foundation

public enum DayPeriod: String, CaseIterable, Sendable, Hashable {
    case morning = "morgens", noon = "mittags", afternoon = "nachmittags", evening = "abends"

    public var key: String { rawValue }

    public var standardMinute: Int {
        switch self {
        case .morning: return 8 * 60
        case .noon: return 12 * 60
        case .afternoon: return 15 * 60
        case .evening: return 18 * 60
        }
    }
}

public struct DayPeriods: Hashable, Sendable {
    private var minutes: [DayPeriod: Int] = [:]

    public init(_ minutes: [DayPeriod: Int] = [:]) {
        for (period, minute) in minutes { self.minutes[period] = Self.clamp(minute) }
    }

    public static let standard = DayPeriods()

    public subscript(period: DayPeriod) -> Int {
        get { minutes[period] ?? period.standardMinute }
        set { minutes[period] = Self.clamp(newValue) }
    }

    public static func clamp(_ minute: Int) -> Int { min(max(minute, 0), 24 * 60 - 1) }
}

public enum EventTimes {
    public static let defaultMinutes = 60

    public static func end(start: Date, end: Date?) -> Date {
        if let end, end > start { return end }
        return start.addingTimeInterval(Double(defaultMinutes * 60))
    }

    public static func moved(end: Date, from oldStart: Date, to newStart: Date) -> Date {
        let length = max(end.timeIntervalSince(oldStart), 60)
        return newStart.addingTimeInterval(length)
    }
}
