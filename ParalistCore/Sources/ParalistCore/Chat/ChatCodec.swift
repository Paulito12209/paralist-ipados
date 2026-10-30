// Zusammenhang: Chat/ChatThread.swift, Chat/ChatDrafts.swift, Chat/ChatStore.swift, Backup/ImportPlanner.swift, Markdown/Instants.swift, Markdown/EntryCodec.swift (isValidId)
import Foundation

public enum ChatCodec {
    public static let formatVersion = 1
    public static let maxFileBytes = 4 * 1_048_576
    public static let maxMessages = 2_000
    public static let maxMessageChars = 20_000
    public static let maxLinks = 50
    public static let maxMentions = 12

    private struct FileThread: Codable {
        var format: Int
        var id: String
        var titel: String
        var erstellt: String
        var geaendert: String
        var nachrichten: [FileMessage]
        var verknuepft: [String]?
        var angepinnt: Bool?
    }

    private struct FileMessage: Codable {
        var id: String
        var rolle: String
        var text: String
        var zeit: String
        var eintraege: [String]?
        var entwuerfe: [FileDraft]?
        var anhang: String?
        var erwaehnt: [String]?
    }

    private struct FileDraft: Codable {
        var id: String
        var art: String
        var titel: String?
        var text: String?
        var punkte: [FileItem]?
        var status: String
        var angelegt: [String]?
        var namen: [String]?
    }

    private struct FileItem: Codable {
        var vorne: String
        var hinten: String?
        var faellig: String?
        var beginn: String?
        var ende: String?
        var gewaehlt: Bool?
        var hinweis: String?
    }

    public static func clip(_ text: String) -> String {
        text.count > maxMessageChars ? String(text.prefix(maxMessageChars)) : text
    }

