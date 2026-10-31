// Zusammenhang: Library/EntryLibrary.swift, Library/ListFilter.swift, Paralist/Pages/OverviewPage.swift, Paralist/Pages/ListPage.swift, Paralist/Pages/ViewSheet.swift
import Foundation

public enum ListKind: String, CaseIterable, Sendable, Hashable, Identifiable {
    case inbox = "eingang"
    case marked = "markiert"
    case pinned = "angepinnt"
    case favorites = "favoriten"
    case all = "alle"
    case archive = "archiv"
    case projects = "projekte"
    case areas = "arbeitsbereiche"
    case resources = "ressourcen"
    case notes = "notizen"
    case tasks = "aufgaben"
    case events = "termine"
    case bookmarks = "lesezeichen"
    case files = "dateien"
    case tags = "tags"
    case flashcards = "karteikarten"

    public var id: String { rawValue }
    public var key: String { rawValue }

    public var types: [EntryType] {
        switch self {
        case .projects: return [.project]
        case .areas: return [.area]
        case .resources: return [.bookmark, .document, .file]
        case .notes: return [.note]
        case .tasks: return [.task]
        case .events: return [.event]
        case .bookmarks: return [.bookmark]
        case .files: return [.file]
        case .tags: return [.tag]
        case .flashcards: return [.flashcard, .deck]
        default: return []
        }
    }

    public static let tiles: [ListKind] = [.projects, .areas, .resources, .archive]
    public static let collections: [ListKind] = [.inbox, .pinned, .favorites, .resources, .archive, .all]
    public static let lists: [ListKind] = [.notes, .tasks, .events, .bookmarks, .files, .tags, .flashcards, .projects, .areas]

    public var isCollection: Bool { Self.collections.contains(self) }

    public static func fromKey(_ key: String?) -> ListKind? { key.flatMap(ListKind.init(rawValue:)) }

    public func includes(_ e: Entry) -> Bool {
        switch self {
        case .inbox: return e.isInInbox
        case .marked: return (e.favorite || e.pinned) && !e.archived
        case .pinned: return e.pinned && !e.archived
        case .favorites: return e.favorite && !e.archived
        case .all: return !e.archived
        case .archive: return e.archived
        case .resources: return (types.contains(e.type) || e.type == .note) && !e.archived
        default: return types.contains(e.type) && !e.archived
        }
    }
}

public enum Ordering {
    public static func pinnedThenUpdated(_ a: Entry, _ b: Entry) -> Bool {
        if a.pinned != b.pinned { return a.pinned }
        return a.updated > b.updated
    }

    public static func pinnedLead(_ entries: [Entry]) -> Entry? {
        entries.filter(\.pinned).min { a, b in a.updated != b.updated ? a.updated > b.updated : a.id < b.id }
    }

    public static func tasks(_ a: Entry, _ b: Entry) -> Bool {
        if a.isDone != b.isDone { return !a.isDone }
        return pinnedThenUpdated(a, b)
    }
}
