// Zusammenhang: Library/EntryLibrary.swift, Model/Entry.swift, Paralist/App/AppPrefs.swift, Paralist/App/AppModel.swift, ParalistShare/ShareViewController.swift
import Foundation

public enum PinLimit {
    public static let range = 1...3
    public static let standard = 1

    public static func clamp(_ value: Int) -> Int { min(max(value, range.lowerBound), range.upperBound) }

    public static func spots(_ entry: Entry) -> Set<String> {
        if !entry.places.isEmpty { return Set(entry.places) }
        return [entry.type.isContainer ? "#" + entry.type.rawValue : "#eingang"]
    }

    public static func displaced(by entry: Entry, among all: [Entry], limit: Int) -> [String] {
        guard entry.pinned, !entry.archived else { return [] }
        let keep = clamp(limit) - 1
        var out: [String] = []
        for spot in spots(entry).sorted() {
            let others = all.filter { $0.id != entry.id && $0.pinned && !$0.archived && !out.contains($0.id) && spots($0).contains(spot) }
                .sorted { ($0.updated, $0.id) < ($1.updated, $1.id) }
            out += others.prefix(max(0, others.count - keep)).map(\.id)
        }
        return out
    }
}
