// Zusammenhang: Shell/RootView.swift (Umschaltung nach Fensterbreite, TabStacks), Shell/SplitTopBar.swift, Shell/SplitParts.swift, Shell/CategoryPanel.swift, Shell/DetailHost.swift (inline), Shell/Router.swift (split, detailEpoch, menuOpen), Shell/RouterSplit.swift (sideOpen, sidePath), Pages/MenuPage.swift, Pages/MediaBar.swift, Shell/AppSheets.swift, Shell/CreateOverlay.swift, Shell/RouteDestination.swift, Theme/SplitDimens.swift, Theme/Palette.swift (window), ParalistCore Library/SplitLayout.swift, docs/ipad.md
import ParalistCore
import SwiftUI
import UIKit

@MainActor
enum SplitMetrics {
    static func side(for width: CGFloat) -> CGFloat? {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return nil }
        return SplitLayout.sideWidth(total: Double(width), minSide: Double(SplitDimens.minSide), minMain: Double(SplitDimens.minMain))
            .map { CGFloat($0) }
    }

    static func sidePane(_ width: CGFloat) -> CGFloat {
        let side = SplitLayout.sideWidth(total: Double(width - SplitDimens.gap), minSide: Double(SplitDimens.minSide), minMain: 0)
        return side.map { CGFloat($0) } ?? SplitDimens.minSide
    }

    static func menu(_ width: CGFloat) -> CGFloat {
        CGFloat(SplitLayout.panelWidth(total: Double(width), minSide: Double(SplitDimens.minSide)))
    }

    static var sceneWidth: CGFloat {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        return scene?.coordinateSpace.bounds.width ?? 0
    }
}

struct SplitRootView: View {
    @Environment(Router.self) private var router
    @State private var drag: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let menu = SplitMetrics.menu(geo.size.width)
            let rest = router.menuOpen ? geo.size.width - menu : geo.size.width
            let inner = max(0, rest - 2 * SplitDimens.margin)
            let sideShown = router.sideOpen && !router.menuOpen
            HStack(spacing: 0) {
                if router.menuOpen {
                    MenuPage(lead: 0, drag: $drag, release: { _ in drag = 0 })
                        .frame(width: menu)
                        .transition(.move(edge: .leading))
                }
                HStack(spacing: SplitDimens.gap) {
                    SplitMain()
                    if sideShown {
                        SplitSide()
                            .frame(width: SplitMetrics.sidePane(inner))
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, SplitDimens.margin)
                .padding(.bottom, SplitDimens.margin)
                .frame(width: rest)
            }
        }
        .background(Palette.window.ignoresSafeArea())
        .tint(Palette.onSurface)
        .background {
            Color.clear
                .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.bottom } action: { router.bottomInset = $0 }
                .ignoresSafeArea(.keyboard)
        }
        .appSheets()
        .overlay { CreateOverlay() }
        .overlay(alignment: .bottom) { NoticeBar(top: false) }
        .overlay(alignment: .top) { NoticeBar(top: true) }
    }
}

struct SplitMain: View {
    @Environment(Router.self) private var router

    var body: some View {
        VStack(spacing: 0) {
            SplitTopBar()
            TabStacks()
        }
        .overlay(alignment: .bottom) { tools }
        .splitPane()
    }

    private var tools: some View {
        GlassEffectContainer(spacing: SplitDimens.gap) {
            VStack(alignment: .trailing, spacing: SplitDimens.gap) {
                if router.tab == .media, router.path(.media).isEmpty {
                    MediaBar(importing: Binding(get: { router.mediaImport }, set: { router.mediaImport = $0 }))
                }
                Button { router.openCreate() } label: {
                    SplitGlyph(asset: "XoolPlus", tint: Palette.level)
                        .frame(width: SplitDimens.fab, height: SplitDimens.fab)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: Circle())
                .accessibilityLabel(L.s("nav_create"))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(SplitDimens.fabInset)
    }
}

struct SplitSide: View {
    @Environment(Router.self) private var router

    var body: some View {
        @Bindable var router = router
        Group {
            if router.detail != nil {
                DetailHost(inline: true).id(router.detailEpoch)
            } else {
                NavigationStack(path: $router.sidePath) {
                    CategoryPanel().routeDestinations()
                }
            }
        }
        .splitPane()
    }
}

struct SplitPane: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.background)
            .clipShape(RoundedRectangle(cornerRadius: SplitDimens.radius, style: .continuous))
    }
}

extension View {
    func splitPane() -> some View { modifier(SplitPane()) }
}
