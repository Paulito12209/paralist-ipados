// Zusammenhang: Chat/ShiftPlan.swift, Chat/ShiftPlanHeader.swift, Chat/ChatTools.swift (oneLine), Text/Pattern.swift
import Foundation

struct ShiftRow: Equatable {
    var name: String
    var number: String
    var cells: [String]
}

enum ShiftRows {
    static let minNameLetters = 2

    static func people(_ table: ScannedTable, from first: Int, nameColumn: Int) -> [ShiftRow] {
        guard first < table.rows.count else { return [] }
        return table.rows[first...].compactMap { row in
            guard nameColumn < row.count else { return nil }
            let (name, number) = split(row[nameColumn])
            guard name.filter(\.isLetter).count >= minNameLetters else { return nil }
            return ShiftRow(name: name, number: number, cells: row.map { ChatTools.oneLine($0) })
        }
    }

    static func split(_ cell: String) -> (name: String, number: String) {
        var words: [String] = []
        var number = ""
        for raw in cell.split(whereSeparator: { $0.isWhitespace || $0.isNewline }) {
            let word = String(raw)
            if number.isEmpty, let digits = ShiftNames.number(word) {
                number = digits
            } else {
                words.append(word)
            }
        }
        let name = words.joined(separator: " ").trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.whitespaces))
        return (name, number)
    }
}

enum ShiftNames {
    static let minNumberDigits = 3

    static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil).lowercased()
    }

    static func tokens(_ name: String) -> [String] {
        fold(name).split(whereSeparator: { !$0.isLetter }).map(String.init).filter { !$0.isEmpty }
    }

    static func number(_ word: String) -> String? {
        let mapped = word.map { c -> Character in "pPoO".contains(c) ? "0" : c }
        let digits = String(mapped.filter(\.isNumber))
        guard digits.count >= minNumberDigits, digits.count == mapped.filter { $0.isNumber || $0.isLetter }.count else { return nil }
        return digits
    }

    static func match(_ query: String, in rows: [ShiftRow]) -> ShiftRow? {
        let (name, number) = ShiftRows.split(query)
        let wanted = tokens(name)
        guard !wanted.isEmpty else { return nil }
        var best: (ShiftRow, Int)?
        for row in rows {
            let have = tokens(row.name)
            guard wanted.allSatisfy({ token in have.contains { same($0, token) } }) else { continue }
            let score = !number.isEmpty && row.number == number ? 1 : 0
            if best == nil || score > best!.1 { best = (row, score) }
        }
        return best?.0
    }

    static func same(_ have: String, _ want: String) -> Bool {
        have == want || (want.count >= 3 && have == String(want.dropFirst())) || (have.count >= 3 && want == String(have.dropFirst()))
    }
}

public enum ShiftCell: Equatable, Sendable {
    case work(start: Int, end: Int)
    case absent
    case free
    case unknown
}

public enum ShiftCells {
    public static let hoursTolerance = 0.1
    public static let shortBreak = 30
    public static let longBreak = 45
    public static let shortBreakFrom = 6 * 60
    public static let longBreakFrom = 9 * 60
    static let time = Pattern("(\\d{1,2})\\s*[:.]\\s*(\\d{2})\\s*[-–—]\\s*(\\d{1,2})\\s*[:.]\\s*(\\d{2})")
    static let number = Pattern("\\d{1,2}(?:[.,]\\d{1,2})?")
    static let absent = Pattern("(?i)abw")
    static let free: Set<String> = ["", "f", "-", "–", "—", "frei", "/", "x"]

    public static func parse(_ cell: String, codes: [String: ShiftCode] = [:]) -> ShiftCell {
        let text = ChatTools.oneLine(cell)
        if let m = time.first(in: text), let h1 = Int(m.group(1)), let m1 = Int(m.group(2)), let h2 = Int(m.group(3)), let m2 = Int(m.group(4)),
           h1 < 24, h2 < 24, m1 < 60, m2 < 60 {
            return .work(start: h1 * 60 + m1, end: h2 * 60 + m2)
        }
        if let code = codes[text] ?? codes[text.trimmingCharacters(in: .punctuationCharacters)] { return .work(start: code.start, end: code.end) }
        if absent.contains(text) { return .absent }
        if free.contains(text.lowercased()) { return .free }
        return .unknown
    }

    public static func hours(_ cell: String) -> Double? {
        guard let m = number.first(in: ChatTools.oneLine(cell)) else { return nil }
        return Double(m.value.replacingOccurrences(of: ",", with: "."))
    }

    public static func breakMinutes(_ minutes: Int) -> Int {
        minutes >= longBreakFrom ? longBreak : minutes >= shortBreakFrom ? shortBreak : 0
    }

    public static func netHours(_ minutes: Int, pause: Int? = nil) -> Double {
        Double(minutes - (pause ?? breakMinutes(minutes))) / 60
    }
}
