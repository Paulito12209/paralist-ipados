// Zusammenhang: Sources/ParalistCore/Planning/SpokenEvent.swift, Sources/ParalistCore/Planning/SpokenDates.swift, Sources/ParalistCore/Planning/SpokenTimes.swift, Sources/ParalistCore/Planning/SpokenWords.swift, Tests/ParalistCoreTests/SpokenEventTests.swift
import Foundation
import Testing
@testable import ParalistCore

struct SpokenWordingTests {
    private let today = Day(year: 2026, month: 10, day: 22)

    private func parse(_ text: String, now: Int = 10 * 60, periods: DayPeriods = .standard, base: Day? = nil) -> SpokenEvent {
        SpokenEvent.parse(text, today: today, nowMinute: now, periods: periods, baseDay: base)
    }

    @Test func leadPhrasesAndTrailingVerbs() {
        #expect(parse("Erinnere mich daran morgen um 9 Uhr die Miete zu überweisen").title == "Miete zu überweisen")
        #expect(parse("Ich habe morgen einen Termin beim Zahnarzt").title == "Termin beim Zahnarzt")
        #expect(parse("Ich muss übermorgen einkaufen").title == "Einkaufen")
        #expect(parse("Remind me to call mom tomorrow at 5 pm").title == "Call mom")
        #expect(parse("Zahnarzt morgen 15 Uhr eintragen bitte").title == "Zahnarzt")
        #expect(parse("Termin: Zahnarzt morgen").title == "Zahnarzt")
        #expect(parse("Erstelle eine Aufgabe Steuer abgeben bis Freitag").title == "Steuer abgeben")
        #expect(parse("Steuer abgeben bis Freitag").day == Day(year: 2026, month: 10, day: 23))
    }

    @Test func relativeDays() {
        #expect(parse("gestern Notiz").day == today.adding(days: -1))
        #expect(parse("vorgestern Notiz").day == today.adding(days: -2))
        #expect(parse("in zwei Wochen Kontrolle").day == today.adding(days: 14))
        #expect(parse("in einem Monat Zahnarzt").day == Day(year: 2026, month: 11, day: 22))
        #expect(parse("in 3 Monaten TÜV").day == Day(year: 2027, month: 1, day: 22))
        #expect(parse("heute in einer Woche Kontrolle").day == today.adding(days: 7))
        #expect(parse("am Wochenende Wandern").day == Day(year: 2026, month: 10, day: 24))
        #expect(parse("am Wochenende Wandern").title == "Wandern")
        #expect(parse("nächste Woche Zahnarzt").day == today.adding(days: 7))
        #expect(parse("nächste Woche Montag Standup").day == Day(year: 2026, month: 10, day: 26))
        #expect(parse("Montag nächste Woche Standup").day == Day(year: 2026, month: 10, day: 26))
        #expect(parse("Montag nächste Woche Standup").title == "Standup")
        #expect(parse("übernächste Woche Freitag Abgabe").day == Day(year: 2026, month: 11, day: 6))
        #expect(parse("übernächste Woche Urlaub").day == today.adding(days: 14))
        #expect(parse("nächsten Monat Miete").day == Day(year: 2026, month: 11, day: 22))
        #expect(parse("am Mo. Standup").day == Day(year: 2026, month: 10, day: 26))
        #expect(parse("so schnell wie möglich Antwort").day == nil)
        #expect(parse("am 24. Friseur").day == Day(year: 2026, month: 10, day: 24))
        #expect(parse("am 3. Friseur").day == Day(year: 2026, month: 11, day: 3))
        #expect(parse("on the 30th Trip").day == Day(year: 2026, month: 10, day: 30))
        #expect(parse("3 Eier kaufen").day == nil)
        #expect(parse("Kapitel 3 lesen").startMinute == nil)
    }

    @Test func clockForms() {
        #expect(parse("zwischen 14 und 16 Uhr Workshop").startMinute == 14 * 60)
        #expect(parse("zwischen 14 und 16 Uhr Workshop").endMinute == 16 * 60)
        #expect(parse("zwischen 14 und 16 Uhr Workshop").title == "Workshop")
        #expect(parse("between 2 and 4 pm Review").endMinute == 16 * 60)
        #expect(parse("dreiviertel 3 Kaffee").startMinute == 2 * 60 + 45)
        #expect(parse("viertel 3 Kaffee").startMinute == 2 * 60 + 15)
        #expect(parse("half past 3 Tea").startMinute == 3 * 60 + 30)
        #expect(parse("quarter to 5 Tea").startMinute == 4 * 60 + 45)
        #expect(parse("zehn nach acht Frühstück").startMinute == 8 * 60 + 10)
        #expect(parse("twenty to five Tea").startMinute == 4 * 60 + 40)
        #expect(parse("halb 9 abends Kino").startMinute == 20 * 60 + 30)
        #expect(parse("um 10 nachts Heimfahrt").startMinute == 22 * 60)
        #expect(parse("um 3 nachts Wecker").startMinute == 3 * 60)
        #expect(parse("um Mitternacht Feuerwerk").startMinute == 0)
        #expect(parse("um Mitternacht Feuerwerk").title == "Feuerwerk")
        #expect(parse("Rendez-vous demain à 18h30").startMinute == 18 * 60 + 30)
        #expect(parse("Rendez-vous demain à 18h30").title == "Rendez-vous")
        #expect(parse("Cita mañana a las 3 de la tarde").startMinute == 15 * 60)
        #expect(parse("Cita mañana a las 3 de la tarde").title == "Cita")
        #expect(parse("Standup 9 a.m. tomorrow").startMinute == 9 * 60)
        #expect(parse("Lauf um 7 Uhr 30").startMinute == 7 * 60 + 30)
    }

