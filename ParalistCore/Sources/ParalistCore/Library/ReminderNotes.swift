// Zusammenhang: Model/Entry.swift, Markdown/EntryCodec.swift, Paralist/Entry/EntryReminderCard.swift, Paralist/Entry/EntryParts.swift, Paralist/Reminders/ReminderScheduler.swift
import Foundation

public extension Entry {
    static let reminderNotePrefix = "erinnerung_notiz_"
    static let maxReminderNoteChars = 200

    static func reminderNoteKey(_ at: Date) -> String {
        reminderNotePrefix + String(Int(at.timeIntervalSince1970.rounded(.down)))
    }

    func upcomingReminders(now: Date) -> [Date] {
        reminders.filter { $0 > now }.sorted()
    }

    func hasUpcomingReminder(now: Date) -> Bool {
        reminders.contains { $0 > now }
    }

    func reminderNote(at: Date) -> String? {
        guard let raw = extras[Self.reminderNoteKey(at)], !raw.isEmpty else { return nil }
        return raw
    }

    mutating func setReminderNote(_ note: String?, at: Date) {
        let cleaned = (note ?? "")
            .components(separatedBy: .newlines)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
        let key = Self.reminderNoteKey(at)
        extras[key] = cleaned.isEmpty || !reminders.contains(at) ? nil : String(cleaned.prefix(Self.maxReminderNoteChars))
    }

    mutating func setReminders(_ list: [Date]) {
        reminders = list
        let kept = Set(list.map(Self.reminderNoteKey))
        for key in extras.keys where key.hasPrefix(Self.reminderNotePrefix) && !kept.contains(key) {
            extras[key] = nil
        }
    }
}
