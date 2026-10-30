// Zusammenhang: Model/Entry.swift, Library/EntryLibrary.swift (inDeck), Paralist/Pages/FlashcardsPage.swift, Tests/ParalistCoreTests/DeckCardsTests.swift
import Foundation

public enum DeckCards {
    public static func loose(_ all: [Entry]) -> [Entry] {
        let decks = Set(all.filter { $0.type == .deck && !$0.archived }.map(\.id))
        return all.filter { card in
            card.type == .flashcard && !card.archived && !(card.deck.map(decks.contains) ?? false)
        }.sorted { $0.created != $1.created ? $0.created < $1.created : $0.id < $1.id }
    }
}
