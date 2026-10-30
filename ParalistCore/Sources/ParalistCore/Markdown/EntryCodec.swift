// Zusammenhang: Markdown/FrontMatter.swift, Markdown/Instants.swift, Markdown/Limits.swift, Model/Entry.swift, Store/EntryStore.swift
import Foundation

public struct EntryParseError: Error, Equatable {
    public let message: String
    public init(_ message: String) { self.message = message }
}

public enum EntryCodec {
    private static let idPattern = Pattern("^[a-z0-9][a-z0-9-]{3,63}$")
    private static let known: Set<String> = [
        "id", "typ", "titel", "erstellt", "geaendert", "orte", "faellig", "status", "favorit", "angepinnt",
        "erinnerungen", "start", "ende", "ganztags", "url", "anhang_hash", "anhang_name", "anhang_typ",
        "anhang_groesse", "deck", "tagart", "archiviert", "tags", "optionen", "richtig", "erledigt_am", "verknuepfungen",
    ]

    public static func isValidId(_ id: String) -> Bool { idPattern.matches(id) }

    public static func encode(_ entry: Entry) -> String {
        var fields: [(String, YamlValue)] = []
        func put(_ key: String, _ value: String?) {
            if let value { fields.append((key, .scalar(value))) }
        }
        func flag(_ key: String, _ value: Bool) { if value { put(key, "true") } }
        put("id", entry.id)
        put("typ", entry.type.key)
        put("titel", entry.title)
        put("erstellt", Instants.format(entry.created))
        put("geaendert", Instants.format(entry.updated))
        fields.append(("orte", .items(entry.places)))
        put("faellig", entry.due?.description)
        put("status", entry.status?.key)
        flag("favorit", entry.favorite)
        flag("angepinnt", entry.pinned)
        if !entry.reminders.isEmpty { fields.append(("erinnerungen", .items(entry.reminders.map(Instants.format)))) }
        put("start", entry.start.map(Instants.format))
        put("ende", entry.end.map(Instants.format))
        flag("ganztags", entry.allDay)
        put("url", entry.url)
        if let a = entry.attachment {
            put("anhang_hash", a.hash)
            put("anhang_name", a.name)
            put("anhang_typ", a.mime)
            put("anhang_groesse", String(a.size))
        }
        put("deck", entry.deck)
        put("tagart", entry.type == .tag ? entry.tagKind.map(\.key) : nil)
        flag("archiviert", entry.archived)
        if !entry.tags.isEmpty { fields.append(("tags", .items(entry.tags))) }
        if !entry.options.isEmpty { fields.append(("optionen", .items(entry.options))) }
        put("richtig", entry.correctOption.map(String.init))
        put("erledigt_am", entry.doneAt.map(Instants.format))
        if !entry.links.isEmpty { fields.append(("verknuepfungen", .items(entry.links))) }
        let used = Set(fields.map(\.0))
        for key in entry.extras.keys.sorted() where !known.contains(key) && !used.contains(key) {
            put(key, entry.extras[key])
        }
        return FrontMatter.write(fields, body: entry.body)
    }

