// Zusammenhang: Entry/EntryPage.swift, Entry/CoverStage.swift (CoverMedia), Entry/CoverMotifLayer.swift, Entry/CoverHeaderVeil.swift, Entry/EntryCanvasPanel.swift, Net/LinkColors.swift, Net/LinkIcons.swift, Files/AttachmentPreview.swift, Files/Thumbnails.swift, ParalistCore Links/VideoLinks.swift, Links/SpotifyLinks.swift
import AVFoundation
import ParalistCore
import SwiftUI

struct EntryHero<Panel: View>: View {
    let entry: Entry
    let t: CGFloat
    let topInset: CGFloat
    let chrome: Bool
    let scrollOffset: CGFloat
    let rowTrailing: CGFloat
    let playRequest: Int
    @Binding var playing: Bool
    @Binding var embedPlaying: Bool
    @Binding var rowFrame: CGRect
    @Binding var hintFrame: CGRect
    let onPlay: () -> Void
    let onToggleDone: () -> Void
    @ViewBuilder let panel: () -> Panel
    @Environment(AppModel.self) private var model
    @State private var linkColor: UInt32?
    @State private var logo: LinkLogo?
    @State private var videoRatio: CGFloat?

    var body: some View {
        content
            .task(id: entry.url) {
                guard entry.type == .bookmark, let url = entry.url, VideoLinks.youtubeId(url) == nil, SpotifyLinks.item(url) == nil else { return }
                async let color = LinkColors.shared.color(url)
                async let icon = LinkIcons.shared.icon(url)
                linkColor = await color
                logo = await icon
            }
            .task(id: videoFile) {
                if let video = videoFile { videoRatio = await Self.ratio(video) }
            }
    }

    @ViewBuilder
    private var content: some View {
        let base = TypeLook.of(entry)
        let look = linkColor.map { TypeLook(color: Palette.fixed($0), icon: base.icon, label: base.label, hint: base.hint) } ?? base
        let media = media
        ZStack(alignment: .top) {
            if let media {
                CoverStage(entry: entry, media: media, look: look, black: model.prefs.blackMediaBackdrop, t: t, topInset: topInset, chrome: chrome,
                           playing: playing || embedPlaying, rowTrailing: rowTrailing, onPlay: onPlay, onToggleDone: onToggleDone, rowFrame: $rowFrame)
                    .ignoresSafeArea()
            }
            panel()
            if let media {
                CoverMotifLayer(media: media, look: look, t: t, topInset: topInset, scrollOffset: scrollOffset, playRequest: playRequest,
                           playing: $playing, embedPlaying: $embedPlaying, hintFrame: $hintFrame)
                    .ignoresSafeArea()
            }
            if let media {
                CoverHeaderVeil(media: media, t: t, topInset: topInset, chrome: chrome).ignoresSafeArea()
            }
        }
    }

    var media: CoverMedia? {
        if let url = entry.url, let videoId = VideoLinks.youtubeId(url) { return .youtube(videoId) }
        if let url = entry.url, let item = SpotifyLinks.item(url) { return .spotify(item) }
        if let image = imageFile { return .image(image) }
        if let video = videoFile { return .video(video, videoRatio) }
        if let logo { return .logo(logo) }
        return .emblem
    }

    private var imageFile: UIImage? {
        guard let attachment = entry.attachment, attachment.mime.hasPrefix("image/"), let file = model.attachmentURL(entry) else { return nil }
        return Thumbnails.image(file, side: 1600)
    }

    private var videoFile: URL? {
        guard let attachment = entry.attachment, attachment.mime.hasPrefix("video/") else { return nil }
        return model.attachmentPreviewURL(entry)
    }

    static func ratio(_ url: URL) async -> CGFloat {
        guard let track = try? await AVURLAsset(url: url).loadTracks(withMediaType: .video).first,
              let (size, transform) = try? await track.load(.naturalSize, .preferredTransform) else { return Dimens.mediaRatio }
        let turned = size.applying(transform)
        let width = abs(turned.width), height = abs(turned.height)
        return width > 0 && height > 0 ? width / height : Dimens.mediaRatio
    }
}

struct AttachmentCard: View {
    let attachment: Attachment
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 12) {
                Image(systemName: attachment.mime.hasPrefix("image/") ? AppIcons.image : AppIcons.file.outlined).font(.system(size: 22)).foregroundStyle(Palette.onSurfaceVariant)
                VStack(alignment: .leading, spacing: 2) {
                    Text(attachment.name).font(Typo.bodyLarge).foregroundStyle(Palette.onSurface).lineLimit(1)
                    Text("\(attachment.mime) · \(Self.formatSize(attachment.size))").font(Typo.bodySmall).foregroundStyle(Palette.onSurfaceVariant)
                }
                Spacer(minLength: 0)
                Image(systemName: AppIcons.openExternal).font(.system(size: 17)).foregroundStyle(Palette.onSurfaceVariant)
            }
            .padding(16)
            .background(Palette.surfaceLow, in: RoundedRectangle(cornerRadius: Dimens.cardRadius))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityLabel(L.s("entry_file_open"))
    }

    static func formatSize(_ size: Int64) -> String {
        if size >= 1_048_576 { return String(format: "%.1f MB", Double(size) / 1_048_576) }
        if size >= 1024 { return "\(size / 1024) KB" }
        return "\(size) B"
    }
}
