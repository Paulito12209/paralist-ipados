// Zusammenhang: Paralist/Entry/MarkdownText.swift, Text/Pattern.swift
import Foundation

public enum Inline: Hashable, Sendable {
    case text(String, bold: Bool = false, italic: Bool = false, code: Bool = false)
    case link(String, url: String)
}

public enum Block: Hashable, Sendable {
    case heading(Int, [Inline])
    case paragraph([Inline])
    case listItem(ordered: Bool, checked: Bool?, [Inline])
    case quote([Inline])
    case code(String)
    case rule
    case blank
}

public enum MarkdownBlocks {
    private static let maxBlocks = 2_000
    private static let heading = Pattern("^(#{1,3})\\s+(.*)$")
    private static let bullet = Pattern("^\\s*[-*+]\\s+(\\[([ xX])]\\s+)?(.*)$")
    private static let numbered = Pattern("^\\s*\\d{1,3}[.)]\\s+(.*)$")
    private static let link = Pattern("\\[([^\\]]{1,200})]\\(([^)\\s]{1,2048})\\)")
    private static let rulePattern = Pattern("^(-{3,}|\\*{3,}|_{3,})$")
    private static let styles = Pattern("(`[^`]+`)|(\\*\\*[^*]+\\*\\*)|(\\*[^*]+\\*)|(_[^_]+_)")
    private static let allowedSchemes: Set<String> = ["http", "https", "mailto"]

    public static func parse(_ markdown: String) -> [Block] {
        var blocks: [Block] = []
        let lines = markdown.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
        var paragraph = ""
        func flush() {
            if !paragraph.isEmpty {
                blocks.append(.paragraph(inlines(paragraph)))
                paragraph = ""
            }
        }
        var i = 0
        while i < lines.count && blocks.count < maxBlocks {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                flush()
                var code: [String] = []
                i += 1
                while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    code.append(lines[i])
                    i += 1
                }
                blocks.append(.code(code.joined(separator: "\n")))
            } else if trimmed.isEmpty {
                flush()
                if !blocks.isEmpty { blocks.append(.blank) }
            } else if rulePattern.matches(trimmed) {
                flush()
                blocks.append(.rule)
            } else if heading.matches(line), let m = heading.first(in: line) {
                flush()
                blocks.append(.heading(m.group(1).count, inlines(m.group(2))))
            } else if line.hasPrefix(">") {
                flush()
                blocks.append(.quote(inlines(String(line.dropFirst()).trimmingCharacters(in: .whitespaces))))
            } else if bullet.matches(line), let m = bullet.first(in: line) {
                flush()
                let mark = m.group(2)
                blocks.append(.listItem(ordered: false, checked: mark.isEmpty ? nil : mark != " ", inlines(m.group(3))))
            } else if numbered.matches(line), let m = numbered.first(in: line) {
                flush()
                blocks.append(.listItem(ordered: true, checked: nil, inlines(m.group(1))))
            } else {
                if !paragraph.isEmpty { paragraph += "\n" }
                paragraph += trimmed
            }
            i += 1
        }
        flush()
        while blocks.last == .blank { blocks.removeLast() }
        return blocks
    }

    public static func inlines(_ text: String) -> [Inline] {
        var out: [Inline] = []
        var rest = Substring(text)
        while !rest.isEmpty {
            let current = String(rest)
            guard let m = link.first(in: current) else {
                out += styled(current)
                break
            }
            if m.range.lowerBound > current.startIndex { out += styled(String(current[..<m.range.lowerBound])) }
            let url = m.group(2)
            out.append(isAllowedLink(url) ? .link(m.group(1), url: url) : .text(m.group(1)))
            rest = Substring(current[m.range.upperBound...])
        }
        return out
    }

    public static func isAllowedLink(_ url: String) -> Bool {
        guard let colon = url.firstIndex(of: ":") else { return false }
        let scheme = url[..<colon].lowercased()
        if scheme.isEmpty { return false }
        if let other = url.firstIndex(where: { "/?#".contains($0) }), colon > other { return false }
        return allowedSchemes.contains(scheme) && !url.unicodeScalars.contains { CharacterSet.whitespacesAndNewlines.contains($0) || CharacterSet.controlCharacters.contains($0) }
    }

    private static func styled(_ text: String) -> [Inline] {
        var out: [Inline] = []
        var last = text.startIndex
        for m in styles.all(in: text) {
            if m.range.lowerBound > last { out.append(.text(String(text[last..<m.range.lowerBound]))) }
            let raw = m.value
            if raw.hasPrefix("`") {
                out.append(.text(raw.trimmingCharacters(in: CharacterSet(charactersIn: "`")), code: true))
            } else if raw.hasPrefix("**") {
                out.append(.text(String(raw.dropFirst(2).dropLast(2)), bold: true))
            } else {
                out.append(.text(String(raw.dropFirst().dropLast()), italic: true))
            }
            last = m.range.upperBound
        }
        if last < text.endIndex { out.append(.text(String(text[last...]))) }
        return out
    }
}
