// Zusammenhang: ParalistWidgets/EntryWidget.swift, ParalistWidgets/PickEntryIntent.swift, Paralist/Intents/EntryEntity.swift, ParalistWidgets/EntryWidgetView.swift, ParalistCore Store/EntryStore.swift, ParalistCore Library/WidgetPicks.swift, Paralist/App/AppPaths.swift, Paralist/App/L.swift
import ParalistCore
import WidgetKit

struct EntrySnapshot: TimelineEntry {
    enum State {
        case empty
        case missing
        case ready(Entry, children: Int)
    }

    let date: Date
    let state: State

    static var sample: EntrySnapshot {
        var entry = Entry(id: "widget-sample", type: .project, title: L.s("widget_sample"), created: .now, updated: .now)
        entry.status = .inProgress
        return EntrySnapshot(date: .now, state: .ready(entry, children: 12))
    }
}

enum WidgetData {
    static func snapshot(for id: String?) -> EntrySnapshot {
        guard let id else { return EntrySnapshot(date: .now, state: .empty) }
        let all = EntryData.entries()
        guard let entry = all.first(where: { $0.id == id }), WidgetPicks.allowed(entry) else {
            return EntrySnapshot(date: .now, state: .missing)
        }
        return EntrySnapshot(date: .now, state: .ready(entry, children: WidgetPicks.childCount(id, in: all)))
    }
}

struct EntryProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> EntrySnapshot {
        EntryData.applyLanguage()
        return .sample
    }

    func snapshot(for configuration: PickEntryIntent, in context: Context) async -> EntrySnapshot {
        EntryData.applyLanguage()
        if context.isPreview && configuration.entry == nil { return .sample }
        return WidgetData.snapshot(for: configuration.entry?.id)
    }

    func timeline(for configuration: PickEntryIntent, in context: Context) async -> Timeline<EntrySnapshot> {
        EntryData.applyLanguage()
        return Timeline(entries: [WidgetData.snapshot(for: configuration.entry?.id)], policy: .never)
    }
}
