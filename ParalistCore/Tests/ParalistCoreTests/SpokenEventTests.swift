// Zusammenhang: Sources/ParalistCore/Planning/SpokenEvent.swift, Sources/ParalistCore/Planning/SpokenParser.swift, Sources/ParalistCore/Planning/DayPeriods.swift, Sources/ParalistCore/Library/ComposerDraft.swift
import Foundation
import Testing
@testable import ParalistCore

struct SpokenEventTests {
    private let today = Day(year: 2026, month: 10, day: 22)

    private func parse(_ text: String, now: Int = 10 * 60, periods: DayPeriods = .standard, base: Day? = nil) -> SpokenEvent {
        SpokenEvent.parse(text, today: today, nowMinute: now, periods: periods, baseDay: base)
    }

    @Test func dentistTheDayAfterTomorrow() {
        let e = parse("Übermorgen 15 Uhr Termin beim Zahnarzt.")
        #expect(e.title == "Termin beim Zahnarzt")
        #expect(e.day == Day(year: 2026, month: 10, day: 24))
        #expect(e.startMinute == 15 * 60)
        #expect(e.endMinute == nil)
    }

    @Test func titleFirstAndLeadPhraseRemoved() {
        let a = parse("Termin beim Zahnarzt übermorgen um 15:30 Uhr")
        #expect(a.title == "Termin beim Zahnarzt")
        #expect(a.startMinute == 15 * 60 + 30)
        let b = parse("Neuer Termin morgen 8 Uhr Zahnarzt")
        #expect(b.title == "Zahnarzt")
        #expect(b.day == today.adding(days: 1))
        #expect(b.startMinute == 8 * 60)
        let c = parse("Erstelle mir einen neuen Termin heute 18 Uhr Kino")
        #expect(c.title == "Kino")
        #expect(c.day == today)
    }

    @Test func periodsUseSettings() {
        var periods = DayPeriods.standard
        periods[.evening] = 19 * 60
        periods[.morning] = 6 * 60 + 30
        let a = parse("morgen abend Kino mit Anna", periods: periods)
        #expect(a.title == "Kino mit Anna")
        #expect(a.day == today.adding(days: 1))
        #expect(a.startMinute == 19 * 60)
        let b = parse("Joggen morgens", periods: periods)
        #expect(b.startMinute == 6 * 60 + 30)
        #expect(b.day == today.adding(days: 1))
        let c = parse("heute Morgen Joggen", periods: periods)
        #expect(c.day == today)
        #expect(c.startMinute == 6 * 60 + 30)
        #expect(c.title == "Joggen")
        let d = parse("Montag morgen Standup")
        #expect(d.day == Day(year: 2026, month: 10, day: 26))
        #expect(d.startMinute == 8 * 60)
        #expect(d.title == "Standup")
    }

    @Test func periodShiftsHours() {
        #expect(parse("Essen um 8 abends").startMinute == 20 * 60)
        #expect(parse("um 3 nachmittags Kaffee").startMinute == 15 * 60)
        #expect(parse("1 Uhr mittags Lunch").startMinute == 13 * 60)
        #expect(parse("halb neun Frühstück").startMinute == 8 * 60 + 30)
        #expect(parse("viertel vor drei Anruf").startMinute == 2 * 60 + 45)
    }

    @Test func rangesAndDurations() {
        let a = parse("Am Montag von 9 bis 11 Uhr Workshop")
        #expect(a.title == "Workshop")
        #expect(a.day == Day(year: 2026, month: 10, day: 26))
        #expect(a.startMinute == 9 * 60)
        #expect(a.endMinute == 11 * 60)
        #expect(a.endDay == a.day)
        let b = parse("morgen 15-17 Uhr Training")
        #expect(b.startMinute == 15 * 60)
        #expect(b.endMinute == 17 * 60)
        #expect(b.title == "Training")
        let c = parse("Party am Samstag von 22 bis 2 Uhr")
        #expect(c.day == Day(year: 2026, month: 10, day: 24))
        #expect(c.endDay == Day(year: 2026, month: 10, day: 25))
        #expect(c.endMinute == 2 * 60)
        let d = parse("Meeting morgen 11 bis 1")
        #expect(d.endMinute == 13 * 60)
        let e = parse("Lernen morgen 14 Uhr für 2 Stunden")
        #expect(e.title == "Lernen")
        #expect(e.endMinute == 16 * 60)
        let f = parse("Call heute 23 Uhr für eine halbe Stunde")
        #expect(f.endMinute == 23 * 60 + 30)
        let g = parse("Nachtzug heute 23:30 für 2 Stunden")
        #expect(g.endDay == today.adding(days: 1))
        #expect(g.endMinute == 90)
    }

