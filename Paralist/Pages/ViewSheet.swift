// Zusammenhang: Pages/OverviewEdge.swift (Regler), Pages/ListPage.swift, App/AppPrefs.swift, Entries/TypeLook.swift, ParalistCore Library/ViewSetting.swift, ParalistCore Library/ListKind.swift
import ParalistCore
import SwiftUI

struct ViewSheet: View {
    let kind: ListKind
    var entryId: String?
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let setting = current
        NavigationStack {
            List {
                header(L.s("view_sort"))
                Picker(selection: binding(\.sort, setting) { s, sort in s.sort = sort; s.ascending = sort.naturalAscending }) {
                    Text(L.s("view_sort_created")).tag(ParalistCore.SortOrder.created)
                    Text(L.s("view_sort_updated")).tag(ParalistCore.SortOrder.updated)
                    Text(L.s("view_sort_title")).tag(ParalistCore.SortOrder.title)
                } label: { row(AppIcons.sortBy, L.s("view_sort_by")) }
                .plainOption()
                Picker(selection: binding(\.ascending, setting) { s, up in s.ascending = up }) {
                    Text(L.s(setting.sort == .title ? "view_order_az" : "view_order_newest")).tag(setting.sort == .title)
                    Text(L.s(setting.sort == .title ? "view_order_za" : "view_order_oldest")).tag(setting.sort != .title)
                } label: { row(AppIcons.sortDirection, L.s("view_order")) }
                .plainOption()
                header(L.s("view_group"))
                Picker(selection: binding(\.grouping, setting) { s, g in s.grouping = g }) {
                    Text(L.s("view_group_none")).tag(Grouping.none)
                    Text(L.s("view_group_type")).tag(Grouping.type)
                } label: { row(AppIcons.groupBy, L.s("view_group_by")) }
                .plainOption()
                if !kind.filterChoices.isEmpty {
                    header(L.s("view_show"))
                    ForEach(setting.choices(for: kind), id: \.self) { type in
                        let look = TypeLook.of(type)
                        Toggle(isOn: Binding(get: { !setting.hidden.contains(type) }, set: { on in
                            var s = setting
                            if on { s.hidden.remove(type) } else { s.hidden.insert(type) }
                            withAnimation(Motion.short) { store(s) }
                        })) {
                            HStack(spacing: 14) {
                                GlyphIcon(look.icon.outlined, size: 18).foregroundStyle(look.color).frame(width: 26)
                                Text(L.s(look.label)).font(Typo.bodyLarge).foregroundStyle(Palette.onSurface)
                            }
                        }
                        .tint(Palette.toggleOn)
                        .frame(minHeight: 52)
                        .listRowInsets(ViewSheet.insets)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.visible, edges: .bottom)
                        .listRowSeparator(.hidden, edges: .top)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 40 }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 0)
            .pickerStyle(.menu)
            .tint(Palette.primary)
            .navigationTitle(L.s("view_customize"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: AppIcons.close) }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Dimens.sheetRadius)
    }

    private var current: ViewSetting { entryId.map(model.prefs.entryView) ?? model.prefs.view(kind) }

    private func store(_ setting: ViewSetting) {
        if let entryId { model.prefs.setEntryView(entryId, setting) } else { model.prefs.setView(kind, setting) }
    }

    static let insets = EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 20)

    private func header(_ text: String) -> some View {
        Text(text)
            .font(Typo.bodyMedium)
            .foregroundStyle(Palette.muted)
            .padding(.top, 18)
            .padding(.bottom, 2)
            .listRowInsets(ViewSheet.insets)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }

    private func row(_ icon: String, _ label: String) -> some View {
        HStack(spacing: 14) {
            GlyphIcon(icon, size: 18).foregroundStyle(Palette.onSurfaceVariant).frame(width: 26)
            Text(label).font(Typo.bodyLarge).foregroundStyle(Palette.onSurface)
        }
    }

    private func binding<T>(_ path: KeyPath<ViewSetting, T>, _ setting: ViewSetting, _ apply: @escaping (inout ViewSetting, T) -> Void) -> Binding<T> {
        Binding(get: { setting[keyPath: path] }, set: { value in
            var s = setting
            apply(&s, value)
            store(s)
        })
    }
}

private extension View {
    func plainOption() -> some View {
        frame(minHeight: 52)
            .listRowInsets(ViewSheet.insets)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}
