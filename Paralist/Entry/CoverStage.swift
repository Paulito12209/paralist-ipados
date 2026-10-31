// Zusammenhang: Entry/EntryHero.swift, Entry/CoverMotifLayer.swift, Entry/CoverChrome.swift, Entry/CoverHeaderVeil.swift, Entry/EntryPage.swift, Entry/CoverArtwork.swift, Entries/TypeLook.swift, Theme/Dimens.swift (cover*), Theme/Palette.swift (media*), ParalistCore Library/CoverTransition.swift
import ParalistCore
import SwiftUI

enum CoverMedia {
    case emblem
    case logo(LinkLogo)
    case image(UIImage)
    case video(URL, CGFloat?)
    case youtube(String)
    case spotify(SpotifyItem)

    var motif: CoverMotif {
        switch self {
        case .emblem: return .emblem
        case .logo: return .logo
        case .image(let image): return .image(ratio: Double(image.size.width / max(image.size.height, 1)))
        case .video(_, let ratio): return .video(ratio: Double(ratio ?? Dimens.mediaRatio))
        case .youtube: return .youtube
        case .spotify: return .spotify
        }
    }

    var isMedia: Bool {
        switch self {
        case .image, .video, .youtube: return true
        default: return false
        }
    }

    var hasEmbed: Bool {
        switch self {
        case .youtube, .spotify: return true
        default: return false
        }
    }

    var hasPlay: Bool {
        switch self {
        case .video, .youtube, .spotify: return true
        default: return false
        }
    }
}

struct CoverStage: View {
    let entry: Entry
    let media: CoverMedia
    let look: TypeLook
    let black: Bool
    let t: CGFloat
    let topInset: CGFloat
    let chrome: Bool
    let playing: Bool
    let rowTrailing: CGFloat
    let onPlay: () -> Void
    let onToggleDone: () -> Void
    let onDetail: () -> Void
    @Binding var rowFrame: CGRect

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let band = CGFloat(CoverTransition.band(width: width, topInset: topInset))
            let coverChrome = CGFloat(CoverTransition.coverChrome(t: t)) * (chrome ? 1 : 0)
            ZStack(alignment: .top) {
                backdrop(width: width, height: height, band: band)
                if !CoverHeaderVeil.covers(media, t: t, width: width, height: height, topInset: topInset) {
                    topFade.opacity(coverChrome)
                }
                CoverChrome(entry: entry, playing: playing, hasPlay: media.hasPlay, trailing: rowTrailing,
                            onPlay: onPlay, onToggleDone: onToggleDone, onDetail: onDetail, frame: $rowFrame)
                    .opacity(coverChrome)
                    .allowsHitTesting(coverChrome >= 1)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(width: width, height: height)
            .clipped()
            .animation(Motion.bars, value: chrome)
            .animation(Motion.bars, value: playing)
        }
    }

    private var artworkColor: Color {
        switch media {
        case .spotify: Palette.mediaSpotify
        case .youtube: Palette.mediaVideo
        default: look.color
        }
    }

    private var blackout: CGFloat {
        if black, media.isMedia || media.hasEmbed { return 1 }
        return media.isMedia && !chrome ? CGFloat(CoverTransition.coverChrome(t: t)) : 0
    }

    private func backdrop(width: CGFloat, height: CGFloat, band: CGFloat) -> some View {
        let artworkHeight = band + (height - band) * min(max(t, 0), 1)
        return ZStack(alignment: .top) {
            VStack(spacing: 0) {
                CoverArtwork(color: artworkColor, glow: false).frame(width: width, height: artworkHeight)
                CoverArtwork(color: artworkColor, glow: false)
                    .frame(width: width, height: artworkHeight)
                    .scaleEffect(x: 1, y: -1)
                    .mask(LinearGradient(colors: [.white, .white.opacity(0)], startPoint: .top, endPoint: .bottom))
            }
            Color.black.opacity(blackout).frame(height: artworkHeight)
        }
        .frame(width: width, height: height, alignment: .top)
        .allowsHitTesting(false)
    }

    private var topFade: some View {
        Group {
            if media.isMedia {
                LinearGradient(colors: [Palette.surfaceContainer.opacity(0.7), Palette.surfaceContainer.opacity(0)], startPoint: .top, endPoint: .bottom)
                    .frame(height: Dimens.coverTopFade)
            }
        }
        .allowsHitTesting(false)
    }
}
