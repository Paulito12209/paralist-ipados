// Zusammenhang: Chat/ChatCodec.swift, Chat/ChatStore.swift, Chat/ChatList.swift, Chat/ChatMentionQuery.swift (maxMentions), Paralist/Chat/ChatModel.swift
import Foundation

public enum ChatRole: String, Sendable, CaseIterable {
    case user = "nutzer", assistant = "modell"
}

public struct ChatMessage: Equatable, Sendable, Identifiable {
    public let id: String
    public var role: ChatRole
    public var text: String
    public var at: Date
    public var entries: [String]
    public var drafts: [ChatDraft]
    public var attachment: String?
    public var mentions: [String]

    public init(id: String, role: ChatRole, text: String, at: Date, entries: [String] = [], drafts: [ChatDraft] = [], attachment: String? = nil, mentions: [String] = []) {
        self.id = id
        self.role = role
        self.text = text
        self.at = at
        self.entries = entries
        self.drafts = drafts
        self.attachment = attachment
        self.mentions = mentions
    }

    public var hasContent: Bool { attachment != nil || !mentions.isEmpty || !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}

public struct ChatThread: Equatable, Sendable, Identifiable {
    public let id: String
    public var title: String
    public var created: Date
    public var updated: Date
    public var messages: [ChatMessage]
    public var links: [String]
    public var pinned: Bool

    public init(id: String, title: String = "", created: Date, updated: Date? = nil, messages: [ChatMessage] = [], links: [String] = [], pinned: Bool = false) {
        self.id = id
        self.title = title
        self.created = created
        self.updated = updated ?? created
        self.messages = messages
        self.links = links
        self.pinned = pinned
    }

    public var last: ChatMessage? { messages.last }

    public var attachments: [String] { messages.compactMap(\.attachment) }

    public var latestImage: String? { messages.last { $0.role == .user && $0.attachment != nil }?.attachment }

    public mutating func append(_ message: ChatMessage, fallbackTitle: String = "") {
        var clipped = message
        clipped.text = ChatCodec.clip(message.text)
        if let hash = message.attachment, !Attachment.isValidHash(hash) { clipped.attachment = nil }
        var seen = Set<String>()
        clipped.mentions = Array(message.mentions.filter { EntryCodec.isValidId($0) && seen.insert($0).inserted }.prefix(ChatMentionQuery.maxMentions))
        guard clipped.hasContent else { return }
        let text = clipped.text
        messages.append(clipped)
        if messages.count > ChatCodec.maxMessages { messages.removeFirst(messages.count - ChatCodec.maxMessages) }
        updated = max(updated, message.at)
        if title.isEmpty, message.role == .user { title = ChatTitle.from(text) }
        if title.isEmpty, message.role == .user { title = ChatTitle.from(fallbackTitle) }
    }

    public mutating func remapAttachments(_ map: (String) -> String?) {
        for m in messages.indices {
            guard let hash = messages[m].attachment else { continue }
            messages[m].attachment = map(hash)
        }
        messages.removeAll { !$0.hasContent }
    }

    public mutating func setLinked(_ entryId: String, _ linked: Bool) {
        guard EntryCodec.isValidId(entryId) else { return }
        links.removeAll { $0 == entryId }
        if linked, links.count < ChatCodec.maxLinks { links.append(entryId) }
    }

    public mutating func setDraft(_ draft: ChatDraft) {
        for m in messages.indices {
            guard let d = messages[m].drafts.firstIndex(where: { $0.id == draft.id }) else { continue }
            messages[m].drafts[d] = draft
            return
        }
    }

    public func draft(_ id: String) -> ChatDraft? {
        messages.lazy.flatMap(\.drafts).first { $0.id == id }
    }

    public func question(before draftId: String) -> ChatMessage? {
        guard let index = messages.firstIndex(where: { $0.drafts.contains { $0.id == draftId } }) else { return nil }
        return messages[..<index].last { $0.role == .user }
    }

    public var lastQuestion: ChatMessage? { messages.last?.role == .user ? messages.last : nil }

    public mutating func rename(_ input: String) {
        let clean = ChatTitle.clean(input)
        if !clean.isEmpty { title = clean }
    }
}

public enum ChatTitle {
    public static let autoChars = 40
    private static let spaces = Pattern("\\s+")

    public static func clean(_ input: String) -> String {
        String(spaces.replace(input.trimmingCharacters(in: .whitespacesAndNewlines), with: " ").prefix(Limits.maxTitleChars))
    }

    public static func from(_ text: String) -> String {
        let line = text.split(whereSeparator: \.isNewline).lazy
            .map { ChatPreview.plain(String($0)) }
            .first { !$0.isEmpty } ?? ""
        guard line.count > autoChars else { return line }
        let cut = line.prefix(autoChars)
        let words = cut.split(separator: " ")
        let base = words.count > 1 ? words.dropLast().joined(separator: " ") : String(cut)
        return base + "…"
    }
}
