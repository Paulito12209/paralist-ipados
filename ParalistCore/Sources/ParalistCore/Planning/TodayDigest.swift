// Zusammenhang: Planning/WeekBriefing.swift, Model/Entry.swift, Model/Day.swift, Paralist/Intents/TodayIntent.swift, Tests/ParalistCoreTests/TodayDigestTests.swift
import Foundation

public struct TodayDigest: Hashable, Sendable {
    public enum Item: Hashable, Sendable {
        case event(Entry, time: Date?)
        case task(Entry, overdue: Bool)

        public var entry: Entry {
            switch self {
            case .event(let entry, _), .task(let entry, _): return entry
            }
        }
    }

    public static let limit = 5

    public let items: [Item]
    public let more: Int

    public var isEmpty: Bool { items.isEmpty }

    public static func build(_ entries: [Entry], today: Day, zone: TimeZone, limit: Int = limit) -> TodayDigest {
        let alive = entries.filter { !$0.archived && !$0.isDone }
        let events = alive.filter { $0.type == .event && $0.start != nil && WeekBriefingBuilder.spans($0, today, zone) }
            .sorted { a, b in
                if a.allDay != b.allDay { return a.allDay }
                if a.start != b.start { return a.start! < b.start! }
                return a.id < b.id
            }
            .map { Item.event($0, time: $0.allDay || Day.of($0.start!, in: zone) != today ? nil : $0.start) }
        let tasks = alive.filter { $0.type == .task && $0.due.map { $0 <= today } == true }
            .sorted { a, b in
                if a.due != b.due { return a.due! < b.due! }
                return a.id < b.id
            }
            .map { Item.task($0, overdue: $0.due! < today) }
        let all = events + tasks
        let shown = Array(all.prefix(max(limit, 0)))
        return TodayDigest(items: shown, more: all.count - shown.count)
    }
}
