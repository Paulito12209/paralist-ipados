// Zusammenhang: Library/EntryLibrary.swift (search), Paralist/Search/SearchOverlay.swift
import Foundation

public enum SearchQuery {
    private static let maxTerms = 8
    private static let maxTermChars = 40
    private static let splitter = Pattern("[^\\p{L}\\p{N}]+")
    private static let spaces = Pattern("\\s+")

    public static func terms(_ input: String) -> [String] {
        Array(splitter.split(input.lowercased()).filter { !$0.isEmpty }.map { String($0.prefix(maxTermChars)) }.prefix(maxTerms))
    }

    public static func matches(_ entry: Entry, terms: [String]) -> Bool {
        if terms.isEmpty { return false }
        let words = Set(splitter.split((entry.title + " " + entry.preview).lowercased()).filter { !$0.isEmpty })
        return terms.allSatisfy { term in words.contains { $0.hasPrefix(term) } }
    }

    public static func filter(_ entries: [Entry], query: String) -> [Entry] {
        let terms = terms(query)
        return terms.isEmpty ? entries : entries.filter { matches($0, terms: terms) }
    }

    public static func normalize(_ input: String) -> String {
        String(spaces.replace(input.trimmingCharacters(in: .whitespacesAndNewlines), with: " ").prefix(100))
    }
}
