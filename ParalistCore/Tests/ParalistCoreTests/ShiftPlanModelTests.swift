// Zusammenhang: Sources/ParalistCore/Chat/ShiftPlanModel.swift, Sources/ParalistCore/Chat/Skills.swift (codes), Sources/ParalistCore/Chat/ShiftPlanRows.swift (ShiftCells.parse codes), Sources/ParalistCore/Chat/ShiftPlan.swift, ShiftPlanTests.swift, TestSupport.swift
import Foundation
import Testing
@testable import ParalistCore

struct ShiftPlanModelTests {
    private let today = Day.parse("2026-10-28")!

    @Test func codesFromTheSkillTurnLettersIntoShifts() {
        let codes = Skills.codes("F=06:00-14:00; S: 14:00-22:00, N=22.00-06.00\nX=kaputt, =08:00-09:00")
        #expect(codes == ["F": ShiftCode(start: 360, end: 840), "S": ShiftCode(start: 840, end: 1320), "N": ShiftCode(start: 1320, end: 360)])
        #expect(Skills.codes(nil).isEmpty && Skills.codes("").isEmpty)
        #expect(ShiftCells.parse("F", codes: codes) == .work(start: 360, end: 840))
        #expect(ShiftCells.parse("N.", codes: codes) == .work(start: 1320, end: 360))
        #expect(ShiftCells.parse("f", codes: codes) == .free)
        #expect(ShiftCells.parse("F") == .free)
        var rows = ShiftPlanTests.rows
        rows[2][3] = "F"
        rows[2][5] = "N"
        let document = ScannedDocument(text: "KW 44/2026", tables: [ScannedTable(rows: rows)])
        let plan = ShiftPlanReader.read(document, name: "Erika Muster", today: today, codes: codes)
        #expect(plan?.shifts.map(\.start) == [360, 1320, 780, 1320])
        #expect(plan?.absences.isEmpty == true)
        let skill = ShiftSkill(Entry("n", .note, "Schichtplan", epoch, epoch) { $0.extras = [Skills.codesKey: "F=06:00-14:00"] })
        #expect(skill.codes["F"] == ShiftCode(start: 360, end: 840))
        let many = (0..<30).map { "K\($0)=08:00-09:00" }.joined(separator: ",")
        #expect(Skills.codes(many).count == Skills.maxCodes)
    }

    @Test func modelOutputBecomesAPlanOnlyWhenPlausible() {
        let model = ModelPlan(isSchedule: true, names: [" Muster, Erika ", "Beispiel, Max", "muster, erika", ""],
                              shifts: [ModelShift(day: "2026-10-29", start: "13:00", end: "21:00", hours: 7.5),
                                       ModelShift(day: "30.10.2026", start: "6:00", end: "13.25"),
                                       ModelShift(day: "2026-10-29", start: "08:00", end: "09:00"),
                                       ModelShift(day: "bald", start: "08:00", end: "09:00"),
                                       ModelShift(day: "2026-10-31", start: "25:00", end: "09:00"),
                                       ModelShift(day: "2020-01-01", start: "08:00", end: "09:00")],
                              absences: ["2026-10-27", "2026-10-29", "x"])
        let plan = ShiftPlanModel.plan(from: model, today: today, rowKnown: true)
        #expect(plan?.rowFound == true)
        #expect(plan?.names == ["Muster, Erika", "Beispiel, Max"])
        #expect(plan?.shifts == [ShiftDay(day: Day.parse("2026-10-29")!, start: 780, end: 1260, hours: 7.5), ShiftDay(day: Day.parse("2026-10-30")!, start: 360, end: 805)])
        #expect(plan?.absences == [Day.parse("2026-10-27")!])
        #expect(plan?.days == [Day.parse("2026-10-27")!, Day.parse("2026-10-29")!, Day.parse("2026-10-30")!])
        let unknown = ShiftPlanModel.plan(from: model, today: today, rowKnown: false)
        #expect(unknown?.rowFound == false && unknown?.shifts.isEmpty == true && unknown?.names.count == 2)
        #expect(ShiftPlanModel.plan(from: ModelPlan(isSchedule: false, names: ["A"], shifts: []), today: today, rowKnown: true) == nil)
        #expect(ShiftPlanModel.plan(from: ModelPlan(isSchedule: true, names: [], shifts: []), today: today, rowKnown: true) == nil)
        let wide = ModelPlan(isSchedule: true, names: ["A"], shifts: [ModelShift(day: "2026-10-01", start: "08:00", end: "09:00"), ModelShift(day: "2026-11-15", start: "08:00", end: "09:00")])
        #expect(ShiftPlanModel.plan(from: wide, today: today, rowKnown: true) == nil)
        let namesOnly = ShiftPlanModel.plan(from: ModelPlan(isSchedule: true, names: ["A"], shifts: []), today: today, rowKnown: true)
        #expect(namesOnly?.rowFound == false)
    }

    @Test func instructionsAndPromptMentionTheRow() {
        #expect(ShiftPlanModel.instructions(name: "Muster, Erika").contains("The user's row is the one for \"Muster, Erika\""))
        #expect(ShiftPlanModel.instructions(name: "").hasSuffix("return the names only and leave shifts empty."))
        #expect(ShiftPlanModel.prompt(table: "").hasSuffix("extract it as described."))
        #expect(ShiftPlanModel.prompt(table: "table 1 (2 rows):\n  a | b").hasSuffix("(cells separated by \"|\"):\ntable 1 (2 rows):\n  a | b"))
    }
}
