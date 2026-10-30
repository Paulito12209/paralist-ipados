// Zusammenhang: Sources/ParalistCore/Library/ReminderNotes.swift, Sources/ParalistCore/Markdown/EntryCodec.swift
import Foundation
import Testing
@testable import ParalistCore

struct ReminderNotesTests {
    private let now = Date(timeIntervalSince1970: 1_790_000_000)

    private func task(reminders: [Date]) -> Entry {
        var e = Entry(id: "aufgabe-1", type: .task, title: "Aufgabe", created: now, updated: now)
        e.reminders = reminders
        return e
    }

    @Test func noteSurvivesCodec() throws {
        let at = now.addingTimeInterval(3_600)
        var e = task(reminders: [at])
        e.setReminderNote("Unterlagen \"mitnehmen\"\nund drucken", at: at)
        let again = try EntryCodec.decode(EntryCodec.encode(e), now: now)
        #expect(again.reminderNote(at: at) == "Unterlagen \"mitnehmen\" und drucken")
    }

    @Test func noteNeedsReminderAndText() {
        let at = now.addingTimeInterval(3_600)
        var e = task(reminders: [at])
        e.setReminderNote("Notiz", at: now)
        #expect(e.reminderNote(at: now) == nil)
        e.setReminderNote("   ", at: at)
        #expect(e.reminderNote(at: at) == nil)
        e.setReminderNote(String(repeating: "a", count: 500), at: at)
        #expect(e.reminderNote(at: at)?.count == Entry.maxReminderNoteChars)
        e.setReminderNote(nil, at: at)
        #expect(e.extras.isEmpty)
    }

    @Test func removingReminderDropsItsNote() {
        let first = now.addingTimeInterval(3_600)
        let second = now.addingTimeInterval(7_200)
        var e = task(reminders: [first, second])
        e.extras["fremd"] = "bleibt"
        e.setReminderNote("eins", at: first)
        e.setReminderNote("zwei", at: second)
        e.setReminders([second])
        #expect(e.reminderNote(at: first) == nil)
        #expect(e.reminderNote(at: second) == "zwei")
        #expect(e.extras["fremd"] == "bleibt")
    }

    @Test func upcomingIgnoresPast() {
        let past = now.addingTimeInterval(-60)
        let later = now.addingTimeInterval(7_200)
        let soon = now.addingTimeInterval(60)
        let e = task(reminders: [later, past, soon])
        #expect(e.upcomingReminders(now: now) == [soon, later])
        #expect(e.hasUpcomingReminder(now: now))
        #expect(!task(reminders: [past]).hasUpcomingReminder(now: now))
    }
}
