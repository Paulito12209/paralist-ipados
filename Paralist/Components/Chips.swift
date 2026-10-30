// Zusammenhang: Composer/ComposerSheet.swift, Entry/EntryPage.swift, Flashcards/ImportCardsSheet.swift, Theme/Dimens.swift (ComposerDimens), Theme/Palette.swift
import ParalistCore
import SwiftUI

struct ComposerChip: View {
    let icon: String
    let label: String
    var tint: Color?
    var selected = false
    var caret = true
    var pill = false

    var body: some View {
        if pill { pillBody } else { boxBody }
    }

    private var content: some View {
        HStack(spacing: 6) {
            GlyphIcon(icon, size: 15).foregroundStyle(tint ?? (selected || pill ? Palette.onSecondaryContainer : Palette.onSurfaceVariant))
            Text(label).font(Typo.labelLarge).lineLimit(1)
            if caret { Image(systemName: AppIcons.caret).font(.system(size: 11, weight: .semibold)) }
        }
    }

    private var pillBody: some View {
        content
            .foregroundStyle(Palette.onSurface)
            .padding(.leading, 14)
            .padding(.trailing, caret ? 12 : 14)
            .frame(height: ComposerDimens.pillHeight)
            .background(Palette.composerPill, in: Capsule())
            .overlay { Capsule().strokeBorder(Palette.onSurface.opacity(0.1), lineWidth: 1) }
            .contentShape(Capsule())
    }

    private var boxBody: some View {
        content
            .foregroundStyle(selected ? Palette.onSecondaryContainer : Palette.onSurfaceVariant)
            .padding(.leading, 10)
            .padding(.trailing, caret ? 8 : 12)
            .frame(height: 32)
            .background(selected ? Palette.secondaryContainer : .clear, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                if !selected { RoundedRectangle(cornerRadius: 8).stroke(Palette.outlineVariant, lineWidth: 1) }
            }
    }
}

struct ChoiceItem: Identifiable {
    let id: String
    let icon: String
    var tint: Color = Palette.onSurfaceVariant
    let label: String
}

struct ChoiceSheet: View {
    let title: String
    let items: [ChoiceItem]
    let selected: Set<String>
    var emptyText: String?
    var keepOpen = false
    let onPick: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if items.isEmpty, let emptyText {
                    Text(emptyText).font(Typo.bodyMedium).foregroundStyle(Palette.onSurfaceVariant)
                }
                ForEach(items) { item in
                    Button {
                        onPick(item.id)
                        if !keepOpen { dismiss() }
                    } label: {
                        HStack(spacing: 16) {
                            GlyphIcon(item.icon, size: 20).foregroundStyle(item.tint).frame(width: 28)
                            Text(item.label).font(Typo.bodyLarge).foregroundStyle(Palette.onSurface).lineLimit(1)
                            Spacer()
                            if selected.contains(item.id) { Image(systemName: AppIcons.check).foregroundStyle(Palette.primary) }
                        }
                        .frame(minHeight: 44)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: keepOpen ? AppIcons.check : AppIcons.close) }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

extension ChoiceItem {
    static func entry(_ e: Entry) -> ChoiceItem {
        let look = TypeLook.of(e)
        return ChoiceItem(id: e.id, icon: look.icon.outlined, tint: look.color, label: e.title.isEmpty ? L.s("list_untitled") : e.title)
    }

    static func type(_ t: EntryType) -> ChoiceItem {
        let look = TypeLook.of(t)
        return ChoiceItem(id: t.key, icon: look.icon.outlined, tint: look.color, label: L.s(look.label))
    }
}
