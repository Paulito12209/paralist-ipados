// Zusammenhang: Chat/ChatEventDrafts.swift (events), Chat/ShiftPlan.swift, Chat/ChatPrompt.swift (withMentions), Chat/ChatMentionQuery.swift, Model/Entry.swift (extras, links), Markdown/EntryCodec.swift (unbekannte Kopf-Felder bleiben), Paralist/App/AppModel.swift (applySkillName), Paralist/Chat/ChatEngine.swift, docs/chat.md
import Foundation

public struct ShiftCode: Equatable, Sendable {
    public var start: Int
    public var end: Int

    public init(start: Int, end: Int) {
        self.start = start
        self.end = end
    }
}

public struct ShiftSkill: Equatable, Sendable {
    public var name: String
    public var title: String
    public var absences: Bool
    public var pause: Int?
    public var reminder: Int?
    public var codes: [String: ShiftCode]
    public var text: String

    public init(name: String = "", title: String = "", absences: Bool = false, pause: Int? = nil, reminder: Int? = nil, codes: [String: ShiftCode] = [:], text: String = "") {
        self.name = name
        self.title = title
        self.absences = absences
        self.pause = pause
        self.reminder = reminder
        self.codes = codes
        self.text = text
    }

    public init(_ entry: Entry) {
        let f = entry.extras
        self.init(name: f[Skills.nameKey] ?? "", title: f[Skills.titleKey] ?? "", absences: f[Skills.absencesKey] == "true",
                  pause: Skills.minutes(f[Skills.pauseKey]), reminder: Skills.minutes(f[Skills.reminderKey]), codes: Skills.codes(f[Skills.codesKey]), text: entry.body)
    }

    public func applied(to entry: Entry) -> Entry {
        var e = entry
        e.extras[Skills.nameKey] = name.isEmpty ? nil : name
        e.extras[Skills.titleKey] = title.isEmpty ? nil : title
        e.extras[Skills.absencesKey] = absences ? "true" : nil
        e.extras[Skills.pauseKey] = pause.map(String.init)
        e.extras[Skills.reminderKey] = reminder.map(String.init)
        return e
    }
}

public enum Skills {
    public static let tagTitle = "Skill"
    public static let nameKey = "schicht_name"
    public static let titleKey = "schicht_titel"
    public static let absencesKey = "schicht_abwesend"
    public static let pauseKey = "schicht_pause"
    public static let reminderKey = "schicht_erinnerung"
    public static let codesKey = "schicht_kuerzel"
    public static let maxCodes = 20
    public static let maxMinutes = 24 * 60
    public static let textChars = 1_500

    public static func tag(in entries: [Entry]) -> Entry? {
        entries.filter { $0.type == .tag && !$0.archived && fold($0.title) == fold(tagTitle) }.min { $0.created < $1.created }
    }

    public static func all(in entries: [Entry]) -> [Entry] {
        guard let tag = tag(in: entries) else { return [] }
        return entries.filter { $0.type == .note && !$0.archived && ($0.links.contains(tag.id) || tag.links.contains($0.id)) }
            .sorted { ($0.title, $0.id) < ($1.title, $1.id) }
    }

    public static func isSkill(_ entry: Entry, in entries: [Entry]) -> Bool {
        all(in: entries).contains { $0.id == entry.id }
    }

    public static func shiftNote(in entries: [Entry]) -> Entry? {
        let skills = all(in: entries)
        return skills.first { $0.extras[nameKey] != nil } ?? skills.first { $0.extras.keys.contains { $0.hasPrefix("schicht_") } }
    }

    public static func shift(in entries: [Entry]) -> ShiftSkill? {
        shiftNote(in: entries).map(ShiftSkill.init)
    }

    public static func instruction(_ skills: [Entry]) -> String {
        let parts = skills.map { skill -> String in
            let text = ChatTools.clip(skill.body.trimmingCharacters(in: .whitespacesAndNewlines), textChars)
            return "Skill \"\(skill.title)\":" + (text.isEmpty ? " (no text)" : "\n" + text)
        }
        return parts.joined(separator: "\n\n")
    }

    public static func planSkill(name: String, title: String, text: String, in entries: [Entry], make: (EntryType, String) -> Entry) -> [Entry] {
        var out: [Entry] = []
        let tag = tag(in: entries) ?? {
            let fresh = make(.tag, tagTitle)
            out.append(fresh)
            return fresh
        }()
        var note = shiftNote(in: entries) ?? {
            var fresh = make(.note, title)
            fresh.body = text.isEmpty ? "" : text + "\n"
            fresh.links = [tag.id]
            return fresh
        }()
        if !note.links.contains(tag.id) { note.links.append(tag.id) }
        var skill = ShiftSkill(note)
        skill.name = String(name.prefix(Limits.maxTitleChars))
        out.append(skill.applied(to: note))
        return out
    }

    public static func codes(_ text: String?) -> [String: ShiftCode] {
        guard let text else { return [:] }
        var out: [String: ShiftCode] = [:]
        for part in text.split(whereSeparator: { $0 == "," || $0 == ";" || $0.isNewline }) {
            let halves = part.split(maxSplits: 1, whereSeparator: { $0 == "=" || $0 == ":" })
            guard halves.count == 2 else { continue }
            let key = halves[0].trimmingCharacters(in: .whitespaces)
            guard !key.isEmpty, key.count <= 8, out.count < maxCodes, case .work(let start, let end) = ShiftCells.parse(String(halves[1])) else { continue }
            out[key] = ShiftCode(start: start, end: end)
        }
        return out
    }

    static func minutes(_ text: String?) -> Int? {
        guard let text, let value = Int(text.trimmingCharacters(in: .whitespaces)), (0...maxMinutes).contains(value) else { return nil }
        return value
    }

    static func fold(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil).lowercased()
    }
}