    @Test func offsetsAndDurations() {
        let a = parse("in einer Stunde Anruf", now: 10 * 60)
        #expect(a.day == today)
        #expect(a.startMinute == 11 * 60)
        #expect(a.title == "Anruf")
        #expect(parse("in 20 Minuten Pause", now: 10 * 60).startMinute == 10 * 60 + 15)
        #expect(parse("in einer halben Stunde Pause", now: 10 * 60 + 7).startMinute == 10 * 60 + 30)
        #expect(parse("in zwei Stunden Pause", now: 10 * 60 + 52).startMinute == 12 * 60 + 45)
        let late = parse("in 2 Stunden Taxi", now: 23 * 60)
        #expect(late.day == today.adding(days: 1))
        #expect(late.startMinute == 60)
        let b = parse("Lernen morgen 14 Uhr 2 Stunden lang")
        #expect(b.endMinute == 16 * 60)
        #expect(b.title == "Lernen")
        #expect(parse("Meeting morgen 9 Uhr eine halbe Stunde lang").endMinute == 9 * 60 + 30)
        #expect(parse("Workshop morgen 9 Uhr für anderthalb Stunden").endMinute == 10 * 60 + 30)
    }

    @Test func wholeDay() {
        let a = parse("morgen ganztägig Messe")
        #expect(a.allDay)
        #expect(a.day == today.adding(days: 1))
        #expect(a.startMinute == nil)
        #expect(a.title == "Messe")
        let b = parse("Konferenz Freitag den ganzen Tag")
        #expect(b.allDay)
        #expect(b.title == "Konferenz")
        #expect(parse("all day Saturday Hackathon").allDay)
    }

    @Test func plainStaysPlain() {
        #expect(parse("Ein Termin beim Arzt").title == "Ein Termin beim Arzt")
        #expect(parse("Treffen in Berlin").title == "Treffen in Berlin")
        #expect(parse("Go to gym tomorrow").title == "Go to gym")
        #expect(parse("Zahlen für Q3 prüfen").title == "Zahlen für Q3 prüfen")
        #expect(parse("Zahlen für Q3 prüfen").startMinute == nil)
    }

    @Test func remindersAndSameTime() {
        let zone = TimeZone(identifier: "Europe/Berlin")!
        let a = parse("Erstelle mir einen Reminder für übermorgen dieselbe Uhrzeit", now: 18 * 60 + 4)
        #expect(a.reminder)
        #expect(a.day == today.adding(days: 2))
        #expect(a.startMinute == 18 * 60)
        #expect(a.title == "")
        let b = parse("Erinnere mich morgen um 18 Uhr an die Miete")
        #expect(b.reminder)
        #expect(b.startMinute == 18 * 60)
        #expect(b.title == "Miete")
        let c = parse("Reminder: Müll rausbringen morgen früh")
        #expect(c.reminder)
        #expect(c.title == "Müll rausbringen")
        #expect(!parse("Zahnarzt morgen 15 Uhr").reminder)
        var task = ComposerDraft(type: .task)
        task.apply(b)
        #expect(task.minute == 18 * 60)
        let at = task.remind(b, periods: .standard, zone: zone)
        #expect(at == today.adding(days: 1).at(hour: 18, in: zone))
        #expect(task.reminders == [at!])
        var plain = ComposerDraft(type: .task)
        plain.apply(parse("Zahnarzt morgen"))
        #expect(plain.remind(parse("Zahnarzt morgen"), periods: .standard, zone: zone) == nil)
        var event = ComposerDraft(type: .event)
        event.apply(b)
        #expect(event.remind(b, periods: .standard, zone: zone) == nil)
    }

