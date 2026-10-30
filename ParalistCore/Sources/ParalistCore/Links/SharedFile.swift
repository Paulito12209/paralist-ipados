// Zusammenhang: Links/FileKind.swift, Model/Entry.swift, Text/SearchQuery.swift, ParalistShare/ShareModel.swift, Paralist/Files/AttachmentImporter.swift
import Foundation

public enum MediaKind: String, CaseIterable, Sendable, Hashable {
    case image, video, audio, document

    public static func of(mime: String) -> MediaKind {
        let m = mime.lowercased()
        if m.hasPrefix("image/") { return .image }
        if m.hasPrefix("video/") { return .video }
        if m.hasPrefix("audio/") { return .audio }
        return .document
    }

    public static func of(_ entry: Entry) -> MediaKind? {
        if let a = entry.attachment { return of(mime: a.mime) }
        return entry.type == .document ? .document : nil
    }

    public var entryType: EntryType { self == .document ? .document : .file }
}

public enum SharedFile {
    public static let maxFiles = 10

    public static func title(_ name: String) -> String {
        let last = name.split(separator: "/").last.map(String.init) ?? name
        var stem = last
        if let dot = last.lastIndex(of: "."), dot != last.startIndex { stem = String(last[..<dot]) }
        let clean = String(String.UnicodeScalarView(stem.unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) }))
        return String(clean.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Limits.maxTitleChars))
    }

    public static func linkCandidates(_ all: [Entry], excluding kinds: Set<MediaKind>, query: String = "") -> [Entry] {
        let terms = SearchQuery.terms(query)
        return all.filter { e in
            guard !e.archived else { return false }
            if let kind = MediaKind.of(e), kinds.contains(kind) { return false }
            return terms.isEmpty || SearchQuery.matches(e, terms: terms)
        }
        .sorted { ($0.updated, $0.id) > ($1.updated, $1.id) }
    }
}
