// Zusammenhang: Shell/SplitRootView.swift (SplitMain), Shell/SplitParts.swift (SplitCircle, SplitGlyph), Shell/Router.swift (tapTab, searchOpen), Shell/RouterSplit.swift (toggleMenu, toggleSide, AppTab.pad), Shell/TabSlotMenu.swift (TabSlotLook, TabSlotMenu), App/AppPrefs.swift (tabOrder), Icons/AppIcons.swift (sidebarRight, search), Theme/SplitDimens.swift, Theme/Palette.swift (padTabActive), docs/ipad.md
import ParalistCore
import SwiftUI

struct SplitTopBar: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @Namespace private var pill

    var body: some View {
        ZStack {
            HStack {
                SplitCircle(title: L.s(router.menuOpen ? "menu_close" : "menu_open"), active: router.menuOpen, action: router.toggleMenu) {
                    SplitGlyph(asset: "XoolMenu")
                }
                Spacer(minLength: 0)
                SplitCircle(title: L.s("ipad_sidebar"), active: router.sideOpen && !router.menuOpen, action: router.toggleSide) {
                    Image(systemName: AppIcons.sidebarRight).font(.system(size: 18, weight: .medium))
                }
            }
            tabs.padding(.horizontal, SplitDimens.button + SplitDimens.gap)
        }
        .padding(.horizontal, SplitDimens.barInset)
        .frame(height: SplitDimens.topBar)
    }

    private var tabs: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.pad(model.prefs.tabOrder), id: \.self) { tab in item(tab) }
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

    private func item(_ tab: AppTab) -> some View {
        let active = router.tab == tab
        return Button { router.tapTab(tab) } label: {
            Text(TabSlotLook.title(tab))
                .font(Typo.dm(SplitDimens.pillFont, active ? .semibold : .medium))
                .lineLimit(1)
                .foregroundStyle(Palette.tabTextActive)
                .padding(.horizontal, SplitDimens.pillEdge)
                .frame(height: SplitDimens.pillItem)
                .background {
                    if active { Capsule().fill(Palette.padTabActive).matchedGeometryEffect(id: "pill", in: pill) }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .contextMenu { TabSlotMenu(slot: tab.slot) }
        .accessibilityAddTraits(active ? .isSelected : [])
        .animation(Motion.dock, value: active)
    }
}