    @Test func calendarDates() {
        let a = parse("Zahnarzt am 24.10. um 15:30")
        #expect(a.day == Day(year: 2026, month: 10, day: 24))
        #expect(a.startMinute == 15 * 60 + 30)
        #expect(a.title == "Zahnarzt")
        let b = parse("Geburtstag Oma am 3. März")
        #expect(b.day == Day(year: 2027, month: 3, day: 3))
        #expect(b.startMinute == nil)
        #expect(b.title == "Geburtstag Oma")
        #expect(parse("Prüfung 12.11.2026 9 Uhr").day == Day(year: 2026, month: 11, day: 12))
        #expect(parse("in 3 Tagen Friseur").day == Day(year: 2026, month: 10, day: 25))
        #expect(parse("in einer Woche Kontrolle").day == Day(year: 2026, month: 10, day: 29))
        #expect(parse("nächsten Donnerstag Yoga").day == Day(year: 2026, month: 10, day: 29))
    }

    @Test func timeWithoutDayLooksAhead() {
        #expect(parse("Zahnarzt 15 Uhr", now: 10 * 60).day == today)
        #expect(parse("Zahnarzt 8 Uhr", now: 10 * 60).day == today.adding(days: 1))
        #expect(parse("Zahnarzt 8 Uhr", now: 10 * 60, base: Day(year: 2026, month: 11, day: 2)).day == Day(year: 2026, month: 11, day: 2))
        #expect(parse("heute 8 Uhr Zahnarzt", now: 10 * 60).day == today)
    }

    @Test func english() {
        let a = parse("Meeting tomorrow at 3 pm for 2 hours")
        #expect(a.title == "Meeting")
        #expect(a.day == today.adding(days: 1))
        #expect(a.startMinute == 15 * 60)
        #expect(a.endMinute == 17 * 60)
        let b = parse("Dinner tonight at 8")
        #expect(b.day == today)
        #expect(b.startMinute == 20 * 60)
        #expect(parse("Dentist on Friday 9:30am").startMinute == 9 * 60 + 30)
        #expect(parse("Trip October 30th").day == Day(year: 2026, month: 10, day: 30))
        #expect(parse("the day after tomorrow lunch at noon").startMinute == 12 * 60)
    }

    @Test func plainTextKeepsEverything() {
        let e = parse("Einkaufen gehen")
        #expect(e.title == "Einkaufen gehen")
        #expect(e.day == nil)
        #expect(e.startMinute == nil)
        #expect(parse("Ein Termin beim Arzt").title == "Ein Termin beim Arzt")
        #expect(parse("").title == "")
    }

    @Test func draftTakesSpokenTimes() {
        let zone = TimeZone(identifier: "Europe/Berlin")!
        var draft = ComposerDraft(type: .event)
        draft.apply(parse("Party am Samstag von 22 bis 2 Uhr"))
        #expect(draft.title == "Party")
        let start = draft.start(zone: zone)
        let end = draft.end(zone: zone)
        #expect(start == Day(year: 2026, month: 10, day: 24).at(hour: 22, in: zone))
        #expect(end == Day(year: 2026, month: 10, day: 25).at(hour: 2, in: zone))
        var task = ComposerDraft(type: .task)
        task.apply(parse("übermorgen 15 Uhr Steuer abgeben"))
        #expect(task.date == Day(year: 2026, month: 10, day: 24))
        #expect(task.minute == 15 * 60)
    }

    @Test func draftEndDefaultsAndSetTimes() {
        let zone = TimeZone(identifier: "Europe/Berlin")!
        var draft = ComposerDraft(type: .event)
        draft.date = today
        draft.minute = 9 * 60
        #expect(draft.end(zone: zone) == today.at(hour: 10, in: zone))
        draft.setTimes(start: today.at(hour: 14, in: zone), end: today.at(hour: 16, minute: 30, in: zone), allDay: false, zone: zone)
        #expect(draft.minute == 14 * 60)
        #expect(draft.endMinute == 16 * 60 + 30)
        #expect(draft.end(zone: zone) == today.at(hour: 16, minute: 30, in: zone))
        draft.setTimes(start: today.at(hour: 14, in: zone), end: today.at(hour: 13, in: zone), allDay: false, zone: zone)
        #expect(draft.endMinute == 15 * 60)
        draft.setTimes(start: today.at(hour: 14, in: zone), end: nil, allDay: true, zone: zone)
        #expect(draft.minute == nil)
        #expect(draft.end(zone: zone) == nil)
        let base = Entry(id: "abcd-1234", type: .event, title: "", created: Date(timeIntervalSince1970: 0), updated: Date(timeIntervalSince1970: 0))
        #expect(draft.build(base, zone: zone)?.allDay == true)
    }

    @Test func eventTimesKeepLength() {
        let a = Date(timeIntervalSince1970: 1_000_000)
        #expect(EventTimes.moved(end: a.addingTimeInterval(5400), from: a, to: a.addingTimeInterval(3600)) == a.addingTimeInterval(9000))
        #expect(EventTimes.end(start: a, end: a) == a.addingTimeInterval(3600))
        #expect(EventTimes.end(start: a, end: nil) == a.addingTimeInterval(3600))
        var periods = DayPeriods.standard
        periods[.noon] = 99_999
        #expect(periods[.noon] == 24 * 60 - 1)
        #expect(DayPeriods.standard[.evening] == 18 * 60)
    }
}
