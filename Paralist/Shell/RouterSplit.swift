// Zusammenhang: Shell/Router.swift (split, sideOpen, sidePath, appendSection), Shell/SplitRootView.swift, Shell/SplitTopBar.swift, Shell/CategoryPanel.swift, App/ParalistApp.swift (shows), ParalistCore Library/TabBarOrder.swift (padTabs), docs/ipad.md
import ParalistCore
import SwiftUI

extension AppTab {
    static let padCore: [AppTab] = [.overview, .tasks, .calendar]

    static func pad(_ order: TabBarOrder) -> [AppTab] {
        order.padTabs(padCore.map(\.key)).compactMap(AppTab.init(rawValue:))
    }
}

extension Router {
    func openSplit(_ route: Route) {
        if let target = route.tab, shows(target) {
            select(target)
            return
        }
        setCompact(false)
        closeMenu()
        if route.opensInDetail {
            mediaQueue = []
            detailPath = []
            detailEpoch += 1
            detail = route
        } else {
            closeDetail()
            sidePath = [route]
        }
        withAnimation(Motion.dock) { sideOpen = true }
    }

    func toggleMenu() {
        if menuOpen { closeMenu() } else { openMenu() }
    }

    func toggleSide() {
        closeMenu()
        withAnimation(Motion.dock) { sideOpen.toggle() }
    }

    func leave(_ dismiss: DismissAction) {
        switch detail {
        case .chat, .study: if split, detailPath.isEmpty { closeDetail() } else { dismiss() }
        default: dismiss()
        }
    }
}
