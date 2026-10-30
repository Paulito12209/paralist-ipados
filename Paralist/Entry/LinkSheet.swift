// Zusammenhang: Entry/LinkPickerSheet.swift, Entry/EntryParts.swift (EntrySheets), Entry/EntryPickers.swift (PlaceRow), ParalistCore Library/PlacePicker.swift, ParalistCore Library/LinkPlace.swift (linkable), App/AppModel.swift
import ParalistCore
import SwiftUI

struct LinkSheet: View {
    let entry: Entry
    @Environment(AppModel.self) private var model

    var body: some View {
        let current = model.entry(entry.id) ?? entry
        let linked = Set(current.links)
        LinkPickerSheet(entry: current, pool: LinkPlace.linkable(for: current, in: model.all), isLinked: { linked.contains($0) },
                        create: { model.save(model.newEntry($0, title: $1)) }) { other in
            guard let other else { return }
            model.setLinked(current.id, other.id, linked: !linked.contains(other.id))
        }
    }
}

struct EntryPlaceSheet: View {
    let entry: Entry
    @Environment(AppModel.self) private var model

    var body: some View {
        let current = model.entry(entry.id) ?? entry
        LinkPickerSheet(entry: current, title: L.s("composer_place_title"), closes: { _ in true },
                        inbox: current.places.isEmpty, tabs: PlacePicker.tabs(for: current.type),
                        pool: PlacePicker.pool(for: current, in: model.all),
                        isLinked: { PlacePicker.isPicked($0, by: current) },
                        create: { model.save(model.newEntry($0, title: $1)) }) { other in
            let places = PlacePicker.places(for: current, picking: other)
            model.update(current.id) { var e = $0; e.places = places; return e }
            if let place = places.first, current.links.contains(place) || model.entry(place)?.links.contains(current.id) == true {
                model.setLinked(current.id, place, linked: false)
            }
        }
    }
}
