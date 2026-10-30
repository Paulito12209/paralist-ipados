// Zusammenhang: Chat/ChatEngine.swift, Chat/ChatEngineWriteTools.swift, ParalistCore Chat/ChatTools.swift, ParalistCore Chat/ChatDrafts.swift, ParalistCore Planning/WeekBriefing.swift
import Foundation
import FoundationModels
import ParalistCore

struct ChatSnapshot: Sendable {
    var entries: [Entry]
    var today: Day
    var zone: TimeZone
    var dueCards: [String: Int]
    var language: String
    var languageTag: String = "en"
    var attachmentsDir: URL = FileManager.default.temporaryDirectory
    var workTitle: String = "Work"
    var absentTitle: String = "Absent"
}

final class ChatData: @unchecked Sendable {
    private let lock = NSLock()
    private var snapshot = ChatSnapshot(entries: [], today: Day.of(Date(), in: .current), zone: .current, dueCards: [:], language: "English")
    private var seenIds: [String] = []
    private var made: [ChatDraft] = []
    private let ids = SecureIds()

    var current: ChatSnapshot {
        lock.lock()
        defer { lock.unlock() }
        return snapshot
    }

    var seen: [String] {
        lock.lock()
        defer { lock.unlock() }
        return seenIds
    }

    func begin(_ next: ChatSnapshot) {
        lock.lock()
        snapshot = next
        seenIds = []
        made = []
        lock.unlock()
    }

    func newId() -> String { ids.next() }

    var drafts: [ChatDraft] {
        lock.lock()
        defer { lock.unlock() }
        return made
    }

    func draft(_ build: (String, ChatSnapshot) -> ChatDraft) -> String {
        lock.lock()
        defer { lock.unlock() }
        guard made.count < ChatDrafts.maxPerMessage else { return ChatDrafts.limitReached() }
        let draft = build(ids.next(), snapshot)
        if !draft.isEmpty { made.append(draft) }
        return ChatDrafts.summary(draft, decks: snapshot.entries.filter { $0.type == .deck })
    }

    func saw(_ ids: [String]) {
        lock.lock()
        for id in ids where !seenIds.contains(id) { seenIds.append(id) }
        lock.unlock()
    }

    func record(_ result: ChatToolResult) -> String {
        saw(result.ids)
        return result.text
    }
}

struct SearchEntriesTool: Tool {
    let data: ChatData
    let name = "searchEntries"
    let description = "Find the user's Paralist entries by words from their title or text, optionally limited to one type. Returns up to 10 entries with title, type, id and a short preview."

    @Generable
    struct Arguments {
        @Guide(description: "Words to search for, e.g. a project name")
        var text: String
        @Guide(description: "Optional entry type: note, task, event, project, area, bookmark, file, document, flashcard or deck")
        var type: String?
    }

    func call(arguments: Arguments) async throws -> String {
        let snap = data.current
        return data.record(ChatTools.search(snap.entries, text: arguments.text, type: ChatTools.type(from: arguments.type)))
    }
}

struct ReadEntryTool: Tool {
    let data: ChatData
    let name = "readEntry"
    let description = "Read one entry by its id (or exact title): type, place, status, due date, text, and the entries inside a project or area."

    @Generable
    struct Arguments {
        @Guide(description: "The id of the entry from searchEntries, or its exact title")
        var id: String
    }

    func call(arguments: Arguments) async throws -> String {
        data.record(ChatTools.read(data.current.entries, id: arguments.id))
    }
}

struct ListTasksTool: Tool {
    let data: ChatData
    let name = "listTasks"
    let description = "List the user's open tasks that are due today, due this week, or overdue."

    @Generable
    struct Arguments {
        @Guide(description: "Which tasks", .anyOf(["today", "week", "overdue"]))
        var range: String
    }

    func call(arguments: Arguments) async throws -> String {
        let snap = data.current
        return data.record(ChatTools.tasks(snap.entries, range: ChatTaskRange.from(arguments.range), today: snap.today))
    }
}

struct WeekOverviewTool: Tool {
    let data: ChatData
    let name = "weekOverview"
    let description = "Overview of the current week: events per day, tasks due and project deadlines."

    @Generable
    struct Arguments {}

    func call(arguments: Arguments) async throws -> String {
        let snap = data.current
        let briefing = WeekBriefingBuilder.build(snap.entries, week: Week.of(snap.today), today: snap.today, zone: snap.zone)
        return data.record(ChatTools.week(briefing, entries: snap.entries, today: snap.today, zone: snap.zone))
    }
}
