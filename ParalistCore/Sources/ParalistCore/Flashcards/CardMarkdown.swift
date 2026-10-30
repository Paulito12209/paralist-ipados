// Zusammenhang: Model/Entry.swift (Karteikarten), Paralist/Flashcards/ImportCardsSheet.swift
import Foundation

public struct ParsedCard: Hashable, Sendable {
    public var front: String
    public var back: String
    public var tags: [String] = []
    public var options: [String] = []
    public var correctOption: Int?

    public init(front: String, back: String, tags: [String] = [], options: [String] = [], correctOption: Int? = nil) {
        self.front = front
        self.back = back
        self.tags = tags
        self.options = options
        self.correctOption = correctOption
    }

    public var isMultipleChoice: Bool { options.count >= 2 && correctOption != nil }
}

public struct CardParseError: Hashable, Sendable {
    public let card: Int
    public let message: String
}

public struct CardParseResult: Sendable {
    public let cards: [ParsedCard]
    public let errors: [CardParseError]
}

public enum CardMarkdown {
    private static let maxCards = 2_000
    private static let control = Pattern("^(==<?|--|---)$")
    private static let answer = Pattern("^true\\s*:\\s*(\\d+)\\s*$", ignoreCase: true)
    private static let option = Pattern("^(\\d+)\\s*:\\s*(.+)$")
    private static let tag = Pattern("^#[\\p{L}\\p{N}_-]+$")
    private static let fence = Pattern("^```(?:markdown|md|text)?\\s*\\n([\\s\\S]*?)\\n```$", ignoreCase: true)
    private static let separator = Pattern("^\\s*---\\s*$", multiline: true)

    private struct Invalid: Error { let message: String }

    public static func parse(_ input: String) -> CardParseResult {
        let text = clean(input)
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return CardParseResult(cards: [], errors: []) }
        var cards: [ParsedCard] = []
        var errors: [CardParseError] = []
        for (index, block) in separator.split(text).enumerated() {
            if block.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || cards.count >= maxCards { continue }
            do {
                cards.append(try parseBlock(block))
            } catch let error as Invalid {
                errors.append(CardParseError(card: index + 1, message: error.message))
            } catch {}
        }
        return CardParseResult(cards: cards, errors: errors)
    }

    public static func serialize(_ cards: [ParsedCard]) -> String {
        cards.map { card in
            let tags = card.tags.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                .map { "#" + ($0.hasPrefix("#") ? String($0.dropFirst()) : $0) }.joined(separator: " ")
            var lines: [String]
            if card.isMultipleChoice {
                lines = [card.front, "==<"] + card.options.enumerated().map { "\($0.offset + 1): \($0.element)" } + ["--", "true: \(card.correctOption ?? 1)"]
            } else {
                lines = [card.front, "==", card.back]
            }
            if !tags.isEmpty { lines.append(tags) }
            return lines.joined(separator: "\n")
        }.joined(separator: "\n---\n")
    }

    private static func clean(_ value: String) -> String {
        var text = value
        if text.hasPrefix("\u{FEFF}") { text.removeFirst() }
        text = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if let m = fence.first(in: text) { text = m.group(1).trimmingCharacters(in: .whitespacesAndNewlines) }
        return text.components(separatedBy: "\n").map { line -> String in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("\\") else { return line }
            let unescaped = String(trimmed.dropFirst())
            guard control.matches(unescaped) || unescaped.hasPrefix("#"), let r = line.range(of: "\\") else { return line }
            return line.replacingCharacters(in: r, with: "")
        }.joined(separator: "\n")
    }

    private static func isBlank(_ s: String) -> Bool { s.trimmingCharacters(in: .whitespaces).isEmpty }

    private static func parseBlock(_ raw: String) throws -> ParsedCard {
        var lines = raw.components(separatedBy: "\n")
        while let f = lines.first, isBlank(f) { lines.removeFirst() }
        while let l = lines.last, isBlank(l) { lines.removeLast() }
        guard let sep = lines.firstIndex(where: { let t = $0.trimmingCharacters(in: .whitespaces); return t == "==" || t == "==<" }) else {
            throw Invalid(message: "Trennzeile == oder ==< fehlt.")
        }
        let front = lines[0..<sep].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if front.isEmpty { throw Invalid(message: "Frage oder Vorderseite fehlt.") }
        let multiple = lines[sep].trimmingCharacters(in: .whitespaces) == "==<"
        let (body, tags) = extractTags(Array(lines[(sep + 1)...]))
        if !multiple {
            let back = body.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if back.isEmpty { throw Invalid(message: "Antwort oder Rückseite fehlt.") }
            return ParsedCard(front: front, back: back, tags: tags)
        }
        guard let answerSep = body.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "--" }) else {
            throw Invalid(message: "Trennzeile -- vor der richtigen Antwort fehlt.")
        }
        var options: [(Int, String)] = []
        for line in body[0..<answerSep] where !isBlank(line) {
            let t = line.trimmingCharacters(in: .whitespaces)
            guard let m = option.first(in: t), option.matches(t), let n = Int(m.group(1)) else {
                throw Invalid(message: "Ungültige Antwortoption: \(t)")
            }
            options.append((n, m.group(2).trimmingCharacters(in: .whitespaces)))
        }
        if options.count < 2 { throw Invalid(message: "Mindestens zwei Antwortoptionen sind erforderlich.") }
        if Set(options.map(\.0)).count != options.count { throw Invalid(message: "Antwortnummern dürfen nicht doppelt vorkommen.") }
        let answerLines = body[(answerSep + 1)...].filter { !isBlank($0) }
        if answerLines.count != 1 { throw Invalid(message: "Genau eine Zeile true: N ist erforderlich.") }
        let a = answerLines.first!.trimmingCharacters(in: .whitespaces)
        guard answer.matches(a), let m = answer.first(in: a), let correctId = Int(m.group(1)) else {
            throw Invalid(message: "Richtige Antwort muss als true: N angegeben werden.")
        }
        guard let correctIndex = options.firstIndex(where: { $0.0 == correctId }) else {
            throw Invalid(message: "Antwortoption \(correctId) existiert nicht.")
        }
        return ParsedCard(front: front, back: options[correctIndex].1, tags: tags, options: options.map(\.1), correctOption: correctIndex + 1)
    }

    private static func extractTags(_ lines: [String]) -> ([String], [String]) {
        var content = lines
        var tags: [String] = []
        while let last = content.last {
            let tokens = last.trimmingCharacters(in: .whitespaces).split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
            if tokens.isEmpty || !tokens.allSatisfy({ tag.matches($0) }) { break }
            tags.insert(contentsOf: tokens.map { String($0.dropFirst()) }, at: 0)
            content.removeLast()
        }
        while let last = content.last, isBlank(last) { content.removeLast() }
        var seen = Set<String>()
        return (content, tags.filter { seen.insert($0).inserted })
    }
}
