// Zusammenhang: Pages/TabArrangePage.swift (TabReset), Shell/AppTabBar.swift (Kontextmenü der Reiter), Pages/MenuNavRow.swift (Drei-Punkte-Menü), Shell/Router.swift (AppTab, freshTab), App/AppPrefs.swift (tabOrder), App/AppModel.swift (say), ParalistCore Library/TabBarOrder.swift
import ParalistCore
import SwiftUI

struct TabSlotMenu: View {
    let slot: TabSlot
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    var body: some View {
        let order = model.prefs.tabOrder
        if let tab = TabSlotLook.tab(slot) {
            let shown = order.shows(tab.key)
            Toggle(L.s("tabbar_show"), isOn: Binding(get: { shown }, set: { on in settled { on ? show(tab) : hide(tab) } }))
                .disabled(shown ? !order.canHide : !order.canShow)
        }
        if let current = order.index(of: slot) {
            Section(L.s("tabbar_position")) {
                Picker(L.s("tabbar_position"), selection: Binding(get: { current }, set: { position in settled { move(to: position) } })) {
                    ForEach(Array(order.slots.enumerated()), id: \.offset) { position, other in
                        Text("\(position + 1) · \(TabSlotLook.title(other))").tag(position)
                    }
                }
                .pickerStyle(.inline)
            }
        }
        Divider()
        resetItem
    }

    private var resetItem: some View {
        Button { settled { TabReset.run(model: model, router: router) } } label: {
            Label(L.s("tabbar_reset"), systemImage: AppIcons.undo)
        }
        .disabled(model.prefs.tabOrder == AppTab.standardOrder)
    }

    private func settled(_ change: @escaping @MainActor () -> Void) {
        Task { @MainActor in
            try? await Task.sleep(for: Motion.menuSettle)
            change()
        }
    }

    private func show(_ tab: AppTab) {
        withAnimation(Motion.drawer) {
            model.prefs.tabOrder.show(tab.key)
            router.highlight(tab)
        }
        model.say(L.s("tabbar_added_hint"))
    }

    private func hide(_ tab: AppTab) {
        withAnimation(Motion.dock) { model.prefs.tabOrder.hide(tab.key) }
        router.settle(tab)
        if router.tab == tab, let first = model.prefs.tabOrder.tabs.first.flatMap(AppTab.init(rawValue:)) {
            router.tab = first
        }
    }

    private func move(to position: Int) {
        withAnimation(Motion.dock) { model.prefs.tabOrder.move(slot, to: position) }
        if let tab = TabSlotLook.tab(slot) { router.settle(tab) }
    }
}

enum TabReset {
    @MainActor
    static func run(model: AppModel, router: Router) {
        withAnimation(Motion.dock) { model.prefs.tabOrder = AppTab.standardOrder }
        router.freshTab = nil
        if !model.prefs.tabOrder.shows(router.tab.key) { router.tab = .overview }
    }
}

enum TabSlotLook {
    static func tab(_ slot: TabSlot) -> AppTab? { slot.tab.flatMap(AppTab.init(rawValue:)) }

    static func title(_ slot: TabSlot) -> String {
        switch slot {
        case .create: return L.s("nav_create")
        case .menu: return L.s("nav_menu")
        case .tab(let key): return tab(slot).map(title) ?? key
        }
    }

    static func title(_ tab: AppTab) -> String {
        switch tab {
        case .overview: return L.s("nav_overview")
        case .calendar: return L.s("nav_calendar")
        case .tasks: return L.s("nav_tasks")
        case .media: return L.s("page_media")
        case .flashcards: return L.s("page_flashcards")
        case .chats: return L.s("chat_title")
        }
    }

    static func icon(_ tab: AppTab) -> TabIcon {
        switch tab {
        case .overview: return AppIcons.overview
        case .calendar: return AppIcons.calendar
        case .tasks: return AppIcons.tasks
        case .media: return AppIcons.media
        case .flashcards: return AppIcons.flashcards
        case .chats: return AppIcons.chat
        }
    }
}
