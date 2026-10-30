// Zusammenhang: Entry/EdgePicker.swift (EdgePickerView, onReselect), Pages/CalendarEdge.swift (gleiche Kerbe), Pages/OverviewPage.swift, Pages/OverviewSwitchSheet.swift (Listenwechsler), Pages/ViewSheet.swift (Regler), App/AppPrefs.swift (overviewLayout, overviewHintSeen), ParalistCore Library/OverviewLayout.swift, Theme/CalendarDimens.swift (edgeAutoTuck, calendarNotchHeight), Theme/OverviewSectionDimens.swift (hint*), Icons/AppIcons.swift, Icons/XoolIcons.swift (XoolSlidersIcon)
import ParalistCore
import SwiftUI

enum OverviewEdgeOption: CaseIterable, Hashable, Identifiable {
    case view, switcher, arrange

    var id: Self { self }
}

struct OverviewEdge: View {
    let focus: OverviewTab
    let tabs: [String]
    @Environment(AppModel.self) private var model
    @State private var pick = OverviewEdgeOption.arrange
    @State private var sheet: OverviewEdgeOption?
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
        .onDisappear { tucked = true }
        .sheet(item: $sheet, onDismiss: {
            pick = .arrange
            tucked = true
        }) { option in
            Group {
                if option == .view {
                    viewSheet
                } else {
                    OverviewSwitchSheet(tabs: tabs)
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(Dimens.sheetRadius)
        }
    }

    @ViewBuilder
    private var viewSheet: some View {
        switch model.overviewSource(focus) {
        case .list(let kind): ViewSheet(kind: kind)
        case .entry(let id): ViewSheet(kind: .all, entryId: id)
        case nil: OverviewSwitchSheet(tabs: tabs)
        }
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

    private func label(_ option: OverviewEdgeOption) -> String {
        switch option {
        case .view: return L.s("view_customize")
        case .switcher: return L.s("overview_switch")
        case .arrange: return L.s(style == .tabs ? "overview_style_tabs" : "overview_style_stacked")
        }
    }

    @ViewBuilder
    private func optionIcon(_ option: OverviewEdgeOption) -> some View {
        switch option {
        case .view:
            XoolSlidersIcon(line: OverviewDimens.slidersLine).frame(width: OverviewDimens.slidersBox, height: OverviewDimens.slidersBox)
        case .switcher:
            Image(systemName: AppIcons.overviewSwitch).font(.system(size: EdgePicker.icon, weight: .semibold))
        case .arrange:
            Image(systemName: style == .tabs ? AppIcons.overviewTabs : AppIcons.overviewStacked).font(.system(size: EdgePicker.icon, weight: .semibold))
        }
    }
}
