// Zusammenhang: Pages/OverviewParts.swift (OverviewTabs), Pages/OverviewPage.swift (Gruppenansicht), Pages/OverviewSections.swift (tabTitle, tabIcon, OverviewFeed), Pages/OverviewSwitchSheet.swift, ParalistCore Library/OverviewOptions.swift (OverviewTabDisplay), Theme/OverviewSectionDimens.swift
import ParalistCore
import SwiftUI

enum OverviewTabTone {
    case plain, active, idle

    var color: Color {
        switch self {
        case .plain: return Palette.muted
        case .active: return Palette.level
        case .idle: return Palette.subtle
        }
    }

    var countColor: Color { self == .active ? Palette.muted : Palette.subtle }
}

struct OverviewTabLabel: View {
    let title: String
    let icon: String
    let count: Int
    let tone: OverviewTabTone
    @Environment(AppModel.self) private var model

    var body: some View {
        let display = model.prefs.overviewLayout.tabDisplay
        HStack(spacing: 6) {
            if display.showsIcon { GlyphIcon(icon, size: OverviewDimens.tabIcon, weight: .medium) }
            if display.showsName {
                CappedWidth(limit: OverviewDimens.tabMaxWidth) { Text(title).lineLimit(1) }
            }
            if count > 0 { Text("\(count)").foregroundStyle(tone.countColor) }
        }
        .font(Typo.dm(15, .medium))
        .foregroundStyle(tone.color)
        .opacity(tone == .idle ? OverviewDimens.idleTab : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(count > 0 ? L.f("entries_count", count) : "")
    }
}

struct OverviewHeadRow: View {
    let feed: OverviewFeed
    var top = OverviewDimens.listTop
    @Environment(AppModel.self) private var model
    @State private var switching = false

    var body: some View {
        HStack(spacing: 0) {
            Button { switching = true } label: {
                OverviewTabLabel(title: model.tabTitle(feed.tab), icon: model.tabIcon(feed.tab), count: feed.rows.count, tone: .plain)
                    .frame(height: OverviewDimens.tabHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isHeader)
            .accessibilityHint(L.s("overview_switch"))
            Spacer(minLength: 12)
        }
        .frame(height: OverviewDimens.tabHeight)
        .padding(.leading, Dimens.titleEdge)
        .padding(.trailing, OverviewDimens.tabsEdge)
        .padding(.top, top)
        .padding(.bottom, OverviewDimens.listGap)
        .overviewSwitcher($switching, tabs: [feed.tab.id])
    }
}

struct OverviewShowAllRow: View {
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(L.f("overview_show_all", count))
                Image(systemName: AppIcons.chevronRight).font(.system(size: 12, weight: .semibold))
                Spacer(minLength: 0)
            }
            .font(Typo.bodyMedium)
            .foregroundStyle(Palette.subtle)
            .padding(.leading, Dimens.titleEdge)
            .frame(minHeight: OverviewDimens.zoneMinHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

extension View {
    func overviewSwitcher(_ shown: Binding<Bool>, tabs: [String]) -> some View {
        sheet(isPresented: shown) {
            OverviewSwitchSheet(tabs: tabs)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(Dimens.sheetRadius)
        }
    }
}
