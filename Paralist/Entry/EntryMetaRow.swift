// Zusammenhang: Entry/EntryPage.swift, Entry/EntryCanvasPanel.swift, Entry/EntryInfoSheet.swift, Entry/EntryParts.swift, Entries/TypeLook.swift, Icons/AppIcons.swift, App/L.swift
import ParalistCore
import SwiftUI

struct EntryMetaRow: View {
    let entry: Entry
    let onType: () -> Void
    let onMore: () -> Void

    var body: some View {
        let look = entry.type == .bookmark ? TypeLook.of(.bookmark) : TypeLook.of(entry)
        HStack(spacing: 8) {
            Button(action: onType) {
                GlyphIcon(look.icon.outlined, size: 13, weight: .semibold).foregroundStyle(look.color)
                    .frame(width: 20, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L.s(look.label))
            Button(action: onMore) {
                HStack(spacing: 8) {
                    Text(summary).font(Typo.entryMeta).foregroundStyle(Palette.muted)
                        .lineLimit(1).minimumScaleFactor(0.85).truncationMode(.tail)
                    Text(L.s("entry_info_more")).font(Typo.entryMetaMore).foregroundStyle(Palette.onSurface)
                        .fixedSize()
                    Spacer(minLength: 0)
                }
                .frame(minHeight: 28)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, Dimens.entryInset - 4)
        .padding(.trailing, Dimens.entryInset)
    }

    private var summary: String {
        L.f("entry_created_on", L.dateOnly(entry.created)) + " · " + L.f("entry_updated_on", L.dateOnly(entry.updated))
    }
}
