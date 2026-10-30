// Zusammenhang: Chat/ChatMascotStage.swift, Chat/ChatMascotScenes.swift, Chat/ChatMascotActor.swift (MascotProp), Theme/Palette.swift (mascotCard, mascotRocket*), Theme/Dimens.swift (MascotDimens)
import SwiftUI

enum MascotProp: Equatable {
    case card, rocket

    var size: CGSize {
        switch self {
        case .card: return CGSize(width: MascotDimens.cardWidth, height: MascotDimens.cardHeight)
        case .rocket: return CGSize(width: MascotDimens.rocketWidth, height: MascotDimens.rocketHeight)
        }
    }
}

struct MascotCardProp: View {
    var split: CGFloat

    var body: some View {
        let w = MascotDimens.cardWidth
        let h = MascotDimens.cardHeight
        ZStack {
            half(leading: true)
                .rotationEffect(.degrees(-28 * split), anchor: .bottomLeading)
                .offset(x: -7 * split, y: 9 * split)
            half(leading: false)
                .rotationEffect(.degrees(28 * split), anchor: .bottomTrailing)
                .offset(x: 7 * split, y: 9 * split)
        }
        .frame(width: w, height: h)
    }

    private func half(leading: Bool) -> some View {
        let w = MascotDimens.cardWidth
        let h = MascotDimens.cardHeight
        return card
            .frame(width: w, height: h)
            .mask(alignment: leading ? .leading : .trailing) {
                MascotTear(leading: leading)
            }
    }

    private var card: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous).fill(Palette.mascotCard)
            RoundedRectangle(cornerRadius: 4, style: .continuous).strokeBorder(Palette.outlineVariant)
            VStack(alignment: .leading, spacing: 4) {
                Capsule().fill(Palette.outline).frame(width: 14, height: 2.5)
                Capsule().fill(Palette.outlineVariant).frame(width: 10, height: 2.5)
                Capsule().fill(Palette.outlineVariant).frame(width: 12, height: 2.5)
            }
            .padding(.leading, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct MascotTear: Shape {
    let leading: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let zig: [CGPoint] = [
            CGPoint(x: rect.midX + 2, y: rect.minY),
            CGPoint(x: rect.midX - 3, y: rect.minY + rect.height * 0.3),
            CGPoint(x: rect.midX + 3, y: rect.minY + rect.height * 0.55),
            CGPoint(x: rect.midX - 2, y: rect.maxY),
        ]
        if leading {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            zig.forEach { path.addLine(to: $0) }
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            zig.forEach { path.addLine(to: $0) }
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}

struct MascotRocketProp: View {
    var body: some View {
        let w = MascotDimens.rocketWidth
        let h = MascotDimens.rocketHeight
        ZStack(alignment: .top) {
            MascotFlame()
                .fill(LinearGradient(colors: [Palette.favorite, Palette.mascotRocketTip], startPoint: .top, endPoint: .bottom))
                .frame(width: w * 0.5, height: h * 0.3)
                .offset(y: h * 0.78)
            MascotFin(leading: true).fill(Palette.mascotRocketTip)
                .frame(width: w * 0.3, height: h * 0.3)
                .offset(x: -w * 0.35, y: h * 0.5)
            MascotFin(leading: false).fill(Palette.mascotRocketTip)
                .frame(width: w * 0.3, height: h * 0.3)
                .offset(x: w * 0.35, y: h * 0.5)
            Capsule().fill(Palette.mascotRocket)
                .frame(width: w * 0.62, height: h * 0.72)
                .offset(y: h * 0.08)
            MascotNose().fill(Palette.mascotRocketTip)
                .frame(width: w * 0.62, height: h * 0.26)
            Circle().fill(Palette.mascotBottom)
                .frame(width: w * 0.3, height: w * 0.3)
                .offset(y: h * 0.33)
        }
        .frame(width: w, height: h)
    }
}

private struct MascotNose: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

private struct MascotFin: Shape {
    let leading: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inner = leading ? rect.maxX : rect.minX
        let outer = leading ? rect.minX : rect.maxX
        path.move(to: CGPoint(x: inner, y: rect.minY))
        path.addLine(to: CGPoint(x: outer, y: rect.maxY))
        path.addLine(to: CGPoint(x: inner, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct MascotFlame: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
