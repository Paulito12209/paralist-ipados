// Zusammenhang: Entry/EntryCanvasPanel.swift, Entry/EntryToolbar.swift (EntryToolbar, EntryBottomBar), Entry/EntryHero.swift, Entry/CoverStage.swift, Entry/CoverChrome.swift, Entry/EdgePicker.swift, Entry/EntryBodyEditor.swift, Entry/TitleKeyboardBar.swift, Entry/EntryDestination.swift, Shell/DetailHost.swift, Shell/RouteDestination.swift (nested), Shell/Router.swift (detailPath, split), Shell/RouterSplit.swift (DetailPane, stack, pop), Flashcards/DeckSection.swift, ParalistCore Library/CoverTransition.swift, Library/EdgePicker.swift, Library/BarCollapse.swift, docs/detailseite.md
import ParalistCore
import QuickLook
import SwiftUI

enum EntrySheet: String, Identifiable {
    case status, tagKind, date, time, place, type, links, reminders, body, info, title, share
    var id: String { rawValue }
}

struct EntryPage: View {
    let id: String
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.detailPane) private var pane
    @State private var sheet: EntrySheet?
    @State private var confirmLink: String?
    @State private var preview: URL?
    @State private var bodyBar: BodyBarActions?
    @State private var canvas: EntryCanvas
    @State private var panel: EntryCanvas
    @State private var cover: CGFloat
    @State private var chrome = true
    @State private var pickerShown = false
    @State private var pickerTucked = true
    @State private var plusFrame: [CGRect] = []
    @State private var expandedAt: CGFloat = 0
    @State private var playing = false
    @State private var embedPlaying = false
    @State private var playRequest = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var scrollEnd: CGFloat = 0
    @State private var rowFrame: CGRect = .zero
    @State private var pickerFrame: CGRect = .zero
    @State private var hintFrame: CGRect = .zero
    @State private var dragFrom: CoverEnd?
    @State private var dragIgnored = false
    @State private var snapTarget: CoverEnd = .detail
    @State private var bar = BarCollapse(threshold: Dimens.entryBarCollapseScroll)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let nested: Bool

    init(id: String, start: EntryCanvas = .actions, bare: Bool = false, nested: Bool = false) {
        self.id = id
        self.nested = nested
        _chrome = State(initialValue: !(bare && start == .cover))
        _canvas = State(initialValue: start)
        _panel = State(initialValue: start == .cover ? .actions : start)
        _cover = State(initialValue: start == .cover ? 1 : 0)
    }

    var body: some View {
        Group {
            if let entry = model.entry(id) {
                content(entry)
            } else {
                Text(L.s("entry_not_found")).font(Typo.bodyLarge).foregroundStyle(Palette.onSurfaceVariant).padding(24)
            }
        }
        .background(Palette.surfaceContainer)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .background { PopGestureEnabler() }
        .toolbarVisibility(cover >= 1 && !chrome ? .hidden : .automatic, for: .navigationBar)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .onAppear {
            model.recordOpened(id)
            router.detailInCover = cover >= 1
        }
        .onChange(of: cover >= 1) { _, now in router.detailInCover = now }
        .quickLookPreview($preview)
        .confirmationDialog(L.s("entry_link_question"), isPresented: Binding(get: { confirmLink != nil }, set: { if !$0 { confirmLink = nil } }), titleVisibility: .visible) {
            Button(L.s("entry_link_open")) {
                if let link = confirmLink, MarkdownBlocks.isAllowedLink(link), let url = URL(string: link) { openURL(url) }
                confirmLink = nil
            }
        } message: {
            Text(confirmLink ?? "")
        }
    }

    private func content(_ entry: Entry) -> some View {
        GeometryReader { geo in
            let topInset = geo.safeAreaInsets.top
            let height = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom
            let band = CGFloat(CoverTransition.band(width: geo.size.width, topInset: topInset))
            EntryHero(entry: entry, t: cover, topInset: topInset, chrome: chrome, scrollOffset: scrollOffset,
                      rowTrailing: pickerOn && canvas == .cover ? Dimens.edgeNotchWidth : 0, playRequest: playRequest,
                      playing: $playing, embedPlaying: $embedPlaying, rowFrame: $rowFrame, hintFrame: $hintFrame,
                      onPlay: { playRequest += 1 }, onToggleDone: { model.setDone(entry.id, !entry.isDone) }) {
                EntryCanvasPanel(entry: entry, canvas: panel, topInset: topInset,
                                 locked: dragFrom != nil, sheet: $sheet, bodyBar: $bodyBar, pickerTucked: $pickerTucked,
                                 confirmLink: $confirmLink, preview: $preview, scrollOffset: $scrollOffset, scrollEnd: $scrollEnd,
                                 onOpenCanvas: { canvas = $0 }, onCreateLinked: { router.openCreate(link: entry.id) })
                    .offset(y: CoverTransition.canvasOffset(t: cover, height: height, band: band) - (dragFrom == .detail ? max(-scrollOffset, 0) : 0))
                    .allowsHitTesting(cover <= 0)
            }
            .contentShape(Rectangle())
            .overlay(alignment: .bottomTrailing) { picker(entry) }
            .simultaneousGesture(SpatialTapGesture(coordinateSpace: .global).onEnded { value in tapped(at: value.location, band: band, entry: entry) })
            .simultaneousGesture(coverDrag(travel: CoverTransition.travel(height: height, band: band), height: height))
            .sensoryFeedback(.selection, trigger: snapTarget)
        }
        .animation(Motion.page, value: pickerShown)
        .onChange(of: canvas) { old, now in
            if now == .cover {
                pickerShown = false
                chrome = !playing
                withAnimation(settleMotion) { cover = 1 }
            } else {
                panel = now
                if old == .cover { withAnimation(settleMotion) { cover = 0 } }
            }
            if now == .text || now == .links { pickerTucked = true }
            bar.reset(at: scrollOffset)
        }
        .onChange(of: sheet) { old, now in
            if now == nil, let old, [.links, .reminders, .date].contains(old) { pickerTucked = true }
        }
        .onChange(of: bodyBar == nil) { _, closed in if closed { bar.reset(at: scrollOffset) } }
        .onChange(of: playing) { _, now in
            if now { chrome = false; pickerShown = false } else { chrome = true }
        }
        .onChange(of: pickerTucked) { _, now in if !now { expandedAt = scrollOffset } }
        .onChange(of: scrollOffset) { _, now in
            if !pickerTucked, canvas != .cover, dragFrom == nil, abs(now - expandedAt) > Dimens.edgeTuckScroll { pickerTucked = true }
            if canvas != .cover, dragFrom == nil, bodyBar == nil { bar.scrolled(to: now, end: scrollEnd) }
        }
        .onPreferenceChange(PlusFrameKey.self) { plusFrame = $0 }
        .onChange(of: plusFrame) { _, now in
            if !pickerTucked, canvas != .cover, now.contains(where: { $0.intersects(pickerFrame) }) { pickerTucked = true }
        }
        .safeAreaInset(edge: .bottom) {
            if cover < 1 {
                if let bar = bodyBar {
                    BodyKeyboardBar(actions: bar)
                } else {
                    EntryBottomBar(entry: entry, playing: playing || embedPlaying, collapsed: bar.collapsed,
                                   onPlay: { playRequest += 1 }, onShowMedia: { showMedia(entry) }, onBack: backAction)
                        .opacity(CoverTransition.detailChrome(t: cover))
                }
            }
        }
        .toolbar {
            EntryToolbar(entry: entry, model: model, router: router, pane: pane, sheet: $sheet, onDelete: {
                model.moveToTrash(entry.id)
                dismiss()
            })
        }
        .sheet(item: $sheet) { which in EntrySheets(which: which, entry: entry) }
    }

    @ViewBuilder
    private func picker(_ entry: Entry) -> some View {
        if EdgePicker.shownOnDetail, bodyBar == nil, canvas != .cover || pickerShown {
            let tucked = pickerTucked && canvas != .cover
            EdgePickerView(selected: $canvas, options: EdgePicker.options(hasText: hasBody(entry) || canvas == .text, hasLinks: !model.related(entry).isEmpty || canvas == .links),
                           title: L.s("canvas_picker"), label: { L.s($0.label) }) { EntryCanvasIcon(item: $0) }
                .offset(x: tucked ? Dimens.edgeNotchWidth - Dimens.edgePeek : 0)
                .allowsHitTesting(!tucked)
                .animation(Motion.dock, value: tucked)
                .overlay(alignment: .trailing) {
                    if tucked {
                        Color.clear.frame(width: Dimens.edgePeekHit).contentShape(Rectangle())
                            .onTapGesture { pickerTucked = false }
                    }
                }
                .opacity(canvas == .cover ? CoverTransition.coverChrome(t: cover) : CoverTransition.detailChrome(t: cover))
                .padding(.bottom, canvas == .cover ? Dimens.edgePickerBottom : Dimens.edgePickerLift)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { pickerFrame = $0 }
                .transition(.move(edge: .trailing).combined(with: .opacity))
        }
    }

    private var pickerOn: Bool {
        EdgePicker.shownOnDetail && (canvas == .cover ? pickerShown : !pickerTucked)
    }

    private var settleMotion: Animation? { reduceMotion ? nil : Motion.dock }

    private func coverDrag(travel: CGFloat, height: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onChanged { value in
                let dy = value.translation.height
                if dragFrom == nil, !dragIgnored {
                    let vertical = abs(dy) > abs(value.translation.width)
                    let onPicker = pickerOn && pickerFrame.contains(value.startLocation)
                    if vertical, !onPicker, cover >= 1 {
                        dragFrom = .cover
                    } else if vertical, !onPicker, cover <= 0, scrollOffset <= 0, dy > 0 {
                        dragFrom = .detail
                    } else {
                        dragIgnored = true
                    }
                    if let from = dragFrom { snapTarget = from }
                }
                guard let from = dragFrom, !reduceMotion else { return }
                let t = CoverTransition.progress(drag: dy, travel: travel, from: from)
                var still = Transaction()
                still.disablesAnimations = true
                withTransaction(still) {
                    cover = t
                    if from == .cover, !router.split { router.detailDrop = cover >= 1 ? max(dy, 0) : 0 }
                }
                snapTarget = CoverTransition.settle(t: t, velocity: 0, from: from)
            }
            .onEnded { value in
                dragIgnored = false
                guard let from = dragFrom else { return }
                dragFrom = nil
                let dy = value.translation.height
                if from == .cover, cover >= 1, dy > Dimens.swipeThreshold, !router.split {
                    if reduceMotion { router.closeDetail() } else { router.dropDetail(height) }
                    return
                }
                if router.detailDrop > 0 { withAnimation(settleMotion) { router.detailDrop = 0 } }
                let t = reduceMotion ? CoverTransition.progress(drag: dy, travel: travel, from: from) : cover
                settle(to: CoverTransition.settle(t: t, velocity: value.velocity.height, from: from))
            }
    }

    private func settle(to target: CoverEnd) {
        withAnimation(settleMotion) { cover = target == .cover ? 1 : 0 }
        if target == .cover {
            if canvas != .cover { canvas = .cover }
        } else if canvas == .cover {
            canvas = panel
        }
    }

    private func tapped(at point: CGPoint, band: CGFloat, entry: Entry) {
        if pickerOn, pickerFrame.contains(point) { return }
        if cover >= 1 {
            if chrome, rowFrame.contains(point) { return }
            if playing || isPhoto(entry) {
                chrome.toggle()
                pickerShown = EdgePicker.shownOnDetail && chrome
            } else {
                if EdgePicker.shownOnDetail { pickerShown.toggle() }
                chrome = true
            }
        } else if cover <= 0, scrollOffset <= 0, point.y < band, !hintFrame.contains(point) {
            if isPhoto(entry) { canvas = .cover } else if isVideo(entry) { playRequest += 1 }
        }
    }

    private var backAction: (() -> Void)? {
        if canvas == .text || canvas == .links { return backToDetail }
        if nested, !router.stack(pane).isEmpty { return { router.pop(pane) } }
        return nil
    }

    private func backToDetail() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        withAnimation(Motion.page) { canvas = .actions }
    }

    private func hasBody(_ entry: Entry) -> Bool {
        !entry.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func isPhoto(_ entry: Entry) -> Bool {
        entry.attachment.map { FileCategory.of($0) == .photo } ?? false
    }

    private func isVideo(_ entry: Entry) -> Bool {
        entry.attachment.map { FileCategory.of($0) == .video } ?? false
    }

    private func showMedia(_ entry: Entry) {
        guard let attachment = entry.attachment else { return }
        switch FileCategory.of(attachment) {
        case .photo: canvas = .cover
        case .video: playRequest += 1
        default: preview = model.attachmentPreviewURL(entry)
        }
    }
}
