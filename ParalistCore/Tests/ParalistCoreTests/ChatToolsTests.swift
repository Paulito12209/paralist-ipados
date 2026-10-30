// Zusammenhang: Sources/ParalistCore/Chat/ChatTools.swift, Sources/ParalistCore/Chat/ChatPrompt.swift, Sources/ParalistCore/Chat/ChatCodec.swift, TestSupport.swift
import Foundation
import Testing
@testable import ParalistCore

struct ChatToolsTests {
    private let today = Day.parse("2026-10-21")!
    private let now = at("2026-10-21T10:00:00Z")

    private func world() -> [Entry] {
        [
            Entry("proj-umzug", .project, "Umzug nach Leipzig", now, now.addingTimeInterval(-500)) { $0.due = Day.parse("2026-10-24"); $0.status = .open },
            Entry("task-kartons", .task, "Umzugskartons bestellen", now, now.addingTimeInterval(-10)) {
                $0.due = Day.parse("2026-10-21"); $0.status = .open; $0.places = ["proj-umzug"]; $0.body = "Bei **Kartonfix**\nmindestens 30 Stück"
            },
            Entry("task-steuer", .task, "Steuererklärung abgeben", now, now.addingTimeInterval(-20)) { $0.due = Day.parse("2026-10-20"); $0.status = .open },
            Entry("task-fertig", .task, "Wohnung kündigen", now, now) { $0.due = Day.parse("2026-10-19"); $0.status = .done },
            Entry("task-freitag", .task, "Schlüssel abholen", now, now.addingTimeInterval(-30)) { $0.due = Day.parse("2026-10-23"); $0.status = .open; $0.places = ["proj-umzug"] },
            Entry("task-alt", .task, "Altes Archiv", now, now) { $0.due = Day.parse("2026-10-01"); $0.status = .open; $0.archived = true },
            Entry("note-ideen", .note, "Ideen fürs Wochenende", now, now.addingTimeInterval(-40)) { $0.body = "Flohmarkt, Radtour" },
            Entry("deck-spanisch", .deck, "Spanisch A2", now, now.addingTimeInterval(-50)),
            Entry("card-casa", .flashcard, "la casa", now, now.addingTimeInterval(-60)) { $0.body = "das Haus\n"; $0.deck = "deck-spanisch" },
            Entry("event-team", .event, "Team-Meeting", now, now) {
                $0.start = Day.parse("2026-10-21")!.at(hour: 10, in: berlin); $0.end = Day.parse("2026-10-21")!.at(hour: 11, in: berlin)
            },
        ]
    }

    @Test func typeNamesInGermanAndEnglish() {
        #expect(ChatTools.type(from: "aufgabe") == .task)
        #expect(ChatTools.type(from: "Tasks") == .task)
        #expect(ChatTools.type(from: "flashcard") == .flashcard)
        #expect(ChatTools.type(from: "kartendeck") == .deck)
        #expect(ChatTools.type(from: "") == nil)
        #expect(ChatTools.type(from: "virus") == nil)
        #expect(ChatTaskRange.from("Woche") == .week)
        #expect(ChatTaskRange.from("overdue") == .overdue)
        #expect(ChatTaskRange.from("irgendwas") == .today)
    }

    @Test func searchFindsByPrefixSkipsArchiveAndLimits() {
        let result = ChatTools.search(world(), text: "umzug", type: nil)
        #expect(result.ids == ["task-kartons", "proj-umzug"])
        #expect(result.text.contains("Umzugskartons bestellen [aufgabe] id task-kartons, status offen, due 2026-10-21, in Umzug nach Leipzig — Bei **Kartonfix** mindestens 30 Stück"))
        #expect(ChatTools.search(world(), text: "archiv", type: nil).ids.isEmpty)
        #expect(ChatTools.search(world(), text: "", type: nil).ids.isEmpty)
        #expect(ChatTools.search(world(), text: "", type: .deck).ids == ["deck-spanisch"])
        #expect(ChatTools.search(world(), text: "umzug", type: .project).ids == ["proj-umzug"])
        let many = (0..<30).map { Entry("note-\($0)", .note, "Liste \($0)", now, now.addingTimeInterval(Double($0))) }
        #expect(ChatTools.search(many, text: "liste", type: nil).ids.count == ChatTools.maxHits)
        #expect(ChatTools.search(world(), text: "xyz", type: nil).text == "No matching entries.")
    }

    @Test func readShowsDetailsContentsAndClipsBody() {
        let project = ChatTools.read(world(), id: "proj-umzug")
        #expect(project.ids == ["proj-umzug", "task-kartons", "task-freitag"])
        #expect(project.text.contains("contains:\n- Umzugskartons bestellen"))
        #expect(ChatTools.read(world(), id: "umzug nach leipzig").ids.first == "proj-umzug")
        #expect(ChatTools.read(world(), id: "nope").ids.isEmpty)
        let long = Entry("note-long", .note, "Lang", now, now) { $0.body = String(repeating: "a", count: 5_000) }
        let text = ChatTools.read([long], id: "note-long").text
        #expect(text.count < ChatTools.bodyChars + 100)
        #expect(text.hasSuffix("…"))
    }

