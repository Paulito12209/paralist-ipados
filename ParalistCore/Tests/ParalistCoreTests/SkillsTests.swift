// Zusammenhang: Sources/ParalistCore/Chat/Skills.swift, Sources/ParalistCore/Chat/ChatMentionQuery.swift, Sources/ParalistCore/Chat/ChatThread.swift (mentions), Sources/ParalistCore/Chat/ChatCodec.swift (erwaehnt), Sources/ParalistCore/Chat/ChatPrompt.swift (withMentions), Sources/ParalistCore/Chat/ChatEventDrafts.swift (skill), ShiftPlanTests.swift, TestSupport.swift
import Foundation
import Testing
@testable import ParalistCore

struct SkillsTests {
    private let now = at("2026-10-28T10:00:00Z")
    private let today = Day.parse("2026-10-28")!

    private func library() -> [Entry] {
        [
            Entry("tag-skill", .tag, " skill ", now, now),
            Entry("note-shift", .note, "Schichtplan", now, now) {
                $0.links = ["tag-skill"]
                $0.body = "Frühschicht heißt bei mir Früh.\n"
                $0.extras = [Skills.nameKey: "Muster, Erika", Skills.titleKey: "Dienst", Skills.absencesKey: "true", Skills.pauseKey: "45", Skills.reminderKey: "60", "fremd": "bleibt"]
            },
            Entry("note-style", .note, "Antwortstil", now, now) { $0.links = ["tag-skill"]; $0.body = "Antworte knapp.\n" },
            Entry("note-old", .note, "Alt", now, now) { $0.links = ["tag-skill"]; $0.archived = true },
            Entry("note-plain", .note, "Einkauf", now, now) { $0.body = "Milch\n" },
            Entry("task-1", .task, "Skill lernen", now, now),
        ]
    }

    private func maker() -> (EntryType, String) -> Entry {
        var n = 0
        return { type, title in
            n += 1
            return Entry("new-\(n)", type, title, self.now, self.now)
        }
    }

    @Test func skillsAreNotesLinkedToTheSkillTag() {
        let all = library()
        #expect(Skills.tag(in: all)?.id == "tag-skill")
        #expect(Skills.all(in: all).map(\.id) == ["note-style", "note-shift"])
        #expect(Skills.isSkill(all[1], in: all) && !Skills.isSkill(all[4], in: all))
        #expect(Skills.all(in: all.filter { $0.id != "tag-skill" }).isEmpty)
        var reversed = all
        reversed[1].links = []
        reversed[0].links = ["note-shift"]
        #expect(Skills.all(in: reversed).map(\.id) == ["note-style", "note-shift"])
        let skill = Skills.shift(in: all)
        #expect(skill == ShiftSkill(name: "Muster, Erika", title: "Dienst", absences: true, pause: 45, reminder: 60, text: "Frühschicht heißt bei mir Früh.\n"))
        #expect(Skills.shift(in: all.filter { $0.id != "note-shift" }) == nil)
        #expect(Skills.instruction(Skills.all(in: all)) == "Skill \"Antwortstil\":\nAntworte knapp.\n\nSkill \"Schichtplan\":\nFrühschicht heißt bei mir Früh.")
    }

    @Test func fieldsSurviveTheEntryFileAndBadValuesAreIgnored() throws {
        let note = ShiftSkill(name: "Beispiel, Max", title: "", absences: false, pause: nil, reminder: 15).applied(to: library()[1])
        let text = EntryCodec.encode(note)
        #expect(text.contains("schicht_name:") && text.contains("schicht_erinnerung: 15") && text.contains("fremd: bleibt"))
        #expect(!text.contains("schicht_titel") && !text.contains("schicht_abwesend") && !text.contains("schicht_pause"))
        let back = try EntryCodec.decode(text, now: now)
        #expect(ShiftSkill(back) == ShiftSkill(name: "Beispiel, Max", reminder: 15, text: note.body))
        var odd = library()[1]
        odd.extras[Skills.pauseKey] = "viel"
        odd.extras[Skills.reminderKey] = "-5"
        #expect(ShiftSkill(odd).pause == nil && ShiftSkill(odd).reminder == nil)
    }

    @Test func choosingARowCreatesOrUpdatesTheSkill() {
        let fresh = Skills.planSkill(name: "uster, Erika", title: "Schichtplan", text: "Regeln", in: [], make: maker())
        #expect(fresh.map(\.type) == [.tag, .note])
        #expect(fresh[0].title == "Skill" && fresh[1].links == ["new-1"] && fresh[1].body == "Regeln\n")
        #expect(ShiftSkill(fresh[1]).name == "uster, Erika")
        let updated = Skills.planSkill(name: "Beispiel, Max", title: "X", text: "Y", in: library(), make: maker())
        #expect(updated.count == 1 && updated[0].id == "note-shift")
        #expect(ShiftSkill(updated[0]) == ShiftSkill(name: "Beispiel, Max", title: "Dienst", absences: true, pause: 45, reminder: 60, text: "Frühschicht heißt bei mir Früh.\n"))
        #expect(updated[0].extras["fremd"] == "bleibt")
        let tagOnly = Skills.planSkill(name: "A", title: "Schichtplan", text: "", in: [library()[0]], make: maker())
        #expect(tagOnly.map(\.type) == [.note] && tagOnly[0].links == ["tag-skill"] && tagOnly[0].body.isEmpty)
    }

