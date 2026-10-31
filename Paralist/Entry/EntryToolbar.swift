// Zusammenhang: Entry/EntryPage.swift, Entry/EntryMoreMenu.swift, Shell/RouterSplit.swift (closePane, push(from:), DetailPane), Shell/SplitParts.swift (SplitExpandButton), Shell/Router.swift (openChat, closeDetail, push, importCards, study, tabBarLift, entryPillDrop), Chat/ChatThreadPage.swift (chatSeed), Flashcards/StudyPage.swift, Flashcards/ImportCardsSheet.swift, ParalistCore Library/EdgePicker.swift (EntryCanvas), Entries/TypeLook.swift, Icons/AppIcons.swift, Theme/EntryBarDimens.swift, ParalistCore Links/SpotifyLinks.swift, Links/VideoLinks.swift, Files/FileCategory.swift, docs/detailseite.md
import ParalistCore
import SwiftUI

struct EntryToolbar: ToolbarContent {
    let entry: Entry
    let model: AppModel
    let router: Router
    let pane: DetailPane
    @Binding var sheet: EntrySheet?
    let onDelete: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button { router.closePane(pane) } label: { Image(systemName: AppIcons.canvasBack).foregroundStyle(Palette.onSurface) }
                .accessibilityLabel(L.s("menu_close"))
        }
        .sharedBackgroundVisibility(.hidden)
        ToolbarItem(placement: .principal) {
            Text(L.s(TypeLook.of(entry).label)).font(Typo.titleMedium).foregroundStyle(Palette.onSurface)
                .lineLimit(1).truncationMode(.tail)
        }
        .sharedBackgroundVisibility(.hidden)
        ToolbarItemGroup(placement: .topBarTrailing) {
            if router.split {
                SplitExpandButton()
                SplitSideButton()
            } else {
                EntryFavoriteButton(entry: entry, model: model)
                EntryMoreMenu(entry: entry, model: model, router: router, sheet: $sheet, onDelete: onDelete)
            }
        }
        .sharedBackgroundVisibility(.hidden)
    }
}

