// Zusammenhang: Icons/AppIcons.swift, Shell/RootView.swift, Composer/CreateSheet.swift, Pages/MenuPage.swift, Entry/EdgePicker.swift
import SwiftUI

struct XoolMenuIcon: View {
    var progress: Double = 0
    var color: Color = Palette.onSurface
    var dot: Color = Palette.menuDot

    var body: some View {
        Canvas { context, size in
            let unit = min(size.width / 32, size.height / 24)
            let origin = CGPoint(x: (size.width - 32 * unit) / 2, y: (size.height - 24 * unit) / 2)
            let p = progress
            func transform(_ dy: Double, _ angle: Double) -> CGAffineTransform {
                CGAffineTransform(translationX: origin.x, y: origin.y).scaledBy(x: unit, y: unit)
                    .translatedBy(x: 16, y: 12).rotated(by: angle * .pi / 180).translatedBy(x: -16, y: -12)
                    .translatedBy(x: 0, y: dy)
            }
            let bars: [(Double, Double, Double, [(CGPoint, Double)])] = [
                (2, 6 * p, 45 * p, [(CGPoint(x: 6, y: 6), 2), (CGPoint(x: 26, y: 6), 2 * p)]),
                (14, -6 * p, -45 * p, [(CGPoint(x: 26, y: 18), 2), (CGPoint(x: 6, y: 18), 2 * p)]),
            ]
            context.drawLayer { layer in
                for (y, dy, angle, knobs) in bars {
                    let t = transform(dy, angle)
                    layer.fill(Path(roundedRect: CGRect(x: 2, y: y, width: 28, height: 8), cornerRadius: 4).applying(t), with: .color(color))
                    layer.blendMode = .clear
                    for (center, radius) in knobs where radius > 0 {
                        layer.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)).applying(t), with: .color(.black))
                    }
                    layer.blendMode = .normal
                    if p > 0 {
                        for (center, radius) in knobs where radius > 0 {
                            layer.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)).applying(t), with: .color(dot.opacity(p)))
                        }
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}

struct XoolPlusShape: Shape {
    var progress: Double = 0

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 10.2, y: 6.2))
        p.addQuadCurve(to: CGPoint(x: 6.2, y: 10.2), control: CGPoint(x: 10.2, y: 10.2))
        p.addLine(to: CGPoint(x: 2.9, y: 10.2))
        p.addQuadCurve(to: CGPoint(x: 2.2, y: 12), control: CGPoint(x: 2.2, y: 10.2))
        p.addQuadCurve(to: CGPoint(x: 2.9, y: 13.8), control: CGPoint(x: 2.2, y: 13.8))
        p.addLine(to: CGPoint(x: 6.2, y: 13.8))
        p.addQuadCurve(to: CGPoint(x: 10.2, y: 17.8), control: CGPoint(x: 10.2, y: 13.8))
        p.addLine(to: CGPoint(x: 10.2, y: 21.1))
        p.addQuadCurve(to: CGPoint(x: 12, y: 21.8), control: CGPoint(x: 10.2, y: 21.8))
        p.addQuadCurve(to: CGPoint(x: 13.8, y: 21.1), control: CGPoint(x: 13.8, y: 21.8))
        p.addLine(to: CGPoint(x: 13.8, y: 17.8))
        p.addQuadCurve(to: CGPoint(x: 17.8, y: 13.8), control: CGPoint(x: 13.8, y: 13.8))
        p.addLine(to: CGPoint(x: 21.1, y: 13.8))
        p.addQuadCurve(to: CGPoint(x: 21.8, y: 12), control: CGPoint(x: 21.8, y: 13.8))
        p.addQuadCurve(to: CGPoint(x: 21.1, y: 10.2), control: CGPoint(x: 21.8, y: 10.2))
        p.addLine(to: CGPoint(x: 17.8, y: 10.2))
        p.addQuadCurve(to: CGPoint(x: 13.8, y: 6.2), control: CGPoint(x: 13.8, y: 10.2))
        p.addLine(to: CGPoint(x: 13.8, y: 2.9))
        p.addQuadCurve(to: CGPoint(x: 12, y: 2.2), control: CGPoint(x: 13.8, y: 2.2))
        p.addQuadCurve(to: CGPoint(x: 10.2, y: 2.9), control: CGPoint(x: 10.2, y: 2.2))
        p.closeSubpath()
        let scale = min(rect.width, rect.height) / 24
        let t = CGAffineTransform(translationX: rect.midX, y: rect.midY)
            .rotated(by: progress * .pi / 4).scaledBy(x: scale, y: scale).translatedBy(x: -12, y: -12)
        return p.applying(t)
    }
}

struct XoolPlusIcon: View {
    var progress: Double = 0
    var color: Color = Palette.onSurface

    var body: some View {
        XoolPlusShape(progress: progress).fill(color).accessibilityHidden(true)
    }
}

struct XoolSlidersIcon: View {
    var color: Color?
    var line: Double = 1.6

    var body: some View {
        Canvas { context, size in
            let unit = min(size.width, size.height) / 24
            let origin = CGPoint(x: (size.width - 24 * unit) / 2, y: (size.height - 24 * unit) / 2)
            func point(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: origin.x + x * unit, y: origin.y + y * unit) }
            let stroke = StrokeStyle(lineWidth: line * unit, lineCap: .round)
            let ink: GraphicsContext.Shading = color.map { .color($0) } ?? .foreground
            var bars = Path()
            bars.move(to: point(11, 8))
            bars.addLine(to: point(17.6, 8))
            bars.move(to: point(6.4, 16))
            bars.addLine(to: point(13, 16))
            context.stroke(bars, with: ink, style: stroke)
            for center in [point(8, 8), point(16, 16)] {
                let r = 2.4 * unit
                let ring = Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r))
                context.stroke(ring, with: ink, style: stroke)
            }
        }
        .accessibilityHidden(true)
    }
}

struct XoolPageShape: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        let unit = min(rect.width, rect.height) / 24
        let t = CGAffineTransform(translationX: rect.midX - 12 * unit, y: rect.midY - 12 * unit).scaledBy(x: unit, y: unit)
        var p = Path(roundedRect: CGRect(x: 4, y: 3, width: 16, height: 10), cornerRadius: 2.5)
            .strokedPath(StrokeStyle(lineWidth: 2))
        p.addPath(Path(roundedRect: CGRect(x: 3, y: 16, width: 18, height: 2), cornerRadius: 1))
        p.addPath(Path(roundedRect: CGRect(x: 3, y: 20, width: 12, height: 2), cornerRadius: 1))
        return p.applying(t)
    }
}
