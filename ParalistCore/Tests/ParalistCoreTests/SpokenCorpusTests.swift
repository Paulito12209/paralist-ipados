// Zusammenhang: Tests/ParalistCoreTests/Resources/spoken_corpus.tsv, Sources/ParalistCore/Planning/SpokenEvent.swift, Sources/ParalistCore/Planning/SpokenParser.swift, Sources/ParalistCore/Planning/SpokenWords.swift, Package.swift, docs/siri.md
import Foundation
import Testing
@testable import ParalistCore

struct SpokenCorpusRow: Sendable, CustomTestStringConvertible {
    let line: Int
    let sentence: String
    let title: String
    let day: String
    let start: String
    let end: String
    let reminder: Bool
    let allDay: Bool

    var testDescription: String { "\(line): \(sentence)" }
}

struct SpokenCorpusTests {
    static let today = Day(year: 2026, month: 10, day: 22)
    static let nowMinute = 10 * 60
    static let rows = load()

    static func load() -> [SpokenCorpusRow] {
        guard let url = Bundle.module.url(forResource: "spoken_corpus", withExtension: "tsv"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        var rows: [SpokenCorpusRow] = []
        for (n, raw) in text.components(separatedBy: "\n").enumerated() {
            let line = raw.trimmingCharacters(in: CharacterSet(charactersIn: "\r"))
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty, !line.hasPrefix("#") else { continue }
            var cells = line.components(separatedBy: "\t").map { $0.trimmingCharacters(in: .whitespaces) }
            while cells.count < 7 { cells.append("") }
            rows.append(SpokenCorpusRow(line: n + 1, sentence: cells[0], title: cells[1], day: cells[2], start: cells[3], end: cells[4],
                                        reminder: cells[5] == "ja", allDay: cells[6] == "ja"))
        }
        return rows
    }

    static func day(_ text: String) -> Day? {
        if text.isEmpty { return nil }
        if let shift = Int(text.hasPrefix("+") ? String(text.dropFirst()) : text), text.count <= 4 { return today.adding(days: shift) }
        if let target = SpokenWords.weekdayAbbr[text] {
            let ahead = (target - today.weekday + 7) % 7
            return today.adding(days: ahead == 0 ? 7 : ahead)
        }
        let parts = text.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return Day(year: parts[0], month: parts[1], day: parts[2])
    }

    static func clock(_ minute: Int?) -> String {
        guard let minute else { return "" }
        return String(format: "%02d:%02d", minute / 60, minute % 60)
    }

    static func show(_ day: Day?) -> String {
        guard let day else { return "" }
        return String(format: "%04d-%02d-%02d", day.year, day.month, day.day)
    }

    @Test func corpusIsLargeEnough() {
        #expect(Self.rows.count >= 80, "Korpus hat nur \(Self.rows.count) Zeilen")
    }

    @Test(arguments: rows)
    func sentence(_ row: SpokenCorpusRow) {
        let e = SpokenEvent.parse(row.sentence, today: Self.today, nowMinute: Self.nowMinute)
        let expected = "Titel „\(row.title)“, Tag \(Self.show(Self.day(row.day))), Beginn \(row.start), Ende \(row.end), Erinnerung \(row.reminder ? "ja" : "nein"), Ganztag \(row.allDay ? "ja" : "nein")"
        let got = "Titel „\(e.title)“, Tag \(Self.show(e.day)), Beginn \(Self.clock(e.startMinute)), Ende \(Self.clock(e.endMinute)), Erinnerung \(e.reminder ? "ja" : "nein"), Ganztag \(e.allDay ? "ja" : "nein")"
        #expect(Self.day(row.day) != nil || row.day.isEmpty, "Zeile \(row.line): Tag „\(row.day)“ unlesbar")
        #expect(expected == got, "Zeile \(row.line): „\(row.sentence)“\n  erwartet: \(expected)\n  erhalten: \(got)")
    }
}
