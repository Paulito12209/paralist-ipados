// Zusammenhang: ParalistCore Library/EdgePicker.swift, Entry/EntryPage.swift, Pages/CalendarEdge.swift (Ansichten Tag, Woche, Monat), Pages/OverviewEdge.swift (onReselect), Theme/Dimens.swift (edge*), Theme/Palette.swift (edgePicker, edgeGlow, level), Icons/AppIcons.swift, Icons/XoolIcons.swift (XoolPageShape)
import ParalistCore
import SwiftUI

struct EdgeNotchShape: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        let curve = min(Dimens.edgeNotchCurve, rect.height / 2)
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addCurve(to: CGPoint(x: rect.minX, y: rect.minY + curve),
                      control1: CGPoint(x: rect.maxX, y: rect.minY + curve * 0.5),
                      control2: CGPoint(x: rect.minX, y: rect.minY + curve * 0.5))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - curve))
        path.addCurve(to: CGPoint(x: rect.maxX, y: rect.maxY),
                      control1: CGPoint(x: rect.minX, y: rect.maxY - curve * 0.5),
                      control2: CGPoint(x: rect.maxX, y: rect.maxY - curve * 0.5))
        path.closeSubpath()
        return path
    }
}

struct EdgePickerView<Option: Hashable, Icon: View>: View {
    @Binding var selected: Option
    let options: [Option]
    let title: String
    let label: (Option) -> String
    @ViewBuilder let icon: (Option) -> Icon
    var glow = false
    var spread = false
    var full: CGFloat = Dimens.edgeNotchHeight
    var tucked = false
    var onReselect: (() -> Void)?
    @State private var drag: CGFloat = 0
    @State private var dragging = false
    @State private var announcing = false

    private var wide: Bool { dragging || announcing }

    private var pill: Double { wide ? EdgePicker.pillWide : EdgePicker.pill }

    private var index: Int { options.firstIndex(of: selected) ?? 0 }

    private var height: Double { EdgePicker.height(count: options.count, full: full) }

    private var reach: Double { height / 2 - Dimens.edgeNotchCurve / 2 - Dimens.edgeEndGap }

    private var spreadReach: Double { reach - EdgePicker.pill / 2 }

    private var shift: Double {
        EdgePicker.shift(selected: index, count: options.count, reach: reach, pill: pill)
    }

    var body: some View {
        ZStack {
            ForEach(Array(options.enumerated()), id: \.element) { position, item in
                if spread {
                    let y = EdgePicker.spread(position, count: options.count, reach: spreadReach)
                    let room = max(reach - EdgePicker.pillWide / 2, 0)
                    slot(item)
                        .opacity(item == selected || !wide ? 1 : 0)
                        .offset(y: item == selected && wide ? min(max(y, -room), room) : y)
                } else {
                    let y = EdgePicker.center(of: position, selected: index, pill: pill) + shift + drag
                    slot(item)
                        .opacity(item == selected ? 1 : EdgePicker.fade(at: y, half: height / 2))
                        .offset(y: y)
                }
            }
        }
        .frame(width: Dimens.edgeNotchWidth, height: height)
        .background { EdgeNotchBackground(glow: glow, beacon: tucked) }
        .clipShape(EdgeNotchShape())
        .contentShape(EdgeNotchShape())
        .shadow(color: .black.opacity(Dimens.edgeShadow), radius: 12, x: -2)
        .highPriorityGesture(gesture)
        .offset(x: Dimens.edgeShift)
        .animation(Motion.dock, value: selected)
        .animation(Motion.dock, value: wide)
        .task(id: selected) {
            guard spread else { return }
            announcing = true
            try? await Task.sleep(for: Dimens.edgeAnnounce)
            if !Task.isCancelled { announcing = false }
        }
        .animation(Motion.dock, value: options.count)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(label(selected))
        .accessibilityAdjustableAction { direction in
            let next = index + (direction == .increment ? 1 : -1)
            if options.indices.contains(next) { selected = options[next] }
        }
    }

    @ViewBuilder
    private func slot(_ item: Option) -> some View {
        if item == selected {
            Capsule()
                .fill(Palette.level)
                .frame(width: EdgePicker.pillWidth, height: pill)
                .overlay {
                    if wide {
                        Text(label(item))
                            .font(Typo.labelLarge)
                            .foregroundStyle(Palette.onLevel)
                            .lineLimit(1)
                            .fixedSize()
                            .rotationEffect(.degrees(-90))
                    } else {
                        icon(item).foregroundStyle(Palette.onLevel)
                    }
                }
        } else {
            icon(item).foregroundStyle(Palette.onSurface)
        }
    }

