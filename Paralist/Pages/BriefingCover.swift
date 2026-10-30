// Zusammenhang: Pages/BriefingPage.swift, Theme/Palette.swift (briefing*), Theme/Dimens.swift (BriefingDimens), Icons/AppIcons.swift (briefing)
import SwiftUI

struct BriefingCover: View {
    let week: Int
    let seen: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            backdrop
            tiles
            Capsule().fill(.white.opacity(0.35))
                .frame(width: BriefingDimens.grabberWidth, height: BriefingDimens.grabberHeight)
                .frame(maxWidth: .infinity)
                .padding(.top, BriefingDimens.grabberTop)
            VStack(alignment: .leading, spacing: 8) {
                Spacer(minLength: 0)
                badge
                Text(L.s("menu_briefing")).font(Typo.pageTitle).foregroundStyle(.white)
            }
            .padding(.horizontal, BriefingDimens.edge)
            .padding(.bottom, 12)
        }
        .frame(height: BriefingDimens.coverHeight)
        .clipped()
        .overlay(alignment: .bottom) { Rectangle().fill(.white.opacity(0.08)).frame(height: 1) }
    }

    private var backdrop: some View {
        ZStack {
            Palette.briefingInk
            RadialGradient(colors: [Palette.briefingGlowWarm.opacity(0.85), .clear], center: UnitPoint(x: 0.5, y: 0.35), startRadius: 0, endRadius: 220)
            RadialGradient(colors: [Palette.briefingGlowCool.opacity(0.8), .clear], center: UnitPoint(x: 1, y: 0.2), startRadius: 0, endRadius: 200)
            RadialGradient(colors: [Palette.briefingGlowGreen.opacity(0.6), .clear], center: UnitPoint(x: 0.95, y: 0.95), startRadius: 0, endRadius: 180)
            LinearGradient(colors: [.black.opacity(0.75), .clear], startPoint: .leading, endPoint: UnitPoint(x: 0.55, y: 0.5))
        }
        .accessibilityHidden(true)
    }

    private var tiles: some View {
        GeometryReader { geo in
            let w = geo.size.width
            tile(BriefingDimens.tileSmall, angle: -8, icon: false).opacity(0.75).position(x: w - 104, y: 70)
            tile(BriefingDimens.tile, angle: -15, icon: true).position(x: w - 52, y: 62)
            tile(BriefingDimens.tileSmall, angle: -8, icon: false).opacity(0.75).position(x: w + 6, y: 46)
        }
        .accessibilityHidden(true)
    }

    private func tile(_ size: CGFloat, angle: Double, icon: Bool) -> some View {
        RoundedRectangle(cornerRadius: BriefingDimens.tileRadius, style: .continuous)
            .fill(Palette.briefingTile)
            .frame(width: size, height: size)
            .overlay {
                if icon {
                    Image(systemName: AppIcons.briefing).font(.system(size: BriefingDimens.tileIcon, weight: .regular))
                        .foregroundStyle(Palette.briefingRead.opacity(0.85))
                        .shadow(color: Palette.briefingRead.opacity(0.5), radius: 6)
                }
            }
            .shadow(color: .black.opacity(0.45), radius: 10, y: 5)
            .rotationEffect(.degrees(angle))
    }

    private var badge: some View {
        HStack(spacing: 10) {
            Text(L.f("week_short", week))
            Rectangle().fill(.white.opacity(0.25)).frame(width: 1, height: 14)
            Text(L.s(seen ? "briefing_status_read" : "briefing_status_new")).foregroundStyle(seen ? Palette.briefingRead : .white.opacity(0.85))
        }
        .font(.system(size: 14, design: .monospaced))
        .foregroundStyle(.white)
        .padding(.horizontal, 12).frame(height: BriefingDimens.badgeHeight)
        .background(.black.opacity(0.35), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.22), lineWidth: 1))
    }
}
