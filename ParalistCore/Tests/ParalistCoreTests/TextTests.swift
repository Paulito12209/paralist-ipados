// Zusammenhang: Text/MarkdownBlocks.swift, Text/SearchQuery.swift, Text/Pattern.swift
import Foundation
import Testing
@testable import ParalistCore

struct MarkdownBlocksTests {
    @Test func parsesBlocks() {
        let blocks = MarkdownBlocks.parse("# Titel\n\nAbsatz mit **fett** und `code`.\n- [x] erledigt\n- offen\n1. eins\n> Zitat\n---\n```\nraw <b>\n```")
        #expect(blocks[0] == .heading(1, [.text("Titel")]))
        if case .paragraph = blocks[2] {} else { Issue.record("Absatz erwartet") }
        #expect(blocks[1] == .blank)
        #expect(blocks[3] == .listItem(ordered: false, checked: true, [.text("erledigt")]))
        #expect(blocks[4] == .listItem(ordered: false, checked: nil, [.text("offen")]))
        #expect(blocks[5] == .listItem(ordered: true, checked: nil, [.text("eins")]))
        #expect(blocks[6] == .quote([.text("Zitat")]))
        #expect(blocks[7] == .rule)
        #expect(blocks[8] == .code("raw <b>"))
    }

    @Test func keepsLineBreaksAndBlankLines() {
        let blocks = MarkdownBlocks.parse("eins\nzwei\n\n\ndrei\n")
        #expect(blocks == [.paragraph([.text("eins\nzwei")]), .blank, .blank, .paragraph([.text("drei")])])
    }

    @Test func rawHtmlStaysText() {
        let blocks = MarkdownBlocks.parse("<script>alert(1)</script> <img onerror=x>")
        #expect(blocks == [.paragraph([.text("<script>alert(1)</script> <img onerror=x>")])])
    }

    @Test func onlySafeLinksBecomeLinks() {
        let ok = MarkdownBlocks.inlines("[Seite](https://example.org) [Mail](mailto:a@b.de)")
        #expect(ok[0] == .link("Seite", url: "https://example.org"))
        #expect(ok[2] == .link("Mail", url: "mailto:a@b.de"))
        let bad = MarkdownBlocks.inlines("[x](javascript:alert(1)) [y](file:///etc/passwd) [z](intent://scan#Intent;end)")
        #expect(!bad.contains { if case .link = $0 { return true } else { return false } })
        #expect(!MarkdownBlocks.isAllowedLink("JAVASCRIPT:void(0)"))
        #expect(!MarkdownBlocks.isAllowedLink("https://exa mple.org"))
    }
}

struct SearchQueryTests {
    @Test func buildsPrefixTermsAndStripsOperators() {
        #expect(SearchQuery.terms("Kartons kaufen") == ["kartons", "kaufen"])
        #expect(SearchQuery.terms("a OR b NEAR/3 \"x") == ["a", "or", "b", "near", "3", "x"])
        #expect(SearchQuery.terms("  *** ").isEmpty)
        #expect(SearchQuery.terms((1...20).map { "w\($0)" }.joined(separator: " ")).count == 8)
    }
}
