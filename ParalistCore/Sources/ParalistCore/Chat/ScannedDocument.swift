// Zusammenhang: Chat/ChatPrompt.swift, Chat/ChatTools.swift (clip, oneLine), Paralist/Chat/DocumentReader.swift, Paralist/Chat/ChatEngine.swift, docs/chat.md
import Foundation

public struct ScannedTable: Equatable, Sendable {
    public var rows: [[String]]

    public init(rows: [[String]]) { self.rows = rows }
}

public struct ScannedDocument: Equatable, Sendable {
    public var text: String
    public var tables: [ScannedTable]

    public init(text: String, tables: [ScannedTable] = []) {
        self.text = text
        self.tables = tables
    }

    public var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && tables.allSatisfy { $0.rows.isEmpty }
    }
}

public enum ScannedContext {
    public static let maxChars = 1_500
    public static let maxTables = 3
    public static let maxRows = 40
    public static let maxColumns = 16
    public static let cellChars = 40
    public static let separator = " | "

    public static func format(_ document: ScannedDocument, limit: Int = maxChars) -> String {
        var parts: [String] = []
        var cells = Set<String>()
        for (index, table) in document.tables.prefix(maxTables).enumerated() {
            let lines = rows(table, into: &cells)
            guard !lines.isEmpty else { continue }
            var block = ["table \(index + 1) (\(table.rows.count) rows):"]
            block += lines.prefix(maxRows).map { "  " + $0 }
            if lines.count > maxRows { block.append("  (\(lines.count - maxRows) more rows)") }
            parts.append(block.joined(separator: "\n"))
        }
        let loose = document.text.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !cells.contains(key($0)) }
        if !loose.isEmpty {
            parts.append((parts.isEmpty ? "text:\n" : "other text:\n") + loose.joined(separator: "\n"))
        }
        return ChatTools.clip(parts.joined(separator: "\n\n"), limit)
    }

    static func rows(_ table: ScannedTable, into cells: inout Set<String>) -> [String] {
        table.rows.compactMap { row in
            let values = row.prefix(maxColumns).map { cell -> String in
                let text = ChatTools.oneLine(cell)
                for line in cell.split(whereSeparator: \.isNewline) {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty { cells.insert(key(trimmed)) }
                }
                if !text.isEmpty { cells.insert(key(text)) }
                return ChatTools.clip(text, cellChars)
            }
            guard values.contains(where: { !$0.isEmpty }) else { return nil }
            return values.joined(separator: separator)
        }
    }

    private static func key(_ text: String) -> String {
        text.lowercased().filter { !$0.isWhitespace }
    }
}
