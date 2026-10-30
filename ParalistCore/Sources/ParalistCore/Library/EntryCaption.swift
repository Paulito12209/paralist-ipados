// Zusammenhang: Library/ListKind.swift, Library/ListFilter.swift, Links/LinkBrand.swift, Links/LinkLogoLibrary.swift, Model/FileCategory.swift, Paralist/Entries/EntrySubtitle.swift, Tests EntryCaptionTests.swift
import Foundation

public enum FileKindLabel: Sendable, Equatable {
    case photo, video, audio, pdf, file

    public static func of(_ category: FileCategory) -> FileKindLabel {
        switch category {
        case .photo: return .photo
        case .video: return .video
        case .audio: return .audio
        case .pdf: return .pdf
        case .markdown, .text, .other: return .file
        }
    }
}

public enum EntryCaption: Sendable, Equatable {
    case type(EntryType)
    case brand(name: String, logos: [String])
    case domain(String)
    case file(FileKindLabel)

    public static func of(_ entry: Entry, showsType: Bool) -> EntryCaption? {
        switch entry.type {
        case .bookmark:
            if let url = entry.url {
                if let name = LinkBrand.name(url) { return .brand(name: name, logos: LinkLogoLibrary.assetNames(url)) }
                if let host = LinkBrand.host(url) { return .domain(host) }
            }
        case .file:
            if let attachment = entry.attachment { return .file(FileKindLabel.of(FileCategory.of(attachment))) }
        default:
            break
        }
        return showsType ? .type(entry.type) : nil
    }
}

extension ListKind {
    public var isSingleCategory: Bool {
        switch self {
        case .notes, .tasks, .events, .bookmarks, .files, .tags, .flashcards, .projects, .areas: return true
        case .inbox, .marked, .pinned, .favorites, .all, .archive, .resources: return false
        }
    }

    public func showsType(filter: ListFilter = .all) -> Bool {
        !isSingleCategory && filter == .all
    }
}
