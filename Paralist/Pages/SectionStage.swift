// Zusammenhang: Theme/FolderTone.swift (Kategoriefarben), Pages/FolderStage.swift (FolderStage, PinnedCardShell, FolderPill), Pages/TaskFolder.swift, Pages/TaskStage.swift (TaskPinnedCard), Pages/ListPage.swift, Chat/ChatListPage.swift (ChatRow.stamp), Entries/TypeLook.swift, ParalistCore Library/ListKind.swift (Ordering.pinnedLead), ParalistCore Chat/ChatView.swift
import ParalistCore
import SwiftUI

struct EntryStage: View {
    let kind: ListKind
    let count: Int
    let glyph: String
    let pinned: Entry?
    @Binding var showsPin: Bool
    let onOpen: (Entry) -> Void

    var body: some View {
        FolderStage(pinKey: pinned?.id, showsPin: $showsPin) {
            TaskFolder(count: count, glyph: glyph, voice: L.f("entries_count", count))
        } card: { allowed in
            if let pinned {
                if pinned.type == .task {
                    TaskPinnedCard(entry: pinned) { if allowed() { onOpen(pinned) } }
                } else {
                    EntryPinnedCard(entry: pinned) { if allowed() { onOpen(pinned) } }
                }
            }
        }
        .environment(\.folderTone, FolderTone.of(kind))
    }
}

struct EntryPinnedCard: View {
    let entry: Entry
    let onOpen: () -> Void

    var body: some View {
        let look = TypeLook.of(entry)
        PinnedCardShell(glyph: look.icon.outlined, tint: look.color,
                        title: entry.title.isEmpty ? L.s("list_untitled") : entry.title,
                        openLabel: L.s("page_pinned_open"), onOpen: onOpen) {
            FolderPill(text: L.s(look.label))
        }
    }
}

struct ChatStage: View {
    let count: Int
    let pinned: ChatThread?
    @Binding var showsPin: Bool
    let onOpen: (ChatThread) -> Void

    var body: some View {
        FolderStage(pinKey: pinned?.id, showsPin: $showsPin) {
            TaskFolder(count: count, glyph: AppIcons.chat.outlined, voice: L.f("chat_count", count))
        } card: { allowed in
            if let pinned {
                PinnedCardShell(glyph: AppIcons.chat.outlined, tint: Palette.level,
                                title: pinned.title.isEmpty ? L.s("chat_new") : pinned.title,
                                openLabel: L.s("chat_pinned_open"), onOpen: { if allowed() { onOpen(pinned) } }) {
                    FolderPill(text: ChatRow.stamp(pinned.updated))
                }
            }
        }
        .environment(\.folderTone, FolderTone.chats)
    }
}
