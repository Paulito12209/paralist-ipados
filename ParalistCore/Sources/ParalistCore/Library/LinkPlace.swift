// Zusammenhang: Library/PlacePicker.swift, Library/EntryLibrary.swift (setLinked, dropPlaceLinks), Model/EntryChanges.swift, Library/ComposerDraft.swift (linkTo), Paralist/Composer/ComposerSheet.swift, Paralist/App/AppModel.swift, Tests/ParalistCoreTests/LinkPlaceTests.swift
import Foundation

public enum LinkPlace {
    public static func deck(for type: EntryType, linkedTo partner: Entry) -> String? {
        type == .flashcard && partner.type == .deck && !partner.archived ? partner.id : nil
    }

    public static func adopted(_ entry: Entry, linkedTo partner: Entry) -> Entry {
        var e = entry
        if entry.deck == nil, let id = deck(for: entry.type, linkedTo: partner) { e.deck = id }
        return e
    }

    public static func linkable(for entry: Entry, in all: [Entry]) -> [Entry] {
        all.filter { !entry.places.contains($0.id) && !$0.places.contains(entry.id) }
    }

    public static func repaired(_ entries: [Entry]) -> [Entry] {
        let byId = Dictionary(entries.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        var fixed: [String: Entry] = [:]
        for entry in entries {
            guard let place = entry.places.first, place != entry.id else { continue }
            let mine = fixed[entry.id] ?? entry
            fixed[entry.id] = EntryChanges.withLink(mine, place, linked: false)
            if let parent = fixed[place] ?? byId[place] {
                fixed[place] = EntryChanges.withLink(parent, entry.id, linked: false)
            }
        }
        return entries.compactMap { fixed[$0.id] }.filter { $0 != byId[$0.id] }
    }
}
