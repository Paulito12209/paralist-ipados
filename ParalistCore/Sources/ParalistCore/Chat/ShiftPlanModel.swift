// Zusammenhang: Chat/ShiftPlan.swift, Chat/ShiftPlanRows.swift (ShiftCells), Chat/Skills.swift, Paralist/Chat/ChatEngineVision.swift (Bild ans Modell ab iOS 27), docs/chat.md
import Foundation

public struct ModelShift: Equatable, Sendable {
    public var day: String
    public var start: String
    public var end: String
    public var hours: Double?

    public init(day: String, start: String, end: String, hours: Double? = nil) {
        self.day = day
        self.start = start
        self.end = end
        self.hours = hours
    }
}

public struct ModelPlan: Equatable, Sendable {
    public var isSchedule: Bool
    public var names: [String]
    public var shifts: [ModelShift]
    public var absences: [String]

    public init(isSchedule: Bool, names: [String], shifts: [ModelShift], absences: [String] = []) {
        self.isSchedule = isSchedule
        self.names = names
        self.shifts = shifts
        self.absences = absences
    }
}

public enum ShiftPlanModel {
    public static let maxShifts = 40
    static let date = Pattern("(\\d{4})-(\\d{1,2})-(\\d{1,2})|(\\d{1,2})\\.(\\d{1,2})\\.(\\d{4})")
    static let clock = Pattern("(\\d{1,2})[:.](\\d{2})")

    public static func instructions(name: String) -> String {
        var out = "You read a photo of a work schedule (shift plan) for the user. " +
            "Return only what is visible: the people named in the plan, and the user's own shifts with the exact date (YYYY-MM-DD), start and end time (HH:MM). " +
            "Resolve dates from the header or period shown in the photo. A night shift ends on the next day; still give its end time as shown. " +
            "Days marked as absent (ABW, Urlaub, krank) go into absences. Free days are not shifts. Never invent shifts, names or dates."
        if !name.isEmpty {
            out += " The user's row is the one for \"\(name)\" (spelling may differ slightly, a leading letter may be missing)."
        } else {
            out += " You do not know which row is the user's: return the names only and leave shifts empty."
        }
        return out
    }

    public static func prompt(table: String) -> String {
        var out = "Read the attached photo. Is it a work schedule? If so, extract it as described."
        if !table.isEmpty { out += " Text already read from the photo on the device (cells separated by \"|\"):\n" + table }
        return out
    }

    public static func plan(from model: ModelPlan, today: Day, rowKnown: Bool) -> ShiftPlan? {
        guard model.isSchedule else { return nil }
        var seen = Set<String>()
        let names = model.names.map { ChatTools.oneLine($0) }.filter { !$0.isEmpty && seen.insert(ShiftNames.fold($0)).inserted }
        var shifts: [ShiftDay] = []
        var days = Set<Day>()
        for shift in model.shifts.prefix(maxShifts) {
            guard let day = day(shift.day, today: today), let start = minute(shift.start), let end = minute(shift.end), days.insert(day).inserted else { continue }
            shifts.append(ShiftDay(day: day, start: start, end: end, hours: shift.hours.flatMap { $0 > 0 && $0 < 24 ? $0 : nil }))
        }
        let absences = model.absences.compactMap { day($0, today: today) }.filter { !days.contains($0) }
        let all = (shifts.map(\.day) + absences).sorted()
        if let first = all.first, let last = all.last, last.epochDay - first.epochDay >= ShiftPlanReader.maxDays { return nil }
        guard !names.isEmpty || !shifts.isEmpty else { return nil }
        let found = rowKnown && (!shifts.isEmpty || !absences.isEmpty)
        return ShiftPlan(days: all, names: Array(names.prefix(ShiftPlanReader.maxNames)), shifts: found ? shifts.sorted { $0.day < $1.day } : [],
                         absences: found ? absences.sorted() : [], rowFound: found)
    }

    static func day(_ text: String, today: Day) -> Day? {
        guard let m = date.first(in: text) else { return nil }
        let parsed = m.group(1).isEmpty ? Day.make(Int(m.group(6)), Int(m.group(5)), Int(m.group(4))) : Day.make(Int(m.group(1)), Int(m.group(2)), Int(m.group(3)))
        guard let parsed, abs(parsed.epochDay - today.epochDay) <= 366 else { return nil }
        return parsed
    }

    static func minute(_ text: String) -> Int? {
        guard let m = clock.first(in: text), let h = Int(m.group(1)), let min = Int(m.group(2)), h < 24, min < 60 else { return nil }
        return h * 60 + min
    }
}
