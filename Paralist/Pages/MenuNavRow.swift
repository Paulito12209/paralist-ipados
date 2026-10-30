// Zusammenhang: Pages/MenuPage.swift, Shell/AppTabBar.swift (HintDot), Shell/TabSlotMenu.swift, Shell/Router.swift (AppTab), App/AppPrefs.swift (tabOrder), Icons/AppIcons.swift (tabShown, more)
import ParalistCore
import SwiftUI

struct MenuNavRow: View {
    let icon: String
    let title: String
    var tab: AppTab?
    var hint = false
    let allowed: () -> Bool
    let action: () -> Void
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 0) {
            Button { if allowed() { action() } } label: {
                HStack(spacing: 12) {
                    Image(systemName: icon).font(.system(size: 19)).foregroundStyle(Palette.onSurfaceVariant).frame(width: 26)
                        .overlay(alignment: .topTrailing) { if hint { HintDot().offset(x: 2, y: -3) } }
                    Text(title).font(Typo.dm(15)).foregroundStyle(Palette.onSurface)
                    Spacer()
                }
                .padding(.leading, 16)
                .padding(.trailing, tab == nil ? 16 : 8)
                .frame(height: MenuDimens.navRow)
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            if let tab {
                let order = model.prefs.tabOrder
                let shown = order.shows(tab.key)
                if shown {
                    Image(systemName: AppIcons.tabShown).font(.system(size: 15)).foregroundStyle(Palette.onSurfaceVariant)
                        .accessibilityLabel(L.s("tabbar_shown"))
                }
                if shown || order.canShow {
                    Menu { TabSlotMenu(slot: tab.slot) } label: {
                    Image(systemName: AppIcons.more).font(.system(size: 17, weight: .medium)).foregroundStyle(Palette.onSurfaceVariant)
                        .frame(width: MenuDimens.navMore, height: MenuDimens.navRow)
                        .contentShape(Rectangle())
                }
                    .menuStyle(.button)
                    .buttonStyle(.plain)
                    .accessibilityLabel(L.s("tabbar_options"))
                } else {
                    Color.clear.frame(width: MenuDimens.navMore, height: MenuDimens.navRow)
                }
            }
        }
        .padding(.horizontal, 12)
    }
}
