// Zusammenhang: ParalistCore Library/TabTap.swift (tapTab, topRequests), Shell/CreateOverlay.swift, Shell/DetailHost.swift, Shell/MediaPager.swift, Pages/MediaPage.swift, Capture/CaptureFlow.swift, Shell/RootView.swift, Shell/RouteDestination.swift, Shell/MenuDrawer.swift, Pages/MenuPage.swift, Shell/TabSlotMenu.swift (freshTab, shows), App/ParalistApp.swift (shows), App/LaunchOptions.swift, Reminders/NotificationHandler.swift, Chat/ChatListPage.swift, Shell/PageBar.swift (Menü aus Seiten außerhalb der Leiste), ParalistCore Library/TabBarLayout.swift (lift, pillDrop), Theme/EntryBarDimens.swift (entryBarPillRest), Entry/EntryToolbar.swift (EntryBottomBar), Library/TabBarOrder.swift, Pages/CalendarPage.swift (pullBlocked, moves), Shell/SplitRootView.swift (split, detailEpoch), Shell/RouterSplit.swift (openSplit, sideOpen, sidePath, toggleMenu, linked, expanded, push(from:)), Shell/SplitParts.swift, ParalistCore Library/SplitLayout.swift, docs/ipad.md
import Foundation
import Observation
import ParalistCore
import SwiftUI

enum AppTab: String, CaseIterable, Hashable {
    case overview, calendar, tasks, media, flashcards, chats

    var key: String { rawValue }
    var slot: TabSlot { .tab(rawValue) }
    static let standardOrder = TabBarOrder.standard(first: AppTab.overview.key)

    var route: Route {
        switch self {
        case .overview: return .overview
        case .calendar: return .calendar
        case .tasks: return .tasks
        case .media: return .media
        case .flashcards: return .flashcards
        case .chats: return .chats
        }
    }
}

enum Route: Hashable {
    case entry(String)
    case cover(String)
    case list(ListKind)
    case study(String?)
    case chat(String)
    case overview, calendar, tasks, media, flashcards, chats
    case progress, settings, trash, feedback, tabArrange

    var isSection: Bool {
        switch self {
        case .entry, .cover, .study, .chat: return false
        default: return true
        }
    }

    var tab: AppTab? {
        switch self {
        case .overview: return .overview
        case .calendar: return .calendar
        case .tasks: return .tasks
        case .media: return .media
        case .flashcards: return .flashcards
        case .chats: return .chats
        default: return nil
        }
    }

    var opensInDetail: Bool {
        switch self {
        case .entry, .cover, .chat, .study: return true
        default: return false
        }
    }
}

struct ComposerRequest: Identifiable, Equatable {
    let id = UUID()
    var type: EntryType
    var day: Day?
    var hour: Int?
    var url: String?
    var title: String?
    var place: String?
    var link: String?
}

struct BackupFile: Identifiable, Equatable {
    let id = UUID()
    var url: URL
}

struct LinkRequest: Identifiable, Equatable {
    let id: String
}

struct ImportRequest: Identifiable, Equatable {
    let id = UUID()
    var deck: String?
}

@MainActor
@Observable
final class Router {
    var tab: AppTab = .overview
    private(set) var paths: [AppTab: [Route]] = [:]
    var shows: (AppTab) -> Bool = { _ in true }
    var detail: Route?
    var detailPath: [Route] = []
    var split = false
    var sideOpen = true
    var sidePath: [Route] = []
    var detailEpoch = 0
    var expanded = false
    var detailSide = false
    var parked: ParkedPane?
    var linked: Route?
    var linkedPath: [Route] = []
    var linkedEpoch = 0
    var mediaQueue: [String] = []
    var detailDrop: CGFloat = 0
    var detailInCover = false
    private(set) var detailClosing = false
    var menuOpen = false
    var briefingOpen = false
    var createOpen = false
    var createLink: String?
    var importing = false
    var mediaImport = false
    private(set) var scrolledTabs: Set<AppTab> = []
    var pullBlocked = false
    private(set) var moves = 0
    private(set) var compact = false
    var camera: CaptureKind?
    var recording = false
    var composer: ComposerRequest?
    var searchOpen = false {
        didSet {
            guard !searchOpen else { return }
            searchPane = .main
            searchWide = false
            searchQuery = ""
        }
    }
    var searchPane: SearchPane = .main
    var searchWide = false
    var searchQuery = ""
    var chatSeed: String?
    var accountOpen = false
    var importCards: ImportRequest?
    var backup: BackupFile?
    var linking: LinkRequest?
    var placing: LinkRequest?
    var bottomInset: CGFloat = 0
    var freshTab: AppTab?
    private(set) var topRequests: [AppTab: Int] = [:]

    func path(_ tab: AppTab) -> [Route] { paths[tab] ?? [] }

    func binding(_ tab: AppTab) -> Binding<[Route]> {
        Binding(get: { self.path(tab) }, set: { new in
            if new.count < self.path(tab).count { self.moves += 1 }
            self.paths[tab] = new
        })
    }

    func select(_ new: AppTab) {
        guard shows(new) else {
            open(new.route)
            return
        }
        if menuOpen, new != tab, path(tab).last?.isSection ?? false { paths[tab]?.removeLast() }
        closeMenu()
        if new == tab { popToRoot(new) } else { compact = false; moves += 1 }
        tab = new
        settle(new)
    }

    func tapTab(_ new: AppTab) {
        switch TabTap.action(current: tab.key, tapped: new.key, depth: path(tab).count, compact: compact) {
        case .switchTab, .popToRoot: select(new)
        case .scrollToTop: topRequests[new, default: 0] += 1
        case .none: break
        }
    }

    func topRequest(_ tab: AppTab) -> Int { topRequests[tab] ?? 0 }