struct EntryBottomBar: View {
    let entry: Entry
    let playing: Bool
    let collapsed: Bool
    let onPlay: () -> Void
    let onShowMedia: () -> Void
    let onBack: (() -> Void)?
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.detailPane) private var pane
    @State private var completing = false

    private struct IconAction {
        let symbol: String
        let label: String
        let run: () -> Void
    }

    var body: some View {
        let back = onBack.map { IconAction(symbol: AppIcons.canvasReturn, label: "back", run: $0) }
        let showsDone = entry.type == .task && (!entry.isDone || completing)
        let icon = showsDone ? nil : self.icon
        ZStack {
            HStack(spacing: 0) {
                if let back { circle(back) }
                Spacer(minLength: 0)
                if showsDone {
                    doneCircle.transition(.scale(scale: Dimens.entryBarHiddenScale).combined(with: .opacity))
                } else if let icon {
                    circle(icon)
                }
            }
            closeButton
                .padding(.leading, collapsed || back == nil ? 0 : Dimens.entryBarCircle + Dimens.entryBarGap)
                .padding(.trailing, collapsed || (icon == nil && !showsDone) ? 0 : Dimens.entryBarCircle + Dimens.entryBarGap)
        }
        .padding(.horizontal, Dimens.entryBarInset)
        .frame(height: Dimens.entryBarHeight)
        .padding(.bottom, router.tabBarLift)
        .animation(reduceMotion ? nil : Motion.dock, value: collapsed)
        .animation(reduceMotion ? nil : Motion.dock, value: showsDone)
    }

    private var doneCircle: some View {
        Button(action: complete) {
            Image(systemName: AppIcons.task.filled)
                .font(.system(size: Dimens.entryBarDoneIcon, weight: .regular))
                .foregroundStyle(completing ? Palette.done : Palette.openTask.opacity(Dimens.entryBarDoneFaded))
                .scaleEffect(completing && !reduceMotion ? Dimens.entryBarDonePop : 1)
                .frame(width: Dimens.entryBarCircle, height: Dimens.entryBarCircle)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Circle())
        .opacity(collapsed ? 0 : 1)
        .scaleEffect(collapsed && !reduceMotion ? Dimens.entryBarHiddenScale : 1)
        .allowsHitTesting(!collapsed && !completing)
        .accessibilityHidden(collapsed)
        .accessibilityLabel(L.s("notif_action_done"))
        .sensoryFeedback(.success, trigger: completing) { _, now in now }
    }

    private func complete() {
        withAnimation(.spring(duration: 0.3)) { completing = true }
        let id = entry.id
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            model.setDone(id, true)
            try? await Task.sleep(for: .milliseconds(450))
            completing = false
        }
    }

    private var closeButton: some View {
        Button { router.closePane(pane) } label: {
            Text(L.s("create_close"))
                .font(Typo.dm(collapsed ? Dimens.entryBarPillFont : Dimens.entryBarFont, .semibold))
                .lineLimit(1)
                .padding(.horizontal, collapsed ? Dimens.entryBarPillPad : 0)
                .frame(minWidth: collapsed ? Dimens.entryBarPillWidth : nil, maxWidth: collapsed ? nil : .infinity)
                .frame(height: collapsed ? Dimens.entryBarPillHeight : Dimens.entryBarCircle)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.tint)
        .glassEffect(.regular.interactive(), in: Capsule())
        .offset(y: collapsed ? router.entryPillDrop : 0)
    }

    private func circle(_ action: IconAction) -> some View {
        Button(action: action.run) {
            Image(systemName: action.symbol)
                .font(Typo.dm(Dimens.entryBarFont, .semibold))
                .frame(width: Dimens.entryBarCircle, height: Dimens.entryBarCircle)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Palette.onSurface)
        .glassEffect(.regular.interactive(), in: Circle())
        .opacity(collapsed ? 0 : 1)
        .scaleEffect(collapsed && !reduceMotion ? Dimens.entryBarHiddenScale : 1)
        .allowsHitTesting(!collapsed)
        .accessibilityHidden(collapsed)
        .accessibilityLabel(L.s(action.label))
    }

    private var playSymbol: String { playing ? AppIcons.pause : AppIcons.play }

    private var icon: IconAction? {
        if entry.type == .deck {
            if model.inDeck(entry.id).isEmpty {
                return IconAction(symbol: AppIcons.importCards, label: "fc_import", run: { router.importCards = ImportRequest(deck: entry.id) })
            }
            return IconAction(symbol: AppIcons.study, label: "fc_study", run: { router.push(.study(entry.id), from: pane) })
        }
        if entry.type == .flashcard, let deck = entry.deck, model.entry(deck) != nil {
            return IconAction(symbol: AppIcons.study, label: "fc_study", run: { router.push(.study(deck), from: pane) })
        }
        if let url = entry.url, SpotifyLinks.item(url) != nil {
            return IconAction(symbol: playSymbol, label: playing ? "entry_audio_pause" : "entry_audio_play", run: onPlay)
        }
        if let url = entry.url, VideoLinks.youtubeId(url) != nil {
            return IconAction(symbol: playSymbol, label: playing ? "entry_video_pause" : "entry_video_play", run: onPlay)
        }
        if entry.type == .bookmark, let url = entry.url, let link = URL(string: url) {
            return IconAction(symbol: AppIcons.openArrow, label: "entry_link_open_web", run: { openURL(link) })
        }
        guard let attachment = entry.attachment else { return nil }
        switch FileCategory.of(attachment) {
        case .photo: return nil
        case .video: return IconAction(symbol: playSymbol, label: playing ? "entry_video_pause" : "entry_video_play", run: onShowMedia)
        default: return IconAction(symbol: AppIcons.openFile, label: "entry_file_open", run: onShowMedia)
        }
    }
}
