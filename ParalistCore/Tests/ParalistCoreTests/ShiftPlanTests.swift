// Zusammenhang: Sources/ParalistCore/Chat/ShiftPlan.swift, Sources/ParalistCore/Chat/ShiftPlanHeader.swift, Sources/ParalistCore/Chat/ShiftPlanRows.swift, TestSupport.swift
import Foundation
import Testing
@testable import ParalistCore

struct ShiftPlanTests {
    private let today = Day.parse("2026-10-28")!
    private let abbreviations = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

    static let rows: [[String]] = [
        ["Name", "Pers.-Nr.", "Mo 26.10", "", "Di 27.10", "", "Mi 28.10", "", "Do 29.10", "", "Fr 30.10\nSa 31.10", "", "", "", "So 01.11", ""],
        ["", "", "Std.", "Zeit", "Std.", "Zeit", "Std.", "Zeit", "Std.", "Zeit", "Std.", "Zeit", "Std.", "Zeit", "Std.", "Zeit"],
        ["uster, Erika", "p00123", "6.92", "06:00-13:25/", "", "ABW", "8,5", "13:00-21:00\n000042g", "", "f", "", "", "8", "22:00-06:30", "", "-"],
        ["Beispiel, Max", "000456", "7.5", "13:00-21:00", "", "f", "", "", "6.92", "06:00-13:25", "", "ABW", "", "", "", ""],
        ["", "000789", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["Mustermann Jonas", "", "", "f", "", "f", "", "f", "", "f", "", "f", "", "f", "", "f"],
    ]

    static func document(text: String = "Wochenplan 26.10.2026-01、11.2026\nKW 44/2026") -> ScannedDocument {
        ScannedDocument(text: text, tables: [ScannedTable(rows: rows)])
    }

    @Test func readsPeriodColumnsNamesAndOwnShifts() throws {
        let plan = try #require(ShiftPlanReader.read(Self.document(), name: "Erika Muster", today: today))
        #expect(plan.days.first == Day.parse("2026-10-26") && plan.days.last == Day.parse("2026-11-01") && plan.days.count == 7)
        #expect(plan.names == ["uster, Erika", "Beispiel, Max", "Mustermann Jonas"])
        #expect(plan.rowFound)
        #expect(plan.shifts.map(\.day) == [Day.parse("2026-10-26"), Day.parse("2026-10-28"), Day.parse("2026-10-31")])
        #expect(plan.shifts[0] == ShiftDay(day: Day.parse("2026-10-26")!, start: 6 * 60, end: 13 * 60 + 25, hours: 6.92))
        #expect(plan.shifts[0].hoursMatch == true)
        #expect(plan.shifts[1].hours == 8.5 && plan.shifts[1].hoursMatch == false)
        #expect(plan.shifts[2].crossesMidnight && plan.shifts[2].minutes == 510 && plan.shifts[2].hoursMatch == true)
    }

    @Test func findsTheRowByNameVariantsAndNumber() {
        func row(_ name: String) -> String? { ShiftPlanReader.read(Self.document(), name: name, today: today).flatMap { $0.rowFound ? $0.shifts.first?.day.description : nil } }
        #expect(row("Muster, Erika") == "2026-10-26")
        #expect(row("erika müster") == "2026-10-26")
        #expect(row("Erika Muster 000123") == "2026-10-26")
        #expect(row("Max Beispiel") == "2026-10-26")
        #expect(row("Jonas Mustermann") == nil)
        let unknown = ShiftPlanReader.read(Self.document(), name: "Niemand", today: today)
        #expect(unknown?.rowFound == false && unknown?.shifts.isEmpty == true && unknown?.names.count == 3)
        #expect(ShiftPlanReader.read(Self.document(), name: "", today: today)?.rowFound == false)
        let jonas = ShiftPlanReader.read(Self.document(), name: "Mustermann, Jonas", today: today)
        #expect(jonas?.rowFound == true && jonas?.shifts.isEmpty == true)
    }

    @Test func parsesCellsTolerantly() {
        #expect(ShiftCells.parse("06:00-13:00/") == .work(start: 360, end: 780))
        #expect(ShiftCells.parse("06.00 – 13.15\n000042g") == .work(start: 360, end: 795))
        #expect(ShiftCells.parse("22:00-06:30") == .work(start: 1320, end: 390))
        #expect(ShiftCells.parse(" ABW ") == .absent)
        #expect(ShiftCells.parse("f") == .free && ShiftCells.parse("-") == .free && ShiftCells.parse("") == .free)
        #expect(ShiftCells.parse("25:00-26:00") == .unknown && ShiftCells.parse("Urlaub") == .unknown)
        #expect(ShiftCells.hours("6,92") == 6.92 && ShiftCells.hours("f") == nil)
        #expect(ShiftCells.breakMinutes(5 * 60) == 0 && ShiftCells.breakMinutes(6 * 60) == 30 && ShiftCells.breakMinutes(9 * 60) == 45)
        #expect(ShiftDay(day: today, start: 480, end: 1080, hours: 9.25).hoursMatch == true)
        #expect(ShiftDay(day: today, start: 480, end: 1080).hoursMatch == nil)
    }

    @Test func periodAcceptsLooseSeparatorsAndWeekNumbers() {
        #expect(ShiftPlanHeader.periodDays("26 10 2026 – 01,11,2026").count == 7)
        #expect(ShiftPlanHeader.periodDays("Zeitraum 26.10.2026-01、11.2026").first == Day.parse("2026-10-26"))
        #expect(ShiftPlanHeader.periodDays("KW 44/2026").first == Day.parse("2026-10-26"))
        #expect(ShiftPlanHeader.periodDays("KW 1 2027").first == Day.parse("2027-01-04"))
        #expect(ShiftPlanHeader.periodDays("01.01.2026-31.12.2026").isEmpty)
        #expect(ShiftPlanHeader.periodDays("nichts").isEmpty)
    }

    @Test func dayHeadsGetTheYearFromTodayAcrossNewYear() {
        let heads = ShiftPlanHeader.dayHeads("Fr 30.10\nSa 31.10")
        #expect(heads.map(\.day) == [30, 31] && heads.map(\.weekday) == [5, 6] && heads.allSatisfy { $0.year == nil })
        #expect(ShiftPlanHeader.dayHeads("Mo 26.10.26").first?.year == 2026)
        #expect(ShiftPlanHeader.dayHeads("Montag 26.10").isEmpty)
        let monday = Day.parse("2026-12-28")!
        let week = (0..<7).map(monday.adding(days:))
        let labels = week.map { "\(abbreviations[$0.weekday - 1]) \(String(format: "%02d.%02d", $0.day, $0.month))" }
        var rows: [[String]] = [[""] + labels.flatMap { [$0, ""] }, [""] + Array(repeating: ["Std.", "Zeit"], count: 7).flatMap { $0 }]
        rows.append(["Muster, Erika"] + Array(repeating: ["", "08:00-16:00"], count: 7).flatMap { $0 })
        let plan = ShiftPlanReader.read(ScannedDocument(text: "", tables: [ScannedTable(rows: rows)]), name: "Erika Muster", today: Day.parse("2026-12-30")!)
        #expect(plan?.days == week)
        #expect(plan?.shifts.count == 7)
    }

    @Test func singleTimeColumnsAndMissingHeadersAreHandled() {
        let rows: [[String]] = [
            ["", "Mo 26.10.2026", "Di 27.10.2026", "Mi 28.10.2026"],
            ["Muster, Erika", "08:00-16:00", "f", "16:00-23:30"],
        ]
        let plan = ShiftPlanReader.read(ScannedDocument(text: "", tables: [ScannedTable(rows: rows)]), name: "Erika Muster", today: today)
        #expect(plan?.days.count == 3 && plan?.shifts.map(\.start) == [480, 960])
        #expect(plan?.shifts.allSatisfy { $0.hours == nil } == true)
        #expect(ShiftPlanReader.read(ScannedDocument(text: "nur Text"), name: "Erika", today: today) == nil)
        let noDays = ScannedDocument(text: "", tables: [ScannedTable(rows: [["Name", "Std.", "Zeit"], ["Muster, Erika", "8", "08:00-16:00"]])])
        #expect(ShiftPlanReader.read(noDays, name: "Erika Muster", today: today) == nil)
        let tooLong = ScannedDocument(text: "01.01.2026-31.12.2026", tables: [ScannedTable(rows: [["Name", "Std.", "Zeit"], ["Muster, Erika", "8", "08:00-16:00"]])])
        #expect(ShiftPlanReader.read(tooLong, name: "Erika Muster", today: today) == nil)
    }

    @Test func numbersAndNamesAreSplit() {
        #expect(ShiftRows.split("Muster, Erika p00123") == ("Muster, Erika", "000123"))
        #expect(ShiftRows.split("Muster, Erika") == ("Muster, Erika", ""))
        #expect(ShiftRows.split("O00123") == ("", "000123"))
        #expect(ShiftRows.split("Max 12") == ("Max 12", ""))
        #expect(ShiftNames.tokens("Müster, Erika-Maria") == ["muster", "erika", "maria"])
        #expect(ShiftNames.same("uster", "muster") && ShiftNames.same("muster", "uster") && !ShiftNames.same("max", "mia"))
    }
}