    @Test func tasksByRangeOnlyOpenAndSorted() {
        #expect(ChatTools.tasks(world(), range: .today, today: today).ids == ["task-kartons"])
        #expect(ChatTools.tasks(world(), range: .overdue, today: today).ids == ["task-steuer"])
        #expect(ChatTools.tasks(world(), range: .week, today: today).ids == ["task-steuer", "task-kartons", "task-freitag"])
        #expect(ChatTools.tasks(world(), range: .overdue, today: today).text.contains("due 2026-10-20 overdue"))
        #expect(ChatTools.tasks([], range: .today, today: today).text == "No open tasks in this range.")
        let many = (0..<20).map { Entry("task-\($0)", .task, "T\($0)", now, now) { $0.due = Day.parse("2026-10-21"); $0.status = .open } }
        let result = ChatTools.tasks(many, range: .today, today: today)
        #expect(result.ids.count == ChatTools.maxTasks)
        #expect(result.text.hasSuffix("(5 more)"))
    }

    @Test func weekListsEventsTasksAndDeadlines() {
        let entries = world()
        let briefing = WeekBriefingBuilder.build(entries, week: Week.of(today), today: today, zone: berlin)
        let result = ChatTools.week(briefing, entries: entries, today: today, zone: berlin)
        #expect(result.text.hasPrefix("week 43: 2026-10-19 to 2026-10-25, today Wed 2026-10-21"))
        #expect(result.text.contains("- Wed 2026-10-21 10:00: Team-Meeting (id event-team)"))
        #expect(result.text.contains("- 2026-10-20 overdue: Steuererklärung abgeben"))
        #expect(result.text.contains("project deadlines:\n- 2026-10-24: Umzug nach Leipzig"))
        #expect(result.ids.contains("event-team") && result.ids.contains("proj-umzug"))
    }

    @Test func contextDescribesEachLinkedType() {
        let entries = world()
        let linked = ["proj-umzug", "deck-spanisch", "card-casa", "note-ideen"].compactMap { id in entries.first { $0.id == id } }
        let text = ChatTools.context(linked, entries: entries, today: today) { $0 == "deck-spanisch" ? 2 : 0 }
        #expect(text.contains("open tasks: Umzugskartons bestellen (due 2026-10-21); Schlüssel abholen (due 2026-10-23)"))
        #expect(text.contains("cards: 1, due for review: 2"))
        #expect(text.contains("front: la casa\nback: das Haus"))
        #expect(text.contains("la casa [karteikarte] id card-casa, deck Spanisch A2"))
        #expect(text.contains("text: Flohmarkt, Radtour"))
        let big = (0..<50).map { Entry("note-\($0)", .note, "Notiz \($0)", now, now) { $0.body = String(repeating: "x", count: 400) } }
        #expect(ChatTools.context(big, entries: big, today: today) { _ in 0 }.count <= ChatTools.maxContextChars)
    }
}

struct ChatPromptTests {
    private let now = at("2026-10-21T10:00:00Z")

    @Test func instructionsCarryLanguageDateLinksAndHistory() {
        let text = ChatPrompt.instructions(language: "German", today: Day.parse("2026-10-21")!, linked: "Umzug [projekt]", history: "User: Hallo")
        #expect(text.contains("Always answer in German."))
        #expect(text.contains("Today is Wed 2026-10-21."))
        #expect(text.contains("linked to these entries:\nUmzug [projekt]"))
        #expect(text.contains("Earlier in this conversation:\nUser: Hallo"))
        let bare = ChatPrompt.instructions(language: "English", today: Day.parse("2026-10-21")!, linked: "", history: "")
        #expect(!bare.contains("linked") && !bare.contains("Earlier"))
    }

    @Test func historyKeepsNewestWithinBudgetAndSummarisesTheRest() {
        let messages = (0..<20).map { i in
            ChatMessage(id: "msg-\(i)", role: i % 2 == 0 ? .user : .assistant, text: "Nachricht \(i) " + String(repeating: "x", count: 150), at: now)
        }
        let history = ChatPrompt.history(messages, limit: 800)
        #expect(history.count <= 800 + 400)
        #expect(history.hasSuffix("Assistant: " + messages.last!.text))
        #expect(history.hasPrefix("("))
        #expect(history.contains("older messages omitted; earlier questions:"))
        #expect(!history.contains("Nachricht 0 x"))
        #expect(ChatPrompt.history([]).isEmpty)
        let short = [ChatMessage(id: "msg-1", role: .user, text: "Was steht\nan?", at: now)]
        #expect(ChatPrompt.history(short) == "User: Was steht an?")
    }

