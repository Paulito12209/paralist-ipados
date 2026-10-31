// Zusammenhang: Pages/OverviewEdge.swift (Edge Picker, OverviewEdgeOption), Pages/OverviewPage.swift (Blatt, Umschaltung), Pages/OverviewSections.swift (OverviewSortRow, Icon-Knöpfe), Pages/OverviewSwitchSheet.swift, Pages/ViewSheet.swift, Theme/SplitBarDimens.swift, Theme/OverviewSectionDimens.swift, Icons/XoolIcons.swift (XoolSlidersIcon), ParalistCore Library/OverviewInline.swift
import ParalistCore
import SwiftUI

extension OverviewEdgeOption {
    func label(_ style: OverviewStyle) -> String {
        switch self {
        case .view: return L.s("view_customize")
        case .switcher: return L.s("overview_switch")
        case .arrange: return L.s(style == .tabs ? "overview_style_tabs" : "overview_style_stacked")
        }
    }
}

struct OverviewOptionIcon: View {
    let option: OverviewEdgeOption
    let style: OverviewStyle
    let size: CGFloat
    var bounce = false

    var body: some View {
        switch option {
        case .view:
            XoolSlidersIcon(line: OverviewDimens.slidersLine).frame(width: OverviewDimens.slidersBox, height: OverviewDimens.slidersBox)
        case .switcher:
            Image(systemName: AppIcons.overviewSwitch).font(.system(size: size, weight: .semibold))
                .symbolEffect(.bounce, value: bounce)
        case .arrange:
            Image(systemName: style == .tabs ? AppIcons.overviewTabs : AppIcons.overviewStacked).font(.system(size: size, weight: .semibold))
        }
    }
}

struct OverviewOptionButtons: View {
    let style: OverviewStyle
    let action: (OverviewEdgeOption) -> Void

    var body: some View {
        HStack(spacing: SplitBarDimens.optionGap) {
            ForEach(OverviewEdgeOption.allCases) { option in
                Button { action(option) } label: {
                    OverviewOptionIcon(option: option, style: style, size: SplitBarDimens.optionIconSize)
                        .scaleEffect(option == .view ? SplitBarDimens.optionIcon / OverviewDimens.slidersBox : 1)
                        .foregroundStyle(Palette.onSurfaceVariant)
                        .frame(width: SplitBarDimens.optionIcon, height: SplitBarDimens.optionIcon)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.label(style))
            }
        }
    }
}

struct OverviewOptionSheet: ViewModifier {
    @Binding var option: OverviewEdgeOption?
    let focus: OverviewTab
    let tabs: [String]
    @Environment(AppModel.self) private var model

    func body(content: Content) -> some View {
        content.sheet(item: $option) { option in
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
}

private struct OverviewOptionActionKey: EnvironmentKey {
    static let defaultValue: ((OverviewEdgeOption) -> Void)? = nil
}

extension EnvironmentValues {
    var overviewOptionAction: ((OverviewEdgeOption) -> Void)? {
        get { self[OverviewOptionActionKey.self] }
        set { self[OverviewOptionActionKey.self] = newValue }
    }
}
