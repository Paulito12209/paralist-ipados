// Zusammenhang: Sources/ParalistCore/Chat/ChatEventDrafts.swift, Sources/ParalistCore/Chat/ChatDrafts.swift, Sources/ParalistCore/Chat/ChatCodec.swift, Sources/ParalistCore/Chat/ChatPrompt.swift (withPlan), Sources/ParalistCore/Chat/ChatThread.swift (question before), ShiftPlanTests.swift, TestSupport.swift
import Foundation
import Testing
@testable import ParalistCore

struct ChatEventDraftsTests {
    private let now = at("2026-10-28T10:00:00Z")
    private let today = Day.parse("2026-10-28")!

    private func plan() -> ShiftPlan {
        ShiftPlanReader.read(ShiftPlanTests.document(), name: "Erika Muster", today: today)!
    }

    private func event(_ id: String, _ title: String, _ day: String, _ start: Int, _ end: Int) -> Entry {
        Entry(id, .event, title, now, now) {
            let d = Day.parse(day)!
            $0.start = d.at(hour: start / 60, minute: start % 60, in: berlin)
            $0.end = d.at(hour: end / 60, minute: end % 60, in: berlin)
        }
    }

    private func maker() -> (EntryType, String) -> Entry {
        var n = 0
        return { type, title in
            n += 1
            return Entry("new-\(n)", type, title, self.now, self.now)
        }
    }

    @Test func draftMarksPastDuplicatesAndOddHours() {
        let existing = [event("e-1", "arbeit", "2026-10-28", 12 * 60, 20 * 60), event("e-2", "Zahnarzt", "2026-10-31", 19 * 60, 20 * 60 + 30)]
        let draft = ChatDrafts.events(id: "d-1", plan: plan(), existing: existing, today: today, zone: berlin, fallback: "Arbeit")
        #expect(draft.kind == .events && draft.title == "Arbeit" && !draft.isEmpty && !draft.asksForRow)
        #expect(draft.items.map(\.due) == [Day.parse("2026-10-26"), Day.parse("2026-10-28"), Day.parse("2026-10-31")])
        #expect(draft.items.map(\.hint) == [.past, .exists, nil])
        #expect(draft.items.map(\.selected) == [false, false, true])
        #expect(draft.items[2].start == 22 * 60 && draft.items[2].end == 6 * 60 + 30)
        #expect(draft.selectedCount == 1)
        let later = ChatDrafts.events(id: "d-2", plan: plan(), existing: [], today: Day.parse("2026-10-01")!, zone: berlin, fallback: "Arbeit")
        #expect(later.items.map(\.hint) == [nil, .hours, nil])
        #expect(later.items.allSatisfy { $0.selected })
    }

    @Test func titleComesFromTheSkillThenFromUsualEventsThenFromTheFallback() {
        let usual = [event("e-1", "Spätschicht", "2026-09-02", 13 * 60, 21 * 60), event("e-2", "Spätschicht", "2026-09-09", 13 * 60, 21 * 60),
                     event("e-3", "Frühdienst", "2026-09-03", 6 * 60, 14 * 60), event("e-4", "Kino", "2026-09-04", 19 * 60, 21 * 60)]
        #expect(ChatDrafts.events(id: "d", plan: plan(), existing: usual, today: today, zone: berlin, skill: ShiftSkill(title: " Dienst "), fallback: "Arbeit").title == "Dienst")
        #expect(ChatDrafts.events(id: "d", plan: plan(), existing: usual, today: today, zone: berlin, fallback: "Arbeit").title == "Spätschicht")
        #expect(ChatDrafts.events(id: "d", plan: plan(), existing: [], today: today, zone: berlin, fallback: "Arbeit").title == "Arbeit")
        var empty = plan()
        empty.shifts = []
        let none = ChatDrafts.events(id: "d", plan: empty, existing: [], today: today, zone: berlin, fallback: "Arbeit")
        #expect(none.isEmpty && ChatDrafts.planSummary(none).contains("contains no shifts"))
    }

    @Test func selectedItemsBecomeEventsAcrossMidnight() {
        let draft = ChatDrafts.events(id: "d-1", plan: plan(), existing: [], today: Day.parse("2026-10-01")!, zone: berlin, fallback: "Arbeit")
        let made = ChatDrafts.entries(draft, decks: [], zone: berlin, make: maker())
        #expect(made.created.map(\.type) == [.event, .event, .event] && made.shown == ["new-1", "new-2", "new-3"])
        #expect(made.created[0].start == at("2026-10-26T05:00:00Z") && made.created[0].end == at("2026-10-26T12:25:00Z"))
        #expect(made.created[2].start == at("2026-10-31T21:00:00Z") && made.created[2].end == at("2026-11-01T05:30:00Z"))
        var partly = draft
        partly.items[1].selected = false
        #expect(ChatDrafts.entries(partly, decks: [], zone: berlin, make: maker()).created.count == 2)
        let choice = ChatDrafts.whichRow(id: "d-2", names: ["uster, Erika", " Beispiel, Max ", "beispiel, max", ""])
        #expect(choice.asksForRow && choice.choices == ["uster, Erika", "Beispiel, Max"] && !choice.isEmpty)
        #expect(ChatDrafts.entries(choice, decks: [], zone: berlin, make: maker()).created.isEmpty)
    }

