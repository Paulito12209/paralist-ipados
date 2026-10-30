// Zusammenhang: ParalistWidgets/EntryWidget.swift, ParalistWidgets/EntryProvider.swift, Paralist/Intents/EntryEntity.swift, ParalistWidgets/Info.plist, project.yml, docs/widget.md
import SwiftUI
import WidgetKit

@main
struct ParalistWidgetsBundle: WidgetBundle {
    init() { EntryData.applyLanguage() }

    var body: some Widget {
        EntryWidget()
    }
}
