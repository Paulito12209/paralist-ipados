// Zusammenhang: Pages/MediaPage.swift, Files/Thumbnails.swift, App/AppModel.swift (attachmentURL), Icons/AppIcons.swift
import ParalistCore
import SwiftUI

struct MediaCell: View {
    let entry: Entry
    let onOpen: () -> Void
    @Environment(AppModel.self) private var model
    @State private var frame: UIImage?

    var body: some View {
        let kind = MediaKind.of(entry)
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay { content(kind).allowsHitTesting(false) }
            .background(Palette.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: MediaDimens.radius))
            .contentShape(Rectangle())
            .onTapGesture(perform: onOpen)
            .task(id: entry.id) { await loadFrame(kind) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(entry.title.isEmpty ? (entry.attachment?.name ?? L.s("list_untitled")) : entry.title)
            .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private func content(_ kind: MediaKind?) -> some View {
        if let preview = kind == .image ? imagePreview : frame {
            Image(uiImage: preview).resizable().scaledToFill()
                .overlay(alignment: .bottomLeading) {
                    if kind == .video { Image(systemName: AppIcons.play).font(.system(size: 12)).foregroundStyle(.white).padding(6) }
                }
        } else {
            Image(systemName: kind == .video ? AppIcons.video : kind == .audio ? AppIcons.audio : AppIcons.image)
                .font(.system(size: 26)).foregroundStyle(Palette.onSurfaceVariant)
        }
    }

    private var imagePreview: UIImage? {
        guard let url = model.attachmentURL(entry) else { return nil }
        return Thumbnails.image(url, side: 320)
    }

    private func loadFrame(_ kind: MediaKind?) async {
        guard kind == .video, let url = model.attachmentURL(entry) else { return }
        frame = await Thumbnails.videoFrame(url, side: 320)
    }
}