    public static func decode(_ text: String, now: Date = Date()) throws -> Entry {
        if text.utf8.count > Limits.maxFileBytes { throw EntryParseError("Datei zu groß") }
        let document: FrontMatterDocument
        do {
            document = try FrontMatter.parse(text)
        } catch let error as FrontMatterError {
            throw EntryParseError(error.message)
        }
        let f = document.fields
        guard let id = try scalar(f, "id") else { throw EntryParseError("id fehlt") }
        guard isValidId(id) else { throw EntryParseError("id ungültig") }
        guard let type = EntryType.fromKey(try scalar(f, "typ")) else { throw EntryParseError("typ unbekannt") }
        let title = try scalar(f, "titel") ?? ""
        if title.count > Limits.maxTitleChars { throw EntryParseError("titel zu lang") }
        guard let created = try instant(f, "erstellt", now) else { throw EntryParseError("erstellt fehlt") }
        let updated = try instant(f, "geaendert", now) ?? created
        var entry = Entry(id: id, type: type, title: title, created: created, updated: updated)
        entry.places = try items(f, "orte").map { if isValidId($0) { return $0 } else { throw EntryParseError("ort ungültig") } }
        if let url = try scalar(f, "url") {
            if url.count > Limits.maxUrlChars { throw EntryParseError("url zu lang") }
            entry.url = url
        }
        entry.due = try date(f, "faellig", now)
        if let s = try scalar(f, "status") {
            guard let status = TaskStatus.fromKey(s) else { throw EntryParseError("status unbekannt") }
            entry.status = status
        }
        entry.favorite = try bool(f, "favorit")
        entry.pinned = try bool(f, "angepinnt")
        entry.reminders = try items(f, "erinnerungen").map { try parseInstant($0, now) }
        entry.start = try instant(f, "start", now)
        entry.end = try instant(f, "ende", now)
        entry.allDay = try bool(f, "ganztags")
        entry.attachment = try attachment(f)
        if let deck = try scalar(f, "deck") {
            guard isValidId(deck) else { throw EntryParseError("deck ungültig") }
            entry.deck = deck
        }
        if type == .tag, let kind = try scalar(f, "tagart") {
            guard let value = TagKind.fromKey(kind) else { throw EntryParseError("tagart unbekannt") }
            entry.tagKind = value
        }
        entry.archived = try bool(f, "archiviert")
        entry.tags = try items(f, "tags").map { String($0.trimmingCharacters(in: .whitespaces).prefix(60)) }.filter { !$0.isEmpty }
        entry.options = try items(f, "optionen").map { String($0.prefix(Limits.maxTitleChars)) }
        if let r = try scalar(f, "richtig") {
            guard let value = Int(r) else { throw EntryParseError("richtig ungültig") }
            entry.correctOption = value
        }
        entry.doneAt = try instant(f, "erledigt_am", now)
        entry.links = try items(f, "verknuepfungen").map { if isValidId($0) { return $0 } else { throw EntryParseError("verknuepfung ungültig") } }
        entry.body = document.body
        var extras: [String: String] = [:]
        for (key, value) in f where !known.contains(key) {
            if case .scalar(let text) = value { extras[key] = text }
        }
        entry.extras = extras
        return entry
    }

    private static func scalar(_ f: [String: YamlValue], _ key: String) throws -> String? {
        switch f[key] {
        case nil: return nil
        case .scalar(let text): return text
        case .items: throw EntryParseError("\(key) darf keine Liste sein")
        }
    }

    private static func items(_ f: [String: YamlValue], _ key: String) throws -> [String] {
        switch f[key] {
        case nil: return []
        case .items(let values): return values
        case .scalar: throw EntryParseError("\(key) muss eine Liste sein")
        }
    }

    private static func bool(_ f: [String: YamlValue], _ key: String) throws -> Bool {
        switch try scalar(f, key) {
        case nil, "false": return false
        case "true": return true
        default: throw EntryParseError("\(key) muss true oder false sein")
        }
    }

    private static func instant(_ f: [String: YamlValue], _ key: String, _ now: Date) throws -> Date? {
        guard let text = try scalar(f, key) else { return nil }
        return try parseInstant(text, now)
    }

    private static func parseInstant(_ text: String, _ now: Date) throws -> Date {
        guard let value = Instants.parse(text) else { throw EntryParseError("Zeitpunkt ungültig: \(text)") }
        try checkYear(Instants.utcYear(value), now)
        return value
    }

    private static func date(_ f: [String: YamlValue], _ key: String, _ now: Date) throws -> Day? {
        guard let text = try scalar(f, key) else { return nil }
        guard let day = Day.parse(text) else { throw EntryParseError("Datum ungültig: \(text)") }
        try checkYear(day.year, now)
        return day
    }

    private static func checkYear(_ year: Int, _ now: Date) throws {
        let maxYear = Instants.utcYear(now) + Limits.maxYearAhead
        if year < Limits.minYear || year > maxYear { throw EntryParseError("Jahr unplausibel: \(year)") }
    }

    private static func attachment(_ f: [String: YamlValue]) throws -> Attachment? {
        guard let hash = try scalar(f, "anhang_hash") else { return nil }
        guard Attachment.isValidHash(hash) else { throw EntryParseError("anhang_hash ungültig") }
        let name = try scalar(f, "anhang_name") ?? ""
        if name.count > Limits.maxNameChars || name.contains("/") || name.contains("\\") {
            throw EntryParseError("anhang_name ungültig")
        }
        let size = Int64(try scalar(f, "anhang_groesse") ?? "") ?? 0
        if size < 0 { throw EntryParseError("anhang_groesse ungültig") }
        return Attachment(hash: hash, name: name, mime: try scalar(f, "anhang_typ") ?? "application/octet-stream", size: size)
    }
}
