// Zusammenhang: Model/EntryType.swift (TaskStatus), Model/Entry.swift, Model/FileCategory.swift, Links/SpotifyLinks.swift, Links/VideoLinks.swift, Library/EntryLibrary.swift (setStatus), Paralist/Entries/TypeLook.swift (StatusLook), Paralist/Entry/EntryActions.swift
import Foundation

public enum EntryStatus {
    public static func options(for entry: Entry) -> [TaskStatus] {
        switch entry.type {
        case .task, .project: return [.open, .inProgress, .done]
        case .event: return [.open, .inProgress, .done, .postponed, .cancelled]
        case .area: return [.open, .closed]
        case .note: return [.open, .read]
        case .document: return [.open, .inProgress, .read]
        case .deck: return [.open, .learned]
        case .flashcard: return [.open, .hard, .good, .easy]
        case .bookmark: return [.open, consumed(url: entry.url), .shared]
        case .file: return [.open, consumed(mime: entry.attachment?.mime), .shared]
        case .tag: return []
        }
    }

    public static func label(_ status: TaskStatus, for type: EntryType) -> String {
        switch (status, type) {
        case (.open, .note), (.open, .document): return "status_unfinished"
        case (.done, .project): return "status_closed_project"
        case (.done, .event): return "status_held"
        default: return key(status)
        }
    }

    public static func key(_ status: TaskStatus) -> String {
        switch status {
        case .open: return "status_open"
        case .inProgress: return "status_in_progress"
        case .done: return "status_done"
        case .postponed: return "status_postponed"
        case .cancelled: return "status_cancelled"
        case .closed: return "status_closed"
        case .read: return "status_read"
        case .viewed: return "status_viewed"
        case .listened: return "status_listened"
        case .played: return "status_played"
        case .shared: return "status_shared"
        case .learned: return "status_learned"
        case .hard: return "status_hard"
        case .good: return "status_good"
        case .easy: return "status_easy"
        }
    }

    public static func consumed(url: String?) -> TaskStatus {
        guard let url else { return .read }
        if SpotifyLinks.item(url) != nil { return .listened }
        if VideoLinks.youtubeId(url) != nil { return .viewed }
        return .read
    }

    public static func consumed(mime: String?) -> TaskStatus {
        guard let mime else { return .read }
        if mime.hasPrefix("image/") { return .viewed }
        if mime.hasPrefix("video/") { return .played }
        if mime.hasPrefix("audio/") { return .listened }
        return .read
    }

    public static func valid(_ status: TaskStatus?, for entry: Entry) -> TaskStatus? {
        guard entry.type.hasStatus else { return nil }
        let allowed = options(for: entry)
        if let status, allowed.contains(status) { return status }
        return .open
    }

    public static func rated(_ rating: Rating) -> TaskStatus {
        switch rating {
        case .again, .hard: return .hard
        case .good: return .good
        case .easy: return .easy
        }
    }
}
