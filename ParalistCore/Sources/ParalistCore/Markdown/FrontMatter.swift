// Zusammenhang: Markdown/EntryCodec.swift, Markdown/Limits.swift, Tests/ParalistCoreTests/MarkdownTests.swift
import Foundation

public struct FrontMatterError: Error, Equatable {
    public let message: String
    public init(_ message: String) { self.message = message }
}

public enum YamlValue: Equatable, Sendable {
    case scalar(String)
    case items([String])
}

public struct FrontMatterDocument: Equatable {
    public let keys: [String]
    public let fields: [String: YamlValue]
    public let body: String
}

public enum FrontMatter {
    private static let fence = "---"
    private static let keyPattern = Pattern("^[a-zA-Z_][a-zA-Z0-9_-]{0,63}$")
    private static let plain = Pattern("^[A-Za-z0-9_][A-Za-z0-9_.:+/@-]*$")

    public static func parse(_ text: String) throws -> FrontMatterDocument {
        var normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        if normalized.hasPrefix("\u{FEFF}") { normalized.removeFirst() }
        guard normalized.hasPrefix(fence + "\n") else { throw FrontMatterError("Kopf fehlt") }
        let lines = normalized.components(separatedBy: "\n")
        let endLine = lines.indices.dropFirst().first { lines[$0] == fence }
        guard let end = endLine else { throw FrontMatterError("Kopf nicht geschlossen") }
        let head = lines[1..<end].joined(separator: "\n")
        if head.count > Limits.maxFrontMatterChars { throw FrontMatterError("Kopf zu groß") }
        let body = end + 1 < lines.count ? lines[(end + 1)...].joined(separator: "\n") : ""
        let (keys, fields) = try parseFields(head)
        return FrontMatterDocument(keys: keys, fields: fields, body: body)
    }

    private static func parseFields(_ head: String) throws -> ([String], [String: YamlValue]) {
        var keys: [String] = []
        var fields: [String: YamlValue] = [:]
        var currentKey: String?
        var currentList: [String] = []
        func closeList() {
            if let key = currentKey { fields[key] = .items(currentList) }
            currentKey = nil
            currentList = []
        }
        for raw in head.components(separatedBy: "\n") {
            if raw.trimmingCharacters(in: .whitespaces).isEmpty { continue }
            if raw.hasPrefix("  - ") || raw == "  -" {
                guard currentKey != nil else { throw FrontMatterError("Listenpunkt ohne Schlüssel") }
                if currentList.count >= Limits.maxListItems { throw FrontMatterError("Liste zu lang") }
                currentList.append(try unquote(String(raw.dropFirst(3)).trimmingCharacters(in: .whitespaces)))
                continue
            }
            if raw.hasPrefix(" ") || raw.hasPrefix("\t") { throw FrontMatterError("Einrückung unerwartet") }
            guard let colon = raw.firstIndex(of: ":"), colon != raw.startIndex else { throw FrontMatterError("Zeile ohne Schlüssel") }
            let key = raw[..<colon].trimmingCharacters(in: .whitespaces)
            guard keyPattern.matches(key) else { throw FrontMatterError("Schlüssel ungültig") }
            if fields[key] != nil || currentKey == key { throw FrontMatterError("Schlüssel doppelt: \(key)") }
            closeList()
            if fields.count >= Limits.maxKeys { throw FrontMatterError("Zu viele Schlüssel") }
            keys.append(key)
            let rest = raw[raw.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            if rest.isEmpty {
                currentKey = key
                currentList = []
                fields[key] = .items([])
            } else if rest == "[]" {
                fields[key] = .items([])
            } else {
                fields[key] = .scalar(try unquote(rest))
            }
        }
        closeList()
        return (keys, fields)
    }

    private static func unquote(_ value: String) throws -> String {
        if value.count >= 2 && value.hasPrefix("\"") && value.hasSuffix("\"") {
            return try unescape(String(value.dropFirst().dropLast()))
        }
        if value.count >= 2 && value.hasPrefix("'") && value.hasSuffix("'") {
            return String(value.dropFirst().dropLast()).replacingOccurrences(of: "''", with: "'")
        }
        return value
    }

    private static func unescape(_ value: String) throws -> String {
        var out = ""
        let iterator = Array(value)
        var i = 0
        while i < iterator.count {
            let c = iterator[i]
            if c == "\\" && i + 1 < iterator.count {
                switch iterator[i + 1] {
                case "n": out.append("\n")
                case "t": out.append("\t")
                case "\"": out.append("\"")
                case "\\": out.append("\\")
                default: throw FrontMatterError("Escape unbekannt: \\\(iterator[i + 1])")
                }
                i += 2
            } else {
                out.append(c)
                i += 1
            }
        }
        return out
    }

    public static func write(_ fields: [(String, YamlValue)], body: String) -> String {
        var out = fence + "\n"
        for (key, value) in fields {
            precondition(keyPattern.matches(key), "Schlüssel ungültig: \(key)")
            switch value {
            case .scalar(let text):
                out += "\(key): \(quote(text))\n"
            case .items(let values):
                if values.isEmpty {
                    out += "\(key): []\n"
                } else {
                    out += "\(key):\n"
                    for v in values { out += "  - \(quote(v))\n" }
                }
            }
        }
        out += fence + "\n"
        out += body
        return out
    }

    private static func quote(_ text: String) -> String {
        if plain.matches(text) { return text }
        let escaped = text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "\t", with: "\\t")
        return "\"\(escaped)\""
    }
}