    @Test func mentionTokensAndSuggestions() {
        #expect(ChatMentionQuery.token(in: "Fasse @Schi") == "Schi")
        #expect(ChatMentionQuery.token(in: "Fasse @") == "")
        #expect(ChatMentionQuery.token(in: "mail@example.com") == nil)
        #expect(ChatMentionQuery.token(in: "Hallo @Schi ") == nil)
        #expect(ChatMentionQuery.removingToken(from: "Fasse @Schi") == "Fasse")
        #expect(ChatMentionQuery.removingToken(from: "Fasse zusammen") == "Fasse zusammen")
        let all = library()
        #expect(ChatMentionQuery.suggestions("", entries: all, exclude: []).map(\.id) == ["note-style", "note-shift", "tag-skill", "note-plain", "task-1"])
        #expect(ChatMentionQuery.suggestions("sk", entries: all, exclude: ["tag-skill"]).map(\.id) == ["task-1"])
        #expect(ChatMentionQuery.suggestions("schicht", entries: all, exclude: []).map(\.id) == ["note-shift"])
        let many = (0..<20).map { Entry("n-\($0)", .note, "Notiz \($0)", now, now) }
        #expect(ChatMentionQuery.suggestions("", entries: many, exclude: []).count == ChatMentionQuery.maxSuggestions)
    }

    @Test func mentionsAreStoredWithTheMessage() throws {
        var thread = ChatThread(id: "chat-1", created: now)
        let ids = (0..<12).map { "note-\($0)" } + ["note-0", "../x"]
        thread.append(ChatMessage(id: "msg-1", role: .user, text: "", at: now, mentions: ids))
        #expect(thread.messages.count == 1 && thread.messages[0].mentions.count == ChatMentionQuery.maxMentions)
        thread.append(ChatMessage(id: "msg-2", role: .user, text: " ", at: now, mentions: ["../x"]))
        #expect(thread.messages.count == 1)
        thread.append(ChatMessage(id: "msg-3", role: .assistant, text: "Ok", at: now))
        let data = try ChatCodec.encode(thread)
        #expect(String(decoding: data, as: UTF8.self).contains("\"erwaehnt\" : ["))
        #expect(try ChatCodec.decode(data) == thread)
        let tooMany = Data("""
        {"format":1,"id":"chat-1","titel":"","erstellt":"2026-10-21T10:00:00Z","geaendert":"2026-10-21T10:00:00Z",
         "nachrichten":[{"id":"msg-1","rolle":"nutzer","text":"x","zeit":"2026-10-21T10:00:00Z","erwaehnt":[\((0..<11).map { "\"n-\($0)\"" }.joined(separator: ","))]}]}
        """.utf8)
        #expect((try? ChatCodec.decode(tooMany)) == nil)
        let prompt = ChatPrompt.withMentions("Frage", context: "Einkauf [note] id note-plain\ntext: Milch", skills: "Skill \"Antwortstil\":\nAntworte knapp.")
        #expect(prompt.hasPrefix("Follow these instructions from the user's skills for this message:\nSkill \"Antwortstil\":"))
        #expect(prompt.contains("\n\nThe user mentioned these entries (use them as context, name them by title):\nEinkauf [note]"))
        #expect(prompt.hasSuffix("\n\nFrage"))
        #expect(ChatPrompt.withMentions("Frage", context: "", skills: "") == "Frage")
    }

    @Test func skillRulesShapeTheEventDraft() {
        let plan = ShiftPlanReader.read(ShiftPlanTests.document(), name: "Erika Muster", today: today)!
        #expect(plan.absences == [Day.parse("2026-10-27")])
        let skill = ShiftSkill(name: "Erika Muster", title: "Dienst", absences: true, pause: 0, reminder: 30)
        let draft = ChatDrafts.events(id: "d", plan: plan, existing: [], today: Day.parse("2026-10-01")!, zone: berlin, skill: skill, fallback: "Arbeit", absent: "Abwesend")
        #expect(draft.title == "Dienst")
        #expect(draft.items.map(\.front) == ["Dienst", "Abwesend", "Dienst", "Dienst"])
        #expect(draft.items.map(\.hint) == [.hours, nil, .hours, .hours])
        #expect(draft.items[1].start == nil && draft.items[1].end == nil && draft.items[1].due == Day.parse("2026-10-27"))
        let noAbsence = ChatDrafts.events(id: "d", plan: plan, existing: [], today: today, zone: berlin, skill: ShiftSkill(absences: false), fallback: "Arbeit", absent: "Abwesend")
        #expect(noAbsence.items.count == 3)
        var n = 0
        let made = ChatDrafts.entries(ChatDrafts.cleaned(draft, today: today), decks: [], zone: berlin, reminder: skill.reminder) { type, title in
            n += 1
            return Entry("new-\(n)", type, title, now, now)
        }
        #expect(made.created.count == 4)
        #expect(made.created[0].reminders == [at("2026-10-26T04:30:00Z")])
        #expect(made.created[1].allDay && made.created[1].start == at("2026-10-26T23:00:00Z") && made.created[1].end == nil && made.created[1].reminders.isEmpty)
        var absentExists = draft
        absentExists = ChatDrafts.events(id: "d", plan: plan, existing: [Entry("e", .event, "abwesend", now, now) { $0.allDay = true; $0.start = Day.parse("2026-10-27")!.startOfDay(in: berlin) }],
                                         today: Day.parse("2026-10-01")!, zone: berlin, skill: skill, fallback: "Arbeit", absent: "Abwesend")
        #expect(absentExists.items[1].hint == .exists && !absentExists.items[1].selected)
    }
}