    @Test func cleaningKeepsSelectionAndDropsBrokenRows() {
        var draft = ChatDrafts.events(id: "d-1", plan: plan(), existing: [], today: today, zone: berlin, fallback: "Arbeit")
        draft.items[2].front = "  Nacht "
        draft.items.append(ChatDraftItem(front: "Ohne Tag", start: 60, end: 120))
        draft.items.append(ChatDraftItem(front: "Kaputt", due: today, start: 60, end: 1500))
        draft.items += (0..<20).map { ChatDraftItem(front: "Viel \($0)", due: today, start: 60, end: 120) }
        let clean = ChatDrafts.cleaned(draft, today: today)
        #expect(clean.items.count == ChatDrafts.maxEvents)
        #expect(clean.items[2].front == "Nacht" && clean.items[0].hint == .past && clean.items[0].selected == false)
        #expect(clean.items[3].front == "Viel 0")
        let summary = ChatDrafts.planSummary(draft)
        #expect(summary.contains("draft of 25 shifts as events titled \"Arbeit\" from 2026-10-26 to 2026-10-28"))
        #expect(summary.contains("(1 are in the past; those are unchecked)"))
        #expect(ChatDrafts.planSummary(ChatDrafts.whichRow(id: "d", names: ["A", "B"])).contains("one row per person: A, B."))
        #expect(ChatPrompt.withPlan(" Trag das ein ", summary: "S").hasSuffix("S\n\nQuestion: Trag das ein"))
        #expect(ChatPrompt.withPlan("", summary: "S").hasSuffix("the user most likely wants these shifts as events."))
    }

    @Test func eventDraftsRoundTripThroughTheChatFile() throws {
        let draft = ChatDrafts.events(id: "draft-1", plan: plan(), existing: [], today: today, zone: berlin, fallback: "Arbeit")
        let choice = ChatDrafts.whichRow(id: "draft-2", names: ["uster, Erika", "Beispiel, Max"])
        let hash = String(repeating: "b", count: 64)
        let thread = ChatThread(id: "chat-1", created: now, messages: [
            ChatMessage(id: "msg-1", role: .user, text: "Trag ein", at: now, attachment: hash),
            ChatMessage(id: "msg-2", role: .assistant, text: "Hier.", at: now, drafts: [draft, choice]),
        ])
        let data = try ChatCodec.encode(thread)
        let json = String(decoding: data, as: UTF8.self)
        #expect(json.contains("\"beginn\" : \"22:00\"") && json.contains("\"ende\" : \"06:30\"") && json.contains("\"gewaehlt\" : false"))
        #expect(json.contains("\"hinweis\" : \"vergangen\"") && json.contains("\"namen\" : [") && json.contains("\"art\" : \"termine\""))
        #expect(try ChatCodec.decode(data) == thread)
        #expect(thread.question(before: "draft-2")?.attachment == hash)
        #expect(thread.question(before: "draft-9") == nil)
        func file(_ item: String) -> Data {
            Data("""
            {"format":1,"id":"chat-1","titel":"","erstellt":"2026-10-21T10:00:00Z","geaendert":"2026-10-21T10:00:00Z",
             "nachrichten":[{"id":"msg-1","rolle":"modell","text":"x","zeit":"2026-10-21T10:00:00Z","entwuerfe":[{"id":"draft-1","art":"termine","status":"offen","punkte":[\(item)]}]}]}
            """.utf8)
        }
        #expect(throws: Never.self) { try ChatCodec.decode(file(#"{"vorne":"Arbeit","faellig":"2026-10-28","beginn":"06:00","ende":"13:00"}"#)) }
        #expect((try? ChatCodec.decode(file(#"{"vorne":"Arbeit","faellig":"2026-10-28","beginn":"6:00","ende":"13:00"}"#))) == nil)
        #expect((try? ChatCodec.decode(file(#"{"vorne":"Arbeit","faellig":"2026-10-28","beginn":"06:00","ende":"24:00"}"#))) == nil)
        #expect((try? ChatCodec.decode(file(#"{"vorne":"Arbeit","hinweis":"egal"}"#))) == nil)
    }
}
