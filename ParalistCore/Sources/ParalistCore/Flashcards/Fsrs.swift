// Zusammenhang: Flashcards/ReviewLog.swift, Flashcards/StudyQueue.swift, Paralist/Flashcards/StudyPage.swift
import Foundation

public enum Rating: Int, CaseIterable, Sendable {
    case again = 1, hard = 2, good = 3, easy = 4
}

public enum CardPhase: String, Sendable {
    case new = "NEW", learning = "LEARNING", review = "REVIEW", relearning = "RELEARNING"
}

public struct CardState: Hashable, Sendable {
    public var phase: CardPhase = .new
    public var stability: Double = 0
    public var difficulty: Double = 0
    public var due: Date?
    public var lastReview: Date?
    public var reps = 0
    public var lapses = 0

    public init(phase: CardPhase = .new, stability: Double = 0, difficulty: Double = 0, due: Date? = nil, lastReview: Date? = nil, reps: Int = 0, lapses: Int = 0) {
        self.phase = phase
        self.stability = stability
        self.difficulty = difficulty
        self.due = due
        self.lastReview = lastReview
        self.reps = reps
        self.lapses = lapses
    }

    public func isDue(_ now: Date) -> Bool { due.map { $0 <= now } ?? false }
}

public enum Fsrs {
    public static let defaultWeights: [Double] = [
        0.40255, 1.18385, 3.173, 15.69105, 7.1949, 0.5345, 1.4604, 0.0046, 1.54575, 0.1192,
        1.01925, 1.9395, 0.11, 0.29605, 2.2698, 0.2315, 2.9898, 0.51655, 0.6621,
    ]
    public static let requestRetention = 0.9
    public static let maxIntervalDays = 36_500
    private static let decay = -0.5
    private static let factor = 19.0 / 81.0
    private static let relearnStep: TimeInterval = 600

    public static func review(_ state: CardState, _ rating: Rating, now: Date, w: [Double] = defaultWeights) -> CardState {
        let g = rating.rawValue
        let again = rating == .again
        if state.phase == .new {
            let stability = w[g - 1]
            let difficulty = initialDifficulty(g, w)
            let due = again ? now.addingTimeInterval(relearnStep) : plusDays(now, interval(stability))
            return CardState(phase: again ? .learning : .review, stability: stability, difficulty: difficulty, due: due, lastReview: now, reps: 1, lapses: again ? 1 : 0)
        }
        let elapsedDays = max(0, now.timeIntervalSince(state.lastReview ?? now) / 86_400)
        let sameDay = elapsedDays < 1 && state.phase != .review
        let r = retrievability(elapsedDays, state.stability)
        let difficulty = nextDifficulty(state.difficulty, g, w)
        let stability: Double
        if sameDay {
            stability = state.stability * exp(w[17] * (Double(g) - 3 + w[18]))
        } else if again {
            stability = forgetStability(difficulty, state.stability, r, w)
        } else {
            stability = recallStability(difficulty, state.stability, r, rating, w)
        }
        let lapses = state.lapses + (again ? 1 : 0)
        if again {
            return CardState(phase: .relearning, stability: stability, difficulty: difficulty, due: now.addingTimeInterval(relearnStep), lastReview: now, reps: state.reps + 1, lapses: lapses)
        }
        return CardState(phase: .review, stability: stability, difficulty: difficulty, due: plusDays(now, interval(stability)), lastReview: now, reps: state.reps + 1, lapses: lapses)
    }

    public static func retrievability(_ elapsedDays: Double, _ stability: Double) -> Double {
        stability <= 0 ? 0 : pow(1 + factor * elapsedDays / stability, decay)
    }

    public static func interval(_ stability: Double, retention: Double = requestRetention) -> Int {
        let days = stability / factor * (pow(retention, 1 / decay) - 1)
        return min(max(Int(days.rounded()), 1), maxIntervalDays)
    }

    private static func initialDifficulty(_ g: Int, _ w: [Double]) -> Double { clamp(w[4] - exp(w[5] * Double(g - 1)) + 1) }

    private static func nextDifficulty(_ d: Double, _ g: Int, _ w: [Double]) -> Double {
        let delta = -w[6] * Double(g - 3)
        let changed = d + delta * (10 - d) / 9
        return clamp(w[7] * initialDifficulty(4, w) + (1 - w[7]) * changed)
    }

    private static func recallStability(_ d: Double, _ s: Double, _ r: Double, _ rating: Rating, _ w: [Double]) -> Double {
        let hard = rating == .hard ? w[15] : 1
        let easy = rating == .easy ? w[16] : 1
        return s * (exp(w[8]) * (11 - d) * pow(s, -w[9]) * (exp(w[10] * (1 - r)) - 1) * hard * easy + 1)
    }

    private static func forgetStability(_ d: Double, _ s: Double, _ r: Double, _ w: [Double]) -> Double {
        let forgotten = w[11] * pow(d, -w[12]) * (pow(s + 1, w[13]) - 1) * exp(w[14] * (1 - r))
        return max(min(forgotten, s), 0.01)
    }

    private static func clamp(_ d: Double) -> Double { min(max(d, 1), 10) }

    private static func plusDays(_ date: Date, _ days: Int) -> Date { date.addingTimeInterval(Double(days) * 86_400) }
}
