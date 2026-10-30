// Zusammenhang: Shell/Router.swift (topRequest), Shell/SectionChrome.swift (tabRoot), Shell/PageBar.swift, Flashcards/StudyPage.swift, Flashcards/ImportCardsSheet.swift, App/AppModel.swift (dueCount, newAvailable), ParalistCore Flashcards/DeckCards.swift
import ParalistCore
import SwiftUI

struct FlashcardsPage: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @Environment(\.tabRoot) private var tabRoot
    @State private var position = ScrollPosition()
    @State private var query = ""
    @State private var searching = false

    var body: some View {
        let allDecks = model.byType(.deck)
        let decks = SearchQuery.filter(allDecks, query: query)
        let cards = model.byType(.flashcard)
        let due = model.dueCount(deck: nil)
        let fresh = model.newAvailable(deck: nil)
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if tabRoot, !router.split { SectionHeader() }
                    PageTitle(text: L.s("page_flashcards")).padding(.horizontal, Dimens.titleEdge)
                    if allDecks.isEmpty && cards.isEmpty {
                        EmptyState(text: L.s("empty_flashcards")) { router.openCreate() }.padding(.top, 40)
                        Button(L.s("fc_import")) { router.importCards = ImportRequest() }.frame(maxWidth: .infinity)
                    } else {
                        HStack(spacing: 16) {
                            Image(systemName: AppIcons.flashcards.filled).font(.system(size: 26)).foregroundStyle(TypeLook.of(.flashcard).color)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L.f("fc_due_today", due)).font(Typo.titleMedium)
                                if fresh > 0 { Text("+ \(fresh) " + L.s("fc_new_badge")).font(Typo.bodySmall).foregroundStyle(Palette.onSurfaceVariant) }
                            }
                            Spacer()
                            Button(L.s("fc_study")) { router.open(.study(nil)) }
                                .buttonStyle(.glassProminent)
                                .disabled(due + fresh == 0)
                        }
                        .padding(20)
                        .background(Palette.tile, in: RoundedRectangle(cornerRadius: Dimens.cardRadius))
                        .padding(.horizontal, Dimens.pageEdge)
                        HStack(spacing: 8) {
                            Text(L.s("type_deck")).font(Typo.labelLarge).foregroundStyle(Palette.muted)
                            Text("\(decks.count)").font(Typo.labelLarge).foregroundStyle(Palette.muted)
                            Spacer()
                            Button(L.s("fc_import")) { router.importCards = ImportRequest() }
                                .font(Typo.labelLarge).foregroundStyle(Palette.onSurfaceVariant)
                        }
                        .padding(.leading, 24).padding(.trailing, 20).padding(.top, 24).padding(.bottom, 4)
                        .id(PageSearchAnchor.id)
                        ForEach(decks) { deck in
                            let count = model.inDeck(deck.id).count
                            let dueHere = model.dueCount(deck: deck.id)
                            PanelCard {
                                EntryRow(entry: deck, metrics: .card, subtitle: L.f("fc_cards_count", count) + (dueHere > 0 ? " · \(dueHere) " + L.s("cal_due").lowercased() : "")) {
                                    router.open(.entry(deck.id))
                                }
                            }
                        }
                        let loose = SearchQuery.filter(DeckCards.loose(model.all), query: query)
                        if !loose.isEmpty {
                            HStack(spacing: 8) {
                                Text(L.s("fc_cards_section")).font(Typo.labelLarge).foregroundStyle(Palette.muted)
                                Text("\(loose.count)").font(Typo.labelLarge).foregroundStyle(Palette.muted)
                            }
                            .padding(.horizontal, 24).padding(.top, 24).padding(.bottom, 4)
                            ForEach(loose) { card in
                                PanelCard {
                                    EntryRow(entry: card, metrics: .card) { router.open(.entry(card.id)) }
                                }
                            }
                        }
                    }
                    PageSearchRoom(active: searching)
                }
            }
            .pageSearchScroll(proxy, active: searching, query: query)
            .scrollPosition($position)
            .onChange(of: router.topRequest(.flashcards)) { _, _ in
                guard tabRoot else { return }
                withAnimation(Motion.dock) { position.scrollTo(edge: .top) }
            }
        }
        .background(Palette.background)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(L.s("page_flashcards"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(removing: .title)
        .pageBar(!tabRoot, search: PageSearch(query: $query, active: $searching), prompt: L.f("page_search_in", L.s("page_flashcards")), addLabel: L.s("add_new_flashcard")) {
            router.compose(ComposerRequest(type: .flashcard))
        }
    }
}
