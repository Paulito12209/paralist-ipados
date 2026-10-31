// Zusammenhang: Entry/EdgePicker.swift (EdgePickerView, onReselect), Pages/CalendarEdge.swift (gleiche Kerbe), Pages/OverviewPage.swift, Pages/OverviewOptionParts.swift (Icons, Blatt), Pages/OverviewSwitchSheet.swift (Listenwechsler), Pages/ViewSheet.swift (Regler), App/AppPrefs.swift (overviewLayout, overviewHintSeen), ParalistCore Library/OverviewLayout.swift, Theme/CalendarDimens.swift (edgeAutoTuck, calendarNotchHeight), Theme/OverviewSectionDimens.swift (hint*), Icons/AppIcons.swift, Icons/XoolIcons.swift (XoolSlidersIcon)
import ParalistCore
import SwiftUI

enum OverviewEdgeOption: CaseIterable, Hashable, Identifiable {
    case view, switcher, arrange

    var id: Self { self }
}

struct OverviewEdge: View {
    @Binding var sheet: OverviewEdgeOption?
    @Environment(AppModel.self) private var model
    @State private var pick = OverviewEdgeOption.arrange
    @State private var tucked = true
    @State private var shown = 0
    @State private var handled = 0

    private var style: OverviewStyle { model.prefs.overviewLayout.style }

    var body: some View {
        EdgePickerView(selected: $pick, options: OverviewEdgeOption.allCases, title: L.s("overview_edge_title"), label: label,
                       icon: optionIcon,
                       glow: true, spread: true, full: Dimens.calendarNotchHeight, tucked: tucked, onReselect: reselect)
        .offset(x: tucked ? Dimens.edgeNotchWidth - Dimens.edgePeek : 0)
        .allowsHitTesting(!tucked)
        .animation(Motion.dock, value: tucked)
        .overlay(alignment: .trailing) {
            if tucked {
                Button {
                    model.prefs.overviewHintSeen = true
                    shown += 1
                } label: {
                    Color.clear.frame(width: Dimens.edgePeekHit).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L.s("overview_edge_title"))
            }
        }
        .overlay(alignment: .trailing) {
            if tucked, !model.prefs.overviewHintSeen { hint }
        }
        .task(id: shown) {
            guard shown > handled else { return }
            handled = shown
            tucked = false
            try? await Task.sleep(for: Dimens.edgeAutoTuck)
            if !Task.isCancelled, sheet == nil { tucked = true }
        }
        .onChange(of: pick) { _, option in
            guard option != .arrange else { return }
            sheet = option
        }
        .onChange(of: sheet) { _, option in
            guard option == nil else { return }
            pick = .arrange
            tucked = true
        }
        .onDisappear { tucked = true }
    }

    private var hint: some View {
        Button { model.prefs.overviewHintSeen = true } label: {
            Text(L.s("overview_edge_hint"))
                .font(Typo.bodyMedium)
                .foregroundStyle(Palette.onSurface)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(width: OverviewDimens.hintWidth, alignment: .leading)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Dimens.sheetRadius / 2))
        }
        .buttonStyle(.plain)
        .padding(.trailing, Dimens.edgePeek + OverviewDimens.hintGap)
        .transition(.opacity)
    }

    private func reselect() {
        guard pick == .arrange else { return }
        shown += 1
        withAnimation(Motion.short) { model.prefs.overviewLayout.style = style.toggled }
    }

    private func label(_ option: OverviewEdgeOption) -> String { option.label(style) }

    private func optionIcon(_ option: OverviewEdgeOption) -> some View {
        OverviewOptionIcon(option: option, style: style, size: EdgePicker.icon, bounce: tucked)
    }
}
