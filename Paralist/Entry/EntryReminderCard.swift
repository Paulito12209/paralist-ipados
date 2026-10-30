// Zusammenhang: Entry/EntryCanvasPanel.swift, Entry/EntryPage.swift (EntrySheet), Entry/CanvasCard.swift, ParalistCore Library/ReminderNotes.swift, Theme/Dimens.swift, Theme/Palette.swift
import ParalistCore
import SwiftUI

struct EntryReminderCard: View {
    let entry: Entry
    let now: Date
    @Binding var sheet: EntrySheet?
    @Environment(AppModel.self) private var model
    @State private var editing: NoteTarget?

    static func shows(_ entry: Entry, now: Date) -> Bool { entry.hasUpcomingReminder(now: now) }

    var body: some View {
        let upcoming = entry.upcomingReminders(now: now)
        VStack(spacing: 0) {
            ForEach(Array(upcoming.enumerated()), id: \.element) { index, at in
                if index > 0 {
                    Rectangle().fill(Palette.cardStroke).frame(height: Dimens.canvasCardStroke).padding(.leading, Dimens.canvasCardPad)
                }
                row(at)
            }
        }
        .canvasCard()
        .padding(.horizontal, Dimens.entryInset)
        .padding(.top, Dimens.canvasCardGap)
        .sheet(item: $editing) { target in
            ReminderNoteSheet(initial: entry.reminderNote(at: target.at) ?? "") { text in
                model.update(entry.id) { var e = $0; e.setReminderNote(text, at: target.at); return e }
            }
        }
    }

    private func row(_ at: Date) -> some View {
        let note = entry.reminderNote(at: at)
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                Button { sheet = .reminders } label: {
                    HStack(spacing: 12) {
                        GlyphIcon(AppIcons.bell.filled, size: 18).foregroundStyle(Palette.onSurfaceVariant)
                        Text(L.dateTime(at)).font(Typo.bodyLarge).foregroundStyle(Palette.onSurface).lineLimit(1).minimumScaleFactor(0.8)
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .accessibilityHint(L.s("reminder_title"))
                if note == nil {
                    Button { editing = NoteTarget(at: at) } label: {
                        Label(L.s("reminder_note_add"), systemImage: AppIcons.add)
                            .font(Typo.labelMedium)
                            .foregroundStyle(Palette.onSurface)
                            .padding(.horizontal, 10)
                            .frame(height: Dimens.reminderNoteChip)
                            .background(Palette.surfaceHigh, in: Capsule())
                            .overlay(Capsule().strokeBorder(Palette.cardStroke, lineWidth: Dimens.canvasCardStroke))
                            .frame(minHeight: Dimens.touchTarget)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(L.s("reminder_note_title"))
                }
            }
            if let note {
                Button { editing = NoteTarget(at: at) } label: {
                    Text(note).font(Typo.bodySmall).foregroundStyle(Palette.muted)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .padding(.leading, Dimens.reminderNoteIndent)
                .accessibilityHint(L.s("reminder_note_title"))
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Dimens.canvasCardPad)
        .padding(.vertical, note == nil ? 4 : Dimens.reminderRowPad)
        .frame(minHeight: Dimens.entryToggleHeight)
    }

    struct NoteTarget: Identifiable {
        let at: Date
        var id: Date { at }
    }
}

struct ReminderNoteSheet: View {
    let initial: String
    let onSave: (String) -> Void
    @State private var text = ""
    @FocusState private var focused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            TextField(L.s("reminder_note_hint"), text: $text, axis: .vertical)
                .font(Typo.bodyLarge)
                .lineLimit(1...4)
                .focused($focused)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .frame(maxHeight: .infinity, alignment: .top)
                .navigationTitle(L.s("reminder_note_title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button { dismiss() } label: { Image(systemName: AppIcons.close) }
                            .accessibilityLabel(L.s("dialog_cancel"))
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            onSave(text)
                            dismiss()
                        } label: { Image(systemName: AppIcons.check) }
                        .buttonStyle(.glassProminent)
                        .accessibilityLabel(L.s("dialog_save"))
                    }
                }
        }
        .onAppear {
            text = initial
            focused = true
        }
        .presentationDetents([.medium])
    }
}
