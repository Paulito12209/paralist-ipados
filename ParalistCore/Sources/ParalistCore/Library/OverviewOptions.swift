// Zusammenhang: Library/OverviewLayout.swift (tabDisplay, sectionLimit, category), Library/ListKind.swift (collections, lists), Paralist/Pages/OverviewParts.swift, Paralist/Pages/OverviewTabsPage.swift, Paralist/Pages/SettingsPage.swift, Tests OverviewLayoutTests.swift
import Foundation

public enum OverviewSourceCategory: String, CaseIterable, Sendable {
    case list, collection, entry
}

public enum OverviewTabDisplay: String, CaseIterable, Sendable {
    case both = "beides"
    case name = "name"
    case icon = "icon"

    public var showsIcon: Bool { self != .name }
    public var showsName: Bool { self != .icon }
}

public enum OverviewSectionLimit {
    public static let steps = [5, 10, 15, 20, 25, 50, 100]
    public static let individual = 10

    public static func clamp(_ value: Int) -> Int {
        steps.min { abs($0 - value) < abs($1 - value) } ?? individual
    }

    public static func index(_ value: Int) -> Int { steps.firstIndex(of: clamp(value)) ?? 0 }

    public static func cut<K, T>(groups: [(K, [T])], limit: Int?) -> (groups: [(K, [T])], more: Int) {
        guard let limit else { return (groups, 0) }
        var left = clamp(limit)
        var kept: [(K, [T])] = []
        var more = 0
        for (key, rows) in groups {
            let taken = Array(rows.prefix(left))
            more += rows.count - taken.count
            left -= taken.count
            if !taken.isEmpty { kept.append((key, taken)) }
        }
        return (kept, more)
    }
}
