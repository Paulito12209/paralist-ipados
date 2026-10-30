// Zusammenhang: Entry/EntryHero.swift, Entry/CoverStage.swift (CoverMedia, topFade), Entry/CoverMotifLayer.swift, Theme/Dimens.swift (coverVeil*), ParalistCore Library/CoverTransition.swift, docs/cover.md
import ParalistCore
import SwiftUI

struct CoverHeaderVeil: View {
    let media: CoverMedia
    let t: CGFloat
    let topInset: CGFloat
    let chrome: Bool

    var body: some View {
        GeometryReader { geo in
            let height = topInset + Dimens.coverVeilTail
            let solid = max(topInset - Dimens.navBarClearance / 2, 0) / height
            let shown = Self.covers(media, t: t, width: geo.size.width, height: geo.size.height, topInset: topInset)
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                    .mask(LinearGradient(stops: [.init(color: .black, location: 0), .init(color: .black, location: solid), .init(color: .clear, location: 1)], startPoint: .top, endPoint: .bottom))
                LinearGradient(stops: [.init(color: Palette.surfaceContainer.opacity(Dimens.coverVeilShade), location: 0), .init(color: Palette.surfaceContainer.opacity(Dimens.coverVeilShade), location: solid), .init(color: Palette.surfaceContainer.opacity(0), location: 1)], startPoint: .top, endPoint: .bottom)
            }
            .frame(height: height)
            .opacity(shown ? CGFloat(CoverTransition.coverChrome(t: t)) * (chrome ? 1 : 0) : 0)
            .animation(Motion.bars, value: chrome)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    static func covers(_ media: CoverMedia, t: CGFloat, width: CGFloat, height: CGFloat, topInset: CGFloat) -> Bool {
        switch media {
        case .image, .video: break
        default: return false
        }
        let frame = CoverTransition.motifFrame(t: t, motif: media.motif, width: width, height: height, topInset: topInset)
        return frame.y < topInset
    }
}
