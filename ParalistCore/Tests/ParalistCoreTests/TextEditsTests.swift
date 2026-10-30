// Zusammenhang: Sources/ParalistCore/Text/TextEdits.swift
import Testing
@testable import ParalistCore

struct TextEditsTests {
    @Test func deletesTheWordBeforeTheCursor() {
        #expect(TextEdits.deleteWord("Hallo schöne Welt", before: 17) == ("Hallo schöne ", 13))
        #expect(TextEdits.deleteWord("Hallo schöne Welt ", before: 18) == ("Hallo schöne ", 13))
        #expect(TextEdits.deleteWord("Hallo schöne Welt", before: 12) == ("Hallo  Welt", 6))
        #expect(TextEdits.deleteWord("Hallo", before: 0) == ("Hallo", 0))
        #expect(TextEdits.deleteWord("", before: 5) == ("", 0))
    }

    @Test func typingOneWordUndoesAtOnce() {
        var history = EditHistory()
        history.record(from: "", to: "H")
        history.record(from: "H", to: "Ha")
        history.record(from: "Ha", to: "Hal")
        #expect(history.undo() == "")
        #expect(!history.canUndo)
    }

    @Test func eachWordAndDeletionIsOneStep() {
        var history = EditHistory()
        history.record(from: "", to: "a")
        history.record(from: "a", to: "a ")
        history.record(from: "a ", to: "a b")
        history.record(from: "a b", to: "a ")
        #expect(history.undo() == "a b")
        #expect(history.undo() == "a ")
        #expect(history.undo() == "a")
        #expect(history.undo() == "")
        #expect(history.undo() == nil)
    }
}
