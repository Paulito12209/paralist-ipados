// Zusammenhang: Model/Entry.swift, Model/EntryType.swift, Tests/ParalistCoreTests/LinkPickerTests.swift, Paralist/Entry/LinkPickerSheet.swift, Paralist/Entries/TypeLook.swift (ListTitles)
import Foundation

public enum LinkTab: String, CaseIterable, Sendable, Hashable, Identifiable {
    case areas, projects, tags, tasks, notes, events, resources, decks, flashcards

    public var id: String { rawValue }

    public var types: [EntryType] {
        switch self {
        case .projects: return [.project]
        case .areas: return [.area]
        case .tasks: return [.task]
        case .notes: return [.note]
        case .events: return [.event]
        case .resources: return [.bookmark, .file, .document]
        case .decks: return [.deck]
        case .flashcards: return [.flashcard]
        case .tags: return [.tag]
        }
    }

    public var creates: EntryType? {
        switch self {
        case .events, .resources: return nil
        default: return types.first
        }
    }
}

public enum LinkPicker {
    public static func tabs(for type: EntryType) -> [LinkTab] {
        LinkTab.allCases.filter { $0.types != [type] || type == .tag }
    }

    public static func entries(_ tab: LinkTab, for entry: Entry, in all: [Entry]) -> [Entry] {
        candidates(for: entry, in: all).filter { tab.types.contains($0.type) }.sorted { $0.updated > $1.updated }
    }

    public static func suggestions(for entry: Entry, in all: [Entry], limit: Int = 12) -> [Entry] {
        let words = keywords(entry.title)
        let scored = candidates(for: entry, in: all).map { candidate -> (Entry, Int) in
            var score = keywords(candidate.title).intersection(words).count * 2
            if !Set(candidate.places).isDisjoint(with: entry.places) { score += 3 }
            if candidate.places.contains(entry.id) || entry.places.contains(candidate.id) { score += 3 }
            return (candidate, score)
        }
        let ranked = scored.sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.0.updated > $1.0.updated }
        return Array(ranked.prefix(limit).map(\.0))
    }

    public static func matching(_ query: String, tabs: [LinkTab], for entry: Entry, in all: [Entry]) -> [Entry] {
        let terms = SearchQuery.terms(query)
        guard !terms.isEmpty else { return [] }
        let allowed = Set(tabs.flatMap(\.types))
        return candidates(for: entry, in: all)
            .filter { allowed.contains($0.type) && SearchQuery.matches($0, terms: terms) }
            .sorted { $0.updated > $1.updated }
    }

    static func candidates(for entry: Entry, in all: [Entry]) -> [Entry] {
        let allowed = Set(tabs(for: entry.type).flatMap(\.types))
        return all.filter { $0.id != entry.id && !$0.archived && ($0.type != entry.type || entry.type == .tag) && allowed.contains($0.type) }
    }

    static func keywords(_ title: String) -> Set<String> {
        Set(title.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init).filter { $0.count >= 4 })
    }
}
