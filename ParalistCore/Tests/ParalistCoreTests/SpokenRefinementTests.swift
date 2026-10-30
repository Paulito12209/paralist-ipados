// Zusammenhang: Sources/ParalistCore/Planning/SpokenRefinement.swift, Sources/ParalistCore/Planning/SpokenEvent.swift
import Foundation
import Testing
@testable import ParalistCore

struct SpokenRefinementTests {
    private let today = Day(year: 2026, month: 10, day: 22)

    @Test func modelFixesTitleAndTimes() {
        let guess = SpokenEvent(title: "Termin beim Zahnarzt am", day: today.adding(days: 1), startMinute: 15 * 60)
        let fixed = guess.refined(by: SpokenRefinement(title: "zahnarzt", day: "2026-10-24", start: "15:30", end: "16:00"), today: today)
        #expect(fixed.title == "Zahnarzt")
        let noisy = guess.refined(by: SpokenRefinement(title: "Zahnarzt morgen um 15 Uhr und erinnere mich daran"), today: today)
        #expect(noisy.title == "Zahnarzt")
        #expect(fixed.day == Day(year: 2026, month: 10, day: 24))
        #expect(fixed.startMinute == 15 * 60 + 30)
        #expect(fixed.endMinute == 16 * 60)
        #expect(fixed.endDay == fixed.day)
    }

    @Test func emptyFieldsKeepTheGuess() {
        let guess = SpokenEvent(title: "Kino", day: today, startMinute: 20 * 60, endDay: today, endMinute: 22 * 60)
        let same = guess.refined(by: SpokenRefinement(title: "", day: "", start: "", end: ""), today: today)
        #expect(same == guess)
        #expect(guess.refined(by: SpokenRefinement(title: "Kino", day: "2031-01-01"), today: today).day == today)
        #expect(guess.refined(by: SpokenRefinement(title: "Kino", day: "morgen", start: "25:00"), today: today).startMinute == 20 * 60)
    }

    @Test func endAfterMidnightAndStaleEnd() {
        let guess = SpokenEvent(title: "Party", day: today, startMinute: 22 * 60)
        let late = guess.refined(by: SpokenRefinement(title: "Party", end: "02:00"), today: today)
        #expect(late.endDay == today.adding(days: 1))
        #expect(late.endMinute == 2 * 60)
        let stale = SpokenEvent(title: "Lernen", day: today, startMinute: 14 * 60, endDay: today, endMinute: 16 * 60)
        #expect(stale.refined(by: SpokenRefinement(title: "Lernen", start: "17:00"), today: today).endMinute == nil)
        let allDay = SpokenEvent(title: "Messe", day: today, allDay: true)
        #expect(allDay.refined(by: SpokenRefinement(title: "Messe", start: "09:00"), today: today).startMinute == nil)
    }

    @Test func promptNamesTheDays() {
        let text = SpokenPrompt.instructions(today: today, nowMinute: 9 * 60 + 5)
        #expect(text.contains("Thursday 2026-10-22"))
        #expect(text.contains("tomorrow = 2026-10-23"))
        #expect(text.contains("Monday = 2026-10-26"))
        #expect(text.contains("09:05"))
        let prompt = SpokenPrompt.prompt("morgen 15 Uhr Zahnarzt", guess: SpokenEvent(title: "Zahnarzt", day: today.adding(days: 1), startMinute: 15 * 60))
        #expect(prompt.contains("date=\"2026-10-23\""))
        #expect(prompt.contains("start=\"15:00\""))
    }
}
