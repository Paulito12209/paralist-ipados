// Zusammenhang: Shell/RootView.swift (Umschaltung nach Fensterbreite, TabStacks), Shell/SplitTopBar.swift, Shell/SplitPanes.swift (SplitRail, SplitPanes), Shell/SplitParts.swift, Shell/CategoryPanel.swift, Shell/DetailHost.swift (inline), Shell/Router.swift (split, detailEpoch), Shell/RouterSplit.swift (railShown, panelOpen), Pages/MediaBar.swift, Shell/MenuDrawer.swift, Shell/AppSheets.swift, Shell/CreateOverlay.swift, Theme/SplitDimens.swift, Theme/Palette.swift (window), ParalistCore Library/SplitLayout.swift, docs/ipad.md
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

    static func listPane(_ width: CGFloat) -> CGFloat {
        let list = SplitLayout.listWidth(total: Double(width - SplitDimens.gap), minList: Double(SplitDimens.minList), minDetail: 0)
        return list.map { CGFloat($0) } ?? SplitDimens.minList
    }

    static var sceneWidth: CGFloat {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        return scene?.coordinateSpace.bounds.width ?? 0
    }
}

struct SplitRootView: View {
    @Environment(Router.self) private var router

    var body: some View {
        GeometryReader { geo in
            let inner = max(0, geo.size.width - 2 * SplitDimens.margin)
            let rail = router.railShown
            let list = SplitMetrics.listPane(inner)
            VStack(spacing: SplitDimens.gap) {
                if !rail { SplitTopBar() }
                HStack(spacing: SplitDimens.gap) {
                    if rail {
                        SplitRail()
                    } else {
                        SplitListPane().frame(width: list)
                    }
                    detail(width: rail ? CGFloat(SplitLayout.beside(total: Double(inner), rail: Double(SplitDimens.rail), gap: Double(SplitDimens.gap))) : inner - list - SplitDimens.gap)
                }
            }
            .padding(.horizontal, SplitDimens.margin)
            .padding(.top, rail ? SplitDimens.margin : 0)
            .padding(.bottom, SplitDimens.margin)
        }
        .background(Palette.window.ignoresSafeArea())
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

    @ViewBuilder
    private func detail(width: CGFloat) -> some View {
        if router.detail != nil {
            SplitPanes(width: width)
        } else if router.panelOpen {
            CategoryPanel().splitPane()
        } else {
            SplitPlaceholder().splitPane()
        }
    }
}

struct SplitListPane: View {
    @Environment(Router.self) private var router

    var body: some View {
        TabStacks()
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