    @Test func mentionsFollowTheAnswerOrderAndIgnoreShortTitles() {
        let entries = [
            Entry("task-a", .task, "Steuererklärung abgeben", now, now),
            Entry("task-b", .task, "Umzugskartons bestellen", now, now),
            Entry("note-c", .note, "Zu", now, now),
            Entry("note-d", .note, "Nicht genannt", now, now),
        ]
        let answer = "Zuerst **umzugskartons bestellen**, dann die Steuererklarung abgeben. Zu spät?"
        #expect(ChatMentions.find(answer, candidates: entries + entries) == ["task-b", "task-a"])
        #expect(ChatMentions.find("", candidates: entries).isEmpty)
    }
}

struct ChatLinkTests {
    private let now = at("2026-10-21T10:00:00Z")

    @Test func linksAndMentionsRoundTripAndStayOptional() throws {
        var thread = ChatThread(id: "chat-1", created: now)
        thread.setLinked("proj-umzug", true)
        thread.setLinked("card-casa", true)
        thread.setLinked("proj-umzug", true)
        thread.setLinked("../x", true)
        #expect(thread.links == ["card-casa", "proj-umzug"])
        thread.setLinked("card-casa", false)
        #expect(thread.links == ["proj-umzug"])
        thread.append(ChatMessage(id: "msg-1", role: .user, text: "Frage", at: now))
        #expect(thread.lastQuestion?.id == "msg-1")
        thread.append(ChatMessage(id: "msg-2", role: .assistant, text: "Antwort", at: now, entries: ["task-a"]))
        #expect(thread.lastQuestion == nil)
        let data = try ChatCodec.encode(thread)
        #expect(String(decoding: data, as: UTF8.self).contains("\"verknuepft\""))
        #expect(try ChatCodec.decode(data) == thread)
        let plain = try ChatCodec.encode(ChatThread(id: "chat-2", created: now))
        let text = String(decoding: plain, as: UTF8.self)
        #expect(!text.contains("verknuepft") && !text.contains("eintraege"))
    }

    @Test func rejectsHostileLinks() {
        func json(_ links: String) -> Data {
            Data("{\"format\":1,\"id\":\"chat-1\",\"titel\":\"\",\"erstellt\":\"2026-10-21T10:00:00Z\",\"geaendert\":\"2026-10-21T10:00:00Z\",\"nachrichten\":[],\"verknuepft\":\(links)}".utf8)
        }
        #expect(throws: EntryParseError.self) { try ChatCodec.decode(json("[\"../etc\"]")) }
        let many = (0...ChatCodec.maxLinks).map { "\"note-\($0)\"" }.joined(separator: ",")
        #expect(throws: EntryParseError.self) { try ChatCodec.decode(json("[\(many)]")) }
        #expect((try? ChatCodec.decode(json("[\"note-1\",\"note-1\"]")))?.links == ["note-1"])
    }

    @Test func pickerOffersAllTypesLinkedFirstWithSearchAndFilter() {
        let entries = [
            Entry("deck-1", .deck, "Spanisch A2", now, now.addingTimeInterval(10)),
            Entry("card-1", .flashcard, "la casa", now, now.addingTimeInterval(20)),
            Entry("proj-1", .project, "Umzug", now, now.addingTimeInterval(30)),
            Entry("note-1", .note, "Spanisch Notizen", now, now.addingTimeInterval(40)),
            Entry("note-old", .note, "Archiviert", now, now.addingTimeInterval(50)) { $0.archived = true },
        ]
        #expect(ChatList.pickable(entries, kind: nil, query: "", linked: ["deck-1"]).map(\.id) == ["deck-1", "note-1", "proj-1", "card-1"])
        #expect(ChatList.pickable(entries, kind: .flashcards, query: "", linked: []).map(\.id) == ["card-1", "deck-1"])
        #expect(ChatList.pickable(entries, kind: nil, query: "span", linked: []).map(\.id) == ["note-1", "deck-1"])
        let many = (0..<150).map { Entry("note-\($0)", .note, "N", now, now) }
        #expect(ChatList.pickable(many, kind: nil, query: "", linked: []).count == ChatList.pickLimit)
    }

    @Test func linkedChatsPerEntryNewestFirst() {
        let a = ChatThread(id: "chat-a", created: now, updated: now, links: ["proj-1"])
        let b = ChatThread(id: "chat-b", created: now, updated: now.addingTimeInterval(60), links: ["proj-1", "card-1"])
        let c = ChatThread(id: "chat-c", created: now, updated: now.addingTimeInterval(90))
        #expect(ChatList.linked(to: "proj-1", in: [a, b, c]).map(\.id) == ["chat-b", "chat-a"])
        #expect(ChatList.linked(to: "card-1", in: [a, b, c]).map(\.id) == ["chat-b"])
    }
}
