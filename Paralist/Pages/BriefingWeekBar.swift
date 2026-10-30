// Zusammenhang: Pages/BriefingPage.swift, Theme/Dimens.swift (BriefingDimens), Icons/AppIcons.swift (close, chevronLeft, chevronRight)
import ParalistCore
import SwiftUI

struct BriefingWeekBar: View {
    let week: Week
    let previous: () -> Void
    let next: () -> Void
    let close: () -> Void

    var body: some View {
        HStack(spacing: BriefingDimens.barGap) {
            Button(action: close) {
                Image(systemName: AppIcons.close).font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Palette.onSurface)
                    .frame(width: BriefingDimens.barHeight, height: BriefingDimens.barHeight)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())
            .accessibilityLabel(L.s("create_close"))
            HStack(spacing: 0) {
                arrow(AppIcons.chevronLeft, "cal_prev_week", previous)
                VStack(spacing: 8) {
                    Text(L.f("week_short", week.isoWeek)).font(.system(size: 18, design: .monospaced)).foregroundStyle(Palette.onSurface)
                        .contentTransition(.numericText())
                    ruler
                }
                .frame(maxWidth: .infinity)
                arrow(AppIcons.chevronRight, "cal_next_week", next)
            }
            .frame(height: BriefingDimens.barHeight)
            .glassEffect(.regular, in: Capsule())
        }
        .padding(.horizontal, BriefingDimens.barEdge)
        .padding(.bottom, 8)
        .animation(.snappy, value: week)
    }

    static var fade: some View {
        LinearGradient(stops: [.init(color: Palette.surface.opacity(0), location: 0), .init(color: Palette.surface.opacity(0.92), location: 0.3), .init(color: Palette.surface, location: 1)], startPoint: .top, endPoint: .bottom)
            .frame(height: BriefingDimens.barHeight + 2 * BriefingDimens.barFade)
            .allowsHitTesting(false)
    }

    private var ruler: some View {
        HStack(alignment: .center, spacing: BriefingDimens.tickGap) {
            ForEach(0..<BriefingDimens.ticks, id: \.self) { i in
                let middle = i == BriefingDimens.ticks / 2
                Capsule()
                    .fill(middle ? Palette.primary : Palette.onSurfaceVariant.opacity(i.isMultiple(of: 2) ? 0.35 : 0.6))
                    .frame(width: middle ? 2 : 1.5, height: middle || !i.isMultiple(of: 2) ? BriefingDimens.tickLong : BriefingDimens.tickShort)
            }
        }
        .accessibilityHidden(true)
    }

    private func arrow(_ icon: String, _ key: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 20, weight: .medium)).foregroundStyle(Palette.onSurface)
                .frame(width: BriefingDimens.barHeight, height: BriefingDimens.barHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L.s(key))
    }
}
