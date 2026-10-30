// Zusammenhang: Chat/ShiftPlanHeader.swift, Chat/ShiftPlanRows.swift, Chat/ChatEventDrafts.swift, Chat/ScannedDocument.swift, Paralist/Chat/ChatEngine.swift, docs/chat.md, docs/etappen-schichtplan.md
import Foundation

public struct ShiftDay: Equatable, Sendable {
    public var day: Day
    public var start: Int
    public var end: Int
    public var hours: Double?

    public init(day: Day, start: Int, end: Int, hours: Double? = nil) {
        self.day = day
        self.start = start
        self.end = end
        self.hours = hours
    }

    public var minutes: Int { end > start ? end - start : end + 24 * 60 - start }

    public var crossesMidnight: Bool { end <= start }

    public var hoursMatch: Bool? { hoursMatch(pause: nil) }

    public func hoursMatch(pause: Int?) -> Bool? {
        guard let hours else { return nil }
        return abs(ShiftCells.netHours(minutes, pause: pause) - hours) <= ShiftCells.hoursTolerance
    }
}

public struct ShiftPlan: Equatable, Sendable {
    public var days: [Day]
    public var names: [String]
    public var shifts: [ShiftDay]
    public var absences: [Day]
    public var rowFound: Bool

    public init(days: [Day], names: [String], shifts: [ShiftDay] = [], absences: [Day] = [], rowFound: Bool = false) {
        self.days = days
        self.names = names
        self.shifts = shifts
        self.absences = absences
        self.rowFound = rowFound
    }
}

public enum ShiftPlanReader {
    public static let maxDays = 31
    public static let maxNames = 30

    public static func read(_ document: ScannedDocument, name: String, today: Day, codes: [String: ShiftCode] = [:]) -> ShiftPlan? {
        for table in document.tables {
            if let plan = read(table, text: document.text, name: name, today: today, codes: codes) { return plan }
        }
        return nil
    }

    static func read(_ table: ScannedTable, text: String, name: String, today: Day, codes: [String: ShiftCode] = [:]) -> ShiftPlan? {
        guard let layout = ShiftPlanHeader.layout(table, text: text, today: today) else { return nil }
        guard layout.days.count >= 1, layout.days.count <= maxDays else { return nil }
        let rows = ShiftRows.people(table, from: layout.firstRow, nameColumn: layout.nameColumn)
        guard !rows.isEmpty else { return nil }
        let names = Array(rows.map(\.name).prefix(maxNames))
        guard let own = ShiftNames.match(name, in: rows) else {
            return ShiftPlan(days: layout.days, names: names)
        }
        var shifts: [ShiftDay] = []
        var absences: [Day] = []
        for (index, column) in layout.columns.enumerated() where index < layout.days.count {
            let time = column.time < own.cells.count ? own.cells[column.time] : ""
            switch ShiftCells.parse(time, codes: codes) {
            case .work(let start, let end):
                let hours = column.hours.flatMap { $0 < own.cells.count ? ShiftCells.hours(own.cells[$0]) : nil }
                shifts.append(ShiftDay(day: layout.days[index], start: start, end: end, hours: hours))
            case .absent:
                absences.append(layout.days[index])
            case .free, .unknown:
                break
            }
        }
        return ShiftPlan(days: layout.days, names: names, shifts: shifts, absences: absences, rowFound: true)
    }
}
