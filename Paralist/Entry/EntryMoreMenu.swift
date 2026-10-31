// Zusammenhang: Entry/EntryToolbar.swift (iPhone-Layout), Entry/EntryActionBar.swift (geteilte Ansicht), Entry/EntryPage.swift (EntrySheet), Shell/Router.swift (openChat), Icons/AppIcons.swift, docs/detailseite.md
import ParalistCore
import SwiftUI

struct EntryFavoriteButton: View {
    let entry: Entry
    let model: AppModel

    var body: some View {
        Button { model.update(entry.id) { var e = $0; e.favorite.toggle(); return e } } label: {
            Image(systemName: entry.favorite ? AppIcons.favorite.filled : AppIcons.favorite.outlined).foregroundStyle(Palette.onSurface)
        }
        .accessibilityLabel(L.s("tool_favorite"))
    }
}

struct EntryMoreMenu: View {
    let entry: Entry
    let model: AppModel
    let router: Router
    @Binding var sheet: EntrySheet?
    let onDelete: () -> Void

    var body: some View {
        Menu {
            Button { model.update(entry.id) { var e = $0; e.pinned.toggle(); return e } } label: {
                Label(L.s(entry.pinned ? "entry_unpin" : "tool_pin"), systemImage: entry.pinned ? AppIcons.pin.filled : AppIcons.pin.outlined)
            }
            Button { sheet = .links } label: { Label { Text(L.s("entry_link")) } icon: { GlyphIcon(AppIcons.link, size: 17) } }
            Button { router.openChat(with: entry.id, newId: model.chats.newId()) } label: { Label(L.s("entry_open_chat"), systemImage: AppIcons.chat.outlined) }
            Button { sheet = .type } label: { Label { Text(L.s("entry_change_type")) } icon: { GlyphIcon(TypeLook.of(entry.type).icon.outlined, size: 17) } }
            Button { model.update(entry.id) { var e = $0; e.archived.toggle(); return e } } label: {
                Label(L.s(entry.archived ? "entry_unarchive" : "entry_archive"), systemImage: entry.archived ? AppIcons.fromArchive : AppIcons.toArchive)
            }
            if !model.shareItems(entry).isEmpty {
                Button { sheet = .share } label: { Label(L.s("entry_share"), systemImage: AppIcons.share) }
            }
            if !EntryFacts.content(entry).isEmpty {
                Menu {
                    if !EntryFacts.title(entry).isEmpty {
                        Button { copy(EntryFacts.title(entry), notice: "entry_title_copied") } label: { Text(L.s("entry_copy_title_only")) }
                    }
                    Button { copy(EntryFacts.content(entry), notice: "entry_content_copied") } label: { Text(L.s("entry_copy_title_text")) }
                } label: {
                    Label(L.s("entry_copy_content"), systemImage: AppIcons.copy)
                }
            }
            Divider()
            Button(role: .destructive, action: onDelete) { Label(L.s("entry_delete"), systemImage: AppIcons.delete) }
        } label: {
            Image(systemName: AppIcons.more).foregroundStyle(Palette.onSurface)
        }
        .accessibilityLabel(L.s("entry_more"))
    }

    private func copy(_ text: String, notice: String) {
        UIPasteboard.general.string = text
        ClipboardMemory.markHandled()
        model.say(L.s(notice), top: true)
    }
}
