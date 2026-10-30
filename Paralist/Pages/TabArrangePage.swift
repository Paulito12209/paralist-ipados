// Zusammenhang: Pages/SettingsNavigation.swift (Zeile Reiter anordnen), Shell/TabSlotMenu.swift (Optionen, TabReset), Shell/RouteDestination.swift (Route.tabArrange), App/AppPrefs.swift (tabOrder), ParalistCore Library/TabBarOrder.swift
import ParalistCore
import SwiftUI

struct TabArrangePage: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    var body: some View {
        let order = model.prefs.tabOrder
        Form {
            Section {
                ForEach(Array(order.slots.enumerated()), id: \.element) { position, slot in
                    row(slot, position: position + 1, shown: true)
                }
                ForEach(AppTab.allCases.filter { !order.shows($0.key) }, id: \.self) { tab in
                    row(tab.slot, position: nil, shown: false)
                }
            } footer: {
                Text(L.s("tabbar_settings_hint")).font(Typo.bodyMedium).foregroundStyle(Palette.onSurfaceVariant)
            }
        }
        .tint(Palette.primary)
        .foregroundStyle(Palette.onSurface)
        .environment(\.defaultMinListRowHeight, 64)
        .navigationTitle(L.s("tabbar_arrange"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L.s("tabbar_reset_short")) { TabReset.run(model: model, router: router) }
                    .disabled(order == AppTab.standardOrder)
            }
        }
    }

    private func row(_ slot: TabSlot, position: Int?, shown: Bool) -> some View {
        HStack(spacing: 12) {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text(TabSlotLook.title(slot)).foregroundStyle(shown ? Palette.onSurface : Palette.onSurfaceVariant)
                    if !shown { Text(L.s("tabbar_hidden")).font(Typo.bodyLarge).foregroundStyle(Palette.onSurfaceVariant) }
                }
            } icon: {
                Image(systemName: icon(slot)).foregroundStyle(shown ? Palette.onSurface : Palette.onSurfaceVariant)
            }
            Spacer(minLength: 0)
            Text(position.map { "\($0)" } ?? "").font(Typo.titleMedium).foregroundStyle(Palette.primary)
                .frame(width: MenuDimens.navNumber, alignment: .trailing)
            Image(systemName: shown ? AppIcons.tabShown : AppIcons.tabHidden).font(.system(size: 15))
                .foregroundStyle(Palette.onSurfaceVariant)
                .opacity(slot.tab == nil ? 0 : 1)
                .accessibilityHidden(slot.tab == nil)
                .accessibilityLabel(L.s(shown ? "tabbar_shown" : "tabbar_hidden"))
            if shown || model.prefs.tabOrder.canShow {
                Menu { TabSlotMenu(slot: slot) } label: {
                    Image(systemName: AppIcons.more).font(.system(size: 17, weight: .medium)).foregroundStyle(Palette.onSurfaceVariant)
                        .frame(width: MenuDimens.navMore, height: MenuDimens.navMore)
                        .contentShape(Rectangle())
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
                .accessibilityLabel(L.s("tabbar_options"))
            } else {
                Color.clear.frame(width: MenuDimens.navMore, height: MenuDimens.navMore)
            }
        }
    }

    private func icon(_ slot: TabSlot) -> String {
        switch slot {
        case .create: return AppIcons.add
        case .menu: return AppIcons.menu.outlined
        case .tab: return TabSlotLook.tab(slot).map { TabSlotLook.icon($0).outlined } ?? AppIcons.more
        }
    }
}
