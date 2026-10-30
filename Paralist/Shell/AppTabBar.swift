// Zusammenhang: Pages/MediaBar.swift (Werkzeuge der Medien-Wurzel), Shell/RootView.swift, Shell/Router.swift (tapTab, compact, searchBarDocked, freshTab), Shell/TabSlotMenu.swift, Shell/SectionChrome.swift, Pages/CalendarPage.swift, Pages/TasksPage.swift (tasksHintSeen), App/AppPrefs.swift (tabOrder, tabLabels, navHintSeen, chatHintSeen), ParalistCore Chat/ChatHint.swift, Pages/MenuPage.swift (HintDot), Pages/SettingsNavigation.swift (HintPulse), Theme/Dimens.swift (TabBarDimens), ParalistCore Library/TabBarOrder.swift
import ParalistCore
import SwiftUI
import UIKit

struct AppTabBar: View {
    @Environment(Router.self) private var router
    @Environment(AppModel.self) private var model
    @Namespace private var glass
    @Namespace private var pill
    @State private var keyboard = false

    var body: some View {
        let docked = router.searchBarDocked
        let compact = docked && router.compact
        let slots = model.prefs.tabOrder.slots
        let tools = router.tab == .media && router.path(.media).isEmpty
        let barHeight = compact ? TabBarDimens.compact : TabBarDimens.height
        let toolsLift = tools ? TabBarDimens.tools + TabBarDimens.gap : 0
        let slot = model.prefs.tabLabels ? TabBarDimens.slot : TabBarDimens.bareSlot
        let width = CGFloat(slots.count) * slot + 2 * TabBarDimens.inset
        Group {
            if !keyboard {
                GlassEffectContainer(spacing: TabBarDimens.gap) {
                    ZStack(alignment: .bottom) {
                        if docked && !compact {
                            searchPill.padding(.bottom, barHeight + TabBarDimens.gap + toolsLift)
                        }
                        if tools {
                            MediaBar(importing: Binding(get: { router.mediaImport }, set: { router.mediaImport = $0 }))
                                .padding(.bottom, barHeight + TabBarDimens.gap)
                        }
                        HStack(alignment: .bottom, spacing: TabBarDimens.gap) {
                            if compact {
                                activeCircle
                                search
                                plusCircle
                            } else {
                                fullBar(slots, width: width)
                            }
                        }
                    }
                }
                .frame(height: TabBarDimens.height, alignment: .bottom)
                .padding(.horizontal, TabBarDimens.edge)
                .padding(.bottom, router.tabBarLift)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in keyboard = true }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in keyboard = false }
    }

