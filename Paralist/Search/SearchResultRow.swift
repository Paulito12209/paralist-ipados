// Zusammenhang: Search/SearchView.swift, Entries/TypeLook.swift, Entries/EntrySubtitle.swift (CaptionLine), Theme/Dimens.swift, ParalistCore Library/EntryCaption.swift
import ParalistCore
import SwiftUI

struct SearchResultRow: View {
    let entry: Entry
    let onOpen: () -> Void

    var body: some View {
        let look = TypeLook.inList(entry)
        HStack(spacing: 8) {
            GlyphIcon(look.icon.outlined, size: 20)
                .foregroundStyle(look.color)
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.title.isEmpty ? L.s("list_untitled") : entry.title)
                    .font(Typo.bodyLarge)
                    .foregroundStyle(entry.isDone ? Palette.onSurfaceVariant : Palette.onSurface)
                    .strikethrough(entry.isDone)
                    .lineLimit(1)
                CaptionLine(caption: caption, text: Text(meta))
                    .font(Typo.bodySmall)
                    .foregroundStyle(Palette.onSurfaceVariant)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if entry.pinned { marker(AppIcons.pin.filled) }
            if entry.favorite { marker(AppIcons.favorite.filled) }
        }
        .padding(.leading, 8)
        .padding(.trailing, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Dimens.listRadius, style: .continuous)
                .fill(Palette.surfaceLow.opacity(0.7))
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    private func marker(_ name: String) -> some View {
        Image(systemName: name).font(.system(size: 13)).foregroundStyle(Palette.outline)
    }

    private var caption: EntryCaption? { EntryCaption.of(entry, showsType: true) }

    private var meta: String {
        [EntrySubtitle.label(caption), L.f("entry_created_on", entry.created.formatted(date: .abbreviated, time: .omitted))].compactMap { $0 }.joined(separator: " · ")
    }
}
