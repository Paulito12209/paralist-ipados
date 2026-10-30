// Zusammenhang: Chat/ChatEngine.swift (planDraft), ParalistCore Chat/ShiftPlanModel.swift, ParalistCore Chat/ScannedDocument.swift, ParalistCore Chat/Skills.swift, docs/chat.md
import Foundation
import FoundationModels
import OSLog
import ParalistCore

@Generable
struct ModelShiftOutput {
    @Guide(description: "Date of the shift as YYYY-MM-DD")
    var day: String
    @Guide(description: "Start time as HH:MM")
    var start: String
    @Guide(description: "End time as HH:MM")
    var end: String
    @Guide(description: "Hours shown for this shift, if any")
    var hours: Double?
}

@Generable
struct ModelPlanOutput {
    @Guide(description: "True only if the photo shows a work schedule or shift plan")
    var isSchedule: Bool
    @Guide(description: "Names of the people listed in the plan, as written", .maximumCount(30))
    var names: [String]
    @Guide(description: "The user's own shifts, empty if the user's row is unknown", .maximumCount(40))
    var shifts: [ModelShiftOutput]
    @Guide(description: "Dates (YYYY-MM-DD) on which the user is marked absent", .maximumCount(31))
    var absences: [String]
}

enum ChatVision {
    private static let log = Logger(subsystem: "app.paralist", category: "chat")

    static var available: Bool {
        if #available(iOS 27.0, *) { return SystemLanguageModel.default.capabilities.contains(.vision) }
        return false
    }

    static func plan(image: URL, document: ScannedDocument, name: String, today: Day) async -> ShiftPlan? {
        guard #available(iOS 27.0, *), available else { return nil }
        let started = Date()
        let session = LanguageModelSession(model: .default, instructions: ShiftPlanModel.instructions(name: name))
        let table = ScannedContext.format(document, limit: ChatTools.maxContextChars)
        let attachment = Attachment<ImageAttachmentContent>(imageURL: image)
        do {
            let response = try await session.respond(generating: ModelPlanOutput.self) {
                ShiftPlanModel.prompt(table: table)
                attachment
            }
            let output = response.content
            let model = ModelPlan(isSchedule: output.isSchedule, names: output.names,
                                  shifts: output.shifts.map { ModelShift(day: $0.day, start: $0.start, end: $0.end, hours: $0.hours) }, absences: output.absences)
            let plan = ShiftPlanModel.plan(from: model, today: today, rowKnown: !name.isEmpty)
            log.info("vision plan took \(Date().timeIntervalSince(started), privacy: .public) seconds: schedule \(output.isSchedule), \(output.shifts.count) shifts, \(output.names.count) names")
            return plan
        } catch {
            log.info("vision plan failed: \(String(describing: error), privacy: .public)")
            return nil
        }
    }
}