    func settle(_ tab: AppTab) {
        if freshTab == tab { freshTab = nil }
    }

    func highlight(_ tab: AppTab) {
        menuOpen = false
        freshTab = tab
    }

    func openMenu() {
        withAnimation(Motion.drawer) { menuOpen = true }
    }

    func closeMenu() {
        guard menuOpen else { return }
        withAnimation(Motion.drawer) { menuOpen = false }
    }

    func openBriefing() {
        closeMenu()
        briefingOpen = true
    }

    func openFromBriefing(_ route: Route) {
        briefingOpen = false
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            open(route)
        }
    }

    func popToRoot(_ tab: AppTab) {
        paths[tab] = []
    }

    var detailCovers: Bool { detail != nil && !split }

    func push(_ route: Route) {
        if detail != nil { detailPath.append(route) } else { open(route) }
    }

    func appendSection(_ route: Route) {
        let swap = menuOpen && route.isSection && (path(tab).last?.isSection ?? false)
        closeMenu()
        if swap { paths[tab, default: []].removeLast() }
        paths[tab, default: []].append(route)
        moves += 1
    }

    func open(_ route: Route) {
        if split {
            openSplit(route)
            return
        }
        if detail != nil {
            detailPath.append(route)
            return
        }
        if let target = route.tab, shows(target) {
            select(target)
            return
        }
        compact = false
        let swap = menuOpen && route.isSection && (path(tab).last?.isSection ?? false)
        closeMenu()
        switch route {
        case .entry, .cover: detail = route
        default:
            if swap { paths[tab, default: []].removeLast() }
            paths[tab, default: []].append(route)
            moves += 1
        }
    }

    func openChat(with entryId: String, newId: String) {
        closeDetail()
        chatSeed = entryId
        open(.chats)
        open(.chat(newId))
    }

    func openMedia(_ id: String, among queue: [String]) {
        if split {
            open(.cover(id))
            mediaQueue = queue
            return
        }
        if detail == nil { mediaQueue = queue }
        open(.cover(id))
    }

    func closeDetail() {
        createLink = nil
        detail = nil
        detailPath = []
        mediaQueue = []
        linked = nil
        linkedPath = []
        expanded = false
        detailSide = false
        parked = nil
    }

    func dropDetail(_ height: CGFloat) {
        guard !detailClosing else { return }
        if split {
            closeDetail()
            return
        }
        detailClosing = true
        withAnimation(.easeOut(duration: 0.2)) { detailDrop = height } completion: {
            var quiet = Transaction()
            quiet.disablesAnimations = true
            withTransaction(quiet) { self.closeDetail() }
            self.detailDrop = 0
            self.detailClosing = false
        }
    }

    func setScrolled(_ tab: AppTab, _ away: Bool) {
        guard away != scrolledTabs.contains(tab) else { return }
        withAnimation(Motion.dock) {
            if away { scrolledTabs.insert(tab) } else { scrolledTabs.remove(tab) }
        }
    }

    func setCompact(_ value: Bool) {
        guard value != compact else { return }
        withAnimation(Motion.dock) { compact = value }
    }

    func track(_ tab: AppTab, offset: CGFloat, delta: CGFloat) {
        guard tab == self.tab else { return }
        let away = offset > Dimens.headerHeight
        setScrolled(tab, away)
        if !away {
            setCompact(false)
        } else if delta > Dimens.collapseStep {
            setCompact(true)
        } else if delta < -Dimens.collapseStep {
            setCompact(false)
        }
    }

    var searchBarDocked: Bool {
        scrolledTabs.contains(tab) && path(tab).isEmpty
    }

    var tabBarLift: CGFloat {
        TabBarLayout.lift(safeAreaBottom: bottomInset, clearance: TabBarDimens.clearance, dip: TabBarDimens.dip, rest: TabBarDimens.rest)
    }

    var entryPillDrop: CGFloat {
        TabBarLayout.pillDrop(safeAreaBottom: bottomInset, lift: tabBarLift, barHeight: Dimens.entryBarHeight,
                              pillHeight: Dimens.entryBarPillHeight, rest: Dimens.entryBarPillRest, clearance: TabBarDimens.clearance)
    }

    var tabBarFloor: CGFloat {
        if split { return SplitDimens.floor }
        return TabBarLayout.reserve(lift: tabBarLift, height: TabBarDimens.height, docked: true, compact: false,
                             compactHeight: TabBarDimens.compact, pillHeight: TabBarDimens.searchPill, gap: TabBarDimens.gap)
    }

    var tabBarReserve: CGFloat {
        if split { return SplitDimens.floor }
        return TabBarLayout.reserve(lift: tabBarLift, height: TabBarDimens.height, docked: searchBarDocked, compact: compact,
                             compactHeight: TabBarDimens.compact, pillHeight: TabBarDimens.searchPill, gap: TabBarDimens.gap)
    }

    var hidesTabBar: Bool { !path(tab).isEmpty }

    func openCreate(link: String? = nil) {
        createLink = link
        withAnimation(Motion.create) { createOpen = true }
    }

    func closeCreate() {
        withAnimation(Motion.create) { createOpen = false }
    }

    func compose(_ request: ComposerRequest) {
        guard createOpen else {
            composer = request
            return
        }
        closeCreate()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            composer = request
        }
    }

    func back() {
        _ = paths[tab, default: []].popLast()
    }
}

enum SearchPane {
    case main
    case side
}

extension Router {
    func openSearch(in pane: SearchPane) {
        searchPane = pane
        searchOpen = true
    }

    func searchShows(in pane: SearchPane) -> Bool {
        searchOpen && split && !searchWide && searchPane == pane
    }

    var searchCoversWindow: Bool {
        searchOpen && (!split || searchWide)
    }
}
