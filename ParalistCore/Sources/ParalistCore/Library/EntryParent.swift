// Zusammenhang: Model/Entry.swift, Model/EntryType.swift, Model/Day.swift, Markdown/EntryCodec.swift (extras), Paralist/Entry/EntryParts.swift (PlaceRow, EntrySheets), Paralist/Entry/EntryDateRow.swift, Tests/ParalistCoreTests/EntryParentTests.swift
import Foundation

public enum EntryParent {
    public static func applies(to type: EntryType) -> Bool { type != .area }

    public static func candidates(for entry: Entry, among containers: [Entry]) -> [Entry] {
        containers.filter { $0.id != entry.id && (entry.type != .project || $0.type == .area) && !$0.places.contains(entry.id) }
    }

    public static func canHold(_ parent: Entry, for type: EntryType) -> Bool {
        parent.type.isContainer || (type == .tag && parent.type == .tag)
    }

    public static func candidates(for entry: Entry, in all: [Entry]) -> [Entry] {
        let byTitle: (Entry, Entry) -> Bool = { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        let open = all.filter { !$0.archived && canHold($0, for: entry.type) }
        let pool = open.filter(\.type.isContainer).sorted(by: byTitle) + open.filter { !$0.type.isContainer }.sorted(by: byTitle)
        let byId = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        return candidates(for: entry, among: pool).filter { !descends($0, from: entry.id, byId) }
    }

    static func descends(_ entry: Entry, from ancestor: String, _ byId: [String: Entry]) -> Bool {
        var current = entry.places.first
        var seen: Set<String> = []
        while let id = current, seen.insert(id).inserted {
            if id == ancestor { return true }
            current = byId[id]?.places.first
        }
        return false
    }
}

public struct DueTime: Hashable, Sendable, CustomStringConvertible {
    public let hour: Int
    public let minute: Int

    public init?(hour: Int, minute: Int) {
        guard (0...23).contains(hour), (0...59).contains(minute) else { return nil }
        self.hour = hour
        self.minute = minute
    }

    public static func parse(_ text: String) -> DueTime? {
        let parts = text.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2, parts.allSatisfy({ $0.count == 2 }), let h = Int(parts[0]), let m = Int(parts[1]) else { return nil }
        return DueTime(hour: h, minute: m)
    }

    public static func of(_ date: Date, in zone: TimeZone) -> DueTime? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return DueTime(hour: c.hour ?? 0, minute: c.minute ?? 0)
    }

    public var description: String { String(format: "%02d:%02d", hour, minute) }
}

public extension Entry {
    static let dueTimeKey = "faellig_zeit"

    var dueTime: DueTime? {
        guard due != nil, let raw = extras[Self.dueTimeKey] else { return nil }
        return DueTime.parse(raw)
    }

    func dueDate(in zone: TimeZone) -> Date? {
        due.map { $0.at(hour: dueTime?.hour ?? 12, minute: dueTime?.minute ?? 0, in: zone) }
    }

    mutating func setDue(_ day: Day?) {
        due = day
        if day == nil { extras[Self.dueTimeKey] = nil }
    }

    mutating func setDueTime(_ time: DueTime?) {
        extras[Self.dueTimeKey] = due == nil ? nil : time?.description
    }
}
