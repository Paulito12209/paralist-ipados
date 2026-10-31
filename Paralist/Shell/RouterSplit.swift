// Zusammenhang: Shell/Router.swift (split, sideOpen, sidePath, appendSection, linked, expanded), Shell/SplitRootView.swift, Shell/SplitTopBar.swift, Shell/SplitParts.swift (SplitExpandButton, DetailRootClose), Shell/DetailHost.swift (pane), Shell/CategoryPanel.swift, Entry/EntryPage.swift, Entry/EntryToolbar.swift, Entry/EntryBlocks.swift, Flashcards/DeckSection.swift, Chat/ChatThreadParts.swift, App/ParalistApp.swift (shows), ParalistCore Library/TabBarOrder.swift (padTabs), docs/ipad.md
import ParalistCore
import SwiftUI

enum DetailPane { case primary, linked }

extension EnvironmentValues {
    @Entry var detailPane: DetailPane = .primary
}

extension AppTab {
    static let padCore: [AppTab] = [.overview, .tasks, .calendar]

    static func pad(_ order: TabBarOrder) -> [AppTab] {
        order.padTabs(padCore.map(\.key)).compactMap(AppTab.init(rawValue:))
    }
}

extension Router {
    var paired: Bool { split && detail != nil && linked != nil }

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
            linked = nil
            linkedPath = []
            expanded = false
            detailEpoch += 1
            detail = route
        } else {
            closeDetail()
            sidePath = [route]
        }
        withAnimation(Motion.dock) { sideOpen = true }
    }

    func push(_ route: Route, from pane: DetailPane) {
        guard split, detail != nil, route.opensInDetail else {
            if pane == .linked, split { linkedPath.append(route) } else { push(route) }
            return
        }
        withAnimation(Motion.dock) {
            if pane == .linked, let current = linked {
                mediaQueue = []
                detail = current
                detailPath = linkedPath
                detailEpoch += 1
            }
            linked = route
            linkedPath = []
            linkedEpoch += 1
        }
    }

    func stack(_ pane: DetailPane) -> [Route] { pane == .linked ? linkedPath : detailPath }

    func pop(_ pane: DetailPane) {
        if pane == .linked { linkedPath.removeLast() } else { detailPath.removeLast() }
    }

    func closePane(_ pane: DetailPane) {
        guard paired else {
            closeDetail()
            return
        }
        withAnimation(Motion.dock) {
            if pane == .primary, let current = linked {
                mediaQueue = []
                detail = current
                detailPath = linkedPath
                detailEpoch += 1
                expanded = false
            } else {
                expanded = true
            }
            linked = nil
            linkedPath = []
        }
    }

    func toggleExpanded() {
        withAnimation(Motion.dock) { expanded.toggle() }
    }

    func toggleMenu() {
        if menuOpen { closeMenu() } else { openMenu() }
    }

    func toggleSide() {
        closeMenu()
        withAnimation(Motion.dock) {
            if expanded { expanded = false } else { sideOpen.toggle() }
        }
    }

    func leave(_ dismiss: DismissAction, pane: DetailPane = .primary) {
        switch pane == .linked ? linked : detail {
        case .chat, .study: if split, stack(pane).isEmpty { closePane(pane) } else { dismiss() }
        default: dismiss()
        }
    }
}
