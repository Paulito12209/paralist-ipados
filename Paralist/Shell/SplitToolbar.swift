// Zusammenhang: Shell/SplitRootView.swift (SplitTabContent), Shell/SectionChrome.swift (SectionHeader, Navigationsleiste in der geteilten Ansicht), Shell/Router.swift (openMenu, openCreate, searchOpen, accountOpen), Shell/AppTabBar.swift (gleiche Zeichnungen), Pages/MediaBar.swift (gleiche Werkzeuge), Components/LevelRing.swift, Theme/SplitDimens.swift, docs/ipad.md
import ParalistCore
import SwiftUI

struct SplitToolbar: ViewModifier {
    let tab: AppTab
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { router.openMenu() } label: { SplitGlyph(asset: "XoolMenu") }
                        .accessibilityLabel(L.s("menu_open"))
                }
                if tab == .media {
                    ToolbarItem(placement: .topBarTrailing) { MediaToolsMenu() }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { router.open(.progress) } label: { Image(systemName: AppIcons.stats) }
                        .accessibilityLabel(L.s("stats_open"))
                    Button { router.searchOpen = true } label: { Image(systemName: AppIcons.search) }
                        .accessibilityLabel(L.s("search_submit"))
                    Button { router.accountOpen = true } label: {
                        LevelRing(info: XpLog.level(model.xp), name: model.prefs.profileName, stamp: model.prefs.avatarStamp)
                            .frame(width: SplitDimens.avatar, height: SplitDimens.avatar)
                    }
                    .accessibilityLabel(L.s("account_open"))
                }
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                ToolbarItem(placement: .topBarTrailing) {
                    Button { router.openCreate() } label: { SplitGlyph(asset: "XoolPlus") }
                        .accessibilityLabel(L.s("nav_create"))
                }
            }
    }
}

struct SplitGlyph: View {
    let asset: String

    var body: some View {
        Image(asset).renderingMode(.template).resizable().scaledToFit()
            .frame(width: TabBarDimens.assetIcon, height: TabBarDimens.assetIcon)
    }
}

struct MediaToolsMenu: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    var body: some View {
        Menu {
            ForEach([CaptureKind.photo, .video, .audio], id: \.self) { kind in
                Button { CaptureFlow.start(kind, router: router, model: model) } label: { Label(L.s(kind.label), systemImage: kind.icon) }
            }
            Button { router.mediaImport = true } label: { Label(L.s("list_files"), systemImage: AppIcons.attach) }
        } label: {
            Image(systemName: CaptureKind.photo.icon)
        }
        .accessibilityLabel(L.s("page_media"))
    }
}

extension View {
    func splitToolbar(_ tab: AppTab) -> some View { modifier(SplitToolbar(tab: tab)) }
}
