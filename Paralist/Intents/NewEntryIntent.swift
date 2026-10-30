// Zusammenhang: Paralist/Intents/TypedEntryIntents.swift, Paralist/Intents/ParalistShortcuts.swift, Paralist/App/AppModel.swift, Paralist/App/ParalistApp.swift, Paralist/Entries/TypeLook.swift, ParalistCore Library/QuickEntry.swift, ParalistCore Planning/SpokenEvent.swift, Paralist/Components/EventTimeSheet.swift, ParalistShare/ShareModel.swift
import AppIntents
import Foundation
import ParalistCore

enum NewEntryKind: String, AppEnum {
    case note, task, project, area, document

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "siri_kind")
    static let caseDisplayRepresentations: [NewEntryKind: DisplayRepresentation] = [
        .note: DisplayRepresentation(title: "type_note"),
        .task: DisplayRepresentation(title: "type_task"),
        .project: DisplayRepresentation(title: "type_project"),
        .area: DisplayRepresentation(title: "type_area"),
        .document: DisplayRepresentation(title: "type_document"),
    ]

    var type: EntryType {
        switch self {
        case .note: return .note
        case .task: return .task
        case .project: return .project
        case .area: return .area
        case .document: return .document
        }
    }
}

enum EntryCreator {
    @MainActor
    static func create(_ type: EntryType, text: String?, model: AppModel) -> String? {
        guard QuickEntry.types.contains(type), let parsed = QuickEntry.parse(text) else { return nil }
        var entry = model.newEntry(type, title: parsed.title)
        entry.body = parsed.body
        return L.s(model.save(entry) == nil ? "save_failed" : "siri_saved_\(type.key)")
    }

    @MainActor
    static func createEvent(text: String?, model: AppModel) -> String? {
        let raw = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        let spoken = SpokenEvent.parse(raw, now: Date(), zone: .current, periods: model.prefs.periods)
        guard spoken.day != nil else { return nil }
        var draft = ComposerDraft(type: .event)
        draft.apply(spoken)
        if draft.title.isEmpty { draft.title = L.s("type_event") }
        guard let entry = draft.build(model.newEntry(.event), zone: .current), let start = entry.start, model.save(entry) != nil else { return L.s("save_failed") }
        return L.f("siri_saved_termin", entry.title, EventLabel.of(start: start, end: entry.end, allDay: entry.allDay))
    }
}

struct NewEntryIntent: AppIntent {
    static let title: LocalizedStringResource = "siri_new_title"
    static let description = IntentDescription("siri_new_description")
    static let supportedModes: IntentModes = .background

    @Parameter(title: "siri_kind")
    var kind: NewEntryKind?

    @Parameter(title: "siri_new_text")
    var text: String?

    @Dependency
    var model: AppModel

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let kind else { throw $kind.needsValueError(IntentDialog("\(L.s("siri_ask_kind"))")) }
        guard let answer = EntryCreator.create(kind.type, text: text, model: model) else {
            throw $text.needsValueError(IntentDialog("\(L.s("siri_ask_\(kind.type.key)"))"))
        }
        return .result(dialog: IntentDialog("\(answer)"))
    }
}
