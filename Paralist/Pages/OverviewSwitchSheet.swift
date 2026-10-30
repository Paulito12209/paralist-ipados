// Zusammenhang: Pages/OverviewEdge.swift (Option Liste wechseln), Pages/OverviewTabsPage.swift (Tabs verwalten), Pages/OverviewSections.swift (sourceTitle, sourceIcon, sourceCount, OverviewPickRow), App/AppPrefs.swift (overviewLayout), ParalistCore Library/OverviewLayout.swift, ParalistCore Library/OverviewScope.swift, Entries/TypeLook.swift (ListTitles)
import ParalistCore
import SwiftUI

struct OverviewSwitchSheet: View {
    let tabs: [String]
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var adding: String?
    @State private var managing = false

    var body: some View {
        let layout = model.prefs.overviewLayout
        NavigationStack {
            List {
                ForEach(tabs.compactMap(layout.tab)) { tab in
                    let shown = tab.shown(existing: model.overviewExists)
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
                            .deleteDisabled(!layout.canRemove(source, from: tab.id))
                        }
                        .onMove { from, to in move(tab, shown: shown, from: from, to: to) }
                        .onDelete { offsets in
                            withAnimation(Motion.short) { offsets.map { shown[$0] }.forEach { model.prefs.overviewLayout.toggle($0, in: tab.id) } }
                        }
                        Button { adding = tab.id } label: {
                            Label(L.s("overview_add_source"), systemImage: AppIcons.add).foregroundStyle(Palette.primary)
                        }
                        .disabled(tab.sources.count >= OverviewLayout.maxSources)
                    } header: {
                        Text(model.tabTitle(tab))
                    } footer: {
                        if tab.id == tabs.last { Text(L.s("overview_sources_hint")).font(Typo.bodyMedium).foregroundStyle(Palette.onSurfaceVariant) }
                    }
                }
            }
            .listStyle(.insetGrouped)
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
        let lists = OverviewSource.listChoices.filter { text.isEmpty || ListTitles.of($0).localizedCaseInsensitiveContains(text) }
        let entries = Array(OverviewScope.choices(in: model.all, query: text).prefix(Self.limit))
        List {
            if !lists.isEmpty {
                Section(L.s("overview_pick_lists")) {
                    ForEach(lists) { kind in
                        toggle(.list(kind), layout: layout) {
                            OverviewPickRow(icon: ListTitles.icon(kind), tint: Palette.onSurfaceVariant, title: ListTitles.of(kind),
                                            count: model.count(kind), chosen: layout.contains(.list(kind), in: tabId))
                        }
                    }
                }
            }
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
