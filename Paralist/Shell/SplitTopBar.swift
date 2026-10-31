// Zusammenhang: Shell/SplitRootView.swift (SplitMain), Shell/SplitParts.swift (SplitCircle, SplitGlyph), Shell/Router.swift (tapTab, searchOpen), Shell/RouterSplit.swift (toggleMenu, toggleSide, AppTab.pad), Shell/TabSlotMenu.swift (TabSlotLook, TabSlotMenu), App/AppPrefs.swift (tabOrder), Icons/AppIcons.swift (sidebarRight, search), Theme/SplitDimens.swift, Theme/SplitBarDimens.swift, Theme/Palette.swift (padTabActive), docs/ipad.md
import ParalistCore
import SwiftUI

struct SplitTopBar: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @Namespace private var pillSpace

    var body: some View {
        HStack(spacing: SplitDimens.gap) {
            SplitCircle(title: L.s(router.menuOpen ? "menu_close" : "menu_open"), active: router.menuOpen, action: router.toggleMenu) {
                SplitGlyph(asset: "XoolMenu")
            }
            .zIndex(1)
            ViewThatFits(in: .horizontal) {
                pill(labels: true)
                pill(labels: false)
                ScrollView(.horizontal, showsIndicators: false) { pill(labels: false) }
            }
            .frame(maxWidth: .infinity)
            SplitCircle(title: L.s("ipad_sidebar"), active: router.sideOpen && !router.menuOpen, action: router.toggleSide) {
                Image(systemName: AppIcons.sidebarRight).font(.system(size: 18, weight: .medium))
            }
            .zIndex(1)
        }
        .padding(.horizontal, SplitDimens.barInset)
        .frame(height: SplitDimens.topBar)
    }

    private func pill(labels: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(AppTab.pad(model.prefs.tabOrder), id: \.self) { tab in item(tab, labels: labels) }
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
        .padding(.vertical, SplitDimens.pillInset)
    }

    private func item(_ tab: AppTab, labels: Bool) -> some View {
        let active = router.tab == tab
        let id = labels ? "pill-text" : "pill-icon"
        return Button { router.tapTab(tab) } label: {
            Group {
                if labels {
                    Text(TabSlotLook.title(tab))
                        .font(Typo.dm(SplitDimens.pillFont, active ? .semibold : .medium))
                        .lineLimit(1)
                        .padding(.horizontal, SplitDimens.pillEdge)
                } else {
                    Image(systemName: TabSlotLook.icon(tab).resolve(active))
                        .font(.system(size: SplitBarDimens.iconSize, weight: .medium))
                        .frame(width: SplitBarDimens.iconItemWidth)
                }
            }
            .foregroundStyle(Palette.tabTextActive)
            .frame(height: SplitDimens.pillItem)
            .background {
                if active { Capsule().fill(Palette.padTabActive).matchedGeometryEffect(id: id, in: pillSpace) }
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
