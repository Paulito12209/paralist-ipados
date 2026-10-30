// Zusammenhang: Chat/ChatPrompt.swift, Chat/ChatPrompt.swift (ChatMentions), Text/SearchQuery.swift, Planning/WeekBriefing.swift, Planning/WeekGrid.swift, Paralist/Chat/ChatEngineTools.swift
import Foundation

public struct ChatToolResult: Equatable, Sendable {
    public let text: String
    public let ids: [String]
}

public enum ChatTaskRange: String, CaseIterable, Sendable {
    case today, week, overdue

    public static func from(_ input: String) -> ChatTaskRange {
        switch input.lowercased().trimmingCharacters(in: .whitespaces) {
        case "week", "woche", "this week": return .week
        case "overdue", "ueberfaellig", "überfällig", "late": return .overdue
        default: return .today
        }
    }
}

public enum ChatTools {
    public static let maxHits = 10
    public static let maxTasks = 15
    public static let maxEvents = 20
    public static let previewChars = 80
    public static let bodyChars = 1_200
    public static let contextBodyChars = 300
    public static let maxContextChars = 1_500
    public static let maxPlaceTasks = 8

    private static let englishTypes: [String: EntryType] = [
        "note": .note, "task": .task, "todo": .task, "event": .event, "appointment": .event,
        "project": .project, "area": .area, "bookmark": .bookmark, "link": .bookmark,
        "file": .file, "document": .document, "flashcard": .flashcard, "card": .flashcard, "deck": .deck,
        "tag": .tag, "person": .tag, "place": .tag,
    ]

    public static func type(from input: String?) -> EntryType? {
        guard let raw = input?.lowercased().trimmingCharacters(in: .whitespaces), !raw.isEmpty else { return nil }
        if let direct = EntryType.fromKey(raw) { return direct }
        let singular = raw.hasSuffix("s") ? String(raw.dropLast()) : raw
        return englishTypes[raw] ?? englishTypes[singular]
    }

    public static func search(_ entries: [Entry], text: String, type: EntryType?) -> ChatToolResult {
        let terms = SearchQuery.terms(text)
        let pool = entries.filter { !$0.archived && (type == nil || $0.type == type) }
        let hits = (terms.isEmpty ? (type == nil ? [] : pool) : pool.filter { SearchQuery.matches($0, terms: terms) })
            .sorted { $0.updated > $1.updated }
            .prefix(maxHits)
        guard !hits.isEmpty else { return ChatToolResult(text: "No matching entries.", ids: []) }
        let lines = hits.map { e -> String in
            let preview = clip(oneLine(e.body), previewChars)
            return line(e, entries) + (preview.isEmpty ? "" : " — \(preview)")
        }
        return ChatToolResult(text: lines.joined(separator: "\n"), ids: hits.map(\.id))
    }

