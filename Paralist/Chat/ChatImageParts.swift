// Zusammenhang: Chat/ChatInputBar.swift, Chat/ChatBubble.swift, Chat/ChatThreadPage.swift (Quick Look), Chat/ChatImagePickers.swift, Files/Thumbnails.swift, Files/AttachmentPreview.swift, ParalistCore Links/FileKind.swift, Theme/Dimens.swift (ComposerDimens, ChatDimens), Icons/AppIcons.swift
import ParalistCore
import SwiftUI

enum ChatImages {
    static func previewURL(_ hash: String, store: EntryStore) -> URL? {
        guard let file = store.attachmentFile(hash), let handle = try? FileHandle(forReadingFrom: file) else { return nil }
        defer { try? handle.close() }
        let head = (try? handle.read(upToCount: 4096)) ?? Data()
        let kind = FileKind.detect(Array(head)) ?? .jpeg
        return AttachmentPreview.url(for: Attachment(hash: hash, name: L.s("chat_image"), mime: kind.mime, size: 0), source: file)
    }
}

struct ChatImageTile: View {
    let url: URL?
    let remove: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: ComposerDimens.tileRadius, style: .continuous)
        ZStack {
            if let url, let image = Thumbnails.image(url, side: ComposerDimens.tile * 3) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Palette.composerButton
                Image(systemName: AppIcons.image).font(.system(size: 19)).foregroundStyle(Palette.onSurfaceVariant)
            }
        }
        .frame(width: ComposerDimens.tile, height: ComposerDimens.tile)
        .clipShape(shape)
        .overlay { shape.strokeBorder(Palette.onSurface.opacity(0.1), lineWidth: 1) }
        .overlay(alignment: .topTrailing) {
            Button(action: remove) {
                Image(systemName: AppIcons.close)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Palette.surface)
                    .frame(width: ComposerDimens.tileClose, height: ComposerDimens.tileClose)
                    .background(Palette.onSurface.opacity(0.8), in: Circle())
                    .overlay { Circle().strokeBorder(Palette.surface.opacity(0.6), lineWidth: 1) }
                    .padding(ComposerDimens.tileCloseInset)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L.s("file_remove"))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L.s("chat_image"))
    }
}

struct ChatImageButton: View {
    let enabled: Bool
    let pickPhoto: () -> Void
    let capture: (ChatCapture) -> Void

    var body: some View {
        Menu {
            Button(action: pickPhoto) { Label(L.s("chat_image_photos"), systemImage: AppIcons.image) }
            Button { capture(.camera) } label: { Label(L.s("chat_image_camera"), systemImage: AppIcons.camera) }
            Button { capture(.scan) } label: { Label(L.s("chat_image_scan"), systemImage: AppIcons.scanDocument) }
        } label: {
            Image(systemName: AppIcons.addImage)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Palette.onSurface)
                .frame(width: ComposerDimens.button, height: ComposerDimens.button)
                .background(Palette.composerButton, in: Circle())
                .opacity(enabled ? 1 : 0.4)
        }
        .disabled(!enabled)
        .accessibilityLabel(L.s("chat_image"))
    }
}

struct ChatBubbleImage: View {
    let url: URL
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            if let image = Thumbnails.image(url, side: ChatDimens.bubbleImage * 3) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: ChatDimens.bubbleImage, maxHeight: ChatDimens.bubbleImage)
                    .clipShape(RoundedRectangle(cornerRadius: ChatDimens.bubbleImageRadius, style: .continuous))
            } else {
                Image(systemName: AppIcons.image).font(.system(size: 24)).foregroundStyle(Palette.onPrimaryContainer)
                    .frame(width: ComposerDimens.tile, height: ComposerDimens.tile)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L.s("chat_image_open"))
    }
}
