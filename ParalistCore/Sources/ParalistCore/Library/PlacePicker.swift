// Zusammenhang: Library/LinkPicker.swift, Library/EntryParent.swift (descends), Library/ComposerDraft.swift (pick), Model/EntryCodec.swift (orte), Paralist/Entry/LinkSheet.swift (EntryPlaceSheet), Paralist/Entry/LinkPickerSheet.swift, ParalistShare/ShareView.swift, Paralist/Entry/EntryPickers.swift (PlaceRow), Paralist/Entry/EntryBlocks.swift (related), Paralist/Composer/ComposerParts.swift, Tests/ParalistCoreTests/PlacePickerTests.swift
import Foundation

public enum PlacePicker {
    public static func tabs(for type: EntryType) -> [LinkTab] {
        switch type {
        case .area, .tag: return [.tags]
        case .project: return [.areas, .tags]
        default: return LinkPicker.tabs(for: type)
        }
    }

    public static func pool(for entry: Entry, in all: [Entry]) -> [Entry] {
        let allowed = Set(tabs(for: entry.type).flatMap(\.types))
        let byId = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        return all.filter { $0.id != entry.id && allowed.contains($0.type) && !EntryParent.descends($0, from: entry.id, byId) }
    }

    public static func isPicked(_ id: String, by entry: Entry) -> Bool { entry.places.first == id }

    public static func places(for entry: Entry, picking other: Entry?) -> [String] {
        guard let other, entry.places.first != other.id, other.id != entry.id,
              tabs(for: entry.type).contains(where: { $0.types.contains(other.type) }) else { return [] }
        return [other.id]
    }
}
