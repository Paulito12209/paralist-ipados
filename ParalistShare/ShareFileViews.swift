// Zusammenhang: ParalistShare/ShareView.swift, ParalistShare/ShareModel.swift, Paralist/Files/Thumbnails.swift, Paralist/Icons/AppIcons.swift, Paralist/Theme/*
import AVKit
import ParalistCore
import SwiftUI

struct SharePreview: View {
    let item: SharedItem

    var body: some View {
        switch item.kind {
        case .image:
            if let image = Thumbnails.image(item.url, side: 1200) {
                Image(uiImage: image).resizable().scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 320)
                    .background(Palette.surfaceLow)
                    .listRowInsets(EdgeInsets())
            } else {
                FileRow(item: item, icon: AppIcons.image)
            }
        case .video:
            ShareVideo(url: item.url)
                .aspectRatio(16 / 9, contentMode: .fit)
                .listRowInsets(EdgeInsets())
        case .audio:
            ShareAudio(item: item)
        default:
            FileRow(item: item, icon: AppIcons.document.outlined)
        }
    }
}

struct FileRow<Accessory: View>: View {
    let item: SharedItem
    let icon: String
    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 22)).foregroundStyle(item.failure == nil ? Palette.primary : Palette.error).frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(Typo.bodyLarge).foregroundStyle(Palette.onSurface).lineLimit(2)
                Text(item.size.formatted(.byteCount(style: .file))).font(Typo.bodySmall).foregroundStyle(Palette.onSurfaceVariant)
            }
            Spacer(minLength: 0)
            accessory()
        }
    }
}

extension FileRow where Accessory == EmptyView {
    init(item: SharedItem, icon: String) {
        self.init(item: item, icon: icon) { EmptyView() }
    }
}

struct ShareVideo: View {
    let url: URL
    @State private var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .background(Color.black)
            .onAppear { if player == nil { player = AVPlayer(url: url) } }
            .onDisappear { player?.pause() }
    }
}

struct ShareAudio: View {
    let item: SharedItem
    @State private var player: AVPlayer?
    @State private var playing = false

    var body: some View {
        FileRow(item: item, icon: AppIcons.audio) {
            Button {
                if player == nil { player = AVPlayer(url: item.url) }
                if playing { player?.pause() } else { player?.play() }
                playing.toggle()
            } label: {
                Image(systemName: playing ? AppIcons.pause : AppIcons.play)
                    .font(.system(size: 17))
                    .frame(width: 44, height: 44)
                    .background(Palette.secondaryContainer, in: Circle())
                    .foregroundStyle(Palette.onSecondaryContainer)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L.s(playing ? "share_audio_pause" : "share_audio_play"))
        }
        .onReceive(NotificationCenter.default.publisher(for: AVPlayerItem.didPlayToEndTimeNotification)) { note in
            guard let ended = note.object as? AVPlayerItem, ended === player?.currentItem else { return }
            playing = false
            player?.seek(to: .zero)
        }
        .onDisappear { player?.pause() }
    }
}
