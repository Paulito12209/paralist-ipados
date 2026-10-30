// Zusammenhang: Chat/ChatEngineTools.swift (ChatData), Chat/ChatEngine.swift, ParalistCore Chat/ChatDrafts.swift, Chat/ChatDraftCard.swift
import Foundation
import FoundationModels
import ParalistCore

struct CreateFlashcardsTool: Tool {
    let data: ChatData
    let name = "createFlashcards"
    let description = "Prepare new flashcards in one deck, e.g. vocabulary for a language. Creates a draft the user confirms; nothing is saved by this call."

    @Generable
    struct Card {
        @Guide(description: "Front: the question or the word to learn")
        var front: String
        @Guide(description: "Back: the answer or the translation")
        var back: String
    }

    @Generable
    struct Arguments {
        @Guide(description: "Name of the deck, usually the topic, e.g. French")
        var deck: String
        @Guide(description: "The cards, as many as the user asked for", .maximumCount(20))
        var cards: [Card]
    }

    func call(arguments: Arguments) async throws -> String {
        data.draft { id, _ in
            ChatDrafts.flashcards(id: id, deck: arguments.deck, cards: arguments.cards.map { ($0.front, $0.back) })
        }
    }
}

struct CreateTasksTool: Tool {
    let data: ChatData
    let name = "createTasks"
    let description = "Prepare new tasks, e.g. steps of a plan. Creates a draft the user confirms; nothing is saved by this call."

    @Generable
    struct Item {
        @Guide(description: "Short title of the task")
        var title: String
        @Guide(description: "Optional due date as YYYY-MM-DD")
        var due: String?
    }

    @Generable
    struct Arguments {
        @Guide(description: "The tasks", .maximumCount(10))
        var tasks: [Item]
    }

    func call(arguments: Arguments) async throws -> String {
        data.draft { id, snap in
            ChatDrafts.tasks(id: id, tasks: arguments.tasks.map { ($0.title, $0.due) }, today: snap.today)
        }
    }
}

struct CreateNoteTool: Tool {
    let data: ChatData
    let name = "createNote"
    let description = "Prepare a new note with a title and Markdown text, e.g. a summary or a plan. Creates a draft the user confirms; nothing is saved by this call."

    @Generable
    struct Arguments {
        @Guide(description: "Title of the note")
        var title: String
        @Guide(description: "Text of the note in Markdown")
        var text: String
    }

    func call(arguments: Arguments) async throws -> String {
        data.draft { id, _ in ChatDrafts.note(id: id, title: arguments.title, text: arguments.text) }
    }
}
