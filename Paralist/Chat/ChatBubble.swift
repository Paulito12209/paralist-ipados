// Zusammenhang: Chat/ChatThreadPage.swift, Chat/ChatImageParts.swift (ChatBubbleImage), Chat/ChatThreadParts.swift (ChatEntryChips), Entry/MarkdownText.swift, Theme/Dimens.swift (ChatDimens), Theme/Palette.swift, docs/chat.md
import ParalistCore
import SwiftUI

struct ChatBubble: View {
    let role: ChatRole
    let text: String
    var image: URL? = nil
    var openImage: () -> Void = {}
    var mentions: [String] = []
    let onLink: (String) -> Void
    @Environment(\.layoutDirection) private var direction

    var body: some View {
        let mine = role == .user
        let tailRight = mine != (direction == .rightToLeft)
        VStack(alignment: mine ? .trailing : .leading, spacing: ChatDimens.imageRowGap) {
            if !mentions.isEmpty {
                ChatEntryChips(ids: mentions)
            }
            if let image {
                ChatBubbleImage(url: image, open: openImage)
            }
            if !text.isEmpty {
                Group {
                    if mine {
                        Text(text).font(Typo.bodyLarge).foregroundStyle(Palette.onPrimaryContainer)
                    } else {
                        MarkdownText(markdown: text, onLink: onLink, hugs: true)
                    }
                }
                .textSelection(.enabled)
            }
        }
        .padding(.horizontal, image == nil && mentions.isEmpty ? ChatDimens.bubblePadH : ChatDimens.bubblePadV)
        .padding(.vertical, ChatDimens.bubblePadV)
        .padding(mine ? .trailing : .leading, ChatDimens.bubbleTail)
        .background(mine ? Palette.primaryContainer : Palette.surfaceContainer, in: ChatBubbleShape(tailRight: tailRight))
        .padding(mine ? .leading : .trailing, ChatDimens.bubbleLead)
        .frame(maxWidth: .infinity, alignment: mine ? .trailing : .leading)
    }
}

struct ChatBubbleShape: Shape {
    var tailRight: Bool

    func path(in rect: CGRect) -> Path {
        let tail = ChatDimens.bubbleTail
        let radius = ChatDimens.bubbleRadius
        let rise = ChatDimens.bubbleTailHeight
        let box = CGRect(x: rect.minX, y: rect.minY, width: rect.width - tail, height: rect.height)
        let corners = RectangleCornerRadii(topLeading: radius, bottomLeading: radius, bottomTrailing: ChatDimens.bubbleTailCorner, topTrailing: radius)
        var path = Path(roundedRect: box, cornerRadii: corners, style: .continuous)
        path.move(to: CGPoint(x: box.maxX - rise, y: box.maxY - rise))
        path.addLine(to: CGPoint(x: box.maxX, y: box.maxY - rise))
        path.addQuadCurve(to: CGPoint(x: box.maxX + tail, y: box.maxY), control: CGPoint(x: box.maxX + 1, y: box.maxY - 4))
        path.addQuadCurve(to: CGPoint(x: box.maxX - rise, y: box.maxY), control: CGPoint(x: box.maxX - 2, y: box.maxY))
        path.closeSubpath()
        guard !tailRight else { return path }
        return path.applying(CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: rect.minX + rect.maxX, ty: 0))
    }
}
