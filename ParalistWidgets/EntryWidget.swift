// Zusammenhang: ParalistWidgets/ParalistWidgetsBundle.swift, ParalistWidgets/PickEntryIntent.swift, ParalistWidgets/EntryProvider.swift, ParalistWidgets/EntryWidgetView.swift, Paralist/App/L.swift
import SwiftUI
import WidgetKit

struct EntryWidget: Widget {
    static let kind = "app.paralist.widgets.entry"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: PickEntryIntent.self, provider: EntryProvider()) { snapshot in
            EntryWidgetView(snapshot: snapshot)
        }
        .configurationDisplayName(L.s("widget_name"))
        .description(L.s("widget_description"))
        .contentMarginsDisabled()
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}
