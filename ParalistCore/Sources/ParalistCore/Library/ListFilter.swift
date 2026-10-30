// Zusammenhang: Library/ListKind.swift, Links/SharedFile.swift (MediaKind), Paralist/Pages/ListPage.swift, Paralist/Pages/ListFilterRow.swift, Tests ListFilterTests.swift
import Foundation

public enum ListFilter: String, CaseIterable, Sendable, Hashable {
    case all, areas, projects, tasks, events, notes, documents, bookmarks, images, videos, audios, files, flashcards

    public static func tabs(for kind: ListKind) -> [ListFilter] {
        switch kind {
        case .archive: return allCases
        case .resources: return [.all, .notes, .documents, .bookmarks, .images, .videos, .audios, .files]
        default: return []
        }
    }

    public static func visible(for kind: ListKind, in entries: [Entry]) -> [ListFilter] {
        tabs(for: kind).filter { $0 == .all || entries.contains(where: $0.matches) }
    }

    public func matches(_ e: Entry) -> Bool {
        switch self {
        case .all: return true
        case .areas: return e.type == .area
        case .projects: return e.type == .project
        case .tasks: return e.type == .task
        case .events: return e.type == .event
        case .notes: return e.type == .note
        case .documents: return e.type == .document
        case .bookmarks: return e.type == .bookmark
        case .flashcards: return e.type == .flashcard || e.type == .deck
        case .images: return e.type == .file && MediaKind.of(e) == .image
        case .videos: return e.type == .file && MediaKind.of(e) == .video
        case .audios: return e.type == .file && MediaKind.of(e) == .audio
        case .files: return e.type == .file && ![.image, .video, .audio].contains(MediaKind.of(e))
        }
    }
}
