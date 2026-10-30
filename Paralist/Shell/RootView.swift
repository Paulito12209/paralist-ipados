// Zusammenhang: Shell/AppTabBar.swift, Shell/MenuDrawer.swift, Shell/CreateOverlay.swift, Shell/Router.swift, Shell/SectionChrome.swift, Shell/RouteDestination.swift, Shell/AppSheets.swift, Shell/TabSlotMenu.swift (TabSlotLook), Shell/SplitRootView.swift (SplitMetrics), Pages/*, Chat/ChatListPage.swift
import ParalistCore
import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    @State private var width = SplitMetrics.sceneWidth

    var body: some View {
        let list = SplitMetrics.list(for: width)
        Group {
            if let list { SplitRootView(listWidth: list) } else { phone }
        }
        .background {
            Color.clear.onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        }
        .onChange(of: list != nil, initial: true) { _, now in router.split = now }
    }

    private var phone: some View {
        ZStack {
            ForEach(AppTab.allCases, id: \.self) { tab in
                let active = router.tab == tab
                NavigationStack(path: router.binding(tab)) {
                    TabRoot(tab: tab).sectionChrome(tab, manualHeader: tab == .calendar).routeDestinations()
                }
                .opacity(active ? 1 : 0)
                .allowsHitTesting(active)
                .accessibilityHidden(!active)
                .zIndex(active ? 1 : 0)
            }
        }
        .tint(Palette.onSurface)
        .safeAreaInset(edge: .bottom, spacing: 0) { if !router.hidesTabBar { AppTabBar() } }
        .background {
            Color.clear
                .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.bottom } action: { router.bottomInset = $0 }
                .ignoresSafeArea(.keyboard)
        }
        .menuDrawer()
        .appSheets()
        .overlay { CreateOverlay() }
        .overlay(alignment: .bottom) { NoticeBar(top: false) }
        .overlay(alignment: .top) { NoticeBar(top: true) }
    }
}

struct TabRoot: View {
    let tab: AppTab

    var body: some View {
        switch tab {
        case .overview: OverviewPage()
        case .calendar: CalendarPage()
        case .tasks: TasksPage()
        case .media: MediaPage()
        case .flashcards: FlashcardsPage()
        case .chats: ChatListPage()
        }
    }
}

struct NoticeBar: View {
    let top: Bool
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    var body: some View {
        if let notice = model.notice, notice.top == top {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: ComposerDimens.counterGap) {
                    if let title = notice.title {
                        Text(title).font(Typo.titleMedium).foregroundStyle(Palette.onSurface).lineLimit(1)
                    }
                    Text(notice.text).font(notice.title == nil ? Typo.bodyMedium : Typo.bodySmall).foregroundStyle(Palette.onSurface).lineLimit(2)
                }
                Spacer(minLength: 0)
                if let id = notice.undoId {
                    Button(L.s("entry_undo")) {
                        model.restore(id)
                        model.notice = nil
                    }
                    .font(Typo.labelLarge)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .glassEffect(.regular, in: notice.title == nil ? AnyShape(Capsule()) : AnyShape(RoundedRectangle(cornerRadius: ComposerDimens.radius, style: .continuous)))
            .overlay {
                if notice.success {
                    RoundedRectangle(cornerRadius: ComposerDimens.radius, style: .continuous).strokeBorder(Palette.success, lineWidth: 1.5)
                }
            }
            .padding(.horizontal, 16)
            .padding(top ? .top : .bottom, top ? Dimens.navBarClearance : (router.split ? SplitDimens.margin : Dimens.tabBarClearance))
            .transition(.move(edge: top ? .top : .bottom).combined(with: .opacity))
            .task(id: notice.id) {
                try? await Task.sleep(for: .seconds(notice.undoId == nil ? 3 : 6))
                if model.notice?.id == notice.id { withAnimation(Motion.short) { model.notice = nil } }
            }
        }
    }
}
