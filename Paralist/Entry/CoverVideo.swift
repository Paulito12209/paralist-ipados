// Zusammenhang: Entry/CoverStage.swift, Entry/CoverChrome.swift, Theme/Dimens.swift (coverPlay*), Theme/Palette.swift, Icons/AppIcons.swift
import AVFoundation
import SwiftUI
import UIKit

struct CoverVideo: View {
    let player: AVPlayer
    @Binding var playing: Bool

    var body: some View {
        CoverVideoLayer(player: player)
            .onReceive(player.publisher(for: \.timeControlStatus)) { playing = $0 != .paused }
            .onReceive(NotificationCenter.default.publisher(for: AVPlayerItem.didPlayToEndTimeNotification, object: player.currentItem)) { _ in
                player.seek(to: .zero)
            }
            .onDisappear { player.pause() }
    }

    static func toggle(_ player: AVPlayer, playing: Bool) {
        if playing {
            player.pause()
        } else {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            player.play()
        }
    }
}

struct CoverPlayButton: View {
    let playing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: playing ? AppIcons.pause : AppIcons.play)
                .font(.system(size: Dimens.coverPlayIcon, weight: .semibold))
                .foregroundStyle(Palette.surfaceContainer)
                .frame(width: Dimens.coverPlay, height: Dimens.coverPlay)
                .background(Palette.onSurface, in: Circle())
                .contentShape(Circle())
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L.s(playing ? "share_audio_pause" : "share_audio_play"))
    }
}

private struct CoverVideoLayer: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .black
        view.playerLayer.videoGravity = .resizeAspectFill
        view.playerLayer.player = player
        return view
    }

    func updateUIView(_ view: PlayerView, context: Context) {
        if view.playerLayer.player !== player { view.playerLayer.player = player }
    }

    final class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}
