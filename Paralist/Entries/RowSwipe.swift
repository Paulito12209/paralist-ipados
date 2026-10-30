// Zusammenhang: Pages/ListPage.swift, Pages/OverviewPage.swift, Entries/SwipeRecognizers.swift (HoldDragRecognizer, HoldPanRecognizer, RowHold), Theme/Dimens.swift (SwipeDimens), Theme/Palette.swift, ParalistCore Library/RowSwipe.swift
import ParalistCore
import SwiftUI

struct SwipeOption {
    let icon: String
    let label: String
    let fill: Color
    let ink: Color

    static var pin: SwipeOption { SwipeOption(icon: AppIcons.pin.filled, label: L.s("tool_pin"), fill: Palette.level, ink: Palette.onLevel) }
    static var delete: SwipeOption { SwipeOption(icon: AppIcons.delete, label: L.s("entry_delete"), fill: Palette.error, ink: Palette.onError) }
}

@MainActor
@Observable
final class RowSwipeState {
    var held: String?
    var dx: CGFloat = 0
    @ObservationIgnored var frames: [String: CGRect] = [:]
    @ObservationIgnored var touchedAt = Date.distantPast

    var recent: Bool { Date.now.timeIntervalSince(touchedAt) < MenuDimens.tapLock }

    func row(at point: CGPoint) -> String? {
        frames.first { $0.value.contains(point) }?.key
    }

    func begin(_ point: CGPoint) {
        touchedAt = .now
        held = row(at: point)
    }

    func change(_ value: CGFloat) {
        touchedAt = .now
        dx = value
    }

    func end(_ value: CGFloat?, model: AppModel) {
        touchedAt = .now
        if let id = held, let value {
            switch RowSwipe.of(value, threshold: SwipeDimens.trigger) {
            case .leading: model.update(id) { var e = $0; e.pinned.toggle(); return e }
            case .trailing: model.moveToTrash(id)
            case nil: break
            }
        }
        held = nil
        withAnimation(Motion.short) { dx = 0 }
    }
}

struct RowSwipeHost: ViewModifier {
    let state: RowSwipeState
    @Environment(AppModel.self) private var model

    func body(content: Content) -> some View {
        content.background(
            HoldDragInstaller(hold: SwipeDimens.hold, canBegin: { state.row(at: $0) != nil }) { point in
                state.begin(point)
            } onChange: { value in
                state.change(value)
            } onEnd: { value in
                state.end(value, model: model)
            }
        )
    }
}

struct RowSwipeGesture: ViewModifier {
    let state: RowSwipeState
    @Environment(AppModel.self) private var model

    func body(content: Content) -> some View {
        content.gesture(
            HoldDragRecognizer(hold: SwipeDimens.hold, canBegin: { state.row(at: $0) != nil }) { point in
                state.begin(point)
            } onChange: { value in
                state.change(value)
            } onEnd: { value in
                state.end(value, model: model)
            }
        )
    }
}

struct RowSwipeFeedback: ViewModifier {
    let state: RowSwipeState

    func body(content: Content) -> some View {
        content
            .scrollDisabled(state.held != nil)
            .sensoryFeedback(.impact(weight: .medium), trigger: state.held) { _, now in now != nil }
            .sensoryFeedback(.selection, trigger: RowSwipe.of(state.dx, threshold: SwipeDimens.trigger)) { _, now in now != nil }
    }
}

struct ArmedSwipe: ViewModifier {
    let id: String
    let state: RowSwipeState

    func body(content: Content) -> some View {
        let armed = state.held == id
        let dx = armed ? state.dx : 0
        let shown = RowSwipe.offset(dx, limit: SwipeDimens.limit)
        let ready = armed ? RowSwipe.of(dx, threshold: SwipeDimens.trigger) : nil
        content
            .background(Palette.background)
            .offset(x: shown)
            .background { backdrop(shown, ready: ready).opacity(armed ? 1 : 0) }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { state.frames[id] = $0 }
            .onDisappear { state.frames[id] = nil }
    }

    private func backdrop(_ shown: CGFloat, ready: RowSwipe?) -> some View {
        let option = shown >= 0 ? SwipeOption.pin : SwipeOption.delete
        return HStack(spacing: 8) {
            Image(systemName: option.icon).font(.system(size: 17, weight: .semibold))
            Text(option.label).font(Typo.dm(15, .medium)).lineLimit(1)
        }
        .foregroundStyle(option.ink)
        .padding(.horizontal, SwipeDimens.edge)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: shown >= 0 ? .leading : .trailing)
        .background(option.fill.opacity(ready == nil ? SwipeDimens.idleFill : 1))
    }
}

extension View {

    func armedSwipe(_ id: String, _ state: RowSwipeState) -> some View { modifier(ArmedSwipe(id: id, state: state)) }
    func rowSwipeHost(_ state: RowSwipeState) -> some View { modifier(RowSwipeHost(state: state)) }
    func rowSwipeGesture(_ state: RowSwipeState) -> some View { modifier(RowSwipeGesture(state: state)) }
    func rowSwipeFeedback(_ state: RowSwipeState) -> some View { modifier(RowSwipeFeedback(state: state)) }
}
