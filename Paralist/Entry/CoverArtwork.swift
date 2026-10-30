// Zusammenhang: Entry/EntryCover.swift, Entry/CoverStage.swift, Theme/Palette.swift (cover*), ParalistWidgets/EntryWidgetView.swift
import SwiftUI

struct CoverArtwork: View {
    let color: Color
    var glow = true
    @Environment(\.colorScheme) private var colorScheme
    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        ZStack {
            EllipticalGradient(
                stops: [
                    .init(color: surface(0), location: 0),
                    .init(color: surface(0.05), location: 0.52),
                    .init(color: surface(0.24), location: 0.82),
                    .init(color: surface(0.46), location: 1),
                ],
                center: UnitPoint(x: 0.5, y: 0.46),
                startRadiusFraction: 0,
                endRadiusFraction: 0.76
            )
            LinearGradient(
                stops: [
                    .init(color: core(0), location: 0),
                    .init(color: core(0.18), location: 0.16),
                    .init(color: core(0.72), location: 0.30),
                    .init(color: core(0.94), location: 0.44),
                    .init(color: core(0.94), location: 0.58),
                    .init(color: core(0.68), location: 0.72),
                    .init(color: core(0.14), location: 0.86),
                    .init(color: core(0), location: 1),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .mask(columnMask)
            if glow {
                EllipticalGradient(
                    stops: [
                        .init(color: silverGlow.opacity(isDark ? 0.48 : 0.58), location: 0),
                        .init(color: silverGlow.opacity(isDark ? 0.20 : 0.26), location: 0.5),
                        .init(color: .clear, location: 1),
                    ],
                    center: UnitPoint(x: 0.5, y: 1.04),
                    startRadiusFraction: 0,
                    endRadiusFraction: 0.68
                )
            }
        }
        .drawingGroup()
        .accessibilityHidden(true)
    }

    private var columnMask: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .white.opacity(0), location: 0),
                .init(color: .white.opacity(0.35), location: 0.14),
                .init(color: .white.opacity(0.92), location: 0.30),
                .init(color: .white, location: 0.52),
                .init(color: .white.opacity(0.86), location: 0.78),
                .init(color: .white.opacity(0.55), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func surface(_ lightening: Double) -> Color {
        if isDark { return color.mix(with: Palette.coverInk, by: 0.16).mix(with: .white, by: lightening) }
        return color.mix(with: .white, by: 0.44 + lightening * 0.7)
    }

    private func core(_ strength: Double) -> Color {
        let base = isDark ? color.mix(with: Palette.coverCore, by: 0.92) : Palette.coverLight
        return base.opacity(strength * (isDark ? 1 : 0.68))
    }

    private var silverGlow: Color {
        isDark
            ? color.mix(with: Palette.coverSilver, by: 0.66).mix(with: .black, by: 0.10)
            : Palette.coverSilver.mix(with: .white, by: 0.52)
    }
}
