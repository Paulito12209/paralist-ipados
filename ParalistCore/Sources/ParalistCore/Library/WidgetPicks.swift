// Zusammenhang: Model/Entry.swift, Library/ListKind.swift, Links/IncomingLink.swift, ParalistWidgets/EntryEntity.swift, ParalistWidgets/EntryProvider.swift, Tests/ParalistCoreTests/WidgetPicksTests.swift
import Foundation

public enum WidgetPicks {
    public static let limit = 50

    public static func allowed(_ entry: Entry) -> Bool {
        entry.type != .flashcard && !entry.archived
    }

    public static func candidates(_ entries: [Entry], matching query: String = "") -> [Entry] {
        let needle = fold(query.trimmingCharacters(in: .whitespacesAndNewlines))
        let rows = entries.filter { allowed($0) && (needle.isEmpty || fold($0.title).contains(needle)) }
        return Array(rows.sorted(by: order).prefix(limit))
    }

    public static func childCount(_ id: String, in entries: [Entry]) -> Int {
        entries.filter { $0.places.contains(id) && !$0.archived }.count
    }

    static func order(_ a: Entry, _ b: Entry) -> Bool {
        if group(a) != group(b) { return group(a) < group(b) }
        if marked(a) != marked(b) { return marked(a) }
        if a.updated != b.updated { return a.updated > b.updated }
        return a.id < b.id
    }

    private static func group(_ entry: Entry) -> Int {
        switch entry.type {
        case .area: return 0
        case .project: return 1
        default: return 2
        }
    }

    private static func marked(_ entry: Entry) -> Bool { entry.pinned || entry.favorite }

    private static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
    }
}
