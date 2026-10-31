// Zusammenhang: Shell/Router.swift (split, sideOpen, sidePath, appendSection, linked, expanded), Shell/SplitRootView.swift, Shell/SplitTopBar.swift, Shell/SplitParts.swift (SplitExpandButton, DetailRootClose), Shell/DetailHost.swift (pane), Shell/CategoryPanel.swift, Entry/EntryPage.swift, Entry/EntryToolbar.swift, Entry/EntryBlocks.swift, Flashcards/DeckSection.swift, Chat/ChatThreadParts.swift, App/ParalistApp.swift (shows), ParalistCore Library/TabBarOrder.swift (padTabs), docs/ipad.md
import ParalistCore
import SwiftUI

enum DetailPane { case primary, linked }

struct ParkedPane {
    let route: Route
    let path: [Route]
    let leading: Bool
}

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
        if detailSide, detail != nil {
            withAnimation(Motion.dock) {
                if route.opensInDetail {
                    detailSide = false
                    linked = route
                    linkedPath = []
                    linkedEpoch += 1
                } else {
                    sidePath = [route]
                }
            }
            return
        }
        if route.opensInDetail {
            mediaQueue = []
            detailPath = []
            linked = nil
            linkedPath = []
            expanded = false
            detailSide = false
            parked = nil
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
            parked = nil
        }
    }

    func isExpanded(_ pane: DetailPane) -> Bool {
        expanded && linked == nil && !detailSide
    }

    func toggleExpanded(_ pane: DetailPane = .primary) {
        withAnimation(Motion.dock) {
            if paired {
                park(keeping: pane)
                expanded = true
            } else if detailSide {
                detailSide = false
                expanded = true
            } else if expanded, let stash = parked {
                unpark(stash)
            } else {
                expanded.toggle()
                parked = nil
            }
        }
    }

    func toggleDetailSide(_ pane: DetailPane = .primary) {
        closeMenu()
        withAnimation(Motion.dock) {
            if paired {
                park(keeping: pane)
                parked = nil
                expanded = true
                detailSide = true
            } else if detailSide {
                detailSide = false
            } else {
                expanded = true
                detailSide = true
                parked = nil
            }
        }
    }

    private func park(keeping pane: DetailPane) {
        guard let first = detail, let second = linked else { return }
        if pane == .linked {
            parked = ParkedPane(route: first, path: detailPath, leading: true)
            mediaQueue = []
            detail = second
            detailPath = linkedPath
            detailEpoch += 1
        } else {
            parked = ParkedPane(route: second, path: linkedPath, leading: false)
        }
        linked = nil
        linkedPath = []
    }

    private func unpark(_ stash: ParkedPane) {
        if stash.leading, let current = detail {
            linked = current
            linkedPath = detailPath
            detail = stash.route
            detailPath = stash.path
            detailEpoch += 1
        } else {
            linked = stash.route
            linkedPath = stash.path
        }
        linkedEpoch += 1
        parked = nil
        expanded = false
    }

    func toggleMenu() {
        if menuOpen { closeMenu() } else { openMenu() }
    }

    func toggleSide() {
        closeMenu()
        withAnimation(Motion.dock) {
            detailSide = false
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
