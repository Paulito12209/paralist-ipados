// Zusammenhang: Chat/ChatDrafts.swift, Chat/ShiftPlan.swift, Chat/Skills.swift (ShiftSkill), Chat/ChatPrompt.swift (withPlan), Chat/ChatCodec.swift, Paralist/Chat/ChatEngine.swift (planDraft), Paralist/Chat/ChatDraftEventRows.swift, Paralist/App/AppModel.swift (applyChatDraft)
import Foundation

public enum ChatDraftHint: String, Sendable, CaseIterable {
    case exists = "schon_da", past = "vergangen", hours = "stunden"
}

extension ChatDrafts {
    public static let maxEvents = 14
    public static let maxNames = 30
    public static let minutesPerDay = 24 * 60

    public static func events(id: String, plan: ShiftPlan, existing: [Entry], today: Day, zone: TimeZone, skill: ShiftSkill? = nil, fallback: String, absent: String = "") -> ChatDraft {
        let events = existing.filter { $0.type == .event && !$0.archived && !$0.allDay && $0.start != nil }
        var name = line(skill?.title ?? "", maxFrontChars)
        if name.isEmpty { name = usualTitle(plan.shifts, events: events, zone: zone) ?? line(fallback, maxFrontChars) }
        let shifts = plan.shifts.sorted { ($0.day, $0.start) < ($1.day, $1.start) }
        var items = shifts.map { shift -> ChatDraftItem in
            var item = ChatDraftItem(front: name, due: shift.day, start: shift.start, end: shift.end)
            if shift.day < today {
                item.hint = .past
                item.selected = false
            } else if events.contains(where: { overlaps($0, shift, title: name, zone: zone) }) {
                item.hint = .exists
                item.selected = false
            } else if shift.hoursMatch(pause: skill?.pause) == false {
                item.hint = .hours
            }
            return item
        }
        let absentTitle = line(absent, maxFrontChars)
        if skill?.absences == true, !absentTitle.isEmpty {
            let allDay = existing.filter { $0.type == .event && !$0.archived && $0.allDay && $0.start != nil }
            items += plan.absences.map { day -> ChatDraftItem in
                var item = ChatDraftItem(front: absentTitle, due: day)
                if day < today {
                    item.hint = .past
                    item.selected = false
                } else if allDay.contains(where: { Day.of($0.start!, in: zone) == day && ShiftNames.fold($0.title) == ShiftNames.fold(absentTitle) }) {
                    item.hint = .exists
                    item.selected = false
                }
                return item
            }
            items.sort { ($0.due ?? today, $0.start ?? -1) < ($1.due ?? today, $1.start ?? -1) }
        }
        return ChatDraft(id: id, kind: .events, title: name, items: Array(items.prefix(maxEvents)))
    }

    public static func whichRow(id: String, names: [String]) -> ChatDraft {
        var seen = Set<String>()
        let clean = names.map { line($0, maxFrontChars) }.filter { !$0.isEmpty && seen.insert(ShiftNames.fold($0)).inserted }
        return ChatDraft(id: id, kind: .events, choices: Array(clean.prefix(maxNames)))
    }

    static func usualTitle(_ shifts: [ShiftDay], events: [Entry], zone: TimeZone) -> String? {
        let starts = Set(shifts.map(\.start))
        let ends = Set(shifts.map(\.end))
        var counts: [String: (Int, String)] = [:]
        for event in events {
            guard let start = event.start else { continue }
            let title = line(event.title, maxFrontChars)
            guard !title.isEmpty else { continue }
            let begin = minuteOfDay(start, zone: zone)
            let finish = event.end.map { minuteOfDay($0, zone: zone) }
            guard starts.contains(begin) || finish.map(ends.contains) == true else { continue }
            let key = ShiftNames.fold(title)
            let seen = counts[key] ?? (0, title)
            counts[key] = (seen.0 + 1, seen.1)
        }
        return counts.values.max { ($0.0, $1.1) < ($1.0, $0.1) }?.1
    }

    static func overlaps(_ event: Entry, _ shift: ShiftDay, title: String, zone: TimeZone) -> Bool {
        guard let start = event.start, ShiftNames.fold(event.title) == ShiftNames.fold(title) else { return false }
        let end = event.end ?? start.addingTimeInterval(3600)
        let (from, to) = span(shift.day, shift.start, shift.end, zone: zone)
        return start < to && end > from
    }

    static func span(_ day: Day, _ start: Int, _ end: Int, zone: TimeZone) -> (Date, Date) {
        let from = day.at(hour: start / 60, minute: start % 60, in: zone)
        let endDay = end <= start ? day.adding(days: 1) : day
        return (from, endDay.at(hour: end / 60, minute: end % 60, in: zone))
    }

    public static func minuteOfDay(_ date: Date, zone: TimeZone) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    static func eventEntries(_ draft: ChatDraft, zone: TimeZone, reminder: Int?, make: (EntryType, String) -> Entry) -> [Entry] {
        draft.items.compactMap { item in
            guard item.selected, let day = item.due else { return nil }
            var event = make(.event, item.front)
            if let start = item.start, let end = item.end {
                (event.start, event.end) = span(day, start, end, zone: zone)
                if let reminder, reminder > 0, let from = event.start { event.reminders = [from.addingTimeInterval(-Double(reminder) * 60)] }
            } else {
                event.start = day.startOfDay(in: zone)
                event.allDay = true
            }
            return event
        }
    }

    static func cleanedEvents(_ draft: ChatDraft) -> ChatDraft {
        let items = draft.items.compactMap { item -> ChatDraftItem? in
            let front = line(item.front, maxFrontChars)
            guard !front.isEmpty, item.due != nil, (item.start == nil) == (item.end == nil),
                  (0..<minutesPerDay).contains(item.start ?? 0), (0..<minutesPerDay).contains(item.end ?? 0) else { return nil }
            var clean = item
            clean.front = front
            clean.back = ""
            return clean
        }
        return ChatDraft(id: draft.id, kind: .events, title: line(draft.title, maxFrontChars), items: Array(items.prefix(maxEvents)), choices: whichRow(id: draft.id, names: draft.choices).choices)
    }

    public static func planSummary(_ draft: ChatDraft) -> String {
        if !draft.choices.isEmpty {
            return "The photo shows a work schedule with one row per person: " + draft.choices.joined(separator: ", ") + ". " +
                "The user's own row could not be identified. A card below your answer asks the user which row is theirs. " +
                "Reply in one short sentence that you need to know which row is theirs; do not list the names."
        }
        guard let first = draft.items.first?.due, let last = draft.items.last?.due else {
            return "The photo shows a work schedule and the user's row was found, but it contains no shifts. Say so in one short sentence."
        }
        let exists = draft.items.filter { $0.hint == .exists }.count
        let past = draft.items.filter { $0.hint == .past }.count
        var notes: [String] = []
        if exists > 0 { notes.append("\(exists) already exist as events") }
        if past > 0 { notes.append("\(past) are in the past") }
        let aside = notes.isEmpty ? "" : " (" + notes.joined(separator: ", ") + "; those are unchecked)"
        return "The photo shows a work schedule. It was read on the device and a draft of \(draft.items.count) shifts as events titled \"\(draft.title)\" " +
            "from \(first) to \(last) is shown below your answer\(aside). Nothing is saved until the user taps Create. " +
            "Reply in one or two short sentences; do not list the shifts; never claim anything was saved."
    }
}