    private func fullBar(_ slots: [TabSlot], width: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(slots, id: \.self) { slot in slotView(slot) }
        }
        .padding(TabBarDimens.inset)
        .frame(maxWidth: width)
        .frame(height: TabBarDimens.height)
        .glassEffect(.regular.interactive(), in: Capsule())
        .glassEffectID("bar", in: glass)
    }

    @ViewBuilder
    private func slotView(_ slot: TabSlot) -> some View {
        switch slot {
        case .tab: if let tab = TabSlotLook.tab(slot) { item(tab) }
        case .create: createItem
        case .menu: menuItem
        }
    }

    private func item(_ tab: AppTab) -> some View {
        let active = router.tab == tab
        return Button { router.tapTab(tab) } label: {
            label(TabSlotLook.title(tab)) { icon(tab, active: active) }
                .background {
                    if active { Capsule().fill(Palette.tabActive).matchedGeometryEffect(id: "pill", in: pill) }
                }
                .overlay { if router.freshTab == tab { HintPulse(size: TabBarDimens.pulseRing) } }
        }
        .buttonStyle(.plain)
        .contextMenu { TabSlotMenu(slot: tab.slot) }
        .accessibilityAddTraits(active ? .isSelected : [])
    }

    private var createItem: some View {
        Button { router.openCreate() } label: {
            label(L.s("nav_create")) { plusGlyph }
        }
        .buttonStyle(.plain)
        .contextMenu { TabSlotMenu(slot: .create) }
    }

    private var menuItem: some View {
        Button { router.openMenu() } label: {
            label(L.s("nav_menu")) { menuGlyph.overlay(alignment: .topTrailing) { if !model.prefs.navHintSeen || chatHint.menuDot { HintDot().offset(x: 3, y: -3) } } }
                .background {
                    if router.menuOpen { Capsule().fill(Palette.tabActive).matchedGeometryEffect(id: "pill", in: pill) }
                }
        }
        .buttonStyle(.plain)
        .contextMenu { TabSlotMenu(slot: .menu) }
        .accessibilityAddTraits(router.menuOpen ? .isSelected : [])
    }

    private func label<Icon: View>(_ text: String, @ViewBuilder icon: () -> Icon) -> some View {
        VStack(spacing: 2) {
            icon().frame(height: TabBarDimens.assetIcon)
            if model.prefs.tabLabels {
                Text(text).font(Typo.dm(TabBarDimens.label, .medium)).lineLimit(1).minimumScaleFactor(0.8)
            }
        }
        .foregroundStyle(Palette.tabTextActive)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }

    @ViewBuilder
    private func icon(_ tab: AppTab, active: Bool) -> some View {
        let glyph = Image(systemName: TabSlotLook.icon(tab).resolve(active)).font(.system(size: TabBarDimens.icon))
        if tab == .tasks {
            glyph.overlay(alignment: .topTrailing) {
                if !model.prefs.tasksHintSeen { HintDot().offset(x: 5, y: -3) }
            }
        } else if tab == .chats {
            glyph.overlay(alignment: .topTrailing) {
                if chatHint.chatsTabDot { HintDot().offset(x: 5, y: -3) }
            }
        } else {
            glyph
        }
    }

    private var chatHint: ChatHintPlacement {
        ChatHint.placement(seen: model.prefs.chatHintSeen, chatsInTabBar: model.prefs.tabOrder.shows(AppTab.chats.key))
    }

    private var menuGlyph: some View {
        Image("XoolMenu").renderingMode(.template).resizable().scaledToFit()
            .frame(width: TabBarDimens.assetIcon, height: TabBarDimens.assetIcon)
    }

    private var plusGlyph: some View {
        Image("XoolPlus").renderingMode(.template).resizable().scaledToFit()
            .frame(width: TabBarDimens.assetIcon, height: TabBarDimens.assetIcon)
            .foregroundStyle(Palette.level)
    }

    private var activeCircle: some View {
        Button { router.setCompact(false) } label: {
            icon(router.tab, active: true)
                .foregroundStyle(Palette.tabTextActive)
                .frame(width: TabBarDimens.compact, height: TabBarDimens.compact)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Circle())
        .glassEffectID("bar", in: glass)
        .accessibilityLabel(TabSlotLook.title(router.tab))
    }

    private var plusCircle: some View {
        Button { router.openCreate() } label: {
            plusGlyph
                .frame(width: TabBarDimens.compact, height: TabBarDimens.compact)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Circle())
        .glassEffectID("plus", in: glass)
        .accessibilityLabel(L.s("nav_create"))
    }

    private var searchPill: some View {
        Button { router.searchOpen = true } label: {
            HStack(spacing: 6) {
                Image(systemName: AppIcons.search).font(.system(size: TabBarDimens.searchPillIcon, weight: .semibold))
                Text(L.s("search_submit")).font(Typo.dm(TabBarDimens.searchPillText, .medium)).lineLimit(1)
            }
            .foregroundStyle(Palette.onSurfaceVariant)
            .padding(.horizontal, TabBarDimens.searchPillEdge)
            .frame(height: TabBarDimens.searchPill)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Capsule())
        .glassEffectID("search", in: glass)
    }

    private var search: some View {
        Button { router.searchOpen = true } label: {
            HStack(spacing: 8) {
                Image(systemName: AppIcons.search).font(.system(size: 15, weight: .medium))
                Text(L.s("search_hint")).font(Typo.bodyLarge).lineLimit(1)
                Spacer(minLength: 0)
            }
            .foregroundStyle(Palette.onSurfaceVariant)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: TabBarDimens.compact)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Capsule())
        .glassEffectID("search", in: glass)
    }
}

struct HintPulse: View {
    let size: CGFloat

    var body: some View {
        Circle().stroke(Palette.level, lineWidth: 2)
            .frame(width: size, height: size)
            .phaseAnimator([false, true]) { ring, waving in
                ring.scaleEffect(waving ? TabBarDimens.pulseScale : 1).opacity(waving ? 0 : 0.9)
            } animation: { waving in
                waving ? .easeOut(duration: TabBarDimens.pulseSeconds) : .linear(duration: 0.01)
            }
            .allowsHitTesting(false)
    }
}

struct HintDot: View {
    var body: some View {
        Circle().fill(Palette.level).frame(width: MenuDimens.updateDot, height: MenuDimens.updateDot)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
