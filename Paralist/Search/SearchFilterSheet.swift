// Zusammenhang: Search/SearchView.swift, Entries/TypeLook.swift, Composer/CreateSheet.swift
import ParalistCore
import SwiftUI

struct SearchFilterSheet: View {
    @Binding var selected: Set<EntryType>
    @Environment(\.dismiss) private var dismiss

    private let sections: [(String, [EntryType])] = [
        ("section_quick", [.task, .note, .event]),
        ("section_resources", [.bookmark, .document, .file]),
        ("section_organize", [.project, .area, .tag]),
        ("section_learn", [.flashcard, .deck]),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(sections, id: \.0) { section in
                        Text(L.s(section.0))
                            .font(Typo.labelMedium)
                            .foregroundStyle(Palette.muted)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(section.1, id: \.self) { type in
                                    FilterChip(type: type, on: selected.contains(type)) { toggle(type) }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle(L.s("search_filter_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .close) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L.s("search_filter_reset")) { selected.removeAll() }
                        .disabled(selected.isEmpty)
                }
            }
        }
    }

    private func toggle(_ type: EntryType) {
        if selected.contains(type) { selected.remove(type) } else { selected.insert(type) }
    }
}

struct FilterChip: View {
    let type: EntryType
    let on: Bool
    let action: () -> Void

    var body: some View {
        let look = TypeLook.of(type)
        Button(action: action) {
            HStack(spacing: 8) {
                GlyphIcon(on ? AppIcons.check : look.icon.outlined, size: 18, weight: on ? .semibold : .regular)
                    .foregroundStyle(look.color)
                    .frame(width: 22)
                    .contentTransition(.symbolEffect(.replace))
                Text(L.s(look.label)).font(Typo.labelLarge).foregroundStyle(Palette.onSurface)
            }
            .padding(.leading, 14)
            .padding(.trailing, 18)
            .frame(height: 44)
            .glassEffect(on ? .regular.tint(look.color.opacity(0.3)).interactive() : .regular.interactive(), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .animation(Motion.short, value: on)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
