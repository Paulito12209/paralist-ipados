// Zusammenhang: Flashcards/Fsrs.swift, Flashcards/ReviewLog.swift, Paralist/Flashcards/StudyPage.swift
import Foundation

public struct StudyCandidate: Hashable, Sendable {
    public let cardId: String
    public let state: CardState

    public init(cardId: String, state: CardState) {
        self.cardId = cardId
        self.state = state
    }
}

public enum StudyQueue {
    public static let defaultNewPerDay = 20

    public static func build(
        _ candidates: [StudyCandidate],
        introducedToday: Int,
        newPerDay: Int,
        now: Date,
        shuffle: ([StudyCandidate]) -> [StudyCandidate] = { $0.shuffled() }
    ) -> [StudyCandidate] {
        let due = candidates.filter { $0.state.phase != .new && $0.state.isDue(now) }
            .sorted { ($0.state.due ?? .distantPast) < ($1.state.due ?? .distantPast) }
        let fresh = candidates.filter { $0.state.phase == .new }
        let room = max(newPerDay - introducedToday, 0)
        return shuffle(due) + Array(shuffle(fresh).prefix(room))
    }

    public static func dueCount(_ candidates: [StudyCandidate], now: Date) -> Int {
        candidates.filter { $0.state.phase != .new && $0.state.isDue(now) }.count
    }

    public static func introducedToday(_ events: [[ReviewEvent]], now: Date, zone: TimeZone) -> Int {
        let today = Day.of(now, in: zone)
        return events.filter { list in
            guard let first = list.min(by: { $0.at < $1.at }) else { return false }
            return Day.of(first.at, in: zone) == today
        }.count
    }

    public static func ratingForSwipe(right: Bool) -> Rating { right ? .good : .again }
}
