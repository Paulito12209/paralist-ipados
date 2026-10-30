// Zusammenhang: Chat/Skills.swift, Chat/ChatList.swift (pickable), Text/SearchQuery.swift, Chat/ChatThread.swift (mentions), Paralist/Chat/ChatInputBar.swift, Paralist/Chat/ChatMentionParts.swift
import Foundation

public enum ChatMentionQuery {
    public static let maxMentions = 10
    public static let maxSuggestions = 8
    public static let marker: Character = "@"

    public static func token(in text: String) -> String? {
        guard let last = text.split(omittingEmptySubsequences: false, whereSeparator: { $0.isWhitespace || $0.isNewline }).last,
              last.first == marker else { return nil }
        return String(last.dropFirst())
    }

    public static func removingToken(from text: String) -> String {
        guard token(in: text) != nil, let at = text.lastIndex(of: marker) else { return text }
        return String(text[..<at]).trimmingCharacters(in: .whitespaces)
    }

    public static func suggestions(_ query: String, entries: [Entry], exclude: [String]) -> [Entry] {
        let skills = Skills.all(in: entries)
        let terms = SearchQuery.terms(query)
        let taken = Set(exclude)
        let hitSkills = skills.filter { !taken.contains($0.id) && (terms.isEmpty || SearchQuery.matches($0, terms: terms)) }
        let skillIds = Set(skills.map(\.id))
        let others = ChatList.pickable(entries, kind: nil, query: query, linked: []).filter { !taken.contains($0.id) && !skillIds.contains($0.id) }
        return Array((hitSkills + others).prefix(maxSuggestions))
    }
}
