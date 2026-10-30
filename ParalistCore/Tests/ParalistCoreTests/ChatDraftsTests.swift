// Zusammenhang: Sources/ParalistCore/Chat/ChatDrafts.swift, Sources/ParalistCore/Chat/ChatCodec.swift, Sources/ParalistCore/Chat/ChatThread.swift, TestSupport.swift
import Foundation
import Testing
@testable import ParalistCore

struct ChatDraftsTests {
    private let now = at("2026-10-21T10:00:00Z")
    private let today = Day.parse("2026-10-21")!

    private func maker() -> (EntryType, String) -> Entry {
        var n = 0
        return { type, title in
            n += 1
            return Entry("new-\(n)", type, title, self.now, self.now)
        }
    }

    @Test func flashcardsAreCleanedDedupedAndCapped() {
        var cards = [("  le chien\n", " der Hund "), ("Le Chien", "doppelt"), ("", "leer"), ("le chat", "  "), ("la maison", "das Haus")]
        cards += (0..<30).map { ("wort \($0)", "Wort \($0)") }
        let draft = ChatDrafts.flashcards(id: "d-1", deck: " Französisch\n", cards: cards)
        #expect(draft.title == "Französisch")
        #expect(draft.items.count == ChatDrafts.maxCards)
        #expect(draft.items[0] == ChatDraftItem(front: "le chien", back: "der Hund"))
        #expect(draft.items[1].front == "la maison")
        #expect(draft.state == .open && !draft.isEmpty)
        #expect(ChatDrafts.flashcards(id: "d-2", deck: "", cards: [("a", "b")]).isEmpty)
        let long = ChatDrafts.flashcards(id: "d-3", deck: "X", cards: [(String(repeating: "a", count: 900), String(repeating: "b", count: 3_000))])
        #expect(long.items[0].front.count == ChatDrafts.maxFrontChars)
        #expect(long.items[0].back.count == ChatDrafts.maxBackChars)
    }

    @Test func tasksKeepOnlyPlausibleDueDates() {
        let draft = ChatDrafts.tasks(id: "d-1", tasks: [("Vokabeln lernen", "2026-10-23"), ("Alt", "2020-01-01"), ("Kaputt", "morgen"), ("Ohne", nil), ("  ", "2026-10-22"), ("Fern", "2040-01-01")], today: today)
        #expect(draft.items.map(\.front) == ["Vokabeln lernen", "Alt", "Kaputt", "Ohne", "Fern"])
        #expect(draft.items.map(\.due) == [Day.parse("2026-10-23"), nil, nil, nil, nil])
        #expect(ChatDrafts.due("2026-10-20", today: today) == Day.parse("2026-10-20"))
        let many = ChatDrafts.tasks(id: "d-2", tasks: (0..<15).map { ("Aufgabe \($0)", nil) }, today: today)
        #expect(many.items.count == ChatDrafts.maxTasks)
        #expect(ChatDrafts.tasks(id: "d-3", tasks: [], today: today).isEmpty)
    }

    @Test func flashcardsGoIntoAMatchingDeckOrANewOne() {
        let decks = [Entry("deck-1", .deck, "franzosisch", now, now), Entry("deck-2", .deck, "Alt", now, now) { $0.archived = true }]
        let draft = ChatDrafts.flashcards(id: "d-1", deck: "Französisch", cards: [("le chien", "der Hund"), ("le chat", "die Katze")])
        let existing = ChatDrafts.entries(draft, decks: decks, make: maker())
        #expect(existing.shown == ["deck-1"])
        #expect(existing.created.map(\.type) == [.flashcard, .flashcard])
        #expect(existing.created.allSatisfy { $0.deck == "deck-1" })
        #expect(existing.created[0].title == "le chien" && existing.created[0].body == "der Hund\n")
        var other = draft
        other.title = "Alt"
        let fresh = ChatDrafts.entries(other, decks: decks, make: maker())
        #expect(fresh.created.map(\.type) == [.deck, .flashcard, .flashcard])
        #expect(fresh.shown == ["new-1"] && fresh.created[1].deck == "new-1")
        #expect(ChatDrafts.summary(draft, decks: decks).contains("2 flashcards for the existing deck \"Französisch\""))
        #expect(ChatDrafts.summary(other, decks: decks).contains("a new deck \"Alt\""))
    }

