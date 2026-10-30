// Zusammenhang: Chat/ChatTools.swift, Chat/ChatDrafts.swift, Chat/ChatEventDrafts.swift (planSummary), Chat/ChatThread.swift, Paralist/Chat/ChatEngine.swift
import Foundation

public enum ChatPrompt {
    public static let historyChars = 1_600
    public static let messageChars = 400

    public static let imageMark = "[image]"

    public static func instructions(language: String, today: Day, linked: String, history: String, image: String = "") -> String {
        var out = """
        You are the assistant inside Paralist, a private notes and planning app organised with the PARA method \
        (projects, areas, resources, archive) plus tasks, events, bookmarks, documents, flashcards and decks.
        Always answer in \(language). Be brief and concrete: short paragraphs or short lists, no filler.
        Today is \(ChatTools.weekdayName(today)) \(today).
        Use only the user's Paralist data and general knowledge. Use the tools to look up entries, tasks and the week; \
        never invent entries, dates or facts. If you cannot find something, say so.
        Name entries by their exact title. Never show ids to the user.
        When the user asks you to create flashcards, tasks or a note, use createFlashcards, createTasks or createNote. \
        They only prepare a draft that the user confirms; never claim something was saved.
        """
        if !linked.isEmpty {
            out += "\n\nThis conversation is linked to these entries:\n" + linked
        }
        if !history.isEmpty {
            out += "\n\nEarlier in this conversation:\n" + history
        }
        if !image.isEmpty {
            out += "\n\nThe user shared a photo earlier in this conversation. Text read from it on the device:\n" + image
        }
        return out
    }

    public static func withImage(_ question: String, image: String) -> String {
        let clean = question.trimmingCharacters(in: .whitespacesAndNewlines)
        var out = image.isEmpty
            ? "The user attached a photo, but no readable text or table was found in it. Say so briefly; do not guess its content."
            : "The user attached a photo. Text and tables read from it on the device (cells separated by \"|\", a cell may be empty):\n" + image
        out += "\n\n" + (clean.isEmpty ? "No question was asked. Say in one or two sentences what the photo contains and offer to help with it." : "Question: " + clean)
        return out
    }

    public static func withPlan(_ question: String, summary: String) -> String {
        let clean = question.trimmingCharacters(in: .whitespacesAndNewlines)
        return summary + "\n\n" + (clean.isEmpty ? "No question was asked; the user most likely wants these shifts as events." : "Question: " + clean)
    }

    public static func withMentions(_ prompt: String, context: String, skills: String) -> String {
        var out = ""
        if !skills.isEmpty {
            out += "Follow these instructions from the user's skills for this message:\n" + skills + "\n\n"
        }
        if !context.isEmpty {
            out += "The user mentioned these entries (use them as context, name them by title):\n" + context + "\n\n"
        }
        return out + prompt
    }

    public static func history(_ messages: [ChatMessage], limit: Int = historyChars) -> String {
        var kept: [String] = []
        var used = 0
        for message in messages.reversed() {
            let who = message.role == .user ? "User" : "Assistant"
            let mark = message.attachment == nil ? "" : imageMark + " "
            let line = "\(who): " + mark + ChatTools.clip(ChatTools.oneLine(message.text), messageChars)
            if used + line.count > limit { break }
            kept.append(line)
            used += line.count + 1
        }
        let dropped = messages.count - kept.count
        var out = kept.reversed().joined(separator: "\n")
        if dropped > 0 {
            let topics = messages.prefix(dropped).filter { $0.role == .user }.map { ChatTools.clip(ChatTools.oneLine($0.text), 60) }
            let summary = "(\(dropped) older messages omitted" + (topics.isEmpty ? ")" : "; earlier questions: " + topics.suffix(5).joined(separator: " / ") + ")")
            out = out.isEmpty ? summary : summary + "\n" + out
        }
        return out
    }
}

public enum ChatMentions {
    public static let minTitleChars = 3

    public static func find(_ answer: String, candidates: [Entry]) -> [String] {
        let text = answer.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        var found: [(String.Index, String)] = []
        var seen = Set<String>()
        for entry in candidates where seen.insert(entry.id).inserted {
            let title = entry.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard title.count >= minTitleChars else { continue }
            let needle = title.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            if let range = text.range(of: needle) { found.append((range.lowerBound, entry.id)) }
        }
        return Array(found.sorted { $0.0 < $1.0 }.map(\.1).prefix(ChatCodec.maxMentions))
    }
}
