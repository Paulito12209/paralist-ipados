// Zusammenhang: Library/OverviewLayout.swift, Library/ListKind.swift (Ordering), Model/Entry.swift, Paralist/Pages/OverviewSections.swift, Paralist/Pages/OverviewSourcePicker.swift, Tests OverviewLayoutTests.swift
import Foundation

public enum OverviewScope {
    public static func contents(of rootId: String, in all: [Entry]) -> [Entry] {
        var children: [String: [Entry]] = [:]
        var byId: [String: Entry] = [:]
        for entry in all {
            byId[entry.id] = entry
            for place in entry.places { children[place, default: []].append(entry) }
        }
        guard let root = byId[rootId] else { return [] }
        var seen: Set<String> = [rootId]
        var result: [Entry] = []
        var queue = [rootId]
        while !queue.isEmpty {
            let next = queue.removeFirst()
            for child in children[next] ?? [] where seen.insert(child.id).inserted {
                result.append(child)
                queue.append(child.id)
            }
        }
        for id in root.links where seen.insert(id).inserted {
            if let linked = byId[id] { result.append(linked) }
        }
        return result.filter { !$0.archived }.sorted(by: Ordering.pinnedThenUpdated)
    }

    public static func choices(in all: [Entry], query: String = "") -> [Entry] {
        let text = query.trimmingCharacters(in: .whitespaces)
        let open = all.filter { !$0.archived && !$0.title.trimmingCharacters(in: .whitespaces).isEmpty }
        let matched = text.isEmpty ? open : open.filter { $0.title.localizedCaseInsensitiveContains(text) }
        return matched.sorted { a, b in
            let ra = rank(a), rb = rank(b)
            if ra != rb { return ra < rb }
            return a.updated > b.updated
        }
    }

    static func rank(_ entry: Entry) -> Int {
        if entry.favorite { return 0 }
        if entry.type.isContainer || entry.type == .tag { return 1 }
        return 2
    }
}
