// Zusammenhang: Paralist/Intents/EntryEntity.swift, Paralist/Intents/ParalistShortcuts.swift, Paralist/Shell/Router.swift, Paralist/App/ParalistApp.swift, ParalistCore Library/WidgetPicks.swift
import AppIntents
import ParalistCore

struct OpenEntryIntent: OpenIntent {
    static let title: LocalizedStringResource = "siri_open_title"
    static let description = IntentDescription("siri_open_description")
    static let supportedModes: IntentModes = .foreground

    @Parameter(title: "widget_entity")
    var target: EntryEntity

    @Dependency
    var model: AppModel

    @Dependency
    var router: Router

    @MainActor
    func perform() async throws -> some IntentResult {
        model.reload()
        guard let entry = model.entry(target.id), WidgetPicks.allowed(entry) else {
            throw $target.needsValueError(IntentDialog("\(L.s("widget_missing"))"))
        }
        router.open(.entry(entry.id))
        return .result()
    }
}
