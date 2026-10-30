// Zusammenhang: Store/EntryStore.swift, Library/EntryLibrary.swift, Paralist/Pages/TrashPage.swift
import Foundation

public struct TrashedEntry: Hashable, Sendable {
    public let entry: Entry
    public let deletedAt: Date
}

public enum TrashRules {
    public static let retentionDays = 30
    private static let retention: TimeInterval = Double(retentionDays) * 86_400
    private static let suffix = ".md"

    public static func expiresAt(_ deletedAt: Date) -> Date { deletedAt.addingTimeInterval(retention) }

    public static func isExpired(_ deletedAt: Date, now: Date) -> Bool { now >= expiresAt(deletedAt) }

    public static func daysLeft(_ deletedAt: Date, now: Date) -> Int {
        let left = expiresAt(deletedAt).timeIntervalSince(now)
        if left <= 0 { return 0 }
        return Int((left / 86_400).rounded(.up))
    }

    public static func fileName(_ deletedAt: Date, id: String) -> String {
        "\(Int64((deletedAt.timeIntervalSince1970 * 1000).rounded()))-\(id)\(suffix)"
    }

    public static func parseFileName(_ name: String) -> (Date, String)? {
        guard name.hasSuffix(suffix), let dash = name.firstIndex(of: "-"), dash != name.startIndex else { return nil }
        guard let millis = Int64(name[..<dash]) else { return nil }
        let id = String(name[name.index(after: dash)..<name.index(name.endIndex, offsetBy: -suffix.count)])
        if id.isEmpty { return nil }
        return (Date(timeIntervalSince1970: Double(millis) / 1000), id)
    }
}
