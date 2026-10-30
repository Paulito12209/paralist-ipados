// Zusammenhang: Markdown/FrontMatter.swift, Markdown/EntryCodec.swift, Links/*.swift, Text/MarkdownBlocks.swift, Flashcards/CardMarkdown.swift
import Foundation

public struct PatternMatch: Sendable {
    public let range: Range<String.Index>
    public let groups: [String?]

    public var value: String { groups[0] ?? "" }

    public func group(_ index: Int) -> String { index < groups.count ? (groups[index] ?? "") : "" }
}

public struct Pattern: @unchecked Sendable {
    private let regex: NSRegularExpression

    public init(_ pattern: String, ignoreCase: Bool = false, dotAll: Bool = false, multiline: Bool = false) {
        var options: NSRegularExpression.Options = []
        if ignoreCase { options.insert(.caseInsensitive) }
        if dotAll { options.insert(.dotMatchesLineSeparators) }
        if multiline { options.insert(.anchorsMatchLines) }
        regex = try! NSRegularExpression(pattern: pattern, options: options)
    }

    public func matches(_ text: String) -> Bool {
        let range = NSRange(text.startIndex..., in: text)
        guard let m = regex.firstMatch(in: text, options: [.anchored], range: range) else { return false }
        return m.range.location == 0 && m.range.length == range.length
    }

    public func contains(_ text: String) -> Bool { first(in: text) != nil }

    public func first(in text: String) -> PatternMatch? {
        let range = NSRange(text.startIndex..., in: text)
        return regex.firstMatch(in: text, options: [], range: range).flatMap { convert($0, text) }
    }

    public func all(in text: String) -> [PatternMatch] {
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, options: [], range: range).compactMap { convert($0, text) }
    }

    public func replace(_ text: String, with template: String) -> String {
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: template)
    }

    public func replace(_ text: String, using transform: (PatternMatch) -> String) -> String {
        var out = ""
        var last = text.startIndex
        for m in all(in: text) {
            out += text[last..<m.range.lowerBound]
            out += transform(m)
            last = m.range.upperBound
        }
        out += text[last...]
        return out
    }

    public func split(_ text: String) -> [String] {
        var parts: [String] = []
        var last = text.startIndex
        for m in all(in: text) {
            parts.append(String(text[last..<m.range.lowerBound]))
            last = m.range.upperBound
        }
        parts.append(String(text[last...]))
        return parts
    }

    private func convert(_ m: NSTextCheckingResult, _ text: String) -> PatternMatch? {
        guard let whole = Range(m.range, in: text) else { return nil }
        var groups: [String?] = []
        for i in 0..<m.numberOfRanges {
            if let r = Range(m.range(at: i), in: text) { groups.append(String(text[r])) } else { groups.append(nil) }
        }
        return PatternMatch(range: whole, groups: groups)
    }
}
