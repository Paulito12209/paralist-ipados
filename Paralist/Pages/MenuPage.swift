// Zusammenhang: Pages/NavRulesSheet.swift, App/StoreLinks.swift (Update-Knopf), Shell/MenuDrawer.swift Shell/Router.swift, Pages/MenuHead.swift, Pages/MenuNavRow.swift, Shell/TabSlotMenu.swift, Shell/AppTabBar.swift (HintDot), ParalistCore Chat/ChatHint.swift, Pages/SettingsPage.swift (Index neu aufbauen), App/AppPrefs.swift (language)
import ParalistCore
import SwiftUI

struct MenuPage: View {
    let lead: CGFloat
    @Binding var drag: CGFloat
    let release: (CGFloat) -> Void
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @Environment(\.colorScheme) private var scheme
    @Environment(\.openURL) private var openURL
    @GestureState private var axis: Axis?
    @State private var swipedAt = Date.distantPast
    @State private var tilesFrame = CGRect.zero
    @State private var rules = false

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: -Dimens.sheetRadius) {
                    MenuHead(topInset: geo.safeAreaInsets.top, lead: lead)
                    VStack(alignment: .leading, spacing: 0) {
                        tiles
                        HStack(spacing: 6) {
                            Text(L.s("menu_navigation").uppercased())
                                .font(Typo.dm(12, .semibold)).tracking(0.7)
                                .foregroundStyle(Palette.onSurfaceVariant)
                            Button { if tapAllowed { rules = true } } label: {
                                Image(systemName: AppIcons.info).font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Palette.onSurfaceVariant)
                                    .frame(width: MenuDimens.infoTap, height: MenuDimens.infoTap).contentShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(L.s("tabbar_rules_title"))
                        }
                        .padding(.leading, 28).padding(.top, 16).padding(.bottom, 12)
                        ForEach(AppTab.allCases, id: \.self) { tab in
                            navRow(TabSlotLook.icon(tab).outlined, TabSlotLook.title(tab), tab: tab) { router.select(tab) }
                        }
                        Divider().overlay(Palette.outlineVariant)
                            .padding(.horizontal, MenuDimens.dividerEdge).padding(.vertical, 8)
                        navRow(AppIcons.delete, L.s("trash_title")) { router.open(.trash) }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    .padding(.leading, lead)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.menuPanel, in: UnevenRoundedRectangle(topLeadingRadius: Dimens.sheetRadius, topTrailingRadius: Dimens.sheetRadius))
                }
            }
            .ignoresSafeArea(edges: .top)
            .sheet(isPresented: $rules) { NavRulesSheet() }
            .simultaneousGesture(swipe)
            .background { VStack(spacing: 0) { Palette.menuTop; Palette.menuPanel }.ignoresSafeArea() }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                foot.padding(.leading, lead)
                .background(Palette.menuPanel.ignoresSafeArea(edges: .bottom))
            }
        }
    }

    private var tiles: some View {
        let week = Week.of(model.today)
        let seen = model.prefs.briefingSeenWeek == week.monday.epochDay
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                tile(AppIcons.favorite.filled, Palette.favorite, L.s("menu_favorites"), L.f("entries_count", model.count(.marked))) {
                    router.open(.list(.marked))
                }
                tile(AppIcons.briefing, Palette.briefing, L.s("menu_briefing"),
                     L.f("week_short", week.isoWeek) + " · " + L.s(seen ? "briefing_status_read" : "briefing_status_new")) {
                    model.prefs.briefingSeenWeek = week.monday.epochDay
                    router.openBriefing()
                }
                tile(AppIcons.stats, Palette.level, L.s("page_progress"), L.f("progress_level", XpLog.level(model.xp).level)) {
                    router.open(.progress)
                }
            }
            .padding(.horizontal, 16)
        }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { tilesFrame = $0 }
        .padding(.bottom, 16)
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: MenuDimens.dragStart, coordinateSpace: .global)
            .updating($axis) { value, axis, _ in
                guard axis == nil else { return }
                let dx = value.translation.width, dy = value.translation.height
                let horizontal = !tilesFrame.contains(value.startLocation) && abs(dx) > abs(dy) * MenuDimens.axisRatio
                axis = horizontal ? .horizontal : .vertical
            }
            .onChanged { value in
                guard axis == .horizontal else { return }
                swipedAt = .now
                drag = max(0, value.translation.width)
            }
            .onEnded { value in
                guard drag > 0 else { return }
                release(value.predictedEndTranslation.width)
            }
    }

    private var tapAllowed: Bool {
        axis != .horizontal && Date.now.timeIntervalSince(swipedAt) > MenuDimens.tapLock
    }

    private func tile(_ icon: String, _ tint: Color, _ label: String, _ sub: String, action: @escaping () -> Void) -> some View {
        Button { if tapAllowed { action() } } label: {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 22)).foregroundStyle(tint)
                VStack(alignment: .leading, spacing: 1) {
                    Text(label).font(Typo.dm(12, .medium)).foregroundStyle(Palette.onSurfaceVariant)
                    Text(sub).font(Typo.dm(13, .semibold)).foregroundStyle(Palette.onSurface)
                }
                .lineLimit(1)
            }
            .padding(.leading, 12).padding(.trailing, 14).padding(.vertical, 10)
            .background(Palette.menuTile, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func navRow(_ icon: String, _ title: String, tab: AppTab? = nil, action: @escaping () -> Void) -> some View {
        let hint = tab == .chats && ChatHint.placement(seen: model.prefs.chatHintSeen, chatsInTabBar: model.prefs.tabOrder.shows(AppTab.chats.key)).chatsRowDot
        return MenuNavRow(icon: icon, title: title, tab: tab, hint: hint, allowed: { tapAllowed }, action: action)
    }

    private var foot: some View {
        @Bindable var prefs = model.prefs
        return HStack(spacing: 4) {
            Menu {
                Picker(L.s("menu_language"), selection: $prefs.language) {
                    ForEach(AppLanguage.allCases) { Text($0.nativeName).tag($0) }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: AppIcons.language).font(.system(size: 16))
                    Text(prefs.language.nativeName).font(Typo.dm(14, .medium)).lineLimit(1).fixedSize()
                    Image(systemName: AppIcons.expandMore).font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Palette.onSurfaceVariant)
                .padding(.horizontal, 18).frame(height: TabBarDimens.height)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Capsule())
            .accessibilityLabel(L.s("menu_language"))
            Spacer()
            HStack(spacing: 0) {
                if StoreLinks.showUpdateButton {
                    footIcon(AppIcons.refresh, "menu_update", dot: model.updateAvailable) { openURL(StoreLinks.page) }
                }
                footIcon(scheme == .dark ? AppIcons.lightMode : AppIcons.darkMode, "menu_theme_toggle") {
                    model.prefs.themeMode = scheme == .dark ? .light : .dark
                }
                footIcon(AppIcons.settings, "menu_settings", hint: !model.prefs.navHintSeen) { router.open(.settings) }
            }
            .padding(.horizontal, 4)
            .glassEffect(.regular.interactive(), in: Capsule())
        }
        .padding(.horizontal, TabBarDimens.edge)
        .padding(.top, 8)
        .padding(.bottom, router.tabBarLift)
    }

    private func footIcon(_ icon: String, _ key: String, dot: Bool = false, hint: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 19)).foregroundStyle(Palette.onSurfaceVariant)
                .overlay(alignment: .topTrailing) {
                    if dot { Circle().fill(Palette.primary).frame(width: MenuDimens.updateDot, height: MenuDimens.updateDot).offset(x: 4, y: -4) }
                    if hint { HintDot().offset(x: 4, y: -4) }
                }
                .frame(width: 52, height: TabBarDimens.height).contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L.s(key))
    }
}
