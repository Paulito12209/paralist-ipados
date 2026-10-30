// Zusammenhang: Paralist/Intents/NewEntryIntent.swift, ParalistCore Planning/SpokenEvent.swift, Paralist/Intents/ParalistShortcuts.swift, Paralist/App/AppModel.swift, ParalistCore Library/QuickEntry.swift
import AppIntents
import ParalistCore

struct NewNoteIntent: AppIntent {
    static let title: LocalizedStringResource = "siri_new_note"
    static let description = IntentDescription("siri_new_description")
    static let supportedModes: IntentModes = .background

    @Parameter(title: "siri_new_text")
    var text: String?

    @Dependency
    var model: AppModel

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let answer = EntryCreator.create(.note, text: text, model: model) else { throw $text.needsValueError(IntentDialog("\(L.s("siri_ask_notiz"))")) }
        return .result(dialog: IntentDialog("\(answer)"))
    }
}

struct NewTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "siri_new_task"
    static let description = IntentDescription("siri_new_description")
    static let supportedModes: IntentModes = .background

    @Parameter(title: "siri_new_text")
    var text: String?

    @Dependency
    var model: AppModel

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let answer = EntryCreator.create(.task, text: text, model: model) else { throw $text.needsValueError(IntentDialog("\(L.s("siri_ask_aufgabe"))")) }
        return .result(dialog: IntentDialog("\(answer)"))
    }
}

struct NewProjectIntent: AppIntent {
    static let title: LocalizedStringResource = "siri_new_project"
    static let description = IntentDescription("siri_new_description")
    static let supportedModes: IntentModes = .background

    @Parameter(title: "siri_new_text")
    var text: String?

    @Dependency
    var model: AppModel

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let answer = EntryCreator.create(.project, text: text, model: model) else { throw $text.needsValueError(IntentDialog("\(L.s("siri_ask_projekt"))")) }
        return .result(dialog: IntentDialog("\(answer)"))
    }
}

struct NewAreaIntent: AppIntent {
    static let title: LocalizedStringResource = "siri_new_area"
    static let description = IntentDescription("siri_new_description")
    static let supportedModes: IntentModes = .background

    @Parameter(title: "siri_new_text")
    var text: String?

    @Dependency
    var model: AppModel

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let answer = EntryCreator.create(.area, text: text, model: model) else { throw $text.needsValueError(IntentDialog("\(L.s("siri_ask_arbeitsbereich"))")) }
        return .result(dialog: IntentDialog("\(answer)"))
    }
}

struct NewDocumentIntent: AppIntent {
    static let title: LocalizedStringResource = "siri_new_document"
    static let description = IntentDescription("siri_new_description")
    static let supportedModes: IntentModes = .background

    @Parameter(title: "siri_new_text")
    var text: String?

    @Dependency
    var model: AppModel

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let answer = EntryCreator.create(.document, text: text, model: model) else { throw $text.needsValueError(IntentDialog("\(L.s("siri_ask_dokument"))")) }
        return .result(dialog: IntentDialog("\(answer)"))
    }
}

struct NewEventIntent: AppIntent {
    static let title: LocalizedStringResource = "siri_new_event"
    static let description = IntentDescription("siri_new_event_description")
    static let supportedModes: IntentModes = .background

    @Parameter(title: "siri_new_text")
    var text: String?

    @Dependency
    var model: AppModel

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let answer = EntryCreator.createEvent(text: text, model: model) else { throw $text.needsValueError(IntentDialog("\(L.s("siri_ask_termin"))")) }
        return .result(dialog: IntentDialog("\(answer)"))
    }
}
