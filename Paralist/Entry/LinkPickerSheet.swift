// Zusammenhang: Entry/LinkSheet.swift, Entry/LinkCreateRow.swift, Composer/ComposerParts.swift (ComposerPanels), ParalistShare/ShareView.swift, Components/Chips.swift, Entries/TypeLook.swift (ListTitles), ParalistCore Library/LinkPicker.swift, ParalistCore Library/PlacePicker.swift
import ParalistCore
import SwiftUI

struct LinkPickerSheet: View {
    let entry: Entry
    var title = L.s("entry_link_add")
    var closes: (Entry?) -> Bool = { _ in false }
    var inbox: Bool?
    var excluded: Set<EntryType> = []
    var tabs: [LinkTab]?
    let pool: [Entry]
    let isLinked: (String) -> Bool
    var create: ((EntryType, String) -> Entry?)?
    let toggle: (Entry?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var tab: LinkTab?
    @State private var query = ""

    var body: some View {
        let pool = pool.filter { !excluded.contains($0.type) }
        let searching = !query.trimmingCharacters(in: .whitespaces).isEmpty
        let items = searching
            ? LinkPicker.matching(query, tabs: tab.map { [$0] } ?? shownTabs, for: entry, in: pool)
            : tab.map { LinkPicker.entries($0, for: entry, in: pool) } ?? LinkPicker.suggestions(for: entry, in: pool)
        NavigationStack {
            List {
                Group {
                    if let type = tab?.creates, let create {
                        LinkCreateRow(type: type, seed: query) { name in
                            if let made = create(type, name) { pick(made) }
                        }
                        .id(type)
                    }
                    if tab == nil, !searching, let inbox {
                        row(.noPlace(for: entry.type), checked: inbox) { pick(nil) }
                    }
                    if items.isEmpty {
                        Text(L.s(searching ? "search_no_results" : "empty_kind_all"))
                            .font(Typo.bodyMedium).foregroundStyle(Palette.onSurfaceVariant)
                    }
                    ForEach(items) { other in
                        row(ChoiceItem.entry(other), checked: isLinked(other.id)) { pick(other) }
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Palette.surface)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Palette.surface)
            .safeAreaInset(edge: .top, spacing: 0) { tabRow }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: L.s("search_hint"))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Palette.surface, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: AppIcons.check) }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Palette.surface)
    }

    private var shownTabs: [LinkTab] {
        (tabs ?? LinkPicker.tabs(for: entry.type)).filter { excluded.isDisjoint(with: $0.types) }
    }

    private func pick(_ other: Entry?) {
        let close = closes(other)
        toggle(other)
        if close { dismiss() }
    }

    private func row(_ item: ChoiceItem, checked: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                GlyphIcon(item.icon, size: 20).foregroundStyle(item.tint).frame(width: 28)
                Text(item.label).font(Typo.bodyLarge).foregroundStyle(Palette.onSurface).lineLimit(1)
                Spacer()
                if checked { Image(systemName: AppIcons.check).foregroundStyle(Palette.primary) }
            }
            .frame(minHeight: 44)
        }
    }

    private var tabRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(nil, icon: AppIcons.suggestions, label: L.s("link_suggestions"))
                ForEach(shownTabs) { value in
                    chip(value, icon: ListTitles.icon(value), label: ListTitles.of(value))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .background(Palette.surface)
    }

    private func chip(_ value: LinkTab?, icon: String, label: String) -> some View {
        Button { tab = value } label: {
            ComposerChip(icon: icon, label: label, selected: tab == value, caret: false)
        }
    }
}

extension ChoiceItem {
    static func noPlace(for type: EntryType) -> ChoiceItem {
        type == .tag || type == .area
            ? ChoiceItem(id: "", icon: AppIcons.tag.outlined, label: L.s("tag_parent_none"))
            : ChoiceItem(id: "", icon: AppIcons.inbox, label: L.s("composer_place_inbox"))
    }
}
