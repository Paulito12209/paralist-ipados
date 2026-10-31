// Zusammenhang: Library/ListKind.swift, Paralist/App/AppPrefs.swift, Paralist/Pages/ViewSheet.swift, Paralist/Pages/OverviewPage.swift, Paralist/Pages/ListPage.swift
import Foundation

public enum SortOrder: String, CaseIterable, Sendable {
    case updated = "geaendert", title = "titel", created = "erstellt"

    public static func fromKey(_ key: String?) -> SortOrder { key.flatMap(SortOrder.init(rawValue:)) ?? .created }

    public var naturalAscending: Bool { self == .title }
}

public enum Grouping: String, CaseIterable, Sendable {
    case none = "keine", type = "art"

    public static func fromKey(_ key: String?) -> Grouping { key.flatMap(Grouping.init(rawValue:)) ?? .none }
}

public struct ViewSetting: Hashable, Sendable {
    public var sort: SortOrder
    public var ascending: Bool
    public var grouping: Grouping
    public var hidden: Set<EntryType>

    public init(sort: SortOrder = .created, ascending: Bool? = nil, grouping: Grouping = .none, hidden: Set<EntryType> = []) {
        self.sort = sort
        self.ascending = ascending ?? sort.naturalAscending
        self.grouping = grouping
        self.hidden = hidden
    }

    public static func standard(for kind: ListKind) -> ViewSetting {
        ViewSetting(hidden: kind == .inbox ? [.tag] : [])
    }

    public func shows(_ entry: Entry) -> Bool { !hidden.contains(entry.type) }

    public func choices(for kind: ListKind) -> [EntryType] {
        let all = kind.filterChoices
        return all.filter(hidden.contains) + all.filter { !hidden.contains($0) }
    }

    public func arrange(_ rows: [Entry]) -> [(EntryType?, [Entry])] {
        let sorted = rows.filter(shows).sorted { a, b in
            if a.pinned != b.pinned { return a.pinned }
            switch sort {
            case .updated: return ascending ? a.updated < b.updated : a.updated > b.updated
            case .created: return ascending ? a.created < b.created : a.created > b.created
            case .title:
                let order = a.title.localizedCaseInsensitiveCompare(b.title)
                return ascending ? order == .orderedAscending : order == .orderedDescending
            }
        }
        if grouping == .none { return [(nil, sorted)] }
        return EntryType.allCases.compactMap { type in
            let group = sorted.filter { $0.type == type }
            return group.isEmpty ? nil : (type, group)
        }
    }

    public static func hiddenKey(_ hidden: Set<EntryType>) -> String {
        EntryType.allCases.filter(hidden.contains).map(\.key).joined(separator: ",")
    }

    public static func hidden(fromKey key: String) -> Set<EntryType> {
        Set(key.split(separator: ",").compactMap { EntryType.fromKey(String($0)) })
    }
}

extension ListKind {
    public var filterChoices: [EntryType] {
        switch self {
        case .resources: return [.note, .bookmark, .document, .file]
        case .inbox: return EntryType.allCases.filter { !$0.isContainer }
        default:
            if types.count == 1 { return [] }
            return types.isEmpty ? EntryType.allCases : types
        }
    }
}
