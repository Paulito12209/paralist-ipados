// Zusammenhang: Shell/Router.swift (split, second, panelOpen, detailWide, paneShare, appendSection), Shell/SplitRootView.swift, Shell/SplitPanes.swift, Shell/SplitTopBar.swift, Shell/DetailHost.swift (second), Entry/EntryToolbar.swift, Shell/SplitParts.swift (DetailRootClose), docs/ipad.md
import SwiftUI

extension Router {
    var railShown: Bool { split && detail != nil && (second != nil || detailWide) }

    func openSplit(_ route: Route) {
        if let target = route.tab, shows(target) {
            select(target)
            return
        }
        setCompact(false)
        if route.opensInDetail {
            closeMenu()
            mediaQueue = []
            detailPath = []
            second = nil
            detailEpoch += 1
            detail = route
            return
        }
        appendSection(route)
    }

    func pushSplit(_ route: Route) {
        guard detail != nil, route.opensInDetail else {
            openSplit(route)
            return
        }
        withAnimation(Motion.dock) {
            secondEpoch += 1
            second = route
        }
    }

    func closeSecond() {
        withAnimation(Motion.dock) { second = nil }
    }

    func toggleWide() {
        withAnimation(Motion.dock) { detailWide.toggle() }
    }

    func togglePanel() {
        withAnimation(Motion.dock) { panelOpen.toggle() }
    }

    func leaveRail(_ tab: AppTab) {
        withAnimation(Motion.dock) {
            second = nil
            detailWide = false
        }
        tapTab(tab)
    }

    func leave(_ dismiss: DismissAction, second inSecond: Bool = false) {
        if split, inSecond {
            closeSecond()
            return
        }
        switch detail {
        case .chat, .study: if split, detailPath.isEmpty { closeDetail() } else { dismiss() }
        default: dismiss()
        }
    }
}