    @Test func clausesBecomeImperatives() {
        let a = parse("stelle mir einen Reminder , dass ich morgen um 15:00 Uhr die Übersichtsseite überarbeiten muss.")
        #expect(a.reminder)
        #expect(a.title == "Übersichtsseite überarbeiten")
        #expect(a.day == today.adding(days: 1))
        #expect(a.startMinute == 15 * 60)
        #expect(parse("Erinnere mich daran, dass ich morgen die Miete überweisen soll").title == "Miete überweisen")
        let g = parse("Erstelle mir einen Reminder für morgen um 13:00 Uhr, dass ich die Mail von Google bearbeiten muss.")
        #expect(g.title == "Mail von Google bearbeiten")
        #expect(g.reminder)
        #expect(g.startMinute == 13 * 60)
        #expect(parse("Erinnere mich bitte morgen daran, dass wir die Bewerbung abschicken müssen").title == "Bewerbung abschicken")
        #expect(parse("Stell mir für Freitag eine Erinnerung, dass ich Oma anrufen soll").title == "Oma anrufen")
        #expect(parse("Remind me that I have to call mom tomorrow").title == "Call mom")
        #expect(parse("Ich muss morgen die Küche putzen").title == "Küche putzen")
        #expect(parse("Dass ich das nicht vergesse").title == "Das nicht vergesse")
        #expect(parse("Ich muss morgen 9 Uhr die E-Mail an Lisa schreiben").title == "E-Mail an Lisa schreiben")
        #expect(parse("Das Buch lesen").title == "Das Buch lesen")
    }

    @Test func reminderPhrasesAnywhere() {
        let zone = TimeZone(identifier: "Europe/Berlin")!
        let a = parse("E-Mail von Google bezüglich Speicherplatz. bearbeiten. Morgen um 13:00 Uhr und erinnere mich daran .")
        #expect(a.reminder)
        #expect(a.title == "E-Mail von Google bezüglich Speicherplatz bearbeiten")
        #expect(a.day == today.adding(days: 1))
        #expect(a.startMinute == 13 * 60)
        let b = parse("Steuer abgeben Freitag mit Erinnerung")
        #expect(b.reminder)
        #expect(b.title == "Steuer abgeben")
        let c = parse("Buy milk tomorrow and set a reminder please")
        #expect(c.reminder)
        #expect(c.title == "Buy milk")
        var task = ComposerDraft(type: .task)
        task.title = "Speicherplatz bearbeiten also stelle mir einen Reminder um diese Uhrzeit"
        task.date = today.adding(days: 1)
        task.minute = 13 * 60
        let at = task.absorbTitle(now: today.at(hour: 10, in: zone), zone: zone, periods: .standard)
        #expect(at == today.adding(days: 1).at(hour: 13, in: zone))
        #expect(task.title == "Speicherplatz bearbeiten")
        #expect(task.minute == 13 * 60)
        var plain = ComposerDraft(type: .task)
        plain.title = "Morgen Gymnastik"
        plain.date = today
        #expect(plain.absorbTitle(now: today.at(hour: 10, in: zone), zone: zone, periods: .standard) == nil)
        #expect(plain.title == "Morgen Gymnastik")
        var dated = ComposerDraft(type: .task)
        dated.title = "Zahnarzt übermorgen 15 Uhr"
        #expect(dated.absorbTitle(now: today.at(hour: 10, in: zone), zone: zone, periods: .standard) == nil)
        #expect(dated.title == "Zahnarzt")
        #expect(dated.date == today.adding(days: 2))
        #expect(dated.minute == 15 * 60)
    }

    @Test func germanReminderWordEqualsReminder() {
        let zone = TimeZone(identifier: "Europe/Berlin")!
        let a = parse("Stelle mir eine Erinnerung für übermorgen um dieselbe Uhrzeit", now: 13 * 60 + 2)
        #expect(a.reminder)
        #expect(a.day == today.adding(days: 2))
        #expect(a.startMinute == 13 * 60)
        #expect(a.title == "")
        let b = parse("Mails von Google bearbeiten morgen 13 Uhr, stell mir eine Erinnerung")
        #expect(b.reminder)
        #expect(b.title == "Mails von Google bearbeiten")
        var task = ComposerDraft(type: .task)
        task.title = "Mails von Google bearbeiten und erstelle mir eine Erinnerung um dieselbe Uhrzeit"
        task.date = today.adding(days: 1)
        task.minute = 13 * 60
        let at = task.absorbTitle(now: today.at(hour: 10, in: zone), zone: zone, periods: .standard)
        #expect(at == today.adding(days: 1).at(hour: 13, in: zone))
        #expect(task.title == "Mails von Google bearbeiten")
        var spoken = ComposerDraft(type: .task)
        spoken.title = "Mails von Google bearbeiten"
        spoken.date = today.adding(days: 1)
        spoken.minute = 13 * 60
        let follow = SpokenEvent.parse("und stelle mir eine Erinnerung um dieselbe Uhrzeit", today: today, nowMinute: 10 * 60, baseDay: spoken.date, baseMinute: spoken.minute)
        spoken.apply(follow)
        #expect(spoken.title == "Mails von Google bearbeiten")
        #expect(spoken.remind(follow, periods: .standard, zone: zone) == today.adding(days: 1).at(hour: 13, in: zone))
    }

    @Test func monthArithmetic() {
        #expect(Day(year: 2026, month: 1, day: 31).adding(months: 1) == Day(year: 2026, month: 2, day: 28))
        #expect(Day(year: 2026, month: 12, day: 15).adding(months: 1) == Day(year: 2027, month: 1, day: 15))
    }
}
