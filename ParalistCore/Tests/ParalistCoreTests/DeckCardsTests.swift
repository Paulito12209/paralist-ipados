// Zusammenhang: Sources/ParalistCore/Flashcards/DeckCards.swift, TestSupport.swift
import Foundation
import Testing
@testable import ParalistCore

struct DeckCardsTests {
    @Test func looseCardsHaveNoLiveDeck() {
        let all = [
            Entry("d", .deck, "Französisch", epoch, epoch),
            Entry("x", .deck, "Alt", epoch, epoch) { $0.archived = true },
            Entry("a", .flashcard, "Im Deck", epoch, epoch) { $0.deck = "d" },
            Entry("b", .flashcard, "Ohne Deck", epoch, Date(timeIntervalSince1970: 1)),
            Entry("c", .flashcard, "Deck archiviert", Date(timeIntervalSince1970: 5), epoch) { $0.deck = "x" },
            Entry("e", .flashcard, "Deck fehlt", Date(timeIntervalSince1970: 9), epoch) { $0.deck = "weg" },
            Entry("f", .flashcard, "Archiviert", epoch, epoch) { $0.archived = true },
            Entry("n", .note, "Notiz", epoch, epoch),
        ]
        #expect(DeckCards.loose(all).map(\.id) == ["b", "c", "e"])
    }
}
