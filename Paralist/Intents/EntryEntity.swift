// Zusammenhang: Paralist/Intents/OpenEntryIntent.swift, Paralist/Intents/ParalistShortcuts.swift, ParalistWidgets/PickEntryIntent.swift, ParalistWidgets/EntryProvider.swift, ParalistCore Library/WidgetPicks.swift, Paralist/Entries/TypeLook.swift, Paralist/App/L.swift, Paralist/App/AppPaths.swift, project.yml
import AppIntents
import ParalistCore

enum EntryData {
    static func applyLanguage() {
        L.apply(AppLanguage.fromTag(AppPaths.defaults.string(forKey: "app_language")) ?? L.systemLanguage)
    }

    static func entries() -> [Entry] {
        EntryStore(root: AppPaths.root).scan().entries
    }
}

struct EntryEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "widget_entity")
    static let defaultQuery = EntryQuery()

    let id: String
    let title: String
    let kind: String

    init(_ entry: Entry) {
        id = entry.id
        title = entry.title.isEmpty ? L.s("list_untitled") : entry.title
        kind = L.s(TypeLook.of(entry.type).label)
    }

    init(missing id: String) {
        self.id = id
        title = L.s("widget_missing")
        kind = ""
    }

    var displayRepresentation: DisplayRepresentation {
        kind.isEmpty ? DisplayRepresentation(title: "\(title)") : DisplayRepresentation(title: "\(title)", subtitle: "\(kind)")
    }
}

struct EntryQuery: EntityStringQuery {
    func entities(for identifiers: [EntryEntity.ID]) async throws -> [EntryEntity] {
        EntryData.applyLanguage()
        let all = EntryData.entries()
        return identifiers.map { id in all.first { $0.id == id && WidgetPicks.allowed($0) }.map(EntryEntity.init) ?? EntryEntity(missing: id) }
    }

    func entities(matching string: String) async throws -> [EntryEntity] {
        EntryData.applyLanguage()
        return WidgetPicks.candidates(EntryData.entries(), matching: string).map(EntryEntity.init)
    }

    func suggestedEntities() async throws -> [EntryEntity] {
        EntryData.applyLanguage()
        return WidgetPicks.candidates(EntryData.entries()).map(EntryEntity.init)
    }
}
