// Zusammenhang: Theme/FolderTone.swift (folderTone), Pages/TaskStage.swift, Pages/TasksPage.swift, Theme/Palette.swift (task*), Theme/Dimens.swift (TaskDimens), Icons/AppIcons.swift
import SwiftUI

struct FolderShape: Shape {
    var tabWidth: CGFloat
    var tabHeight: CGFloat
    var radius: CGFloat

    nonisolated func path(in rect: CGRect) -> Path {
        let r = min(radius, rect.width / 4, rect.height / 4)
        let tabEnd = rect.minX + rect.width * tabWidth
        let slope = min(tabHeight * 1.2, 28)
        let top = rect.minY + tabHeight
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY - r))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.addLine(to: CGPoint(x: tabEnd - slope, y: rect.minY))
        p.addCurve(to: CGPoint(x: tabEnd + slope, y: top), control1: CGPoint(x: tabEnd, y: rect.minY), control2: CGPoint(x: tabEnd, y: top))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: top))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: top + r), radius: r, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r), radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        p.addArc(center: CGPoint(x: rect.minX + r, y: rect.maxY - r), radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.closeSubpath()
        return p
    }
}

struct TaskGlowBackdrop: View {
    @Environment(\.folderTone) private var tone

    var body: some View {
        ZStack {
            tone.flapBase
            RadialGradient(colors: [tone.glowDeep.opacity(0.9), .clear], center: UnitPoint(x: 0.1, y: 1.15), startRadius: 0, endRadius: 200)
            RadialGradient(colors: [tone.glowMid.opacity(0.8), .clear], center: UnitPoint(x: 0.6, y: 1.2), startRadius: 0, endRadius: 180)
            RadialGradient(colors: [tone.glowSoft.opacity(0.55), .clear], center: UnitPoint(x: 1, y: 1), startRadius: 0, endRadius: 150)
            RadialGradient(colors: [tone.glowIndigo.opacity(0.35), .clear], center: UnitPoint(x: 1, y: 0), startRadius: 0, endRadius: 160)
            LinearGradient(colors: [.white.opacity(0.10), .clear], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.35))
        }
        .accessibilityHidden(true)
    }
}

struct TaskFolder: View {
    let count: Int
    var archive: Binding<Bool>?
    var glyph = AppIcons.task.outlined
    var voice: String?

    @Environment(\.folderTone) private var tone

    private var dim: Bool { archive?.wrappedValue ?? false }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let back = FolderShape(tabWidth: TaskDimens.folderTabWidth, tabHeight: TaskDimens.folderTabHeight, radius: TaskDimens.folderRadius)
            ZStack(alignment: .topLeading) {
                back
                    .fill(LinearGradient(colors: [tone.backTop, tone.backBottom], startPoint: .top, endPoint: .bottom))
                    .overlay(back.stroke(.white.opacity(0.18), lineWidth: 1))
                let frontTop = h * TaskDimens.flapTabTop + TaskDimens.sheetFrontGap
                ZStack(alignment: .topLeading) {
                    sheet(width: w, height: h, top: 2 * frontTop - h * TaskDimens.flapTop, inset: TaskDimens.sheetBackInset).opacity(0.7)
                    sheet(width: w, height: h, top: frontTop, inset: TaskDimens.sheetFrontInset)
                }
                .frame(width: w, height: h, alignment: .topLeading)
                .clipShape(back)
                .allowsHitTesting(false)
                flap(width: w, height: h * (1 - TaskDimens.flapTabTop))
                    .offset(y: h * TaskDimens.flapTabTop)
            }
            .shadow(color: tone.glowDeep.opacity(0.16), radius: 14, y: 8)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(voice ?? L.f(dim ? "tasks_archived_count" : "tasks_active_count", count))
    }

    private func sheet(width: CGFloat, height: CGFloat, top: CGFloat, inset: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: TaskDimens.sheetRadius, style: .continuous)
        return Color.clear
            .frame(width: width - inset * 2, height: max(height - top, 0))
            .glassEffect(.regular.tint(tone.sheet.opacity(0.75)), in: shape)
            .overlay(shape.stroke(.white.opacity(0.7), lineWidth: 0.8))
            .shadow(color: .black.opacity(0.12), radius: 6, y: -1)
            .offset(x: inset, y: top)
    }

    private func flap(width: CGFloat, height: CGFloat) -> some View {
        let tab = (TaskDimens.flapTop - TaskDimens.flapTabTop) / (1 - TaskDimens.flapTabTop) * height
        let shape = FolderShape(tabWidth: TaskDimens.flapTabWidth, tabHeight: tab, radius: TaskDimens.flapRadius)
        return HStack(alignment: .center) {
            Text("\(count)")
                .font(Typo.dm(TaskDimens.countSize, .medium, relativeTo: .title2))
                .foregroundStyle(dim ? tone.inkMuted : tone.ink)
                .monospacedDigit()
                .contentTransition(.numericText())
                .alignmentGuide(VerticalAlignment.center) { d in d[.firstTextBaseline] - Typo.uiFont(TaskDimens.countSize).capHeight / 2 }
            Spacer(minLength: 8)
            if let archive { toggle(archive) } else { badge }
        }
        .padding(TaskDimens.flapPad)
        .frame(width: width, height: height, alignment: .bottom)
        .background { TaskGlowBackdrop().saturation(dim ? 0.15 : 1) }
        .clipShape(shape)
        .overlay(shape.stroke(LinearGradient(colors: [.white.opacity(0.45), .white.opacity(0.08)], startPoint: .top, endPoint: .bottom), lineWidth: 1))
        .animation(Motion.dock, value: dim)
    }

    private var badge: some View {
        GlyphIcon(glyph, size: 16, weight: .semibold)
            .foregroundStyle(tone.ink)
            .frame(width: TaskDimens.toggleHeight, height: TaskDimens.toggleHeight)
            .glassEffect(.regular, in: Circle())
            .accessibilityHidden(true)
    }

    private func toggle(_ archive: Binding<Bool>) -> some View {
        let on = archive.wrappedValue
        return Button {
            withAnimation(Motion.dock) { archive.wrappedValue.toggle() }
        } label: {
            HStack(spacing: 8) {
                if on { knob }
                ZStack {
                    caption("tasks_toggle_active").hidden()
                    caption("tile_archive").hidden()
                    caption(on ? "tile_archive" : "tasks_toggle_active")
                }
                if !on { knob }
            }
            .padding(.leading, on ? 5 : 14)
            .padding(.trailing, on ? 14 : 5)
            .frame(height: TaskDimens.toggleHeight)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Capsule())
        .accessibilityLabel(L.s("tasks_show_archive"))
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func caption(_ key: String) -> some View {
        Text(L.s(key))
            .font(Typo.dm(15, .medium))
            .foregroundStyle(tone.ink)
            .lineLimit(1)
    }

    private var knob: some View {
        Circle()
            .fill(dim ? tone.knobOff : tone.knobOn)
            .frame(width: TaskDimens.toggleKnob, height: TaskDimens.toggleKnob)
            .overlay {
                GlyphIcon(dim ? AppIcons.archive : AppIcons.task.outlined, size: 14, weight: .semibold)
                    .foregroundStyle(.white)
            }
    }
}
