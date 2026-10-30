// Zusammenhang: Flashcards/StudyPage.swift, ParalistCore Flashcards/StudyQueue.swift (ratingForSwipe)
import ParalistCore
import SwiftUI

struct StudyCard: View {
    let card: Entry
    @Binding var flipped: Bool
    let onRate: (Rating) -> Void
    @State private var drag: CGFloat = 0
    @State private var picked: Int?

    var body: some View {
        let mc = card.isMultipleChoice
        ZStack {
            RoundedRectangle(cornerRadius: Dimens.sheetRadius).fill(Palette.surfaceContainer).shadow(color: .black.opacity(0.08), radius: 4, y: 2)
            RoundedRectangle(cornerRadius: Dimens.sheetRadius)
                .stroke(abs(drag) > Dimens.swipeThreshold ? (drag > 0 ? Palette.tertiary : Palette.error) : .clear, lineWidth: 3)
            Group {
                if mc { choices } else if flipped { back } else { front }
            }
            .rotation3DEffect(.degrees(flipped && !mc ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        }
        .rotation3DEffect(.degrees(flipped && !mc ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.easeInOut(duration: 0.26), value: flipped)
        .padding(.horizontal, 16)
        .offset(x: drag)
        .rotationEffect(.degrees(Double(drag / 18)))
        .onTapGesture { if !mc { flipped.toggle() } }
        .gesture(mc ? nil : DragGesture()
            .onChanged { drag = $0.translation.width }
            .onEnded { value in
                if abs(value.translation.width) > Dimens.swipeThreshold {
                    onRate(StudyQueue.ratingForSwipe(right: value.translation.width > 0))
                }
                withAnimation(.spring) { drag = 0 }
            })
        .sensoryFeedback(.impact(weight: .light), trigger: abs(drag) > Dimens.swipeThreshold)
    }

    private var front: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(card.title).font(Typo.dm(26, .semibold)).multilineTextAlignment(.center)
                if !card.tags.isEmpty {
                    Text(card.tags.map { "#" + $0 }.joined(separator: "  ")).font(Typo.labelMedium).foregroundStyle(Palette.onSurfaceVariant)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: 300)
        }
    }

    private var back: some View {
        ScrollView {
            Text(card.body.trimmingCharacters(in: .whitespacesAndNewlines)).font(Typo.dm(22)).multilineTextAlignment(.center)
                .padding(24).frame(maxWidth: .infinity, minHeight: 300)
        }
    }

    private var choices: some View {
        VStack(spacing: 8) {
            Text(card.title).font(Typo.titleLarge).multilineTextAlignment(.center).padding(.bottom, 12)
            ForEach(Array(card.options.enumerated()), id: \.offset) { item in
                let number = item.offset + 1
                let correct = number == card.correctOption
                Button {
                    guard picked == nil else { return }
                    picked = number
                    flipped = true
                    Task {
                        try? await Task.sleep(for: .milliseconds(700))
                        picked = nil
                        onRate(correct ? .good : .again)
                    }
                } label: {
                    Text("\(number) · \(item.element)").font(Typo.bodyLarge).frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .background(picked != nil && correct ? Palette.tertiaryContainer : (picked == number ? Palette.error.opacity(0.15) : .clear), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.outlineVariant))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
    }
}
