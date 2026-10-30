// Zusammenhang: Chat/ChatDraftCard.swift, Chat/ChatDraftSheet.swift, Chat/ChatModel.swift (toggleDraftItem, chooseRow), ParalistCore Chat/ChatEventDrafts.swift, Theme/Dimens.swift (ChatDimens), Icons/AppIcons.swift
import ParalistCore
import SwiftUI

struct ChatEventDraftRows: View {
    let threadId: String
    let draft: ChatDraft
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if draft.asksForRow {
                ForEach(Array(draft.choices.enumerated()), id: \.offset) { _, name in
                    Button(name) { model.chats.chooseRow(name, draft: draft.id, in: threadId) }
                        .buttonStyle(.glass)
                        .font(Typo.labelLarge)
                        .disabled(draft.state != .open)
                }
            } else {
                ForEach(Array(draft.items.enumerated()), id: \.offset) { index, item in
                    ChatEventDraftRow(item: item, title: item.front == draft.title ? nil : item.front, open: draft.state == .open) {
                        model.chats.toggleDraftItem(draft.id, at: index, in: threadId)
                    }
                }
            }
        }
    }
}

struct ChatEventDraftRow: View {
    let item: ChatDraftItem
    let title: String?
    let open: Bool
    let toggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Button(action: toggle) {
                Image(systemName: item.selected ? AppIcons.task.filled : AppIcons.task.outlined)
                    .font(.system(size: ChatDimens.draftCheck))
                    .foregroundStyle(item.selected ? Palette.primary : Palette.outline)
            }
            .buttonStyle(.plain)
            .disabled(!open)
            .accessibilityLabel(L.s("chat_draft_toggle"))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(ChatEventText.day(item.due)).font(Typo.bodyMedium).foregroundStyle(Palette.onSurface)
                    Text(ChatEventText.span(item)).font(Typo.bodyMedium).foregroundStyle(Palette.onSurfaceVariant)
                }
                if let title {
                    Text(title).font(Typo.labelMedium).foregroundStyle(Palette.onSurfaceVariant)
                }
                if let hint = item.hint {
                    Text(L.s(ChatEventText.hintKey(hint))).font(Typo.labelMedium).foregroundStyle(hint == .hours ? Palette.error : Palette.muted)
                }
            }
        }
        .opacity(item.selected ? 1 : 0.6)
    }
}

enum ChatEventText {
    static func day(_ day: Day?) -> String {
        guard let day else { return "" }
        return day.at(hour: 12, in: .current).formatted(Date.FormatStyle(locale: L.locale).weekday(.abbreviated).day().month(.abbreviated))
    }

    static func span(_ item: ChatDraftItem) -> String {
        guard let start = item.start, let end = item.end else { return "" }
        return clock(start) + "–" + clock(end)
    }

    static func clock(_ minute: Int) -> String {
        L.time(Day(epochDay: 0).at(hour: minute / 60, minute: minute % 60, in: .current))
    }

    static func hintKey(_ hint: ChatDraftHint) -> String {
        switch hint {
        case .exists: return "chat_draft_exists"
        case .past: return "chat_draft_past"
        case .hours: return "chat_draft_hours"
        }
    }
}
