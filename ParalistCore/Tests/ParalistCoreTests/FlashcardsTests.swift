// Zusammenhang: Flashcards/CardMarkdown.swift, Flashcards/Fsrs.swift, Flashcards/ReviewLog.swift, Flashcards/StudyQueue.swift
import Foundation
import Testing
@testable import ParalistCore

struct CardMarkdownTests {
    private let source = """
        Capital of France
        ==
        Paris
        #geography #europe
        ---
        Which language is spoken in Brazil?
        ==<
        1: Spanish
        2: Portuguese
        3: French
        --
        true: 2
        #languages
        """

    @Test func parsesStandardAndMultipleChoice() {
        let result = CardMarkdown.parse(source)
        #expect(result.errors.isEmpty)
        #expect(result.cards.count == 2)
        #expect(result.cards[0] == ParsedCard(front: "Capital of France", back: "Paris", tags: ["geography", "europe"]))
        let mc = result.cards[1]
        #expect(mc.isMultipleChoice)
        #expect(mc.correctOption == 2)
        #expect(mc.back == "Portuguese")
        #expect(mc.options == ["Spanish", "Portuguese", "French"])
    }

    @Test func roundTripsAndHandlesEscapesAndFences() {
        let parsed = CardMarkdown.parse(source)
        let again = CardMarkdown.parse(CardMarkdown.serialize(parsed.cards))
        #expect(again.cards == parsed.cards)
        #expect(again.errors == parsed.errors)
        let escaped = CardMarkdown.parse("Question\n\\==\nAnswer\n\\#tag")
        #expect(escaped.cards.count == 1)
        #expect(escaped.cards.first?.tags == ["tag"])
        let fenced = CardMarkdown.parse("```markdown\nQ\n==\nA\n```")
        #expect(fenced.cards.count == 1)
        #expect(CardMarkdown.parse((1...75).map { "Q\($0)\n==\nA\($0)" }.joined(separator: "\n---\n")).cards.count == 75)
    }

    @Test func reportsErrorsPerCardAndKeepsValidOnes() {
        let result = CardMarkdown.parse("Question\n==<\n1: A\n2: B\n--\ntrue: 3\n---\nOk\n==\nJa\n---\nNur Frage\n---\nX\n==<\n1: A\n2: B\n--\ncorrect: 2")
        #expect(result.cards.count == 1)
        #expect(result.errors.map(\.card) == [1, 3, 4])
        #expect(result.errors[0].message.contains("existiert nicht"))
        #expect(result.errors[2].message.contains("true: N"))
    }
}

struct FsrsTests {
    private let t0 = at("2026-10-16T10:00:00Z")

    @Test func firstRatingsGiveGrowingIntervals() throws {
        let again = Fsrs.review(CardState(), .again, now: t0)
        let hard = Fsrs.review(CardState(), .hard, now: t0)
        let good = Fsrs.review(CardState(), .good, now: t0)
        let easy = Fsrs.review(CardState(), .easy, now: t0)
        #expect(again.phase == .learning)
        #expect(again.due == t0.addingTimeInterval(600))
        let hardDue = try #require(hard.due), goodDue = try #require(good.due), easyDue = try #require(easy.due)
        #expect(hardDue < goodDue && goodDue < easyDue)
        #expect(Int(goodDue.timeIntervalSince(t0) / 86_400) == 3)
        #expect((1.0...10.0).contains(good.difficulty))
    }

    @Test func goodReviewsGrowStabilityAndLapseShrinksIt() {
        var state = Fsrs.review(CardState(), .good, now: t0)
        let first = state.stability
        state = Fsrs.review(state, .good, now: state.due!)
        #expect(state.stability > first)
        let lapsed = Fsrs.review(state, .again, now: state.due!)
        #expect(lapsed.stability < state.stability)
        #expect(lapsed.lapses == 1)
        #expect(lapsed.phase == .relearning)
        let recovered = Fsrs.review(lapsed, .good, now: lapsed.due!)
        #expect(recovered.phase == .review)
    }

    @Test func clockSetBackDoesNotCrashOrGoNegative() {
        let state = Fsrs.review(CardState(), .good, now: t0)
        let back = t0.addingTimeInterval(-30 * 86_400)
        let earlier = Fsrs.review(state, .good, now: back)
        #expect(earlier.stability > 0)
        #expect(earlier.due! > back)
        #expect(Fsrs.interval(1e9) <= Fsrs.maxIntervalDays)
    }

    @Test func logReplayIgnoresGarbageAndFutureEntries() throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let log = ReviewLog(root: root)
        try log.append(ReviewEvent(cardId: "card-1", at: t0, rating: .good))
        try log.append(ReviewEvent(cardId: "card-1", at: t0.addingTimeInterval(3 * 86_400), rating: .good))
        let file = log.dir.appendingPathComponent("card-1.log")
        let handle = try FileHandle(forWritingTo: file)
        try handle.seekToEnd()
        try handle.write(contentsOf: Data("kaputt\n2099-01-01T00:00:00Z 3\n2026-10-20T10:00:00Z 9\n".utf8))
        try handle.close()
        let events = log.read("card-1", now: t0.addingTimeInterval(4 * 86_400))
        #expect(events.count == 2)
        let state = ReviewLog.replay(events)
        #expect(state.reps == 2)
        #expect(state.phase == .review)
        #expect(log.read("../evil").isEmpty)
    }

    @Test func queueRespectsDailyLimitForNewCards() {
        let now = t0
        let fresh = (1...30).map { StudyCandidate(cardId: "new-\($0)", state: CardState()) }
        let due = (1...3).map {
            StudyCandidate(cardId: "due-\($0)", state: CardState(phase: .review, stability: 5, difficulty: 5, due: now.addingTimeInterval(-60), lastReview: now.addingTimeInterval(-5 * 86_400), reps: 2, lapses: 0))
        }
        let later = StudyCandidate(cardId: "later", state: CardState(phase: .review, stability: 5, difficulty: 5, due: now.addingTimeInterval(3600), lastReview: now, reps: 1, lapses: 0))
        let all = due + fresh + [later]
        let queue = StudyQueue.build(all, introducedToday: 5, newPerDay: 20, now: now) { $0 }
        #expect(queue.count == 3 + 15)
        #expect(queue.prefix(3).allSatisfy { $0.cardId.hasPrefix("due") })
        #expect(StudyQueue.dueCount(all, now: now) == 3)
        let events = [[ReviewEvent(cardId: "a", at: now, rating: .good)], [ReviewEvent(cardId: "b", at: now.addingTimeInterval(-2 * 86_400), rating: .good)]]
        #expect(StudyQueue.introducedToday(events, now: now, zone: berlin) == 1)
    }
}
