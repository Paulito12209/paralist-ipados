// Zusammenhang: Library/EntryLibrary.swift, Library/SearchHome.swift, Paralist/Search/SearchView.swift
import Foundation

public struct UsageRecord: Codable, Hashable, Sendable {
    public var id: String
    public var lastOpened: Date
    public var openCount: Int
}

public struct SearchRecord: Codable, Hashable, Sendable {
    public var query: String
    public var at: Date
}

public struct EventChange: Codable, Hashable, Sendable {
    public var at: Date
    public var from: Date?
    public var to: Date?
    public var cancelled: Bool

    public init(at: Date, from: Date? = nil, to: Date? = nil, cancelled: Bool = false) {
        self.at = at
        self.from = from
        self.to = to
        self.cancelled = cancelled
    }
}

public struct UsageData: Codable, Sendable {
    public var opened: [String: UsageRecord] = [:]
    public var searches: [SearchRecord] = []
    public var shared: [String: Int] = [:]
    public var eventChanges: [String: [EventChange]] = [:]

    public init() {}

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        opened = try c.decodeIfPresent([String: UsageRecord].self, forKey: .opened) ?? [:]
        searches = try c.decodeIfPresent([SearchRecord].self, forKey: .searches) ?? []
        shared = try c.decodeIfPresent([String: Int].self, forKey: .shared) ?? [:]
        eventChanges = try c.decodeIfPresent([String: [EventChange]].self, forKey: .eventChanges) ?? [:]
    }

    public func changes(_ id: String) -> [EventChange] { eventChanges[id] ?? [] }

    public func moves(_ id: String) -> Int { changes(id).filter { !$0.cancelled }.count }

    public mutating func recordMoved(_ id: String, from: Date?, to: Date?, at: Date) {
        guard from != to else { return }
        eventChanges[id, default: []].append(EventChange(at: at, from: from, to: to))
    }

    public mutating func recordCancelled(_ id: String, at: Date) {
        eventChanges[id, default: []].append(EventChange(at: at, cancelled: true))
    }

    public func views(_ id: String) -> Int { opened[id]?.openCount ?? 0 }

    public func shares(_ id: String) -> Int { shared[id] ?? 0 }

    public mutating func recordShared(_ id: String) { shared[id, default: 0] += 1 }

    public var recent: [UsageRecord] { Array(opened.values.sorted { $0.lastOpened > $1.lastOpened }.prefix(20)) }

    public var recentSearches: [SearchRecord] { Array(searches.sorted { $0.at > $1.at }.prefix(20)) }

    public mutating func recordOpened(_ id: String, at: Date) {
        let previous = opened[id]?.openCount ?? 0
        opened[id] = UsageRecord(id: id, lastOpened: at, openCount: previous + 1)
    }

    public mutating func recordSearch(_ text: String, at: Date) {
        let normalized = SearchQuery.normalize(text)
        if normalized.isEmpty { return }
        searches.removeAll { $0.query == normalized }
        searches.append(SearchRecord(query: normalized, at: at))
        searches = Array(searches.sorted { $0.at > $1.at }.prefix(50))
    }

    public mutating func forgetSearch(_ text: String) { searches.removeAll { $0.query == text } }

    public mutating func forget(_ id: String) {
        opened[id] = nil
        shared[id] = nil
        eventChanges[id] = nil
    }
}
