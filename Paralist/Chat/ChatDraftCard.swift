// Zusammenhang: Chat/ChatThreadPage.swift, Chat/ChatModel.swift (createDraft, discardDraft), Chat/ChatDraftSheet.swift, Chat/ChatDraftEventRows.swift, Chat/ChatThreadParts.swift (ChatEntryChips), ParalistCore Chat/ChatDrafts.swift, Entries/TypeLook.swift
import ParalistCore
import SwiftUI

struct ChatDraftCard: View {
    let threadId: String
    let draft: ChatDraft
    @Environment(AppModel.self) private var model
    @State private var editing = false

    var body: some View {
        let look = TypeLook.of(type)
        VStack(alignment: .leading, spacing: ChatDimens.draftGap) {
            HStack(spacing: 8) {
                GlyphIcon(look.icon.outlined, size: 16).foregroundStyle(look.color)
                Text(headline).font(Typo.titleSmall).foregroundStyle(Palette.onSurface)
            }
            if let subline {
                Text(subline).font(Typo.labelMedium).foregroundStyle(Palette.muted)
            }
            content
            footer
        }
        .padding(.horizontal, ChatDimens.bubblePadH)
        .padding(.vertical, ChatDimens.bubblePadV)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surfaceLow, in: RoundedRectangle(cornerRadius: ChatDimens.bubbleRadius))
        .overlay(RoundedRectangle(cornerRadius: ChatDimens.bubbleRadius).strokeBorder(Palette.outlineVariant))
        .opacity(draft.state == .discarded ? 0.6 : 1)
        .sheet(isPresented: $editing) { ChatDraftSheet(threadId: threadId, draft: draft) }
    }

    private var type: EntryType {
        switch draft.kind {
        case .flashcards: return .flashcard
        case .tasks: return .task
        case .note: return .note
        case .events: return .event
        }
    }

    private var headline: String {
        switch draft.kind {
        case .flashcards: return L.f("chat_draft_cards", draft.items.count)
        case .tasks: return L.f("chat_draft_tasks", draft.items.count)
        case .note: return draft.title
        case .events: return draft.asksForRow ? L.s("chat_draft_which_row") : L.f("chat_draft_events", draft.items.count)
        }
    }

    private var subline: String? {
        if draft.kind == .events { return draft.asksForRow || draft.title.isEmpty ? nil : draft.title }
        guard draft.kind == .flashcards else { return nil }
        let exists = ChatDrafts.deck(named: draft.title, in: model.byType(.deck)) != nil || draft.state == .saved
        return L.f(exists ? "chat_draft_deck_existing" : "chat_draft_deck_new", draft.title)
    }

    @ViewBuilder
    private var content: some View {
        switch draft.kind {
        case .note:
            if !draft.text.isEmpty {
                Text(draft.text).font(Typo.bodyMedium).foregroundStyle(Palette.onSurfaceVariant).lineLimit(ChatDimens.draftNoteLines)
            }
        case .events:
            ChatEventDraftRows(threadId: threadId, draft: draft)
        case .flashcards, .tasks:
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(draft.items.prefix(ChatDimens.draftPreview).enumerated()), id: \.offset) { _, item in
                    row(item)
                }
                if draft.items.count > ChatDimens.draftPreview {
                    Text(L.f("chat_draft_more", draft.items.count - ChatDimens.draftPreview)).font(Typo.labelMedium).foregroundStyle(Palette.muted)
                }
            }
        }
    }

    private func row(_ item: ChatDraftItem) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(item.front).font(Typo.bodyMedium).foregroundStyle(Palette.onSurface)
            if draft.kind == .flashcards {
                Text(item.back).font(Typo.bodyMedium).foregroundStyle(Palette.onSurfaceVariant)
            } else if let due = item.due {
                Text(L.f("label_due", L.date(due))).font(Typo.labelMedium).foregroundStyle(Palette.muted)
            }
        }
        .lineLimit(1)
    }

    @ViewBuilder
    private var footer: some View {
        switch draft.state {
        case .open:
            if model.chats.failedDrafts.contains(draft.id) {
                Text(L.s("chat_draft_failed")).font(Typo.bodySmall).foregroundStyle(Palette.error)
            }
            HStack(spacing: 8) {
                if !draft.asksForRow {
                    Button(L.s("chat_draft_create")) { model.chats.createDraft(draft.id, in: threadId) }
                        .buttonStyle(.glassProminent)
                        .tint(Palette.primary)
                        .foregroundStyle(Palette.onPrimary)
                        .disabled(draft.kind == .events && draft.selectedCount == 0)
                    Button(L.s("chat_draft_edit")) { editing = true }
                        .buttonStyle(.glass)
                }
                Button(L.s("chat_draft_discard")) { model.chats.discardDraft(draft.id, in: threadId) }
                    .buttonStyle(.glass)
            }
            .font(Typo.labelLarge)
        case .saved:
            HStack(spacing: 6) {
                Image(systemName: AppIcons.check).foregroundStyle(Palette.done)
                Text(L.s("chat_draft_saved")).font(Typo.labelLarge).foregroundStyle(Palette.onSurfaceVariant)
            }
            ChatEntryChips(ids: draft.saved)
        case .discarded:
            Text(L.s("chat_draft_discarded")).font(Typo.labelLarge).foregroundStyle(Palette.muted)
        }
    }
}
