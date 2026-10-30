// Zusammenhang: Markdown/EntryCodec.swift, Flashcards/ReviewLog.swift, Model/Day.swift
import Foundation

public enum Instants {
    private static let pattern = Pattern("^(\\d{4})-(\\d{2})-(\\d{2})T(\\d{2}):(\\d{2})(?::(\\d{2})(?:\\.(\\d{1,9}))?)?(Z|[+-]\\d{2}:\\d{2})$")

    public static func parse(_ text: String) -> Date? {
        guard pattern.matches(text), let m = pattern.first(in: text) else { return nil }
        guard let day = Day.parse("\(m.group(1))-\(m.group(2))-\(m.group(3))"),
              let hour = Int(m.group(4)), let minute = Int(m.group(5)), hour < 24, minute < 60 else { return nil }
        let second = Int(m.group(6)) ?? 0
        guard second < 60 else { return nil }
        let fraction = m.group(7)
        let nanos = fraction.isEmpty ? 0.0 : (Double("0." + fraction) ?? 0)
        var offset = 0
        let zone = m.group(8)
        if zone != "Z" {
            let sign = zone.hasPrefix("-") ? -1 : 1
            let parts = zone.dropFirst().split(separator: ":")
            offset = sign * ((Int(parts[0]) ?? 0) * 3600 + (Int(parts[1]) ?? 0) * 60)
        }
        let seconds = Double(day.epochDay) * 86_400 + Double(hour * 3600 + minute * 60 + second) - Double(offset)
        return Date(timeIntervalSince1970: seconds + nanos)
    }

    public static func format(_ date: Date) -> String {
        let totalMillis = (date.timeIntervalSince1970 * 1000).rounded()
        let millis = Int64(totalMillis)
        let seconds = Int64((Double(millis) / 1000).rounded(.down))
        let ms = Int(millis - seconds * 1000)
        let days = Int((Double(seconds) / 86_400).rounded(.down))
        let rest = Int(seconds - Int64(days) * 86_400)
        let day = Day(epochDay: days)
        let time = String(format: "%02d:%02d:%02d", rest / 3600, (rest % 3600) / 60, rest % 60)
        let fraction = ms == 0 ? "" : String(format: ".%03d", ms)
        return "\(day)T\(time)\(fraction)Z"
    }

    public static func utcYear(_ date: Date) -> Int {
        Day(epochDay: Int((date.timeIntervalSince1970 / 86_400).rounded(.down))).year
    }
}
