// Zusammenhang: Entry/CoverStage.swift (CoverMedia), Entry/EntryHero.swift, Entry/CoverVideo.swift, Entry/EntryCover.swift (CoverEmblem, CoverLogo, CoverRatioHint), Entry/YouTubePlayer.swift, Entry/SpotifyPlayer.swift, Entry/EntryPage.swift, Theme/Dimens.swift (cover*, spotify*), ParalistCore Library/CoverTransition.swift
import AVFoundation
import ParalistCore
import SwiftUI

struct CoverMotifLayer: View {
    let media: CoverMedia
    let look: TypeLook
    let t: CGFloat
    let topInset: CGFloat
    let scrollOffset: CGFloat
    let playRequest: Int
    @Binding var playing: Bool
    @Binding var embedPlaying: Bool
    @Binding var hintFrame: CGRect
    @State private var player: AVPlayer?
    @State private var embedCommand = 0

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let band = CGFloat(CoverTransition.band(width: width, topInset: topInset))
            let frame = CoverTransition.motifFrame(t: t, motif: media.motif, width: width, height: height, topInset: topInset)
            let panelTop = band + CGFloat(CoverTransition.canvasOffset(t: t, height: height, band: band)) - scrollOffset
            ZStack(alignment: .top) {
                motif(frame: frame)
                    .mask(alignment: .top) { Rectangle().frame(height: max(panelTop, 0)) }
                ratioHint(width: width, panelTop: panelTop)
            }
            .frame(width: width, height: height)
            .clipped()
            .animation(Motion.bars, value: playing)
        }
        .onChange(of: playRequest) { togglePlay() }
        .task(id: videoURL) { player = videoURL.map { AVPlayer(url: $0) } }
    }

    private var videoURL: URL? {
        if case .video(let url, _) = media { return url }
        return nil
    }

    @ViewBuilder
    private func motif(frame: CoverFrame) -> some View {
        if media.hasEmbed {
            ScrollView { content(frame: frame).frame(width: frame.width, height: frame.height) }
                .scrollDisabled(true)
                .scrollEdgeEffectHidden(true)
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)
        } else {
            content(frame: frame)
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func content(frame: CoverFrame) -> some View {
        switch media {
        case .emblem:
            CoverEmblem(look: look)
        case .logo(let logo):
            CoverLogo(logo: logo)
        case .image(let image):
            Image(uiImage: image).resizable().scaledToFit()
        case .video:
            ZStack {
                if let player { CoverVideo(player: player, playing: $playing) }
                if !playing {
                    CoverPlayButton(playing: false, action: togglePlay)
                        .opacity(CoverTransition.detailChrome(t: t))
                        .transition(.opacity)
                }
            }
        case .spotify(let item):
            SpotifyPlayer(item: item, height: t >= 1 ? Dimens.spotifyTall : Dimens.spotifyCompact, command: embedCommand) { embedPlaying = $0 }
        case .youtube(let id):
            YouTubePlayer(videoId: id, command: embedCommand) { embedPlaying = $0 }.background(Color.black)
        }
    }

    @ViewBuilder
    private func ratioHint(width: CGFloat, panelTop: CGFloat) -> some View {
        let ratio: CGFloat? = switch media {
        case .image(let image): image.size.width / max(image.size.height, 1)
        case .video(_, let ratio): ratio ?? Dimens.mediaRatio
        default: nil
        }
        if let ratio, abs(ratio - Dimens.mediaRatio) > Dimens.coverRatioTolerance {
            CoverRatioHint()
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { hintFrame = $0 }
                .position(x: width - Dimens.coverHintEdge - Dimens.coverHintCircle / 2, y: panelTop - Dimens.coverHintLift - Dimens.coverHintCircle / 2)
                .opacity(CoverTransition.detailChrome(t: t))
                .allowsHitTesting(t <= 0 && scrollOffset <= 0)
        }
    }

    private func togglePlay() {
        if let player {
            CoverVideo.toggle(player, playing: playing)
        } else if media.hasEmbed {
            embedCommand += 1
        }
    }
}
