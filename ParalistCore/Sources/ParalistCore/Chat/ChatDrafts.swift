// Zusammenhang: Chat/ChatThread.swift (ChatMessage.drafts), Chat/ChatCodec.swift, Chat/ChatPrompt.swift, Chat/ChatEventDrafts.swift, Paralist/Chat/ChatEngineTools.swift, Paralist/Chat/ChatDraftCard.swift, Paralist/App/AppModel.swift (applyChatDraft)
import Foundation

public enum ChatDraftKind: String, Sendable, CaseIterable {
    case flashcards = "karteikarten", tasks = "aufgaben", note = "notiz", events = "termine"
}

public enum ChatDraftState: String, Sendable, CaseIterable {
    case open = "offen", saved = "angelegt", discarded = "verworfen"
}

public struct ChatDraftItem: Equatable, Sendable {
    public var front: String
    public var back: String
    public var due: Day?
    public var start: Int?
    public var end: Int?
    public var selected: Bool
    public var hint: ChatDraftHint?

    public init(front: String, back: String = "", due: Day? = nil, start: Int? = nil, end: Int? = nil, selected: Bool = true, hint: ChatDraftHint? = nil) {
        self.front = front
        self.back = back
        self.due = due
        self.start = start
        self.end = end
        self.selected = selected
        self.hint = hint
    }
}

public struct ChatDraft: Equatable, Sendable, Identifiable {
    public let id: String
    public var kind: ChatDraftKind
    public var title: String
    public var text: String
    public var items: [ChatDraftItem]
    public var state: ChatDraftState
    public var saved: [String]
    public var choices: [String]

    public init(id: String, kind: ChatDraftKind, title: String = "", text: String = "", items: [ChatDraftItem] = [], state: ChatDraftState = .open, saved: [String] = [], choices: [String] = []) {
        self.id = id
        self.kind = kind
        self.title = title
        self.text = text
        self.items = items
        self.state = state
        self.saved = saved
        self.choices = choices
    }

    public var isEmpty: Bool {
        switch kind {
        case .flashcards: return title.isEmpty || items.isEmpty
        case .tasks: return items.isEmpty
        case .note: return title.isEmpty
        case .events: return items.isEmpty && choices.isEmpty
        }
    }

    public var asksForRow: Bool { kind == .events && items.isEmpty && !choices.isEmpty }

    public var selectedCount: Int { items.filter(\.selected).count }
}

public enum ChatDrafts {
    public static let maxPerMessage = 3
    public static let maxCards = 20
    public static let maxTasks = 10
    public static let maxFrontChars = 200
    public static let maxBackChars = 1_000
    public static let maxNoteChars = 4_000
    public static let maxDaysAhead = 3_650

    public static func flashcards(id: String, deck: String, cards: [(String, String)]) -> ChatDraft {
        let items = unique(cards.map { ChatDraftItem(front: line($0.0, maxFrontChars), back: block($0.1, maxBackChars)) }
            .filter { !$0.front.isEmpty && !$0.back.isEmpty })
        return ChatDraft(id: id, kind: .flashcards, title: line(deck, maxFrontChars), items: Array(items.prefix(maxCards)))
    }

    public static func tasks(id: String, tasks: [(String, String?)], today: Day) -> ChatDraft {
        let items = unique(tasks.map { ChatDraftItem(front: line($0.0, maxFrontChars), due: due($0.1, today: today)) }
            .filter { !$0.front.isEmpty })
        return ChatDraft(id: id, kind: .tasks, items: Array(items.prefix(maxTasks)))
    }

    public static func note(id: String, title: String, text: String) -> ChatDraft {
        ChatDraft(id: id, kind: .note, title: line(title, maxFrontChars), text: block(text, maxNoteChars))
    }

    public static func due(_ text: String?, today: Day) -> Day? {
        guard let text, let day = Day.parse(text.trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
        let offset = day.epochDay - today.epochDay
        return offset >= -1 && offset <= maxDaysAhead ? day : nil
    }

    public static func cleaned(_ draft: ChatDraft, today: Day) -> ChatDraft {
        var out: ChatDraft
        switch draft.kind {
        case .flashcards: out = flashcards(id: draft.id, deck: draft.title, cards: draft.items.map { ($0.front, $0.back) })
        case .tasks: out = tasks(id: draft.id, tasks: draft.items.map { ($0.front, $0.due?.description) }, today: today)
        case .note: out = note(id: draft.id, title: draft.title, text: draft.text)
        case .events: out = cleanedEvents(draft)
        }
        out.state = draft.state
        out.saved = draft.saved
        return out
    }

    public static func deck(named title: String, in decks: [Entry]) -> Entry? {
        let key = fold(title)
        return decks.first { $0.type == .deck && !$0.archived && fold($0.title) == key }
    }

    public static func entries(_ draft: ChatDraft, decks: [Entry], zone: TimeZone = .current, reminder: Int? = nil, make: (EntryType, String) -> Entry) -> (created: [Entry], shown: [String]) {
        guard draft.state == .open, !draft.isEmpty else { return ([], []) }
        switch draft.kind {
        case .flashcards:
            var created: [Entry] = []
            let deck: Entry
            if let existing = Self.deck(named: draft.title, in: decks) {
                deck = existing
            } else {
                deck = make(.deck, draft.title)
                created.append(deck)
            }
            for item in draft.items {
                var card = make(.flashcard, item.front)
                card.body = item.back + "\n"
                card.deck = deck.id
                created.append(card)
            }
            return (created, [deck.id])
        case .tasks:
            let created = draft.items.map { item -> Entry in
                var task = make(.task, item.front)
                task.due = item.due
                return task
            }
            return (created, created.map(\.id))
        case .note:
            var note = make(.note, draft.title)
            note.body = draft.text.isEmpty ? "" : draft.text + "\n"
            return ([note], [note.id])
        case .events:
            let created = eventEntries(draft, zone: zone, reminder: reminder, make: make)
            return (created, created.map(\.id))
        }
    }

    public static func summary(_ draft: ChatDraft, decks: [Entry]) -> String {
        guard !draft.isEmpty else { return "Nothing was prepared: the input had no usable content. Tell the user briefly." }
        let what: String
        switch draft.kind {
        case .flashcards:
            let target = deck(named: draft.title, in: decks) == nil ? "a new deck \"\(draft.title)\"" : "the existing deck \"\(draft.title)\""
            what = "\(draft.items.count) flashcards for \(target)"
        case .tasks:
            what = "\(draft.items.count) task" + (draft.items.count == 1 ? "" : "s")
        case .note:
            what = "a note \"\(draft.title)\""
        case .events:
            return planSummary(draft)
        }
        return "Prepared a draft of \(what). Nothing is saved yet: the user sees a preview below your answer and taps Create to save it. " +
            "Reply in one short sentence; do not list the items again."
    }

    public static func limitReached() -> String {
        "Not prepared: at most \(maxPerMessage) drafts per answer. Tell the user to ask again for more."
    }

    static func line(_ text: String, _ limit: Int) -> String {
        String(ChatTools.oneLine(text).prefix(limit)).trimmingCharacters(in: .whitespaces)
    }

    static func block(_ text: String, _ limit: Int) -> String {
        String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(limit)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func unique(_ items: [ChatDraftItem]) -> [ChatDraftItem] {
        var seen = Set<String>()
        return items.filter { seen.insert(fold($0.front)).inserted }
    }

    private static func fold(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}
