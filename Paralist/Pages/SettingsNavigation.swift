// Zusammenhang: Pages/SettingsPage.swift (Abschnitt Navigation, Glow), Pages/TabArrangePage.swift (Unterseite Reiter anordnen), Shell/TabSlotMenu.swift, Shell/AppTabBar.swift (HintPulse), App/AppPrefs.swift (tabOrder, tabLabels, navHintSeen), Pages/MenuNavRow.swift, ParalistCore Library/TabBarOrder.swift
import ParalistCore
import SwiftUI

struct SettingsNavigation: View {
    @Binding var spotted: Bool
    let floor: CGFloat
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var prefs = model.prefs
        let order = prefs.tabOrder
        Section {
            Toggle(isOn: Binding(get: { prefs.tabLabels }, set: { on in
                withAnimation(Motion.dock) { prefs.tabLabels = on }
                prefs.navHintSeen = true
            })) {
                Label { VStack(alignment: .leading, spacing: 4) {
                    Text(L.s("tabbar_labels"))
                    Text(L.s("tabbar_labels_hint")).font(Typo.bodyLarge).foregroundStyle(Palette.onSurfaceVariant)
                } } icon: {
                    Image(systemName: AppIcons.tabLabels)
                        .overlay { if !prefs.navHintSeen { HintPulse(size: TabBarDimens.pulseRing) } }
                }
            }
            .onGeometryChange(for: Bool.self) { $0.frame(in: .global).midY < floor } action: { if $1 { spotted = true } }
            NavigationLink(value: Route.tabArrange) {
                Label { VStack(alignment: .leading, spacing: 4) {
                    Text(L.s("tabbar_arrange"))
                    Text(order.slots.map(TabSlotLook.title).joined(separator: " · "))
                        .font(Typo.bodyLarge).foregroundStyle(Palette.onSurfaceVariant).lineLimit(2)
                } } icon: { Image(systemName: AppIcons.sortBy) }
            }
        } header: {
            SettingsHeader(key: "menu_navigation")
        }
    }
}

struct SettingsHeader: View {
    let key: String

    var body: some View {
        Text(L.s(key))
            .font(Typo.headlineSmall)
            .foregroundStyle(Palette.onSurface)
            .textCase(nil)
            .padding(.top, 12)
            .padding(.bottom, 4)
    }
}

struct ScrollGlow: View {
    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [Palette.level.opacity(MenuDimens.glowOpacity), Palette.level.opacity(0)],
                                 center: .center, startRadius: 0, endRadius: MenuDimens.glowSize / 2))
            .frame(width: MenuDimens.glowSize, height: MenuDimens.glowSize)
            .blur(radius: MenuDimens.glowBlur)
            .phaseAnimator([0.55, 1.0]) { glow, strength in glow.opacity(strength) } animation: { _ in
                .easeInOut(duration: MenuDimens.glowSeconds)
            }
            .offset(y: MenuDimens.glowSize * (1 - MenuDimens.glowVisible))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
