// Zusammenhang: Shell/RouteDestination.swift, Shell/DetailHost.swift, Shell/MediaPager.swift, Entry/EntryPage.swift
import ParalistCore
import SwiftUI

struct EntryDestination: View {
    let id: String
    var cover = false
    var nested = false
    @Environment(AppModel.self) private var model

    var body: some View {
        let bare = Self.bare(model.entry(id))
        EntryPage(id: id, start: cover || bare ? .cover : .actions, bare: bare, nested: nested)
    }

    static func bare(_ entry: Entry?) -> Bool {
        guard let entry, [.file, .document].contains(entry.type), let attachment = entry.attachment else { return false }
        return [.photo, .video].contains(FileCategory.of(attachment))
    }
}
