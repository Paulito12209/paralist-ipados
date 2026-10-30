// Zusammenhang: ParalistWidgets/EntryWidget.swift, ParalistWidgets/EntryProvider.swift, Paralist/Intents/EntryEntity.swift
import AppIntents
import WidgetKit

struct PickEntryIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "widget_intent_title"
    static let description = IntentDescription("widget_description")

    @Parameter(title: "widget_entity")
    var entry: EntryEntity?

    init() {}
}
