// Zusammenhang: Shell/Router.swift, Shell/MediaPager.swift, ParalistCore Library/MediaPaging.swift, Shell/AppSheets.swift, Shell/RouteDestination.swift, Shell/RootView.swift (NoticeBar), Shell/CreateOverlay.swift, Entry/EntryDestination.swift, Theme/Dimens.swift (swipeBack*), Entry/EntryPage.swift (Cover-Zug, detailDrop), Shell/SplitRootView.swift (inline, pane), Shell/RouterSplit.swift (DetailPane, stack, pop), Chat/ChatThreadPage.swift, Flashcards/StudyPage.swift
import ParalistCore
import SwiftUI
import UIKit

struct DetailHost: View {
    private enum Swipe { case nested, drop, page }

    var inline = false
    var pane: DetailPane = .primary
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shift: CGFloat = 0
    @State private var size: CGSize = .zero
    @GestureState private var swiping = false
    @State private var closing = false
    @State private var mode: Swipe?
    @State private var engaged = false

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: pane == .linked ? $router.linkedPath : $router.detailPath) {
            Group {
                switch current {
                case .cover(let id):
                    if router.mediaQueue.isEmpty {
                        EntryDestination(id: id, cover: true)
                    } else {
                        MediaPager(id: id, shift: shift, width: size.width)
                    }
                case .entry(let id): EntryDestination(id: id)
                case .chat(let id): ChatThreadPage(id: id).background { Palette.surface.ignoresSafeArea() }.modifier(DetailRootClose(inline: inline))
                case .study(let deck): StudyPage(deck: deck).modifier(DetailRootClose(inline: inline))
                default: Color.clear
                }
            }
            .routeDestinations()
        }
        .environment(\.detailPane, pane)
        .overlay(alignment: .bottom) { if !inline { NoticeBar(top: false) } }
        .overlay { CreateOverlay(nested: true) }
        .createSheets(nested: true)
        .importCardsSheet(inDetail: true)
        .background(Palette.surfaceContainer)
        .shadow(color: .black.opacity(!inline && router.detailDrop > 0 ? 0.25 : 0), radius: 16)
        .offset(y: inline ? 0 : router.detailDrop)
        .simultaneousGesture(swipeBack, isEnabled: !router.createOpen)
        .onChange(of: swiping) { _, now in
            guard !now else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(80))
                guard !swiping else { return }
                if !closing, shift != 0 { withAnimation(Motion.dock) { shift = 0 } }
                if engaged, mode == .drop, !router.detailClosing { withAnimation(Motion.dock) { router.detailDrop = 0 } }
                mode = nil
                engaged = false
            }
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .presentationBackground(.clear)
    }

    private var swipeBack: some Gesture {
        DragGesture(minimumDistance: Dimens.swipeBackStart)
            .updating($swiping) { _, state, _ in state = true }
            .onChanged { value in
                if mode == nil { mode = startMode(value.startLocation.x) }
                let dx = value.translation.width
                let sideways = abs(dx) > abs(value.translation.height) * 1.5
                switch mode {
                case .drop:
                    if engaged || (dx > 0 && sideways) {
                        engaged = true
                        if !reduceMotion, !router.detailClosing { router.detailDrop = max(dx, 0) * dropRatio }
                    }
                case .page:
                    if engaged || sideways {
                        engaged = true
                        shift = MediaPaging.shift(drag: dx, hasNeighbor: neighbor(dx < 0 ? 1 : -1) != nil)
                    }
                case .nested, nil: break
                }
            }
            .onEnded { value in
                let current = mode
                let wasEngaged = engaged
                mode = nil
                engaged = false
                let dx = value.translation.width
                let fling = value.predictedEndTranslation.width
                switch current {
                case .nested:
                    if value.startLocation.x > Dimens.swipeBackEdge, dx > abs(value.translation.height) * 1.5,
                       fling > size.width * Dimens.swipeBackShare, !router.stack(pane).isEmpty {
                        router.pop(pane)
                    }
                case .drop:
                    guard wasEngaged else { return }
                    if max(dx, fling) > size.width * Dimens.swipeBackShare {
                        if reduceMotion { router.closeDetail() } else { router.dropDetail(size.height) }
                    } else if router.detailDrop > 0 {
                        withAnimation(Motion.dock) { router.detailDrop = 0 }
                    }
                case .page:
                    guard wasEngaged else { return }
                    turn(MediaPaging.step(fling: fling, width: size.width))
                case nil: break
                }
            }
    }

    private func startMode(_ x: CGFloat) -> Swipe? {
        if !router.stack(pane).isEmpty { return .nested }
        if case .cover(let id) = router.detail, EntryDestination.bare(model.entry(id)),
           !router.mediaQueue.isEmpty, router.detailInCover, x > Dimens.swipeBackEdge { return .page }
        return inline ? nil : .drop
    }

    private var current: Route? { pane == .linked ? router.linked : router.detail }

    private var dropRatio: CGFloat {
        size.width > 0 ? size.height / size.width : 1
    }

    private func neighbor(_ step: Int) -> String? {
        guard pane == .primary, case .cover(let id) = router.detail else { return nil }
        return MediaPaging.neighbor(of: id, in: router.mediaQueue, step: step)
    }

    private func turn(_ step: Int) {
        guard step != 0, let next = neighbor(step) else {
            withAnimation(Motion.dock) { shift = 0 }
            return
        }
        closing = true
        withAnimation(.easeOut(duration: 0.2)) { shift = step > 0 ? -size.width : size.width } completion: {
            var quiet = Transaction()
            quiet.disablesAnimations = true
            withTransaction(quiet) {
                router.detail = .cover(next)
                shift = 0
            }
            closing = false
        }
    }
}

struct PopGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Host { Host() }
    func updateUIViewController(_ controller: Host, context: Context) {}

    final class Host: UIViewController {
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            let nested = (navigationController?.viewControllers.count ?? 0) > 1
            navigationController?.interactivePopGestureRecognizer?.delegate = nil
            navigationController?.interactivePopGestureRecognizer?.isEnabled = nested
        }
    }
}
