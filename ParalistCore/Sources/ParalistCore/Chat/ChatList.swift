// Zusammenhang: Chat/ChatThread.swift, Chat/ChatStore.swift, Text/SearchQuery.swift, Paralist/Chat/ChatListPage.swift
import Foundation

public enum ChatList {
    private static let splitter = Pattern("[^\\p{L}\\p{N}]+")

    public static func newestFirst(_ a: ChatThread, _ b: ChatThread) -> Bool {
        a.updated != b.updated ? a.updated > b.updated : a.id < b.id
    }

    public static func filter(_ threads: [ChatThread], query: String) -> [ChatThread] {
        let sorted = threads.sorted(by: newestFirst)
        let terms = SearchQuery.terms(query)
        if terms.isEmpty { return sorted }
        return sorted.filter { matches($0, terms: terms) }
    }

    public static let pickKinds: [ListKind] = [.projects, .areas, .tasks, .notes, .events, .resources, .flashcards]
    public static let pickLimit = 100

    public static func pickable(_ entries: [Entry], kind: ListKind?, query: String, linked: [String]) -> [Entry] {
        let terms = SearchQuery.terms(query)
        let chosen = Set(linked)
        return Array(entries
            .filter { !$0.archived && (kind?.includes($0) ?? true) && (terms.isEmpty || SearchQuery.matches($0, terms: terms)) }
            .sorted { a, b in
                let (la, lb) = (chosen.contains(a.id), chosen.contains(b.id))
                return la != lb ? la : a.updated > b.updated
            }
            .prefix(pickLimit))
    }

    public static func linked(to entryId: String, in threads: [ChatThread]) -> [ChatThread] {
        threads.filter { $0.links.contains(entryId) }.sorted(by: newestFirst)
    }

    public static func matches(_ thread: ChatThread, terms: [String]) -> Bool {
        let text = ([thread.title] + thread.messages.map(\.text)).joined(separator: " ").lowercased()
        let words = Set(splitter.split(text).filter { !$0.isEmpty })
        return terms.allSatisfy { term in words.contains { $0.hasPrefix(term) } }
    }
}

public enum ChatPreview {
    public static let maxChars = 120
    private static let marks = Pattern("^\\s*(#{1,6}\\s+|>\\s*|[-*+]\\s+(\\[[ xX]\\]\\s+)?|\\d+[.)]\\s+)")
    private static let links = Pattern("\\[([^\\]]*)\\]\\([^)]*\\)")
    private static let emphasis = Pattern("(\\*\\*|__|\\*|`|~~)")
    private static let spaces = Pattern("\\s+")

    public static func plain(_ line: String) -> String {
        var out = marks.replace(line, with: "")
        out = links.replace(out, with: "$1")
        out = emphasis.replace(out, with: "")
        return spaces.replace(out, with: " ").trimmingCharacters(in: .whitespaces)
    }

    public static func of(_ thread: ChatThread) -> String {
        guard let last = thread.last else { return "" }
        let joined = last.text.split(whereSeparator: \.isNewline).map { plain(String($0)) }.filter { !$0.isEmpty }.joined(separator: " ")
        return joined.count > maxChars ? String(joined.prefix(maxChars)) + "…" : joined
    }
}
