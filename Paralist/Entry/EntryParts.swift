// Zusammenhang: Entry/EntryPage.swift, Entry/EntryPickers.swift, ParalistCore Library/EntryParent.swift, Components/Chips.swift, Components/EventTimeSheet.swift, Entries/TypeLook.swift, Flashcards/DeckSection.swift, Entry/EntryBlocks.swift, Entry/LinkSheet.swift, Entry/EntryInfoSheet.swift, Backup/ShareSheet.swift
import ParalistCore
import SwiftUI

struct ListHeader: View {
    let icon: String
    let title: String
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            GlyphIcon(icon, size: 17).foregroundStyle(Palette.muted)
            Text(title).font(Typo.titleSmall).foregroundStyle(Palette.onSurface)
            if count > 0 { Text("\(count)").font(Typo.titleSmall).foregroundStyle(Palette.muted) }
        }
        .padding(.leading, 20)
        .padding(.trailing, 8)
        .padding(.top, 16)
        .padding(.bottom, 4)
    }
}

struct EntrySheets: View {
    let which: EntrySheet
    let entry: Entry
    @Environment(AppModel.self) private var model

    var body: some View {
        switch which {
        case .status:
            ChoiceSheet(title: L.s("status_title"), items: EntryStatus.options(for: entry).map { s in
                let look = StatusLook.of(s, for: entry.type)
                return ChoiceItem(id: s.key, icon: look.icon, tint: look.color, label: L.s(look.label))
            }, selected: [(entry.status ?? .open).key]) { key in
                if let s = TaskStatus.fromKey(key) { model.setStatus(entry.id, s) }
            }
        case .tagKind:
            ChoiceSheet(title: L.s("tag_kind_title"), items: TagKind.allCases.map { k in
                let look = TagKindLook.of(k)
                return ChoiceItem(id: k.key, icon: look.icon.outlined, tint: TypeLook.of(.tag).color, label: L.s(look.label))
            }, selected: [(entry.tagKind ?? .tag).key]) { key in
                let kind = TagKind.fromKey(key)
                model.update(entry.id) { var e = $0; e.tagKind = kind == .tag ? nil : kind; return e }
            }
        case .date where entry.type == .event:
            EventTimeSheet(start: entry.start ?? EventLabel.suggestedStart(), end: entry.end, allDay: entry.allDay, canClear: entry.start != nil) { start, end, allDay in
                model.update(entry.id) { e in
                    var c = e
                    c.start = start
                    c.end = start == nil || allDay ? nil : end
                    c.allDay = start != nil && allDay
                    return c
                }
            }
        case .date:
            DateSheet(title: L.s("composer_date"), initial: entry.dueDate(in: .current) ?? Date(), canClear: entry.due != nil) { date in
                model.update(entry.id) { var c = $0; c.setDue(date.map { Day.of($0, in: .current) }); return c }
            }
        case .time:
            TimeSheet(initial: entry.dueDate(in: .current) ?? Date(), canClear: entry.dueTime != nil) { date in
                model.update(entry.id) { var c = $0; c.setDueTime(date.flatMap { DueTime.of($0, in: .current) }); return c }
            }
        case .place:
            EntryPlaceSheet(entry: entry)
        case .type:
            ChoiceSheet(title: L.s("entry_type_title"), items: EntryType.allCases.map(ChoiceItem.type), selected: [entry.type.key]) { key in
                if let type = EntryType.fromKey(key) { model.update(entry.id) { EntryChanges.withType($0, type) } }
            }
        case .links:
            LinkSheet(entry: entry)
        case .reminders:
            EntryReminders(entry: entry)
        case .info:
            EntryInfoSheet(entry: entry)
        case .title:
            EntryInfoSheet(entry: entry, editTitle: true)
        case .share:
            ShareSheet(items: model.shareItems(entry)) { done in
                if done { model.recordShared(entry.id) }
            }
            .presentationDetents([.medium, .large])
            .ignoresSafeArea()
        case .body:
            TextEditorSheet(title: L.s("entry_edit_body"), placeholder: L.s("entry_body_hint"), initial: entry.body, multiline: true) { text in
                let trimmed = text.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
                model.update(entry.id) { var e = $0; e.body = trimmed.isEmpty ? "" : trimmed + "\n"; return e }
            }
        }
    }
}

struct EntryReminders: View {
    let entry: Entry
    @Environment(AppModel.self) private var model
    @State private var reminders: [Date] = []
    @State private var offset: EventOffset = .none

    var body: some View {
        ReminderSheet(reminders: $reminders, eventStart: entry.start, offset: $offset)
            .onAppear { reminders = entry.reminders }
            .onDisappear {
                var all = reminders
                if let start = entry.start, let extra = offset.before(start) { all.append(extra) }
                let final = Array(Set(all)).sorted()
                if final != entry.reminders {
                    model.update(entry.id) { var e = $0; e.setReminders(final); return e }
                    Task { _ = await model.reminders.ensurePermission() }
                }
            }
    }
}

struct TextEditorSheet: View {
    let title: String
    let placeholder: String
    let initial: String
    let multiline: Bool
    let onSave: (String) -> Void
    @State private var text = ""
    @FocusState private var focused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if multiline {
                    TextEditor(text: $text).font(Typo.bodyLarge).scrollContentBackground(.hidden).padding(.horizontal, 12)
                } else {
                    TextField(placeholder, text: $text, axis: .vertical).font(Typo.titleLarge).padding(.horizontal, 20).padding(.top, 12)
                    Spacer()
                }
            }
            .focused($focused)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L.s("dialog_cancel")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.s("dialog_save")) {
                        onSave(text)
                        dismiss()
                    }
                    .buttonStyle(.glassProminent)
                }
            }
        }
        .onAppear {
            text = initial
            focused = true
        }
        .presentationDetents(multiline ? [.large] : [.height(220)])
    }
}
