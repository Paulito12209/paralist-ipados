// Zusammenhang: Library/QuickEntry.swift, Markdown/Limits.swift
import Foundation
import Testing
@testable import ParalistCore

struct QuickEntryTests {
    @Test func singleLineBecomesTitle() {
        #expect(QuickEntry.parse("  Milch kaufen  ") == QuickEntry(title: "Milch kaufen", body: ""))
    }

    @Test func furtherLinesBecomeBody() {
        #expect(QuickEntry.parse("\n\nEinkauf\r\nMilch\n\nBrot\n\n") == QuickEntry(title: "Einkauf", body: "Milch\n\nBrot\n"))
    }

    @Test func emptyTextIsRejected() {
        #expect(QuickEntry.parse(nil) == nil)
        #expect(QuickEntry.parse(" \n\t\n ") == nil)
    }

    @Test func longFirstLineKeepsFullTextInBody() {
        let long = String(repeating: "a", count: Limits.maxTitleChars + 10)
        let note = QuickEntry.parse(long + "\nRest")
        #expect(note?.title.count == Limits.maxTitleChars)
        #expect(note?.body == long + "\nRest\n")
    }

    @Test func siriCreatesOnlyPlainTypes() {
        #expect(QuickEntry.types == [.note, .task, .project, .area, .document])
        #expect(!QuickEntry.types.contains(.bookmark))
    }

    @Test func capsInputLength() {
        let note = QuickEntry.parse("Titel\n" + String(repeating: "b", count: QuickEntry.maxChars * 2))
        #expect((note?.body.count ?? 0) <= QuickEntry.maxChars)
    }
}
