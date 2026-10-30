// Zusammenhang: Chat/ChatMascotStage.swift, Chat/ChatMascotActor.swift (MascotFace), Theme/Palette.swift (mascot*), Theme/Dimens.swift (MascotDimens), docs/chat.md
import SwiftUI

enum MascotFace: Equatable {
    case neutral, happy, excited, tired, angry, surprised, dead

    var cover: CGFloat {
        switch self {
        case .tired: return MascotDimens.lidTired
        case .angry: return MascotDimens.lidAngry
        default: return 0
        }
    }

    var slant: CGFloat { self == .angry ? MascotDimens.lidSlant : 0 }

    var mouth: (curve: CGFloat, open: CGFloat, width: CGFloat) {
        switch self {
        case .neutral: return (0.35, 0, 10)
        case .happy: return (1, 0, 14)
        case .excited: return (1, 0.7, 14)
        case .tired: return (-0.15, 0, 8)
        case .angry: return (-0.8, 0, 11)
        case .surprised: return (0, 0.9, 7)
        case .dead: return (0, 0, 9)
        }
    }
}

struct ChatMascotView: View {
    var face: MascotFace = .neutral
    var gaze: CGFloat = 0
    var cover: CGFloat = 0
    var slant: CGFloat = 0

    var body: some View {
        let mouth = face.mouth
        ZStack {
            RoundedRectangle(cornerRadius: MascotDimens.height / 2, style: .continuous)
                .fill(LinearGradient(colors: [Palette.mascotTop, Palette.mascotBottom], startPoint: .top, endPoint: .bottom))
                .shadow(color: Palette.mascotBottom.opacity(0.25), radius: 4, y: 2)
            HStack(spacing: MascotDimens.eyeGap) {
                MascotEye(face: face, cover: cover, slant: slant)
                MascotEye(face: face, cover: cover, slant: -slant)
            }
            .offset(x: gaze * MascotDimens.pupilShift, y: -MascotDimens.eyeLift)
            ZStack {
                MascotMouth(curve: mouth.curve, open: mouth.open, width: mouth.width).fill(Palette.mascotEye)
                MascotMouth(curve: mouth.curve, open: mouth.open, width: mouth.width)
                    .stroke(Palette.mascotEye, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
            .frame(width: MascotDimens.mouthWidth, height: MascotDimens.mouthHeight)
            .offset(x: gaze * MascotDimens.pupilShift * 0.6, y: MascotDimens.mouthDrop)
        }
        .frame(width: MascotDimens.width, height: MascotDimens.height)
        .animation(.easeInOut(duration: 0.25), value: gaze)
        .animation(Motion.short, value: face)
    }
}

private struct MascotEye: View {
    let face: MascotFace
    let cover: CGFloat
    let slant: CGFloat

    private var round: Bool { face != .happy && face != .excited && face != .dead }

    var body: some View {
        ZStack {
            ZStack {
                Ellipse().fill(Palette.mascotEye)
                MascotLid(cover: cover, slant: slant).fill(Palette.mascotTop)
            }
            .clipShape(Ellipse())
            .opacity(round ? 1 : 0)
            MascotArc()
                .stroke(Palette.mascotEye, style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                .opacity(face == .happy || face == .excited ? 1 : 0)
            MascotCross()
                .stroke(Palette.mascotEye, style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                .opacity(face == .dead ? 1 : 0)
        }
        .frame(width: MascotDimens.eyeWidth, height: MascotDimens.eyeHeight)
        .animation(Motion.short, value: face)
        .animation(.easeInOut(duration: 0.1), value: cover)
        .animation(Motion.short, value: slant)
    }
}

private struct MascotLid: Shape {
    var cover: CGFloat
    var slant: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(cover, slant) }
        set {
            cover = newValue.first
            slant = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let edge = rect.minY + rect.height * cover
        path.move(to: CGPoint(x: rect.minX - 4, y: rect.minY - 4))
        path.addLine(to: CGPoint(x: rect.maxX + 4, y: rect.minY - 4))
        path.addLine(to: CGPoint(x: rect.maxX + 4, y: edge + slant))
        path.addLine(to: CGPoint(x: rect.minX - 4, y: edge - slant))
        path.closeSubpath()
        return path
    }
}

private struct MascotMouth: Shape {
    var curve: CGFloat
    var open: CGFloat
    var width: CGFloat

    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(curve, AnimatablePair(open, width)) }
        set {
            curve = newValue.first
            open = newValue.second.first
            width = newValue.second.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let left = CGPoint(x: rect.midX - width / 2, y: rect.midY)
        let right = CGPoint(x: rect.midX + width / 2, y: rect.midY)
        let top = CGPoint(x: rect.midX, y: rect.midY + curve * MascotDimens.mouthCurve)
        let bottom = CGPoint(x: rect.midX, y: top.y + open * MascotDimens.mouthOpen)
        var path = Path()
        path.move(to: left)
        path.addQuadCurve(to: right, control: top)
        path.addQuadCurve(to: left, control: bottom)
        path.closeSubpath()
        return path
    }
}

private struct MascotArc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY + rect.height * 0.25),
                    radius: rect.width * 0.48, startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
        return path
    }
}

private struct MascotCross: Shape {
    func path(in rect: CGRect) -> Path {
        let inset = rect.insetBy(dx: rect.width * 0.15, dy: rect.height * 0.22)
        var path = Path()
        path.move(to: CGPoint(x: inset.minX, y: inset.minY))
        path.addLine(to: CGPoint(x: inset.maxX, y: inset.maxY))
        path.move(to: CGPoint(x: inset.maxX, y: inset.minY))
        path.addLine(to: CGPoint(x: inset.minX, y: inset.maxY))
        return path
    }
}

struct SpeechBubble: Shape {
    func path(in rect: CGRect) -> Path {
        let tail = MascotDimens.bubbleTail
        let box = CGRect(x: rect.minX + tail, y: rect.minY, width: rect.width - tail, height: rect.height)
        var path = Path(roundedRect: box, cornerRadius: MascotDimens.bubbleRadius, style: .continuous)
        let y = box.maxY - MascotDimens.bubbleRadius - 2
        path.move(to: CGPoint(x: box.minX + 1, y: y - tail))
        path.addLine(to: CGPoint(x: box.minX - tail, y: y + tail * 0.6))
        path.addLine(to: CGPoint(x: box.minX + 1, y: y + tail))
        path.closeSubpath()
        return path
    }
}
