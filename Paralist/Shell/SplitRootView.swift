// Zusammenhang: Shell/RootView.swift (Umschaltung nach Fensterbreite), Shell/SplitParts.swift, Shell/SplitToolbar.swift, Shell/DetailHost.swift (inline), Shell/Router.swift (split, columns, push, detailEpoch), Shell/TabSlotMenu.swift (TabSlotLook), Shell/MenuDrawer.swift, Shell/AppSheets.swift, Shell/CreateOverlay.swift, Theme/SplitDimens.swift, ParalistCore Library/SplitLayout.swift, docs/ipad.md
import ParalistCore
import SwiftUI
import UIKit

@MainActor
enum SplitMetrics {
    static func list(for width: CGFloat) -> CGFloat? {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return nil }
        return SplitLayout.listWidth(total: Double(width), minList: Double(SplitDimens.minList), minDetail: Double(SplitDimens.minDetail))
            .map { CGFloat($0) }
    }

    static var sceneWidth: CGFloat {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        return scene?.coordinateSpace.bounds.width ?? 0
    }
}

struct SplitRootView: View {
    let listWidth: CGFloat
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    var body: some View {
        TabView(selection: Binding(get: { router.tab }, set: { if $0 != router.tab { router.select($0) } })) {
            ForEach(tabs, id: \.self) { tab in
                Tab(TabSlotLook.title(tab), systemImage: TabSlotLook.icon(tab).outlined, value: tab) {
                    SplitTabContent(tab: tab, listWidth: listWidth)
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tint(Palette.onSurface)
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

    private var tabs: [AppTab] {
        model.prefs.tabOrder.tabs.compactMap(AppTab.init(rawValue:))
    }
}

struct SplitTabContent: View {
    let tab: AppTab
    let listWidth: CGFloat
    @Environment(Router.self) private var router

    var body: some View {
        NavigationSplitView(columnVisibility: Binding(get: { router.columns }, set: { router.columns = $0 })) {
            NavigationStack(path: router.binding(tab)) {
                TabRoot(tab: tab).sectionChrome(tab, manualHeader: tab == .calendar).splitToolbar(tab).routeDestinations()
            }
            .navigationSplitViewColumnWidth(listWidth)
        } detail: {
            detail
        }
        .navigationSplitViewStyle(.balanced)
        .background(Palette.background.ignoresSafeArea())
    }

    @ViewBuilder
    private var detail: some View {
        if router.detail != nil {
            DetailHost(inline: true).id(router.detailEpoch)
        } else {
            NavigationStack { SplitPlaceholder() }
        }
    }
}
