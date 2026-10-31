// Zusammenhang: Pages/OverviewEdge.swift (Option Wechseln), Pages/OverviewTabLabel.swift (overviewSwitcher), ParalistCore Library/OverviewOptions.swift (OverviewSourceCategory), Pages/OverviewTabsPage.swift (Tabs verwalten), Pages/OverviewSections.swift (sourceTitle, sourceIcon, sourceCount, OverviewPickRow), App/AppPrefs.swift (overviewLayout), ParalistCore Library/OverviewLayout.swift, ParalistCore Library/OverviewScope.swift, Entries/TypeLook.swift (ListTitles)
import ParalistCore
import SwiftUI

struct OverviewSwitchSheet: View {
    let tabs: [String]
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var adding: String?
    @State private var managing = false
    @State private var segment: OverviewSourceCategory?

    var body: some View {
        let layout = model.prefs.overviewLayout
        let items = tabs.compactMap(layout.tab)
        let segments = Self.segments(items)
        let first = items.first.flatMap(model.overviewSource)?.category
        let chosen = segment ?? first.flatMap { segments.contains($0) ? $0 : nil } ?? .collection
        NavigationStack {
            TabView(selection: Binding(get: { chosen }, set: { segment = $0 })) {
                ForEach(segments, id: \.self) { category in
                    page(category, items: items, layout: layout).tag(category)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .safeAreaInset(edge: .top, spacing: 0) {
                Picker(L.s("overview_switch"), selection: Binding(get: { chosen }, set: { new in withAnimation(Motion.short) { segment = new } })) {
                    ForEach(segments, id: \.self) { Text(Self.label($0)).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Dimens.pageEdge)
                .padding(.vertical, 8)
            }
            .navigationTitle(L.s("overview_switch"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $adding) { OverviewSourcePicker(tabId: $0) }
            .navigationDestination(isPresented: $managing) { OverviewTabsPage() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(L.s("overview_tabs")) { managing = true }
                }
            }
        }
    }

    private func page(_ category: OverviewSourceCategory, items: [OverviewTab], layout: OverviewLayout) -> some View {
        List {
            ForEach(items) { tab in
                let shown = tab.shown(existing: model.overviewExists).filter { $0.category == category }
                let current = model.overviewSource(tab)
                Section {
                    ForEach(shown) { source in
                        Button {
                            model.prefs.overviewLayout.setActive(source, in: tab.id)
                            dismiss()
                        } label: {
                            OverviewPickRow(icon: model.sourceIcon(source), tint: Palette.onSurfaceVariant, title: model.sourceTitle(source),
                                            count: model.sourceCount(source), chosen: source == current)
                        }
                        .buttonStyle(.plain)
                    }
                    .onMove { from, to in move(tab, shown: shown, from: from, to: to) }
                    Button { adding = tab.id } label: {
                        Label(L.s("overview_add_source"), systemImage: AppIcons.add).foregroundStyle(Palette.primary)
                    }
                    .disabled(tab.sources.count >= OverviewLayout.maxSources)
                } header: {
                    if items.count > 1 { Text(model.tabTitle(tab)) }
                } footer: {
                    if tab.id == items.last?.id { Text(L.s("overview_sources_hint")).font(Typo.bodyMedium).foregroundStyle(Palette.onSurfaceVariant) }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    static func segments(_ items: [OverviewTab]) -> [OverviewSourceCategory] {
        let entries = items.contains { $0.sources.contains { $0.category == .entry } }
        return [.list, .collection] + (entries ? [.entry] : [])
    }

    static func label(_ category: OverviewSourceCategory) -> String {
        switch category {
        case .list: return L.s("overview_pick_lists")
        case .collection: return L.s("overview_pick_collections")
        case .entry: return L.s("overview_pick_entries")
        }
    }

    private func move(_ tab: OverviewTab, shown: [OverviewSource], from: IndexSet, to: Int) {
        let source = from.compactMap { tab.sources.firstIndex(of: shown[$0]) }
        let target = to < shown.count ? tab.sources.firstIndex(of: shown[to]) ?? tab.sources.count : tab.sources.count
        model.prefs.overviewLayout.moveSources(in: tab.id, from: source, to: target)
    }
}

struct OverviewSourcePicker: View {
    let tabId: String
    var creating = false
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var body: some View {
        let layout = model.prefs.overviewLayout
        let text = query.trimmingCharacters(in: .whitespaces)
        let matches = { (kinds: [ListKind]) in kinds.filter { text.isEmpty || ListTitles.of($0).localizedCaseInsensitiveContains(text) } }
        let entries = Array(OverviewScope.choices(in: model.all, query: text).prefix(Self.limit))
        List {
            kinds(matches(ListKind.collections), title: "overview_pick_collections", layout: layout)
            kinds(matches(ListKind.lists), title: "overview_pick_lists", layout: layout)
            if !entries.isEmpty {
                Section(L.s("overview_pick_entries")) {
                    ForEach(entries) { entry in
                        let look = TypeLook.of(entry)
                        toggle(.entry(entry.id), layout: layout) {
                            OverviewPickRow(icon: look.icon.outlined, tint: look.color, title: entry.title, subtitle: L.s(look.label),
                                            chosen: layout.contains(.entry(entry.id), in: tabId))
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: L.s("search_hint"))
        .navigationTitle(creating ? L.s("overview_tab_from_source") : layout.tab(tabId).map(model.tabTitle) ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func kinds(_ kinds: [ListKind], title: String, layout: OverviewLayout) -> some View {
        if !kinds.isEmpty {
            Section(L.s(title)) {
                ForEach(kinds) { kind in
                    toggle(.list(kind), layout: layout) {
                        OverviewPickRow(icon: ListTitles.icon(kind), tint: Palette.onSurfaceVariant, title: ListTitles.of(kind),
                                        count: model.count(kind), chosen: layout.contains(.list(kind), in: tabId))
                    }
                }
            }
        }
    }

    private func toggle(_ source: OverviewSource, layout: OverviewLayout, @ViewBuilder label: () -> some View) -> some View {
        let added = layout.contains(source, in: tabId)
        let full = (layout.tab(tabId)?.sources.count ?? 0) >= OverviewLayout.maxSources
        return Button {
            if creating {
                model.prefs.overviewLayout.addTab(id: tabId, source: source)
                dismiss()
            } else {
                withAnimation(Motion.short) { model.prefs.overviewLayout.toggle(source, in: tabId) }
            }
        } label: { label() }
        .buttonStyle(.plain)
        .disabled(creating ? !layout.canAddTab : added ? !layout.canRemove(source, from: tabId) : full)
    }

    private static let limit = 200
}