    public static func read(_ entries: [Entry], id: String) -> ChatToolResult {
        let key = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let entry = entries.first(where: { $0.id == key })
            ?? entries.first(where: { $0.title.compare(key, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }) else {
            return ChatToolResult(text: "No entry with this id.", ids: [])
        }
        var out = [line(entry, entries)]
        if let url = entry.url { out.append("link: \(clip(url, 200))") }
        if entry.isMultipleChoice { out.append("options: " + entry.options.joined(separator: " | ")) }
        let body = clip(entry.body.trimmingCharacters(in: .whitespacesAndNewlines), bodyChars)
        if !body.isEmpty { out.append("text:\n\(body)") }
        var ids = [entry.id]
        if entry.type.isContainer {
            let inside = entries.filter { $0.places.contains(entry.id) && !$0.archived }.sorted { $0.updated > $1.updated }.prefix(maxHits)
            if !inside.isEmpty {
                out.append("contains:")
                out += inside.map { "- " + line($0, entries) }
                ids += inside.map(\.id)
            }
        }
        return ChatToolResult(text: out.joined(separator: "\n"), ids: ids)
    }

    public static func tasks(_ entries: [Entry], range: ChatTaskRange, today: Day) -> ChatToolResult {
        let week = Week.of(today)
        let open = entries.filter { $0.type == .task && !$0.isDone && !$0.archived }
        let picked = open.filter { e in
            guard let due = e.due else { return false }
            switch range {
            case .today: return due == today
            case .week: return due >= week.monday && due <= week.sunday
            case .overdue: return due < today
            }
        }
        .sorted { ($0.due!, $0.title) < ($1.due!, $1.title) }
        guard !picked.isEmpty else { return ChatToolResult(text: "No open tasks in this range.", ids: []) }
        let shown = picked.prefix(maxTasks)
        var lines = shown.map { "- " + line($0, entries, today: today) }
        if picked.count > shown.count { lines.append("(\(picked.count - shown.count) more)") }
        return ChatToolResult(text: lines.joined(separator: "\n"), ids: shown.map(\.id))
    }

    public static func week(_ briefing: WeekBriefing, entries: [Entry], today: Day, zone: TimeZone) -> ChatToolResult {
        var out = ["week \(briefing.week.isoWeek): \(briefing.week.monday) to \(briefing.week.sunday), today \(weekdayName(today)) \(today)"]
        var ids: [String] = []
        let events = briefing.days.flatMap { day in day.events.map { (day.date, $0) } }.prefix(maxEvents)
        out.append(events.isEmpty ? "events: none" : "events:")
        for (day, event) in events {
            let time = event.allDay ? "all day" : event.start.map { WeekGrid.timeLabel($0, zone: zone) } ?? ""
            out.append("- \(weekdayName(day)) \(day) \(time): \(event.title) (id \(event.id))")
            ids.append(event.id)
        }
        out.append(briefing.tasks.isEmpty ? "tasks due: none" : "tasks due:")
        for task in briefing.tasks.prefix(maxTasks) {
            out.append("- \(task.date)\(task.overdue ? " overdue" : ""): \(task.entry.title) (id \(task.entry.id))")
            ids.append(task.entry.id)
        }
        if !briefing.deadlines.isEmpty {
            out.append("project deadlines:")
            for deadline in briefing.deadlines {
                out.append("- \(deadline.date): \(deadline.entry.title) (id \(deadline.entry.id))")
                ids.append(deadline.entry.id)
            }
        }
        return ChatToolResult(text: out.joined(separator: "\n"), ids: ids)
    }

    public static func context(_ linked: [Entry], entries: [Entry], today: Day, dueCards: (String) -> Int) -> String {
        var parts: [String] = []
        for entry in linked {
            var out = [line(entry, entries, today: today)]
            switch entry.type {
            case .project, .area:
                let open = entries.filter { $0.places.contains(entry.id) && $0.type == .task && !$0.isDone && !$0.archived }
                    .sorted { ($0.due ?? Day(epochDay: .max)) < ($1.due ?? Day(epochDay: .max)) }
                if !open.isEmpty {
                    out.append("open tasks: " + open.prefix(maxPlaceTasks).map { $0.title + ($0.due.map { " (due \($0))" } ?? "") }.joined(separator: "; "))
                }
            case .deck:
                let cards = entries.filter { $0.deck == entry.id && !$0.archived }.count
                out.append("cards: \(cards), due for review: \(dueCards(entry.id))")
            case .flashcard:
                out.append("front: \(clip(entry.title, contextBodyChars))")
                out.append("back: \(clip(oneLine(entry.body), contextBodyChars))")
                if entry.isMultipleChoice { out.append("options: " + entry.options.joined(separator: " | ")) }
                parts.append(out.joined(separator: "\n"))
                continue
            default:
                break
            }
            let body = clip(oneLine(entry.body), contextBodyChars)
            if !body.isEmpty { out.append("text: \(body)") }
            parts.append(out.joined(separator: "\n"))
        }
        return clip(parts.joined(separator: "\n\n"), maxContextChars)
    }

    public static func line(_ e: Entry, _ entries: [Entry], today: Day? = nil) -> String {
        var bits = ["\(e.title.isEmpty ? "(untitled)" : e.title) [\(e.type.key)] id \(e.id)"]
        if let status = e.status { bits.append("status \(status.key)") }
        if let due = e.due {
            bits.append("due \(due)" + (today.map { due < $0 && !e.isDone ? " overdue" : "" } ?? ""))
        }
        if let start = e.start { bits.append("starts \(Instants.format(start))") }
        let places = e.places.compactMap { id in entries.first { $0.id == id }?.title }.filter { !$0.isEmpty }
        if !places.isEmpty { bits.append("in " + places.joined(separator: ", ")) }
        if e.type == .flashcard, let deck = e.deck.flatMap({ id in entries.first { $0.id == id } }) { bits.append("deck \(deck.title)") }
        return bits.joined(separator: ", ")
    }

    public static func clip(_ text: String, _ max: Int) -> String {
        text.count > max ? String(text.prefix(max - 1)) + "…" : text
    }

    static func oneLine(_ text: String) -> String {
        text.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }.joined(separator: " ")
    }

    static func weekdayName(_ day: Day) -> String {
        ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][day.weekday - 1]
    }
}
