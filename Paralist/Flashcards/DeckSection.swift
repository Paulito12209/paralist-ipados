// Zusammenhang: Entry/EntryBlocks.swift (EntryRelations), Entry/CanvasCard.swift, Entry/EntryToolbar.swift (Lernen, Karten importieren), Entry/EntryInfoSheet.swift, Flashcards/StudyPage.swift, Shell/Router.swift (push), Shell/RouterSplit.swift (DetailPane, push(from:), leave)
import ParalistCore
import SwiftUI

struct DeckSection: View {
    let deck: Entry
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @Environment(\.detailPane) private var pane

    var body: some View {
        let cards = model.inDeck(deck.id)
        if !cards.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Text(L.s("fc_cards_section")).font(Typo.titleSmall).foregroundStyle(Palette.onSurface)
                    Text("\(cards.count)").font(Typo.titleSmall).foregroundStyle(Palette.muted)
                }
                .padding(.horizontal, Dimens.canvasCardPad)
                .padding(.top, 4)
                .frame(minHeight: 44)
                ForEach(cards) { card in
                    EntryRow(entry: card, showsType: false) { router.push(.entry(card.id), from: pane) }
                }
            }
            .padding(.bottom, 8)
            .canvasCard()
            .padding(.horizontal, Dimens.entryInset)
            .padding(.top, Dimens.canvasCardGap)
        }
    }
}
