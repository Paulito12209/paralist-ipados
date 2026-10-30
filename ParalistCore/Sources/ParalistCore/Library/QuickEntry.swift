// Zusammenhang: Markdown/Limits.swift, Library/ComposerDraft.swift, Paralist/Intents/NewNoteIntent.swift, Tests/ParalistCoreTests/QuickEntryTests.swift
import Foundation

public struct QuickEntry: Hashable, Sendable {
    public static let maxChars = 8192
    public static let types: [EntryType] = [.note, .task, .project, .area, .document]

    public let title: String
    public let body: String

    public static func parse(_ text: String?) -> QuickEntry? {
        let clean = String((text ?? "").prefix(maxChars)).replacingOccurrences(of: "\r\n", with: "\n")
        let lines = clean.components(separatedBy: "\n")
        guard let first = lines.firstIndex(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) else { return nil }
        let head = lines[first].trimmingCharacters(in: .whitespaces)
        let rest = lines[(first + 1)...].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if head.count > Limits.maxTitleChars {
            let all = clean.trimmingCharacters(in: .whitespacesAndNewlines)
            return QuickEntry(title: String(head.prefix(Limits.maxTitleChars)), body: all + "\n")
        }
        return QuickEntry(title: head, body: rest.isEmpty ? "" : rest + "\n")
    }
}
