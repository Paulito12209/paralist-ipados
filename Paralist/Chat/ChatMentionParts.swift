// Zusammenhang: Chat/ChatInputBar.swift (Chips in der Eingabekarte), Chat/ChatThreadPage.swift (Vorschläge über der Eingabe), Components/Chips.swift (ComposerChip), Entries/TypeLook.swift, ParalistCore Chat/ChatMentionQuery.swift, ParalistCore Chat/Skills.swift, Theme/Dimens.swift (ComposerDimens, ChatDimens), Icons/AppIcons.swift
import ParalistCore
import SwiftUI

struct ChatMentionChips: View {
    let ids: [String]
    let remove: (String) -> Void
    @Environment(AppModel.self) private var model

    var body: some View {
        let entries = ids.compactMap { model.entry($0) }
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(entries) { entry in
                    let look = TypeLook.of(entry)
                    HStack(spacing: 6) {
                        GlyphIcon(look.icon.outlined, size: 14).foregroundStyle(look.color)
                        Text(entry.title.isEmpty ? L.s("list_untitled") : entry.title).font(Typo.labelLarge).lineLimit(1)
                        Button { remove(entry.id) } label: {
                            Image(systemName: AppIcons.close).font(.system(size: 10, weight: .bold)).foregroundStyle(Palette.onSurfaceVariant)
                                .frame(width: 18, height: 18)
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(L.s("chat_mention_remove"))
                    }
                    .foregroundStyle(Palette.onSurface)
                    .padding(.leading, 10)
                    .padding(.trailing, 6)
                    .frame(height: ChatDimens.chipHeight)
                    .background(Palette.composerPill, in: Capsule())
                    .overlay { Capsule().strokeBorder(Palette.onSurface.opacity(0.1), lineWidth: 1) }
                }
            }
        }
        .scrollClipDisabled()
    }
}

struct ChatMentionSuggestions: View {
    let entries: [Entry]
    let skills: Set<String>
    let pick: (Entry) -> Void

    var body: some View {
        if !entries.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(entries) { entry in
                        let look = TypeLook.of(entry)
                        Button { pick(entry) } label: {
                            ComposerChip(icon: skills.contains(entry.id) ? AppIcons.sparkle : look.icon.outlined,
                                         label: entry.title.isEmpty ? L.s("list_untitled") : entry.title,
                                         tint: skills.contains(entry.id) ? Palette.primary : look.color, caret: false, pill: true)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(L.s("chat_mention_pick"))
                    }
                }
                .padding(.horizontal, ComposerDimens.edge)
                .padding(.bottom, ChatDimens.imageRowGap)
            }
            .scrollClipDisabled()
        }
    }
}
