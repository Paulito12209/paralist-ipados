// Zusammenhang: Flashcards/StudyCard.swift, Entries/TypeLook.swift (StatusLook), ParalistCore Flashcards/StudyQueue.swift, Model/EntryStatus.swift, App/AppModel.swift (studyQueue, review, finishStudy), Shell/Router.swift (leave), Shell/RouteDestination.swift (hidesPhoneTabBar)
import ParalistCore
import SwiftUI

struct StudyPage: View {
    let deck: String?
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var queue: [StudyCandidate]?
    @State private var index = 0
    @State private var flipped = false
    @State private var results: [(String, Bool)] = []
    @State private var chosen: Rating?

    var body: some View {
        VStack(spacing: 0) {
            if let queue {
                if queue.isEmpty {
                    Spacer()
                    Text(L.s("fc_queue_empty")).font(Typo.bodyLarge).foregroundStyle(Palette.onSurfaceVariant).multilineTextAlignment(.center).padding(32)
                    Spacer()
                } else if index >= queue.count {
                    StudyResult(results: results) { router.leave(dismiss) }
                } else if let card = model.entry(queue[index].cardId) {
                    ProgressView(value: Double(index), total: Double(queue.count)).tint(Palette.primary).padding(.horizontal, 16)
                    StudyCard(card: card, flipped: $flipped) { rate(card, $0) }
                        .id(card.id)
                        .padding(.vertical, 16)
                    if flipped && !card.isMultipleChoice {
                        HStack(spacing: Dimens.canvasCardGap) {
                            ForEach(Rating.allCases, id: \.self) { rating in
                                Button {
                                    chosen = rating
                                    Task {
                                        try? await Task.sleep(for: .milliseconds(350))
                                        rate(card, rating)
                                    }
                                } label: {
                                    Text(L.s(label(rating))).font(Typo.labelLarge).fixedSize()
                                }
                                .buttonStyle(.glass)
                                .tint(chosen == rating ? StatusLook.of(EntryStatus.rated(rating), for: .flashcard).color : nil)
                                .disabled(chosen != nil)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16).padding(.bottom, 24)
                        .animation(Motion.short, value: chosen)
                    } else if !card.isMultipleChoice {
                        Text(L.s("fc_flip_hint")).font(Typo.bodySmall).foregroundStyle(Palette.muted).padding(.bottom, 24)
                    }
                } else {
                    Color.clear.onAppear { index += 1 }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface)
        .navigationTitle(deck.flatMap { model.entry($0)?.title } ?? L.s("fc_study_all"))
        .navigationBarTitleDisplayMode(.inline)
        .hidesPhoneTabBar()
        .toolbar {
            if let queue, index < queue.count {
                ToolbarItem(placement: .topBarTrailing) {
                    Text(L.f("fc_counter", index + 1, queue.count)).font(Typo.labelLarge).foregroundStyle(Palette.onSurfaceVariant)
                }
            }
        }
        .onAppear { if queue == nil { queue = model.studyQueue(deck: deck) } }
    }

    private func rate(_ card: Entry, _ rating: Rating) {
        model.review(card.id, rating)
        results.append((card.id, rating != .again))
        flipped = false
        chosen = nil
        withAnimation(Motion.short) { index += 1 }
        if let queue, index >= queue.count { model.finishStudy(deck: deck) }
    }

    private func label(_ rating: Rating) -> String {
        switch rating {
        case .again: return "fc_rating_again"
        case .hard: return "fc_rating_hard"
        case .good: return "fc_rating_good"
        case .easy: return "fc_rating_easy"
        }
    }
}

struct StudyResult: View {
    let results: [(String, Bool)]
    let onDone: () -> Void
    @Environment(AppModel.self) private var model

    var body: some View {
        let known = results.filter(\.1).count
        let wrong = results.filter { !$0.1 }.compactMap { model.entry($0.0) }
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(L.s("fc_result_title")).font(Typo.headlineSmall).padding(.leading, 8).padding(.top, 24)
                HStack(spacing: 8) {
                    tile("\(known)", L.s("fc_result_known"), Palette.tertiary)
                    tile("\(results.count - known)", L.s("fc_result_unknown"), Palette.error)
                }
                if !wrong.isEmpty {
                    Text(L.s("fc_result_wrong")).font(Typo.titleSmall).foregroundStyle(Palette.muted).padding(.leading, 8).padding(.top, 8)
                    ForEach(wrong) { card in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(card.title).font(Typo.bodyLarge).lineLimit(2)
                            Text(card.body.trimmingCharacters(in: .whitespacesAndNewlines)).font(Typo.bodySmall).foregroundStyle(Palette.onSurfaceVariant).lineLimit(2)
                        }
                        .padding(8)
                    }
                }
                Button(action: onDone) { Text(L.s("fc_result_done")).frame(maxWidth: .infinity) }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .padding(.vertical, 24)
            }
            .padding(.horizontal, 16)
        }
    }

    private func tile(_ value: String, _ label: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(Typo.headlineMedium).foregroundStyle(tint)
            Text(label).font(Typo.bodyMedium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Palette.surfaceContainer, in: RoundedRectangle(cornerRadius: Dimens.cardRadius))
    }
}
