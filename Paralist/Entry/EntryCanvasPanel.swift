// Zusammenhang: Entry/EntryPage.swift, Entry/EntryCover.swift (CoverTitleVeil, CanvasSheet), Entry/EntryActions.swift, Entry/EntryBodyEditor.swift, Entry/EntryParts.swift, Entry/EntryPickers.swift, Entry/EntryReminderCard.swift, Entry/EntryTitle.swift, Entry/EntryMetaRow.swift, Entry/EntryActionBar.swift, Entry/EntryInfoSheet.swift, Entry/EntryBlocks.swift, Entry/CanvasCard.swift, Entry/EntryHero.swift (AttachmentCard), Theme/Dimens.swift (mediaRatio), ParalistCore Library/CoverTransition.swift, Library/EdgePicker.swift (shownOnDetail)
import ParalistCore
import SwiftUI

struct EntryCanvasPanel: View {
    let entry: Entry
    let canvas: EntryCanvas
    let topInset: CGFloat
    let locked: Bool
    @Binding var sheet: EntrySheet?
    @Binding var bodyBar: BodyBarActions?
    @Binding var pickerTucked: Bool
    @Binding var confirmLink: String?
    @Binding var preview: URL?
    @Binding var scrollOffset: CGFloat
    @Binding var scrollEnd: CGFloat
    let onOpenCanvas: (EntryCanvas) -> Void
    let onCreateLinked: () -> Void
    let onCover: () -> Void
    let onDelete: () -> Void
    @Binding var actionFrame: CGRect
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @State private var scrolled = false
    @State private var textShown = false
    @State private var scrollHeight: CGFloat = 0
    @State private var caretBottom: CGFloat = 0
    @State private var visibleBottom: CGFloat = 0

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Color.clear.aspectRatio(Dimens.mediaRatio, contentMode: .fit).frame(maxWidth: .infinity)
                    VStack(alignment: .leading, spacing: 0) {
                        EntryTitleLine(entry: entry, onTap: { sheet = .title })
                            .padding(.horizontal, Dimens.entryInset).padding(.top, Dimens.entryTitleTop)
                        EntryMetaRow(entry: entry, onType: { sheet = .type }, onMore: { sheet = .info })
                            .padding(.bottom, router.split ? Dimens.entryActionMetaBottom : Dimens.entryMetaBottom)
                        if router.split {
                            EntryActionBar(entry: entry, onCover: onCover, onDelete: onDelete, sheet: $sheet)
                                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { actionFrame = $0 }
                        }
                    }
                    .background { CoverTitleVeil().allowsHitTesting(false) }
                    VStack(alignment: .leading, spacing: 0) {
                        if canvas == .text {
                            EntryBodyEditor(entry: entry, autofocus: false, bar: $bodyBar, caretBottom: $caretBottom, onRemoved: {
                                textShown = false
                                onOpenCanvas(.actions)
                            })
                        } else if canvas == .links {
                            links
                        } else {
                            actions
                        }
                        Spacer().frame(height: 12)
                    }
                    .padding(.top, Dimens.entryActionTop + Dimens.entryGrabberTop)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .background { CanvasSheet().allowsHitTesting(false) }
                    .background {
                        if EdgePicker.shownOnDetail, canvas == .actions || canvas == .links {
                            Color.clear.contentShape(Rectangle()).onTapGesture { pickerTucked.toggle() }
                        }
                    }
                }
                .frame(minHeight: scrollHeight, alignment: .top)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollDisabled(locked)
            .onScrollGeometryChange(for: CGFloat.self) { $0.containerSize.height - $0.contentInsets.bottom } action: { _, now in visibleBottom = now }
            .onChange(of: caretBottom > visibleBottom && bodyBar != nil) { _, hidden in
                if hidden { withAnimation(Motion.page) { proxy.scrollTo(EntryBodyEditor.caretAnchor, anchor: .bottom) } }
            }
            .onScrollGeometryChange(for: CGFloat.self) { $0.containerSize.height - $0.contentInsets.top - $0.contentInsets.bottom - 24 } action: { _, now in scrollHeight = max(now, 0) }
            .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { _, now in
                scrollOffset = now
                scrolled = now > 8
            }
            .onScrollGeometryChange(for: CGFloat.self) { $0.contentSize.height - $0.containerSize.height } action: { _, now in
                scrollEnd = max(now, 0)
            }
            .overlay(alignment: .top) {
                LinearGradient(colors: [Palette.surfaceContainer, Palette.surfaceContainer.opacity(0)], startPoint: .top, endPoint: .bottom)
                    .frame(height: topInset + 24)
                    .ignoresSafeArea(edges: .top)
                    .opacity(scrolled ? 1 : 0)
                    .animation(.easeOut(duration: 0.2), value: scrolled)
                    .allowsHitTesting(false)
            }
        }
        .animation(Motion.page, value: canvas)
    }

    private var hasBody: Bool {
        !entry.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @ViewBuilder
    private var actions: some View {
        EntryActionButtons(entry: entry, sheet: $sheet, onCreateLinked: onCreateLinked)
        PlaceRow(entry: entry, sheet: $sheet).padding(.top, Dimens.entryPlaceTop)
        Spacer().frame(height: Dimens.canvasCardGap)
        if EntryDateCard.shows(entry) {
            EntryDateCard(entry: entry, sheet: $sheet)
        }
        if EntryReminderCard.shows(entry, now: Date()) {
            EntryReminderCard(entry: entry, now: Date(), sheet: $sheet)
        }
        if let attachment = entry.attachment, ![.photo, .video].contains(FileCategory.of(attachment)) {
            AttachmentCard(attachment: attachment) { preview = model.attachmentPreviewURL(entry) }
        }
        if hasBody || textShown {
            EntryTextBox(entry: entry, bar: $bodyBar, caretBottom: $caretBottom, onOpen: { onOpenCanvas(.text) }, onLink: { confirmLink = $0 })
                .transition(.opacity)
        } else {
            EntryTextToggle(label: L.s("entry_add_body"), isOn: Binding(get: { false }, set: { on in
                if on { withAnimation(Motion.page) { textShown = true } }
            }))
            .transition(.opacity)
        }
        EntryRelations(entry: entry, onAdd: { sheet = .links }, onCreate: onCreateLinked, onOpen: { onOpenCanvas(.links) })
    }

    @ViewBuilder
    private var links: some View {
        if model.related(entry).isEmpty {
            EntryOption(icon: AppIcons.link, label: L.s("entry_link_add")) { sheet = .links }
        }
        EntryRelations(entry: entry, chats: false, onAdd: { sheet = .links }, onCreate: onCreateLinked)
    }
}
