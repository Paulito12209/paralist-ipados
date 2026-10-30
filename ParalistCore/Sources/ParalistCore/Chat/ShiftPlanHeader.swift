// Zusammenhang: Chat/ShiftPlan.swift, Chat/ShiftPlanRows.swift, Chat/ScannedDocument.swift, Text/Pattern.swift, Model/Day.swift
import Foundation

struct ShiftColumn: Equatable {
    var hours: Int?
    var time: Int
}

struct ShiftLayout: Equatable {
    var days: [Day]
    var columns: [ShiftColumn]
    var firstRow: Int
    var nameColumn: Int
}

enum ShiftPlanHeader {
    static let hoursHead = Pattern("(?i)^(std\\.?|stunden|h|hrs\\.?|hours)$")
    static let timeHead = Pattern("(?i)^(zeit|uhrzeit|time)$")
    static let dayHead = Pattern("(?i)(?<![\\p{L}])(mo|di|mi|do|fr|sa|so|mon|tue|wed|thu|fri|sat|sun)\\.?\\s*(\\d{1,2})\\s*[.,]\\s*(\\d{1,2})(?:\\s*[.,]\\s*(\\d{2,4}))?")
    static let period = Pattern("(\\d{1,2})(?:\\s*[.,]\\s*|\\s+)(\\d{1,2})(?:\\s*[.,]\\s*|\\s+)(\\d{4})\\s*[-–—]\\s*(\\d{1,2})(?:\\s*[.,]\\s*|\\s+)(\\d{1,2})(?:\\s*[.,]\\s*|\\s+)(\\d{4})")
    static let week = Pattern("(?i)(?<![\\p{L}])KW\\s*(\\d{1,2})\\s*[/.\\-\\s]\\s*(\\d{4})")
    private static let weekdays = ["mo": 1, "mon": 1, "di": 2, "tue": 2, "mi": 3, "wed": 3, "do": 4, "thu": 4, "fr": 5, "fri": 5, "sa": 6, "sat": 6, "so": 7, "sun": 7]

    struct DayHead: Equatable {
        var weekday: Int
        var day: Int
        var month: Int
        var year: Int?
    }

    static func normalize(_ text: String) -> String {
        text.replacingOccurrences(of: "、", with: ".").replacingOccurrences(of: "，", with: ",").replacingOccurrences(of: "。", with: ".")
    }

    static func layout(_ table: ScannedTable, text: String, today: Day) -> ShiftLayout? {
        let rows = table.rows.map { $0.map { ChatTools.oneLine(normalize($0)) } }
        guard let (header, columns) = columns(rows) else { return nil }
        let heads = rows.prefix(header + 1).flatMap { $0.flatMap(dayHeads) }
        let all = text + "\n" + rows.flatMap { $0 }.joined(separator: "\n")
        let span = periodDays(all)
        let resolved = heads.map { resolve($0, span: span, today: today) }
        let used = Set(columns.flatMap { [$0.hours, $0.time].compactMap { $0 } })
        let nameColumn = (0...(used.max() ?? 0)).first { !used.contains($0) } ?? 0
        guard let days = pick(resolved, span: span, count: columns.count) else { return nil }
        return ShiftLayout(days: days, columns: columns, firstRow: header + 1, nameColumn: nameColumn)
    }

    static func columns(_ rows: [[String]]) -> (Int, [ShiftColumn])? {
        for (index, row) in rows.enumerated() {
            var columns: [ShiftColumn] = []
            var hours: Int?
            for (column, cell) in row.enumerated() {
                if hoursHead.matches(cell) {
                    hours = column
                } else if timeHead.matches(cell) {
                    columns.append(ShiftColumn(hours: hours, time: column))
                    hours = nil
                }
            }
            if !columns.isEmpty { return (index, columns) }
        }
        for (index, row) in rows.enumerated() {
            let columns = row.enumerated().filter { !dayHeads($0.element).isEmpty }.map { ShiftColumn(hours: nil, time: $0.offset) }
            if columns.count >= 2 { return (index, columns) }
        }
        return nil
    }

    static func dayHeads(_ cell: String) -> [DayHead] {
        dayHead.all(in: cell).compactMap { match in
            guard let weekday = weekdays[match.group(1).lowercased()], let day = Int(match.group(2)), let month = Int(match.group(3)) else { return nil }
            var year = Int(match.group(4))
            if let y = year, y < 100 { year = 2000 + y }
            guard (1...12).contains(month), day >= 1, day <= 31 else { return nil }
            return DayHead(weekday: weekday, day: day, month: month, year: year)
        }
    }

    static func periodDays(_ raw: String) -> [Day] {
        let text = normalize(raw)
        if let m = period.first(in: text),
           let start = Day.make(Int(m.group(3)), Int(m.group(2)), Int(m.group(1))),
           let end = Day.make(Int(m.group(6)), Int(m.group(5)), Int(m.group(4))),
           end >= start, end.epochDay - start.epochDay < ShiftPlanReader.maxDays {
            return (start.epochDay...end.epochDay).map(Day.init(epochDay:))
        }
        if let m = week.first(in: text), let number = Int(m.group(1)), let year = Int(m.group(2)), (1...53).contains(number) {
            let fourth = Day(year: year, month: 1, day: 4)
            let monday = fourth.adding(days: 1 - fourth.weekday + (number - 1) * 7)
            return (0..<7).map(monday.adding(days:))
        }
        return []
    }

    static func resolve(_ head: DayHead, span: [Day], today: Day) -> Day? {
        if let year = head.year { return Day.make(year, head.month, head.day) }
        if let hit = span.first(where: { $0.month == head.month && $0.day == head.day }) { return hit }
        let candidates = (today.year - 1...today.year + 1).compactMap { Day.make($0, head.month, head.day) }
        let fitting = candidates.filter { $0.weekday == head.weekday }
        return (fitting.isEmpty ? candidates : fitting).min { abs($0.epochDay - today.epochDay) < abs($1.epochDay - today.epochDay) }
    }

    static func pick(_ heads: [Day?], span: [Day], count: Int) -> [Day]? {
        let days = heads.compactMap { $0 }
        if days.count == heads.count, days.count == count { return days }
        if span.count == count { return span }
        if days.count == heads.count, days.count > count { return Array(days.prefix(count)) }
        if span.count > count { return Array(span.prefix(count)) }
        return nil
    }
}

extension Day {
    static func make(_ year: Int?, _ month: Int?, _ day: Int?) -> Day? {
        guard let year, let month, let day, (1...12).contains(month), day >= 1, day <= Day.length(of: month, in: year) else { return nil }
        return Day(year: year, month: month, day: day)
    }
}
