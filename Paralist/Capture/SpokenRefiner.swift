// Zusammenhang: Composer/ComposerDictation.swift, ParalistCore Planning/SpokenRefinement.swift (SpokenPrompt, SpokenRefinement), ParalistCore Planning/SpokenEvent.swift, Chat/ChatEngine.swift (gleiches Modell)
import Foundation
import FoundationModels
import ParalistCore

@Generable
struct SpokenGuess {
    @Guide(description: "The entry title without date and time words, in the language of the sentence")
    var title: String
    @Guide(description: "Date as YYYY-MM-DD, or empty when none was said")
    var date: String
    @Guide(description: "Start time as HH:MM in 24-hour time, or empty")
    var start: String
    @Guide(description: "End time as HH:MM in 24-hour time, or empty")
    var end: String
}

@MainActor
final class SpokenRefiner {
    static let timeout = Duration.seconds(3)

    static var available: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    private var session: LanguageModelSession?

    func prewarm(now: Date, zone: TimeZone) {
        guard Self.available, session == nil else { return }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let c = calendar.dateComponents([.hour, .minute], from: now)
        let instructions = SpokenPrompt.instructions(today: Day.of(now, in: zone), nowMinute: (c.hour ?? 0) * 60 + (c.minute ?? 0))
        let session = LanguageModelSession(model: .default, instructions: instructions)
        session.prewarm()
        self.session = session
    }

    func refine(_ text: String, guess: SpokenEvent) async -> SpokenRefinement? {
        guard let session, !session.isResponding else { return nil }
        let prompt = SpokenPrompt.prompt(text, guess: guess)
        return await withTaskGroup(of: SpokenRefinement?.self) { group in
            group.addTask { @MainActor in
                guard let answer = try? await session.respond(to: prompt, generating: SpokenGuess.self).content else { return nil }
                return SpokenRefinement(title: answer.title, day: answer.date, start: answer.start, end: answer.end)
            }
            group.addTask {
                try? await Task.sleep(for: Self.timeout)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }
}