    public static func encode(_ thread: ChatThread) throws -> Data {
        let file = FileThread(
            format: formatVersion,
            id: thread.id,
            titel: thread.title,
            erstellt: Instants.format(thread.created),
            geaendert: Instants.format(thread.updated),
            nachrichten: thread.messages.map {
                FileMessage(id: $0.id, rolle: $0.role.rawValue, text: $0.text, zeit: Instants.format($0.at), eintraege: $0.entries.isEmpty ? nil : $0.entries, entwuerfe: $0.drafts.isEmpty ? nil : $0.drafts.map(fileDraft), anhang: $0.attachment, erwaehnt: $0.mentions.isEmpty ? nil : $0.mentions)
            },
            verknuepft: thread.links.isEmpty ? nil : thread.links,
            angepinnt: thread.pinned ? true : nil
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(file)
    }

    public static func decode(_ data: Data) throws -> ChatThread {
        if data.count > maxFileBytes { throw EntryParseError("Datei zu groß") }
        let file: FileThread
        do {
            file = try JSONDecoder().decode(FileThread.self, from: data)
        } catch {
            throw EntryParseError("unlesbar")
        }
        guard file.format >= 1 else { throw EntryParseError("format unbekannt") }
        guard EntryCodec.isValidId(file.id) else { throw EntryParseError("id ungültig") }
        if file.titel.count > Limits.maxTitleChars { throw EntryParseError("titel zu lang") }
        if file.nachrichten.count > maxMessages { throw EntryParseError("zu viele Nachrichten") }
        guard let created = Instants.parse(file.erstellt), let updated = Instants.parse(file.geaendert) else {
            throw EntryParseError("zeit ungültig")
        }
        var seen = Set<String>()
        let messages = try file.nachrichten.map { m -> ChatMessage in
            guard EntryCodec.isValidId(m.id), seen.insert(m.id).inserted else { throw EntryParseError("nachricht ohne gültige id") }
            guard let role = ChatRole(rawValue: m.rolle) else { throw EntryParseError("rolle unbekannt") }
            guard let at = Instants.parse(m.zeit) else { throw EntryParseError("zeit ungültig") }
            if m.text.count > maxMessageChars { throw EntryParseError("nachricht zu lang") }
            let entries = try ids(m.eintraege, max: maxMentions)
            let list = m.entwuerfe ?? []
            if list.count > ChatDrafts.maxPerMessage { throw EntryParseError("zu viele Entwürfe") }
            let drafts = try list.map(parseDraft)
            guard Set(drafts.map(\.id)).count == drafts.count else { throw EntryParseError("entwurf doppelt") }
            if let hash = m.anhang, !Attachment.isValidHash(hash) { throw EntryParseError("anhang ungültig") }
            let mentions = try ids(m.erwaehnt, max: ChatMentionQuery.maxMentions)
            return ChatMessage(id: m.id, role: role, text: m.text, at: at, entries: entries, drafts: drafts, attachment: m.anhang, mentions: mentions)
        }
        let links = try ids(file.verknuepft, max: maxLinks)
        return ChatThread(id: file.id, title: file.titel, created: created, updated: updated, messages: messages, links: links, pinned: file.angepinnt ?? false)
    }

    private static func fileDraft(_ draft: ChatDraft) -> FileDraft {
        FileDraft(
            id: draft.id,
            art: draft.kind.rawValue,
            titel: draft.title.isEmpty ? nil : draft.title,
            text: draft.text.isEmpty ? nil : draft.text,
            punkte: draft.items.isEmpty ? nil : draft.items.map(fileItem),
            status: draft.state.rawValue,
            angelegt: draft.saved.isEmpty ? nil : draft.saved,
            namen: draft.choices.isEmpty ? nil : draft.choices
        )
    }

    private static func fileItem(_ item: ChatDraftItem) -> FileItem {
        FileItem(vorne: item.front, hinten: item.back.isEmpty ? nil : item.back, faellig: item.due?.description,
                 beginn: item.start.map(clock), ende: item.end.map(clock), gewaehlt: item.selected ? nil : false, hinweis: item.hint?.rawValue)
    }

    static func clock(_ minute: Int) -> String { String(format: "%02d:%02d", minute / 60, minute % 60) }

    static func minute(_ text: String) -> Int? {
        let parts = text.split(separator: ":")
        guard parts.count == 2, parts[0].count == 2, parts[1].count == 2, let h = Int(parts[0]), let m = Int(parts[1]), h < 24, m < 60 else { return nil }
        return h * 60 + m
    }

    private static func parseDraft(_ file: FileDraft) throws -> ChatDraft {
        guard EntryCodec.isValidId(file.id) else { throw EntryParseError("entwurf ohne gültige id") }
        guard let kind = ChatDraftKind(rawValue: file.art) else { throw EntryParseError("entwurf art unbekannt") }
        guard let state = ChatDraftState(rawValue: file.status) else { throw EntryParseError("entwurf status unbekannt") }
        let items = file.punkte ?? []
        if items.count > max(ChatDrafts.maxCards, ChatDrafts.maxTasks) { throw EntryParseError("entwurf zu groß") }
        let title = file.titel ?? ""
        let text = file.text ?? ""
        if title.count > ChatDrafts.maxFrontChars || text.count > ChatDrafts.maxNoteChars { throw EntryParseError("entwurf zu lang") }
        let parsed = try items.map { item -> ChatDraftItem in
            let back = item.hinten ?? ""
            if item.vorne.count > ChatDrafts.maxFrontChars || back.count > ChatDrafts.maxBackChars { throw EntryParseError("entwurf zu lang") }
            var due: Day?
            if let text = item.faellig {
                guard let day = Day.parse(text) else { throw EntryParseError("entwurf datum ungültig") }
                due = day
            }
            var start: Int?
            var end: Int?
            if let text = item.beginn {
                guard let value = minute(text) else { throw EntryParseError("entwurf zeit ungültig") }
                start = value
            }
            if let text = item.ende {
                guard let value = minute(text) else { throw EntryParseError("entwurf zeit ungültig") }
                end = value
            }
            var hint: ChatDraftHint?
            if let text = item.hinweis {
                guard let value = ChatDraftHint(rawValue: text) else { throw EntryParseError("entwurf hinweis unbekannt") }
                hint = value
            }
            return ChatDraftItem(front: item.vorne, back: back, due: due, start: start, end: end, selected: item.gewaehlt ?? true, hint: hint)
        }
        let saved = try ids(file.angelegt, max: ChatDrafts.maxCards + 1)
        let names = file.namen ?? []
        if names.count > ChatDrafts.maxNames || names.contains(where: { $0.count > ChatDrafts.maxFrontChars }) { throw EntryParseError("entwurf namen zu lang") }
        return ChatDraft(id: file.id, kind: kind, title: title, text: text, items: parsed, state: state, saved: saved, choices: names)
    }

    private static func ids(_ list: [String]?, max: Int) throws -> [String] {
        let list = list ?? []
        if list.count > max { throw EntryParseError("zu viele Verweise") }
        guard list.allSatisfy(EntryCodec.isValidId) else { throw EntryParseError("verweis ungültig") }
        var seen = Set<String>()
        return list.filter { seen.insert($0).inserted }
    }
}
