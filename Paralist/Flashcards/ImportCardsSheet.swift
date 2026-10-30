// Zusammenhang: ParalistCore Flashcards/CardMarkdown.swift, Shell/AppSheets.swift, Components/Chips.swift
import ParalistCore
import SwiftUI

struct ImportCardsSheet: View {
    @State var deck: String?
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var choosing = false

    var body: some View {
        let parsed = CardMarkdown.parse(text)
        let decks = model.byType(.deck)
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(L.s("fc_import_hint")).font(Typo.bodySmall).foregroundStyle(Palette.onSurfaceVariant)
                HStack(spacing: 12) {
                    Button { choosing = true } label: {
                        ComposerChip(icon: AppIcons.deck.outlined, label: deck.flatMap { model.entry($0)?.title } ?? L.s("fc_import_into"), selected: deck != nil)
                    }
                    .buttonStyle(.plain)
                    if !parsed.cards.isEmpty {
                        Text(L.f("fc_import_preview", parsed.cards.count)).font(Typo.labelLarge).foregroundStyle(Palette.primary)
                    }
                }
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text).font(.system(.body, design: .monospaced)).scrollContentBackground(.hidden)
                    if text.isEmpty {
                        Text("Frage\n==\nAntwort\n#tag").font(.system(.body, design: .monospaced)).foregroundStyle(Palette.muted).padding(.top, 8).padding(.leading, 5).allowsHitTesting(false)
                    }
                }
                .padding(8)
                .background(Palette.surfaceLow, in: RoundedRectangle(cornerRadius: 12))
                if !parsed.errors.isEmpty {
                    Text(L.f("fc_import_errors", parsed.errors.count)).font(Typo.labelLarge).foregroundStyle(Palette.error)
                    ForEach(parsed.errors.prefix(4), id: \.self) { error in
                        Text(L.f("fc_import_error_line", error.card, error.message)).font(Typo.bodySmall).foregroundStyle(Palette.error)
                    }
                }
                if decks.isEmpty { Text(L.s("fc_no_decks")).font(Typo.bodySmall).foregroundStyle(Palette.muted) }
            }
            .padding(.horizontal, 20)
            .navigationTitle(L.s("fc_import"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L.s("dialog_cancel")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.s("fc_import_save")) { save(parsed.cards) }
                        .buttonStyle(.glassProminent)
                        .disabled(parsed.cards.isEmpty)
                }
            }
            .sheet(isPresented: $choosing) {
                ChoiceSheet(title: L.s("fc_import_into"), items: decks.map(ChoiceItem.entry), selected: Set(deck.map { [$0] } ?? []), emptyText: L.s("fc_no_decks")) { id in
                    deck = deck == id ? nil : id
                }
            }
        }
    }

    private func save(_ cards: [ParsedCard]) {
        for card in cards {
            var entry = model.newEntry(.flashcard, title: String(card.front.prefix(Limits.maxTitleChars)))
            entry.body = card.back + "\n"
            entry.deck = deck
            entry.tags = card.tags
            entry.options = card.options
            entry.correctOption = card.correctOption
            model.save(entry)
        }
        dismiss()
    }
}
