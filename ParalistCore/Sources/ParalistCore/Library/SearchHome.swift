// Zusammenhang: Library/Usage.swift, Library/EntryLibrary.swift, Paralist/Search/SearchView.swift, Paralist/Search/SearchHomeTabs.swift
import Foundation

public enum SearchHome: Int, CaseIterable, Sendable {
    case opened, created, searched

    public var key: String {
        switch self {
        case .opened: "search_recent_opened"
        case .created: "search_recent_created"
        case .searched: "search_recent_queries"
        }
    }

    public func step(_ forward: Bool) -> SearchHome {
        let count = Self.allCases.count
        return SearchHome(rawValue: (rawValue + (forward ? 1 : count - 1)) % count) ?? self
    }

    public static func recentlyCreated(_ entries: [Entry], limit: Int = 20) -> [Entry] {
        Array(entries.filter { !$0.archived }.sorted { $0.created != $1.created ? $0.created > $1.created : $0.id > $1.id }.prefix(limit))
    }

    public static func start(entries: [Entry], usage: UsageData) -> SearchHome {
        let created = recentlyCreated(entries, limit: 1).first
        let opened = usage.recent.first
        switch (created, opened) {
        case (nil, nil): return usage.searches.isEmpty ? .opened : .searched
        case (.some, nil): return .created
        case (nil, .some): return .opened
        case let (.some(c), .some(o)):
            if c.id == o.id { return .created }
            return c.created > o.lastOpened ? .created : .opened
        }
    }
}
