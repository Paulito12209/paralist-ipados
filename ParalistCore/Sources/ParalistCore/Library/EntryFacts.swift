// Zusammenhang: Library/Usage.swift, Model/Entry.swift, Model/FileCategory.swift, Text/MarkdownBlocks.swift, Paralist/Entry/EntryInfoSheet.swift, Paralist/Entry/EntryMetaRow.swift
import Foundation

public enum EntryFactKind: String, Sendable {
    case photo, video, audio, file, entry
}

public enum EntryFacts {
    public static func words(_ body: String) -> Int {
        body.split { $0.isWhitespace || $0.isNewline }
            .filter { $0.contains { $0.isLetter || $0.isNumber } }
            .count
    }

    public static func kind(_ entry: Entry) -> EntryFactKind {
        guard let attachment = entry.attachment else { return .entry }
        switch FileCategory.of(attachment) {
        case .photo: return .photo
        case .video: return .video
        case .audio: return .audio
        default: return .file
        }
    }

    public static func edited(_ entry: Entry) -> Bool {
        abs(entry.updated.timeIntervalSince(entry.created)) >= 60
    }

    public static func source(_ entry: Entry) -> String? {
        guard let url = entry.url?.trimmingCharacters(in: .whitespacesAndNewlines), !url.isEmpty else { return nil }
        return url
    }

    public static func title(_ entry: Entry) -> String {
        entry.title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func content(_ entry: Entry) -> String {
        [entry.title, entry.body]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }
}
