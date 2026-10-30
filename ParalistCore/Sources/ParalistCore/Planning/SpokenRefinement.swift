// Zusammenhang: Planning/SpokenEvent.swift, Model/Day.swift, Paralist/Capture/SpokenRefiner.swift, Paralist/Composer/ComposerDictation.swift, Tests/ParalistCoreTests/SpokenRefinementTests.swift
import Foundation

public struct SpokenRefinement: Hashable, Sendable {
    public var title: String
    public var day: String
    public var start: String
    public var end: String

    public init(title: String, day: String = "", start: String = "", end: String = "") {
        self.title = title
        self.day = day
        self.start = start
        self.end = end
    }

    public static let maxDaysAway = 2 * 366

    public static func minute(_ text: String) -> Int? {
        let parts = text.trimmingCharacters(in: .whitespaces).split(separator: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]), (0...23).contains(h), (0...59).contains(m) else { return nil }
        return h * 60 + m
    }
}

extension SpokenEvent {
    public func refined(by r: SpokenRefinement, today: Day) -> SpokenEvent {
        var e = self
        let raw = r.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = raw.count <= Limits.maxInputTitleChars * 2 ? SpokenEvent.parse(raw, today: today, nowMinute: 0).title : ""
        if !name.isEmpty { e.title = String(name.prefix(Limits.maxInputTitleChars)) }
        if let d = Day.parse(r.day.trimmingCharacters(in: .whitespaces)), abs(d.epochDay - today.epochDay) <= SpokenRefinement.maxDaysAway { e.day = d }
        guard let day = e.day else {
            e.startMinute = nil
            e.endDay = nil
            e.endMinute = nil
            return e
        }
        if e.allDay { return e }
        if let s = SpokenRefinement.minute(r.start) { e.startMinute = s }
        guard let s = e.startMinute else {
            e.endDay = nil
            e.endMinute = nil
            return e
        }
        if let m = SpokenRefinement.minute(r.end) {
            if m == s {
                e.endDay = nil
                e.endMinute = nil
            } else {
                e.endDay = day.adding(days: m < s ? 1 : 0)
                e.endMinute = m
            }
        } else if let endDay = e.endDay, let endMinute = e.endMinute, endDay.epochDay * 1440 + endMinute <= day.epochDay * 1440 + s {
            e.endDay = nil
            e.endMinute = nil
        }
        return e
    }
}

public enum SpokenPrompt {
    static let weekdayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    public static func instructions(today: Day, nowMinute: Int) -> String {
        let days = (0..<8).map { offset -> String in
            let d = today.adding(days: offset)
            let label = offset == 0 ? "today" : offset == 1 ? "tomorrow" : weekdayNames[d.weekday - 1]
            return "\(label) = \(d)"
        }
        return """
        You turn one spoken sentence into a calendar entry. Today is \(weekdayNames[today.weekday - 1]) \(today), the time is \(clock(nowMinute)).
        Days: \(days.joined(separator: ", ")).
        The sentence may be German, English, Spanish or French. Keep the title in that language.
        Fields: title = only the essence of the entry, short, without any date, weekday, time or duration words and without requests like \
        "remind me", "erinnere mich daran", "stelle mir einen Reminder", "erstelle einen Termin"; \
        date = YYYY-MM-DD or empty; start = HH:MM in 24-hour time or empty; end = HH:MM or empty.
        Never invent a date or time that was not said. A number without a time word is not a time. \
        German "halb 9" is 08:30, "viertel vor 3" is 14:45 or 02:45, "abends" means after 17:00, "morgens" before 12:00.
        Write the title like a short to-do in the imperative, no subordinate clause, no "dass ich", no "muss".
        Examples: "stelle mir einen Reminder, dass ich morgen um 15 Uhr die Übersichtsseite überarbeiten muss" -> title "Übersichtsseite überarbeiten", date tomorrow, start 15:00. \
        "Erinnere mich übermorgen daran, die Miete zu überweisen" -> title "Miete überweisen". \
        "remind me to call mom on Friday at 5 pm" -> title "Call mom", start 17:00.
        A rule-based guess follows the sentence. Keep the guess unless the sentence clearly says otherwise.
        """
    }

    public static func prompt(_ text: String, guess: SpokenEvent) -> String {
        let day = guess.day.map { "\($0)" } ?? ""
        let start = guess.startMinute.map(clock) ?? ""
        let end = guess.endMinute.map(clock) ?? ""
        return "Sentence: \"\(text.trimmingCharacters(in: .whitespacesAndNewlines))\"\nGuess: title=\"\(guess.title)\", date=\"\(day)\", start=\"\(start)\", end=\"\(end)\""
    }

    static func clock(_ minute: Int) -> String { String(format: "%02d:%02d", minute / 60, minute % 60) }
}