    private var gesture: some Gesture {
        spread ? AnyGesture(spreadGesture.map { _ in () }) : AnyGesture(slideGesture.map { _ in () })
    }

    private var spreadGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if abs(value.translation.height) >= EdgePicker.dragStart { dragging = true }
                guard dragging else { return }
                pick(EdgePicker.spreadSlot(at: value.location.y - height / 2, count: options.count, reach: spreadReach))
            }
            .onEnded { value in
                let target = EdgePicker.spreadSlot(at: value.location.y - height / 2, count: options.count, reach: spreadReach)
                if !dragging, options.indices.contains(target), options[target] == selected { onReselect?() }
                pick(target)
                dragging = false
            }
    }

    private func pick(_ target: Int) {
        if options.indices.contains(target), options[target] != selected { selected = options[target] }
    }

    private var slideGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard abs(value.translation.height) >= EdgePicker.dragStart else { return }
                dragging = true
                drag = value.translation.height
            }
            .onEnded { value in
                let count = options.count
                let target: Int
                if dragging {
                    target = EdgePicker.afterDrag(value.translation.height, selected: index, count: count, pill: pill)
                } else {
                    target = EdgePicker.nearest(to: value.location.y - height / 2 - shift, selected: index, count: count)
                }
                dragging = false
                drag = 0
                if options.indices.contains(target) { selected = options[target] }
            }
    }
}

struct EntryCanvasIcon: View {
    let item: EntryCanvas

    var body: some View {
        switch item {
        case .cover: XoolPageShape().frame(width: EdgePicker.icon + 4, height: EdgePicker.icon + 4)
        case .actions: Image(systemName: AppIcons.canvasActions).font(.system(size: EdgePicker.icon, weight: .semibold))
        case .text: Image(systemName: AppIcons.text).font(.system(size: EdgePicker.icon, weight: .semibold))
        case .links: GlyphIcon(AppIcons.link, size: EdgePicker.icon, weight: .semibold)
        }
    }
}

struct EdgeNotchBackground: View {
    let glow: Bool
    var beacon = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var flow = false

    var body: some View {
        EdgeNotchShape().fill(Palette.edgePicker)
            .overlay {
                if glow {
                    GeometryReader { geo in
                        LinearGradient(colors: [Palette.edgeGlow.opacity(0), Palette.edgeGlow, Palette.edgeGlow.opacity(0)],
                                       startPoint: .top, endPoint: .bottom)
                            .frame(height: geo.size.height * Dimens.edgeGlowSpan)
                            .offset(y: flow ? geo.size.height * (1 - Dimens.edgeGlowSpan / 2) : -geo.size.height * Dimens.edgeGlowSpan / 2)
                            .opacity(Dimens.edgeGlowOpacity)
                    }
                    .clipShape(EdgeNotchShape())
                    .opacity(beacon ? 0 : 1)
                    .allowsHitTesting(false)
                    .onAppear {
                        guard !reduceMotion else { return }
                        withAnimation(.easeInOut(duration: Dimens.edgeGlowPeriod).repeatForever(autoreverses: true)) { flow = true }
                    }
                }
            }
            .overlay {
                if glow { beaconLayer.opacity(beacon ? 1 : 0) }
            }
            .animation(Motion.dock, value: beacon)
    }

    private var beaconLayer: some View {
        TimelineView(.animation(paused: !beacon || reduceMotion)) { context in
            GeometryReader { geo in
                let band = geo.size.height * Dimens.edgeGlowSpan
                let linear = context.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: Dimens.edgeBeaconPeriod) / Dimens.edgeBeaconPeriod
                let phase = reduceMotion ? 0.5 : linear * linear * (3 - 2 * linear)
                LinearGradient(colors: [Palette.edgeGlow.opacity(0), Palette.edgeGlow, Palette.edgeGlow.opacity(0)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: band)
                    .offset(y: (geo.size.height + band) * phase - band)
            }
            .background(Palette.edgeGlow.opacity(Dimens.edgeBeaconBase))
        }
        .clipShape(EdgeNotchShape())
        .opacity(Dimens.edgeGlowOpacity)
        .allowsHitTesting(false)
    }
}
