// Zusammenhang: Model/Entry.swift, Markdown/EntryCodec.swift, Paralist/Entries/TypeLook.swift
import Foundation

public enum EntryType: String, CaseIterable, Sendable, Hashable, Codable {
    case note = "notiz"
    case task = "aufgabe"
    case event = "termin"
    case project = "projekt"
    case area = "arbeitsbereich"
    case bookmark = "lesezeichen"
    case file = "datei"
    case document = "dokument"
    case flashcard = "karteikarte"
    case deck = "kartendeck"
    case tag = "tag"

    public var key: String { rawValue }

    public var isContainer: Bool { self == .project || self == .area }

    public var hasDate: Bool { self == .task || self == .event || self == .project }

    public var hasStatus: Bool { self != .tag }

    public static func fromKey(_ key: String?) -> EntryType? {
        guard let key else { return nil }
        return EntryType(rawValue: key)
    }
}

public enum TaskStatus: String, CaseIterable, Sendable, Hashable, Codable {
    case open = "offen"
    case inProgress = "laufend"
    case done = "erledigt"
    case postponed = "verschoben"
    case cancelled = "abgesagt"
    case closed = "geschlossen"
    case read = "gelesen"
    case viewed = "angesehen"
    case listened = "angehoert"
    case played = "abgespielt"
    case shared = "geteilt"
    case learned = "gelernt"
    case hard = "schwer"
    case good = "gut"
    case easy = "leicht"

    public var key: String { rawValue }

    public static func fromKey(_ key: String?) -> TaskStatus? {
        guard let key else { return nil }
        return TaskStatus(rawValue: key)
    }
}

public enum TagKind: String, CaseIterable, Sendable, Hashable, Codable {
    case tag = "tag"
    case person = "person"
    case place = "ort"

    public var key: String { rawValue }

    public static func fromKey(_ key: String?) -> TagKind? {
        guard let key else { return nil }
        return TagKind(rawValue: key)
    }
}
