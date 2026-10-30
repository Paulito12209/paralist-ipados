// Zusammenhang: Model/EntryType.swift, Model/Day.swift, Markdown/EntryCodec.swift, Store/EntryStore.swift, Library/EntryLibrary.swift
import Foundation

public struct Attachment: Hashable, Sendable {
    public var hash: String
    public var name: String
    public var mime: String
    public var size: Int64

    public init(hash: String, name: String, mime: String, size: Int64) {
        self.hash = hash
        self.name = name
        self.mime = mime
        self.size = size
    }

    public static func isValidHash(_ value: String) -> Bool {
        value.count == 64 && value.utf8.allSatisfy { (48...57).contains($0) || (97...102).contains($0) }
    }
}

public struct Entry: Hashable, Sendable, Identifiable {
    public var id: String
    public var type: EntryType
    public var title: String
    public var created: Date
    public var updated: Date
    public var places: [String] = []
    public var due: Day?
    public var status: TaskStatus?
    public var favorite = false
    public var pinned = false
    public var reminders: [Date] = []
    public var start: Date?
    public var end: Date?
    public var allDay = false
    public var url: String?
    public var attachment: Attachment?
    public var deck: String?
    public var tagKind: TagKind?
    public var tags: [String] = []
    public var options: [String] = []
    public var correctOption: Int?
    public var doneAt: Date?
    public var archived = false
    public var body = ""
    public var links: [String] = []
    public var extras: [String: String] = [:]

    public init(id: String, type: EntryType, title: String, created: Date, updated: Date) {
        self.id = id
        self.type = type
        self.title = title
        self.created = created
        self.updated = updated
    }

    public var isInInbox: Bool { !type.isContainer && places.isEmpty && !archived }
    public var isDone: Bool { status == .done }
    public var isMultipleChoice: Bool { options.count >= 2 && correctOption != nil }

    public var preview: String {
        let joined = body.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }.joined(separator: " ")
        return String(joined.prefix(200))
    }
}
