// Zusammenhang: Sources/ParalistCore/Library/TitleEdit.swift
import Testing
@testable import ParalistCore

struct TitleEditTests {
    @Test func flattensLinesAndTrims() {
        #expect(TitleEdit.clean("  Hallo\nWelt  ") == "Hallo Welt")
    }

    @Test func blankBecomesEmpty() {
        #expect(TitleEdit.clean("   ") == "")
    }

    @Test func addsSpaceForEditing() {
        #expect(TitleEdit.forEditing("Foto 14:19") == "Foto 14:19 ")
        #expect(TitleEdit.forEditing("Foto ") == "Foto ")
        #expect(TitleEdit.forEditing("") == "")
        #expect(TitleEdit.clean(TitleEdit.forEditing("Foto.")) == "Foto.")
    }

    @Test func capsLength() {
        #expect(TitleEdit.clean(String(repeating: "a", count: 900)).count == Limits.maxTitleChars)
    }
}
