// Zusammenhang: Entry/EntryPage.swift, Entry/EntryParts.swift, Entry/MarkdownText.swift, Entry/EntryBodyEditor.swift (Bearbeiten im Text-Container), Entry/TitleKeyboardBar.swift (BodyBarActions), Entry/CanvasCard.swift, Entry/EntryActions.swift (CanvasCardHead, CanvasOpenButton), Entries/EntryRow.swift, Flashcards/DeckSection.swift, App/AppModel.swift, Theme/Dimens.swift, Chat/ChatListPage.swift (ChatRow), Chat/ChatModel.swift (linked), ParalistCore Library/AttachmentEntry.swift, ParalistCore Library/PlacePicker.swift, Shell/Router.swift (push)
import ParalistCore
import SwiftUI

extension AppModel {
    func related(_ entry: Entry) -> [Entry] {
        let children = inPlace(entry.id)
        let seen = Set(children.map(\.id) + entry.places)
        return children + rows(entry.links).filter { !seen.contains($0.id) && !(entry.type == .deck && $0.deck == entry.id) }
    }

    func saveCreated(_ entry: Entry) -> Entry? {
        guard let saved = save(entry) else { return nil }
        for other in saved.links { setLinked(saved.id, other, linked: true) }
        return saved
    }

    func saveAttachmentEntry(_ attachment: Attachment?, for saved: Entry) -> Bool {
        switch AttachmentEntry.plan(attachment, for: saved, in: library.all) {
        case .none:
            return false
        case .link(let id):
            setLinked(saved.id, id, linked: true)
            return true
        case .create:
            guard let attachment else { return false }
            return saveCreated(AttachmentEntry.make(newEntry(.file), attachment, for: saved)) != nil
        }
    }
}

struct EntryOption: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        QuickAddRow(icon: icon, label: label, metrics: RowMetrics(inset: Dimens.entryInset - 13, minHeight: 54), fullWidth: false, action: action)
    }
}

struct EntryTextBox: View {
    let entry: Entry
    @Binding var bar: BodyBarActions?
    @Binding var caretBottom: CGFloat
    let onOpen: () -> Void
    let onLink: (String) -> Void
    @State private var contentHeight: CGFloat = 0
    @State private var expanded = false
    @State private var editing = false

    private var empty: Bool { entry.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var overflows: Bool { contentHeight > Dimens.entryTextBox }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CanvasCardHead(icon: AppIcons.text, title: L.s("canvas_text")) {
                CanvasOpenButton(action: onOpen).background(PlusFrameReporter())
            }
            if editing {
                EntryBodyEditor(entry: entry, autofocus: true, inCard: true, minHeight: empty ? Dimens.entryTextEmpty + Dimens.canvasCardPad : Dimens.entryTextBox,
                                bar: $bar, caretBottom: $caretBottom, onEnd: { editing = false })
            } else {
                preview
            }
        }
        .canvasCard()
        .padding(.horizontal, Dimens.entryInset)
        .padding(.top, Dimens.canvasCardGap)
    }

    private var preview: some View {
        Group {
            if empty {
                Text(L.s("entry_body_hint")).font(Typo.bodyLarge).foregroundStyle(Palette.muted)
                    .frame(maxWidth: .infinity, minHeight: Dimens.entryTextEmpty, alignment: .topLeading)
                    .padding([.horizontal, .bottom], Dimens.canvasCardPad)
            } else {
                text
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { editing = true }
    }

    private var text: some View {
        MarkdownText(markdown: entry.body, onLink: onLink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.horizontal, .bottom], Dimens.canvasCardPad)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            .frame(height: expanded && overflows ? contentHeight + Dimens.caretGap * 2 : Dimens.entryTextBox, alignment: .top)
            .clipped()
            .overlay(alignment: .bottom) {
                if overflows, !expanded {
                    Button(L.s("entry_show_more")) { withAnimation(Motion.page) { expanded = true } }
                        .font(Typo.bodyMedium)
                        .buttonStyle(.glass)
                        .foregroundStyle(Palette.onSurface)
                        .padding(.bottom, 12)
                        .frame(maxWidth: .infinity)
                        .background(alignment: .bottom) {
                            LinearGradient(colors: [Palette.cardBottom.opacity(0), Palette.cardBottom], startPoint: .top, endPoint: .bottom)
                                .frame(height: Dimens.entryTextFade)
                                .allowsHitTesting(false)
                        }
                }
            }
    }
}

struct LinkAddMenu<Label: View>: View {
    let onCreate: () -> Void
    let onLink: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Menu {
            Button(action: onCreate) { SwiftUI.Label(L.s("entry_link_new"), systemImage: AppIcons.add) }
            Button(action: onLink) { SwiftUI.Label { Text(L.s("entry_link")) } icon: { GlyphIcon(AppIcons.link, size: 17) } }
        } label: {
            label()
        }
        .menuOrder(.fixed)
        .buttonStyle(.plain)
    }
}

struct PlusFrameKey: PreferenceKey {
    static let defaultValue: [CGRect] = []
    static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) {
        value.append(contentsOf: nextValue())
    }
}

struct PlusFrameReporter: View {
    var body: some View {
        GeometryReader { geo in
            Color.clear.preference(key: PlusFrameKey.self, value: [geo.frame(in: .global)])
        }
    }
}

struct EntryRelations: View {
    let entry: Entry
    var chats = true
    let onAdd: () -> Void
    let onCreate: () -> Void
    var onOpen: (() -> Void)?
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if entry.type == .deck { DeckSection(deck: entry) }
            let related = model.related(entry)
            if !related.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    CanvasCardHead(icon: AppIcons.link, title: L.s("entry_links"), count: related.count) {
                        Group {
                            if let onOpen {
                                CanvasOpenButton(action: onOpen)
                            } else {
                                LinkAddMenu(onCreate: onCreate, onLink: onAdd) {
                                    Image(systemName: AppIcons.add).font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.onSurfaceVariant)
                                        .frame(width: Dimens.canvasOpenHit, height: Dimens.canvasOpenHit)
                                        .contentShape(Rectangle())
                                }
                                .accessibilityLabel(L.s("entry_link_add"))
                            }
                        }
                        .background(PlusFrameReporter())
                    }
                    ForEach(related) { child in
                        EntryRow(entry: child) { router.push(.entry(child.id)) }
                    }
                }
                .padding(.bottom, 8)
                .canvasCard()
                .padding(.horizontal, Dimens.entryInset)
                .padding(.top, Dimens.canvasCardGap)
            }
            let chats = chats ? model.chats.linked(to: entry.id) : []
            if !chats.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    CanvasCardHead(icon: AppIcons.chat.outlined, title: L.s("chat_section"), count: chats.count) { EmptyView() }
                    ForEach(chats) { thread in
                        ChatRow(thread: thread) { router.push(.chat(thread.id)) }
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 8)
                .canvasCard()
                .padding(.horizontal, Dimens.entryInset)
                .padding(.top, Dimens.canvasCardGap)
            }
        }
    }
}
