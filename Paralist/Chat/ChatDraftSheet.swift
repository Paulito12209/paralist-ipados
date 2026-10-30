// Zusammenhang: Chat/ChatDraftCard.swift, Chat/ChatDraftEventRows.swift (ChatEventText), Chat/ChatModel.swift (editDraft), ParalistCore Chat/ChatDrafts.swift, ParalistCore Chat/ChatEventDrafts.swift
import ParalistCore
import SwiftUI

struct ChatDraftSheet: View {
    let threadId: String
    let draft: ChatDraft
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var text = ""
    @State private var rows: [Row] = []

    private struct Row: Identifiable {
        let id = UUID()
        var front: String
        var back: String = ""
        var due: Day? = nil
        var start: Int? = nil
        var end: Int? = nil
        var selected = true
        var hint: ChatDraftHint? = nil
    }

    var body: some View {
        NavigationStack {
            Form {
                switch draft.kind {
                case .flashcards: cards
                case .tasks: tasks
                case .note: note
                case .events: events
                }
            }
            .navigationTitle(L.s("chat_draft_edit_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L.s("dialog_cancel")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.s("dialog_save")) { save() }.buttonStyle(.glassProminent).tint(Palette.primary).foregroundStyle(Palette.onPrimary)
                }
            }
        }
        .onAppear {
            title = draft.title
            text = draft.text
            rows = draft.items.map { Row(front: $0.front, back: $0.back, due: $0.due, start: $0.start, end: $0.end, selected: $0.selected, hint: $0.hint) }
        }
    }

    @ViewBuilder
    private var cards: some View {
        Section { TextField(L.s("type_deck"), text: $title) }
        Section {
            ForEach($rows) { $row in
                VStack(alignment: .leading, spacing: 6) {
                    TextField(L.s("composer_hint_flashcard"), text: $row.front).font(Typo.bodyLarge)
                    TextField(L.s("composer_back_hint"), text: $row.back, axis: .vertical).font(Typo.bodyMedium).foregroundStyle(Palette.onSurfaceVariant)
                }
            }
            .onDelete { rows.remove(atOffsets: $0) }
            if rows.count < ChatDrafts.maxCards { addButton }
        }
    }

    @ViewBuilder
    private var tasks: some View {
        Section {
            ForEach($rows) { $row in
                VStack(alignment: .leading, spacing: 6) {
                    TextField(L.s("type_task"), text: $row.front).font(Typo.bodyLarge)
                    if let due = row.due {
                        HStack {
                            DatePicker(L.s("composer_date"), selection: Binding(
                                get: { due.at(hour: 12, in: .current) },
                                set: { row.due = Day.of($0, in: .current) }
                            ), displayedComponents: [.date])
                            Button { row.due = nil } label: { Image(systemName: AppIcons.close) }
                                .buttonStyle(.borderless)
                                .accessibilityLabel(L.s("composer_date_clear"))
                        }
                    } else {
                        Button(L.s("entry_date_add")) { row.due = model.today }.buttonStyle(.borderless).font(Typo.labelLarge)
                    }
                }
            }
            .onDelete { rows.remove(atOffsets: $0) }
            if rows.count < ChatDrafts.maxTasks { addButton }
        }
    }

    @ViewBuilder
    private var note: some View {
        Section { TextField(L.s("type_note"), text: $title) }
        Section { TextField(L.s("entry_add_body"), text: $text, axis: .vertical).lineLimit(8...) }
    }

    @ViewBuilder
    private var events: some View {
        Section {
            ForEach($rows) { $row in
                VStack(alignment: .leading, spacing: 6) {
                    TextField(L.s("type_event"), text: $row.front).font(Typo.bodyLarge)
                    DatePicker(L.s("composer_date"), selection: Binding(
                        get: { (row.due ?? model.today).at(hour: 12, in: .current) },
                        set: { row.due = Day.of($0, in: .current) }
                    ), displayedComponents: [.date])
                    DatePicker(L.s("event_start"), selection: minutes($row.start), displayedComponents: [.hourAndMinute])
                    DatePicker(L.s("event_end"), selection: minutes($row.end), displayedComponents: [.hourAndMinute])
                }
            }
            .onDelete { rows.remove(atOffsets: $0) }
            if rows.count < ChatDrafts.maxEvents { addButton }
        }
    }

    private func minutes(_ minute: Binding<Int?>) -> Binding<Date> {
        Binding(
            get: { Day(epochDay: 0).at(hour: (minute.wrappedValue ?? 0) / 60, minute: (minute.wrappedValue ?? 0) % 60, in: .current) },
            set: { minute.wrappedValue = ChatDrafts.minuteOfDay($0, zone: .current) }
        )
    }

    private var addButton: some View {
        Button {
            if draft.kind == .events {
                rows.append(Row(front: draft.title, due: model.today, start: 8 * 60, end: 16 * 60))
            } else {
                rows.append(Row(front: ""))
            }
        } label: { Label(L.s("chat_draft_add"), systemImage: AppIcons.add) }
    }

    private func save() {
        var edited = draft
        edited.title = title
        edited.text = text
        edited.items = rows.map { ChatDraftItem(front: $0.front, back: $0.back, due: $0.due, start: $0.start, end: $0.end, selected: $0.selected, hint: $0.hint) }
        model.chats.editDraft(edited, in: threadId)
        dismiss()
    }
}
