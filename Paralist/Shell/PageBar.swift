// Zusammenhang: Shell/Router.swift (openMenu, tabBarLift, hidesTabBar), Shell/AppTabBar.swift (gleiche Glas-Knöpfe), Search/SearchView.swift und Search/SearchTextField.swift (gleiche Such-Pille mit X), Pages/ListPage.swift, Pages/TasksPage.swift, Pages/FlashcardsPage.swift, Pages/MediaPage.swift, Pages/OverviewPage.swift, Pages/CalendarPage.swift, Chat/ChatListPage.swift, Theme/Dimens.swift (PageBarDimens, TabBarDimens)
import SwiftUI

struct PageSearch {
    var query: Binding<String>
    var active: Binding<Bool>
}

struct PageBar<Add: View>: View {
    let search: PageSearch?
    let prompt: String
    @ViewBuilder let add: () -> Add
    @Environment(Router.self) private var router

    var body: some View {
        if let search, search.active.wrappedValue {
            PageSearchField(search: search, prompt: prompt)
                .transition(.opacity)
        } else {
            GlassEffectContainer(spacing: TabBarDimens.gap) {
                HStack(spacing: TabBarDimens.gap) {
                    Button { router.openMenu() } label: {
                        PageBarGlyph(asset: "XoolMenu", tint: Palette.tabTextActive)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: Circle())
                    .accessibilityLabel(L.s("menu_open"))
                    field
                    add()
                }
            }
            .padding(.horizontal, TabBarDimens.edge)
            .padding(.top, PageBarDimens.top)
            .padding(.bottom, router.tabBarLift)
            .ignoresSafeArea(.keyboard)
        }
    }

    private var field: some View {
        let text = search?.query.wrappedValue ?? ""
        return HStack(spacing: 8) {
            Button {
                if let search { withAnimation(Motion.short) { search.active.wrappedValue = true } } else { router.searchOpen = true }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: AppIcons.search).font(.system(size: 15, weight: .medium))
                    Text(text.isEmpty ? prompt : text).font(Typo.bodyLarge).lineLimit(1)
                        .foregroundStyle(text.isEmpty ? Palette.onSurfaceVariant : Palette.onSurface)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: PageBarDimens.height)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if let search, !text.isEmpty {
                Button { search.query.wrappedValue = "" } label: {
                    Image(systemName: AppIcons.clearField).font(.system(size: 16))
                        .frame(width: 28, height: 28).contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L.s("search_clear"))
            }
        }
        .foregroundStyle(Palette.onSurfaceVariant)
        .padding(.leading, 16)
        .padding(.trailing, text.isEmpty ? 16 : 10)
        .glassEffect(.regular.interactive(), in: Capsule())
    }
}

struct PageSearchField: View {
    let search: PageSearch
    let prompt: String
    @State private var focused = false

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                SearchTextField(text: search.query, focused: $focused, placeholder: prompt) { focused = false }
                    .frame(maxHeight: .infinity)
                if !search.query.wrappedValue.isEmpty {
                    Button { search.query.wrappedValue = "" } label: {
                        Image(systemName: AppIcons.clearField)
                            .font(.system(size: 20))
                            .foregroundStyle(Palette.onSurfaceVariant)
                            .frame(width: 32, height: 32)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L.s("search_clear"))
                }
            }
            .padding(.leading, 18)
            .padding(.trailing, 12)
            .frame(height: PageBarDimens.field)
            .contentShape(Capsule())
            .onTapGesture { focused = true }
            .glassEffect(.regular, in: Capsule())
            Button {
                focused = false
                search.query.wrappedValue = ""
                withAnimation(Motion.short) { search.active.wrappedValue = false }
            } label: {
                Image(systemName: AppIcons.close)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Palette.onSurface)
                    .frame(width: PageBarDimens.field, height: PageBarDimens.field)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())
            .accessibilityLabel(L.s("search_close"))
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .onAppear { focused = true }
    }
}

struct PageSearchRoom: View {
    let active: Bool

    var body: some View {
        if active { Color.clear.frame(height: PageBarDimens.searchRoom) }
    }
}

enum PageSearchAnchor {
    static let id = "page-search-top"
}

struct PageBarGlyph: View {
    let asset: String
    let tint: Color

    var body: some View {
        Image(asset).renderingMode(.template).resizable().scaledToFit()
            .frame(width: TabBarDimens.assetIcon, height: TabBarDimens.assetIcon)
            .foregroundStyle(tint)
            .frame(width: PageBarDimens.height, height: PageBarDimens.height)
            .contentShape(Circle())
    }
}

struct PageBarAdd: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) { PageBarGlyph(asset: "XoolPlus", tint: Palette.level) }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())
            .accessibilityLabel(label)
    }
}

extension View {
    func pageBar<Add: View>(_ shown: Bool = true, search: PageSearch?, prompt: String, @ViewBuilder add: @escaping () -> Add) -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            if shown { PageBar(search: search, prompt: prompt, add: add) }
        }
    }

    func pageBar(_ shown: Bool = true, search: PageSearch?, prompt: String, addLabel: String, add: @escaping () -> Void) -> some View {
        pageBar(shown, search: search, prompt: prompt) { PageBarAdd(label: addLabel, action: add) }
    }

    func pageSearchScroll(_ proxy: ScrollViewProxy, active: Bool, query: String) -> some View {
        task(id: active) {
            guard active else { return }
            try? await Task.sleep(for: .milliseconds(PageBarDimens.scrollDelay))
            withAnimation(Motion.dock) { proxy.scrollTo(PageSearchAnchor.id, anchor: .top) }
        }
        .onChange(of: query) { _, _ in
            guard active else { return }
            proxy.scrollTo(PageSearchAnchor.id, anchor: .top)
        }
    }
}
