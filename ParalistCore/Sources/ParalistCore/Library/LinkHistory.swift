// Zusammenhang: Library/EntryLibrary.swift (linkverlauf.json), Library/ClipboardHint.swift, Paralist/Composer/ComposerSheet.swift, Paralist/App/AppModel.swift, Tests/LinkHistoryTests.swift, docs/lesezeichen.md
import Foundation

public struct LinkRecord: Codable, Hashable, Sendable {
    public var url: String
    public var first: Date
    public var last: Date
}

public struct LinkHistory: Codable, Equatable, Sendable {
    public private(set) var links: [String: LinkRecord] = [:]

    public init() {}

    @discardableResult
    public mutating func record(_ url: String?, at time: Date) -> Bool {
        guard let url else { return false }
        let key = Self.key(url)
        guard !key.isEmpty else { return false }
        guard var known = links[key] else {
            links[key] = LinkRecord(url: url.trimmingCharacters(in: .whitespacesAndNewlines), first: time, last: time)
            return true
        }
        guard time < known.first || time > known.last else { return false }
        known.first = min(known.first, time)
        known.last = max(known.last, time)
        links[key] = known
        return true
    }

    public func knows(_ url: String) -> Bool {
        let key = Self.key(url)
        return !key.isEmpty && links[key] != nil
    }

    public func merged(with other: LinkHistory) -> LinkHistory {
        var result = self
        for (key, record) in other.links {
            guard var known = result.links[key] else {
                result.links[key] = record
                continue
            }
            known.first = min(known.first, record.first)
            known.last = max(known.last, record.last)
            result.links[key] = known
        }
        return result
    }

    public static func saved(_ url: String, in entries: [Entry]) -> Entry? {
        let wanted = key(url)
        guard !wanted.isEmpty else { return nil }
        return entries.first { entry in !entry.archived && entry.url.map(key) == wanted }
    }

    public static func key(_ url: String) -> String {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parts = URLComponents(string: trimmed), var host = parts.host?.lowercased() else { return trimmed }
        if host.hasPrefix("www.") { host.removeFirst(4) }
        var path = parts.percentEncodedPath
        while path.hasSuffix("/") { path.removeLast() }
        let query = parts.percentEncodedQuery.map { "?" + $0 } ?? ""
        return host + path + query
    }
}
