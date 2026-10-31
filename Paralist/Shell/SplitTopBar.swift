// Zusammenhang: Shell/SplitRootView.swift, Shell/SplitParts.swift (SplitCircle, SplitGlyph), Shell/Router.swift (tapTab, openMenu, searchOpen), Shell/RouterSplit.swift (togglePanel), Shell/TabSlotMenu.swift (TabSlotLook, TabSlotMenu), Shell/CategoryPanel.swift, App/AppPrefs.swift (tabOrder), Icons/AppIcons.swift (sidebarRight, search), Theme/SplitDimens.swift, docs/ipad.md
import ParalistCore
import SwiftUI

struct SplitTopBar: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @Namespace private var pill

    var body: some View {
        ZStack {
            HStack {
                SplitCircle(title: L.s("menu_open"), action: router.openMenu) { SplitGlyph(asset: "XoolMenu") }
                Spacer(minLength: 0)
                SplitCircle(title: L.s("ipad_sidebar"), active: panelShown, action: panel) {
                    Image(systemName: AppIcons.sidebarRight).font(.system(size: 18, weight: .medium))
                }
            }
            ViewThatFits(in: .horizontal) {
                tabs(labels: true)
                tabs(labels: false)
            }
            .padding(.horizontal, SplitDimens.button + SplitDimens.gap)
        }
        .frame(height: SplitDimens.topBar)
    }

    private var panelShown: Bool { router.panelOpen && router.detail == nil }

    private func panel() {
        if router.detail != nil {
            router.closeDetail()
            router.panelOpen = true
        } else {
            router.togglePanel()
        }
    }

    private var shown: [AppTab] {
        model.prefs.tabOrder.tabs.compactMap(AppTab.init(rawValue:))
    }

    private func tabs(labels: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(shown, id: \.self) { tab in item(tab, labels: labels) }
            Button { router.searchOpen = true } label: {
                Image(systemName: AppIcons.search).font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Palette.onSurface)
                    .frame(width: SplitDimens.pillItem, height: SplitDimens.pillItem)
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L.s("search_submit"))
        }
        .padding(SplitDimens.pillInset)
        .glassEffect(.regular.interactive(), in: Capsule())
        .fixedSize()
    }

    private func item(_ tab: AppTab, labels: Bool) -> some View {
        let active = router.tab == tab
        return Button { router.tapTab(tab) } label: {
            HStack(spacing: 6) {
                Image(systemName: TabSlotLook.icon(tab).resolve(active)).font(.system(size: 16, weight: .medium))
                if labels {
                    Text(TabSlotLook.title(tab)).font(Typo.dm(15, active ? .semibold : .medium)).lineLimit(1)
                }
            }
            .foregroundStyle(Palette.tabTextActive)
            .padding(.horizontal, labels ? SplitDimens.pillEdge : 0)
            .frame(minWidth: SplitDimens.pillItem, minHeight: SplitDimens.pillItem)
            .background {
                if active { Capsule().fill(Palette.tabActive).matchedGeometryEffect(id: labels ? "pill" : "dot", in: pill) }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .contextMenu { TabSlotMenu(slot: tab.slot) }
        .accessibilityLabel(TabSlotLook.title(tab))
        .accessibilityAddTraits(active ? .isSelected : [])
        .animation(Motion.dock, value: active)
    }
}