    @Test func tasksAndNotesBecomeEntriesOnlyWhileOpen() {
        let tasks = ChatDrafts.tasks(id: "d-1", tasks: [("Lernen", "2026-10-22"), ("Wiederholen", nil)], today: today)
        let made = ChatDrafts.entries(tasks, decks: [], make: maker())
        #expect(made.created.map(\.type) == [.task, .task])
        #expect(made.created[0].due == Day.parse("2026-10-22") && made.created[1].due == nil)
        #expect(made.shown == ["new-1", "new-2"])
        let note = ChatDrafts.note(id: "d-2", title: "Plan", text: "  - Montag\n- Dienstag \n")
        let written = ChatDrafts.entries(note, decks: [], make: maker())
        #expect(written.created.first?.body == "- Montag\n- Dienstag\n")
        var done = note
        done.state = .saved
        #expect(ChatDrafts.entries(done, decks: [], make: maker()).created.isEmpty)
        #expect(ChatDrafts.entries(ChatDrafts.note(id: "d-3", title: " ", text: "x"), decks: [], make: maker()).created.isEmpty)
        #expect(ChatDrafts.summary(ChatDrafts.note(id: "d-3", title: "", text: ""), decks: []).hasPrefix("Nothing was prepared"))
    }

    @Test func cleaningAnEditedDraftKeepsStateAndSaved() {
        var draft = ChatDrafts.flashcards(id: "d-1", deck: "Deck", cards: [("a", "b")])
        draft.items.append(ChatDraftItem(front: " c ", back: " d "))
        draft.items.append(ChatDraftItem(front: "", back: "leer"))
        draft.saved = ["x-1"]
        let clean = ChatDrafts.cleaned(draft, today: today)
        #expect(clean.items == [ChatDraftItem(front: "a", back: "b"), ChatDraftItem(front: "c", back: "d")])
        #expect(clean.saved == ["x-1"] && clean.id == "d-1")
    }

    @Test func draftsRoundTripThroughTheChatFile() throws {
        var flash = ChatDrafts.flashcards(id: "draft-1", deck: "Französisch", cards: [("le chien", "der Hund")])
        flash.state = .saved
        flash.saved = ["deck-1"]
        let tasks = ChatDrafts.tasks(id: "draft-2", tasks: [("Lernen", "2026-10-22"), ("Später", nil)], today: today)
        let note = ChatDrafts.note(id: "draft-3", title: "Plan", text: "Text")
        let message = ChatMessage(id: "msg-2", role: .assistant, text: "Fertig.", at: now, drafts: [flash, tasks, note])
        var thread = ChatThread(id: "chat-1", created: now, messages: [ChatMessage(id: "msg-1", role: .user, text: "Bitte", at: now), message])
        let back = try ChatCodec.decode(ChatCodec.encode(thread))
        #expect(back == thread)
        var discarded = tasks
        discarded.state = .discarded
        thread.setDraft(discarded)
        #expect(thread.draft("draft-2")?.state == .discarded)
        #expect(thread.draft("draft-9") == nil)
    }

    @Test func brokenDraftsAreRejected() {
        func file(_ draft: String) -> Data {
            Data("""
            {"format":1,"id":"chat-1","titel":"","erstellt":"2026-10-21T10:00:00Z","geaendert":"2026-10-21T10:00:00Z",
             "nachrichten":[{"id":"msg-1","rolle":"modell","text":"x","zeit":"2026-10-21T10:00:00Z","entwuerfe":[\(draft)]}]}
            """.utf8)
        }
        #expect(throws: Never.self) { try ChatCodec.decode(file(#"{"id":"draft-1","art":"notiz","titel":"Plan","status":"offen"}"#)) }
        #expect((try? ChatCodec.decode(file(#"{"id":"draft-1","art":"spiel","status":"offen"}"#))) == nil)
        #expect((try? ChatCodec.decode(file(#"{"id":"draft-1","art":"notiz","status":"fertig"}"#))) == nil)
        #expect((try? ChatCodec.decode(file(#"{"id":"../x","art":"notiz","status":"offen"}"#))) == nil)
        #expect((try? ChatCodec.decode(file(#"{"id":"draft-1","art":"aufgaben","status":"offen","punkte":[{"vorne":"a","faellig":"bald"}]}"#))) == nil)
        #expect((try? ChatCodec.decode(file(#"{"id":"draft-1","art":"notiz","status":"offen"},{"id":"draft-1","art":"notiz","status":"offen"}"#))) == nil)
        let many = (0..<25).map { #"{"vorne":"w\#($0)","hinten":"x"}"# }.joined(separator: ",")
        #expect((try? ChatCodec.decode(file(#"{"id":"draft-1","art":"karteikarten","status":"offen","punkte":["# + many + "]}"))) == nil)
    }
}
