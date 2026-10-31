// Zusammenhang: Chat/ChatListPage.swift (ChatRow), Shell/Router.swift (Chat-Reiter öffnet die Suche mit Chat-Bereich), ParalistCore Library/EntryLibrary.swift (search, usage), Shell/AppSheets.swift, Search/SearchTextField.swift, Search/SearchResultRow.swift, Search/SearchFilterSheet.swift, Search/SearchHomeTabs.swift, Pages/FilterTabRow.swift, ParalistCore Library/ListFilter.swift
import ParalistCore
import SwiftUI

struct SearchView: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @Environment(\.colorScheme) private var scheme
    @State private var query = ""
    @State private var debounced = ""
    @State private var focused = false
    @State private var home: SearchHome = .opened
    @State private var filterTypes: Set<EntryType> = []
    @State private var category = ListFilter.all
    @State private var categoryFrame = CGRect.zero
    @State private var filterOpen = false
    @State private var reopenKeyboard = false
    @State private var chatScope = false

    private let barHeight: CGFloat = 48
    private static let space = "search"

    private var rowEdge: EdgeInsets {
        EdgeInsets(top: 0, leading: Dimens.pageEdge, bottom: 0, trailing: Dimens.pageEdge)
    }

    private var isHome: Bool {
        debounced.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                if chatScope { ChatScopeChip { withAnimation(Motion.short) { chatScope = false } } }
                else if isHome { SearchHomeTabs(selection: $home) } else { queryRow }
                List {
                    if chatScope {
                        chatRows
                    } else if isHome {
                        homeRows
                    } else {
                        let results = filtered(model.search(debounced))
                        if results.isEmpty {
                            Text(L.s("search_no_results")).font(Typo.bodyLarge).foregroundStyle(Palette.onSurfaceVariant)
                                .listRowInsets(rowEdge)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                        ForEach(results) { entry in
                            entryRow(entry) {
                                model.recordSearch(debounced)
                                open(entry.id)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollBounceBehavior(.always, axes: .vertical)
                .scrollDismissesKeyboard(.never)
                .onScrollPhaseChange { _, phase in
                    if phase == .interacting, focused { focused = false }
                }
            }
            .simultaneousGesture(swipeBetweenHomeTabs)
        }
        .coordinateSpace(name: Self.space)
        .safeAreaInset(edge: .bottom, spacing: 0) { fieldBar }
        .background {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Palette.scrim.opacity(scheme == .dark ? Dimens.searchDimDark : Dimens.searchDimLight)
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $filterOpen, onDismiss: {
            if reopenKeyboard { focused = true }
            reopenKeyboard = false
        }) {
            SearchFilterSheet(selected: $filterTypes)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(Dimens.sheetRadius)
        }
        .onAppear {
            home = model.searchHomeStart
            query = router.searchQuery
            chatScope = router.tab == .chats && router.path(.chats).isEmpty
        }
        .onChange(of: query) { _, value in router.searchQuery = value }
        .task(id: query) {
            try? await Task.sleep(for: .milliseconds(150))
            debounced = String(query.prefix(100))
        }
    }

    private var queryRow: some View {
        Button { submitQuery() } label: {
            HStack(spacing: 12) {
                Image(systemName: AppIcons.search)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Palette.onSurface)
                Text(query)
                    .font(Typo.bodyLarge)
                    .foregroundStyle(Palette.onSurface)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(Palette.surfaceHighest.opacity(0.85), in: RoundedRectangle(cornerRadius: Dimens.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Dimens.cardRadius, style: .continuous)
                    .strokeBorder(Palette.onSurface.opacity(0.35), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: Dimens.cardRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Dimens.pageEdge)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var fieldBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                SearchTextField(text: $query, focused: $focused, placeholder: L.s(chatScope ? "chat_search" : "search_hint")) { submitQuery() }
                    .frame(maxHeight: .infinity)
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: AppIcons.clearField)
                            .font(.system(size: 20))
                            .foregroundStyle(Palette.onSurfaceVariant)
                            .frame(width: 32, height: 32)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L.s("search_clear"))
                }
                if !chatScope { Button { openFilter() } label: {
                    Image(systemName: filterTypes.isEmpty ? AppIcons.filter : AppIcons.filterActive)
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(filterTypes.isEmpty ? Palette.onSurfaceVariant : Palette.filterActive)
                        .frame(width: 32, height: 32)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L.s("search_filter_title")) }
            }
            .padding(.leading, 18)
            .padding(.trailing, 12)
            .frame(height: barHeight)
            .contentShape(Capsule())
            .onTapGesture { focused.toggle() }
            .glassEffect(.regular, in: Capsule())
            Button { close() } label: {
                Image(systemName: AppIcons.close)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Palette.onSurface)
                    .frame(width: barHeight, height: barHeight)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())
            .accessibilityLabel(L.s("search_close"))
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    private var swipeBetweenHomeTabs: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .named(Self.space))
            .onEnded { value in
                let dx = value.translation.width
                guard isHome, !categoryFrame.contains(value.startLocation),
                      abs(dx) > Dimens.swipeThreshold, abs(dx) > abs(value.translation.height) * 1.5 else { return }
                withAnimation(Motion.short) { home = home.step(dx < 0) }
            }
    }

    private func entryRow(_ entry: Entry, onOpen: @escaping () -> Void) -> some View {
        SearchResultRow(entry: entry, onOpen: onOpen)
            .listRowInsets(EdgeInsets(top: 3, leading: Dimens.pageEdge, bottom: 3, trailing: Dimens.pageEdge))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    @ViewBuilder
    private var homeRows: some View {
        switch home {
        case .opened, .created:
            let all = filtered(home == .opened ? model.rows(model.usage.recent.map(\.id)) : model.recentlyCreated)
            let tabs = ListFilter.visible(for: .archive, in: all)
            let active = tabs.contains(category) ? category : .all
            let rows = all.filter(active.matches)
            if tabs.count > 1 {
                FilterTabRow(items: tabs, selection: Binding(get: { active }, set: { category = $0 }), label: \.label) { tab in
                    all.filter(tab.matches).count
                }
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.space)) } action: { categoryFrame = $0 }
                .onDisappear { categoryFrame = .zero }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            if rows.isEmpty { hint }
            ForEach(rows) { entry in
                entryRow(entry) { open(entry.id) }
            }
        case .searched:
            let searches = model.usage.recentSearches
            if searches.isEmpty { hint }
            ForEach(searches, id: \.query) { item in
                Button { query = item.query } label: {
                    Label(item.query, systemImage: AppIcons.search).font(Typo.bodyLarge).foregroundStyle(Palette.onSurface)
                }
                .listRowInsets(rowEdge)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .contextMenu {
                    Button(role: .destructive) { model.forgetSearch(item.query) } label: {
                        Label(L.s("search_forget"), systemImage: AppIcons.delete)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var chatRows: some View {
        let threads = model.chats.search(debounced)
        if threads.isEmpty {
            Text(L.s("chat_no_results")).font(Typo.bodyLarge).foregroundStyle(Palette.onSurfaceVariant)
                .listRowInsets(rowEdge)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
        ForEach(threads) { thread in
            ChatRow(thread: thread) {
                close()
                router.open(.chat(thread.id))
            }
            .listRowInsets(EdgeInsets(top: 3, leading: Dimens.pageEdge, bottom: 3, trailing: Dimens.pageEdge))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }

    private var hint: some View {
        Text(L.s("search_empty_hint")).font(Typo.bodyMedium).foregroundStyle(Palette.muted)
            .listRowInsets(rowEdge)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    private func filtered(_ entries: [Entry]) -> [Entry] {
        filterTypes.isEmpty ? entries : entries.filter { filterTypes.contains($0.type) }
    }

    private func openFilter() {
        reopenKeyboard = focused
        focused = false
        filterOpen = true
    }

    private func submitQuery() {
        model.recordSearch(query)
        focused = false
    }

    private func close() {
        router.searchOpen = false
    }

    private func open(_ id: String) {
        close()
        router.open(.entry(id))
    }
}

private struct ChatScopeChip: View {
    let remove: () -> Void

    var body: some View {
        HStack {
            Button(action: remove) {
                HStack(spacing: 6) {
                    Image(systemName: AppIcons.chat.outlined).font(.system(size: 14, weight: .medium))
                    Text(L.s("chat_title")).font(Typo.dm(14, .medium))
                    Image(systemName: AppIcons.close).font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(Palette.tabTextActive)
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(Palette.tabActive, in: Capsule())
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L.s("chat_title"))
            .accessibilityHint(L.s("search_clear"))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Dimens.pageEdge)
        .padding(.vertical, 10)
    }
}
