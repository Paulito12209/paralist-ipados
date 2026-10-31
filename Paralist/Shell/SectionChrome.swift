// Zusammenhang: Shell/RootView.swift (tabRoot für alle Reiterwurzeln), Pages/* (tabRoot), Components/LevelRing.swift, Search/SearchView.swift, Shell/AccountSheet.swift, Pages/CalendarPage.swift (pullBlocked)
import ParalistCore
import SwiftUI

struct SectionChrome: ViewModifier {
    let tab: AppTab
    let manualHeader: Bool
    @Environment(Router.self) private var router
    @State private var atTop = true
    @State private var armed = false

    func body(content: Content) -> some View {
        content
            .environment(\.tabRoot, true)
            .onScrollGeometryChange(for: Bool.self) { $0.contentOffset.y <= -$0.contentInsets.top + 1 } action: { _, top in
                atTop = top
            }
            .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { old, new in
                if !manualHeader { router.track(tab, offset: new, delta: new - old) }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 30)
                    .onChanged { armed = opensSearch($0) }
                    .onEnded { value in
                        if opensSearch(value) { router.searchOpen = true }
                        armed = false
                    }
            )
            .sensoryFeedback(.impact(weight: .medium), trigger: armed) { _, now in now }
            .background { Palette.background.ignoresSafeArea() }
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .top) {
                if !manualHeader, !router.split {
                    LinearGradient(colors: [Palette.background, Palette.background.opacity(0)], startPoint: .top, endPoint: .bottom)
                        .frame(height: Dimens.statusFade)
                        .ignoresSafeArea(edges: .top)
                        .allowsHitTesting(false)
                }
            }
    }

    private func opensSearch(_ value: DragGesture.Value) -> Bool {
        atTop && !(manualHeader && router.pullBlocked) && value.translation.height > Dimens.searchOpenSwipe && abs(value.translation.width) < value.translation.height / 2
    }
}

struct SectionHeader: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    var body: some View {
        HStack(spacing: 12) {
            Button { router.open(.progress) } label: {
                Image(systemName: AppIcons.stats).font(.system(size: 18, weight: .medium)).foregroundStyle(Palette.onSurface)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())
            .accessibilityLabel(L.s("stats_open"))
            Button { router.searchOpen = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: AppIcons.search).font(.system(size: 15, weight: .medium))
                    Text(L.s("search_hint")).font(Typo.bodyLarge).lineLimit(1)
                    Spacer(minLength: 0)
                }
                .foregroundStyle(Palette.onSurfaceVariant)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Capsule())
            Button { router.accountOpen = true } label: {
                LevelRing(info: XpLog.level(model.xp), name: model.prefs.profileName, stamp: model.prefs.avatarStamp)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())
            .accessibilityLabel(L.s("account_open"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

struct PageTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Typo.pageTitle)
            .foregroundStyle(Palette.onSurface)
            .padding(.top, Dimens.titleTop)
            .padding(.bottom, Dimens.titleBottom)
    }
}

extension EnvironmentValues {
    @Entry var tabRoot = false
}

struct HeaderRoom: ViewModifier {
    @Environment(\.tabRoot) private var tabRoot

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            if tabRoot {
                Color.clear.containerRelativeFrame(.vertical) { length, _ in length + Dimens.headerHeight + Dimens.collapseSlack }
            }
            content
        }
    }
}

extension View {
    func headerRoom() -> some View { modifier(HeaderRoom()) }

    func sectionChrome(_ tab: AppTab, manualHeader: Bool = false) -> some View { modifier(SectionChrome(tab: tab, manualHeader: manualHeader)) }
}
