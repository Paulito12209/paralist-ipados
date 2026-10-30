// Zusammenhang: ParalistCore Text/MarkdownBlocks.swift, Entry/EntryPage.swift, Chat/ChatBubble.swift (hugs)
import ParalistCore
import SwiftUI

struct MarkdownText: View {
    let markdown: String
    let onLink: (String) -> Void
    var hugs = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(MarkdownBlocks.parse(markdown).enumerated()), id: \.offset) { item in
                block(item.element)
            }
        }
        .frame(maxWidth: hugs ? nil : .infinity, alignment: .leading)
        .environment(\.openURL, OpenURLAction { url in
            onLink(url.absoluteString)
            return .handled
        })
    }

    @ViewBuilder
    private func block(_ block: Block) -> some View {
        switch block {
        case .heading(let level, let inlines):
            Text(Self.attributed(inlines)).font(level == 1 ? Typo.titleLarge : level == 2 ? Typo.titleMedium : Typo.titleSmall)
        case .paragraph(let inlines):
            Text(Self.attributed(inlines)).font(Typo.bodyLarge).foregroundStyle(Palette.onSurface)
        case .listItem(_, let checked, let inlines):
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(checked == true ? "☑" : checked == false ? "☐" : "•").foregroundStyle(Palette.onSurfaceVariant).frame(width: 24, alignment: .leading)
                Text(Self.attributed(inlines)).font(Typo.bodyLarge)
            }
        case .quote(let inlines):
            HStack(spacing: 12) {
                Rectangle().fill(Palette.outlineVariant).frame(width: 3)
                Text(Self.attributed(inlines)).font(Typo.bodyLarge).italic().foregroundStyle(Palette.onSurfaceVariant)
            }
            .padding(.leading, 4)
            .fixedSize(horizontal: false, vertical: true)
        case .code(let text):
            Text(text).font(.system(.callout, design: .monospaced)).padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.surfaceLow, in: RoundedRectangle(cornerRadius: 8))
        case .rule:
            Divider()
        case .blank:
            Color.clear.frame(height: 8)
        }
    }

    static func attributed(_ inlines: [Inline]) -> AttributedString {
        var out = AttributedString()
        for inline in inlines {
            switch inline {
            case .text(let text, let bold, let italic, let code):
                var part = AttributedString(text)
                var intent: InlinePresentationIntent = []
                if bold { intent.insert(.stronglyEmphasized) }
                if italic { intent.insert(.emphasized) }
                if code { intent.insert(.code) }
                if !intent.isEmpty { part.inlinePresentationIntent = intent }
                out += part
            case .link(let text, let url):
                var part = AttributedString(text)
                part.link = URL(string: url)
                part.underlineStyle = .single
                part.foregroundColor = Palette.primary
                out += part
            }
        }
        return out
    }
}
