// Zusammenhang: Shell/Router.swift (topRequest), Shell/SectionChrome.swift (tabRoot), Pages/MediaCell.swift, Pages/MediaBar.swift (MediaAddMenu), Shell/PageBar.swift, Pages/FilterTabRow.swift, Pages/ListPage.swift (PageTitle-Aufbau), App/AppModel.swift (byType), Shell/RouteDestination.swift, Shell/MediaPager.swift (Blättern), ParalistCore Links/SharedFile.swift (MediaKind)
import ParalistCore
import SwiftUI

enum MediaFilter: CaseIterable {
    case all, image, video, audio

    var label: String {
        switch self {
        case .all: return "list_all"
        case .image: return "media_filter_images"
        case .video: return "media_filter_videos"
        case .audio: return "media_filter_audios"
        }
    }

    func matches(_ kind: MediaKind?) -> Bool {
        switch self {
        case .all: return kind == .image || kind == .video || kind == .audio
        case .image: return kind == .image
        case .video: return kind == .video
        case .audio: return kind == .audio
        }
    }
}

struct MediaPage: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @State private var filter = MediaFilter.all
    @State private var swiping = false
    @State private var swipedAt = Date.distantPast
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabRoot) private var tabRoot
    @State private var position = ScrollPosition()
    @State private var query = ""
    @State private var searching = false

    var body: some View {
        let all = model.byType(.file).filter { MediaFilter.all.matches(MediaKind.of($0)) }
        let shown = SearchQuery.filter(all.filter { filter.matches(MediaKind.of($0)) }, query: query)
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if tabRoot, !router.split { SectionHeader() }
                    PageTitle(text: L.s("page_media")).padding(.horizontal, Dimens.titleEdge)
                    MediaFilterRow(filter: $filter, counts: counts(all))
                        .id(PageSearchAnchor.id)
                    if shown.isEmpty {
                        EmptyHint(icon: AppIcons.image, info: L.s("media_empty")).padding(.top, 40)
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: MediaDimens.gap), count: 3), spacing: MediaDimens.gap) {
                            ForEach(shown) { entry in
                                MediaCell(entry: entry) { open(entry, among: shown) }
                            }
                        }
                        .padding(.horizontal, MediaDimens.edge)
                        .padding(.top, 8)
                    }
                    Color.clear.frame(height: tabRoot ? router.tabBarFloor + (router.split ? 0 : TabBarDimens.tools + TabBarDimens.gap) : 0)
                    PageSearchRoom(active: searching)
                }
            }
            .pageSearchScroll(proxy, active: searching, query: query)
            .scrollPosition($position)
            .onChange(of: router.topRequest(.media)) { _, _ in
                guard tabRoot else { return }
                withAnimation(Motion.dock) { position.scrollTo(edge: .top) }
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 8)
                .onChanged { value in
                    if !swiping, value.startLocation.x > Dimens.swipeBackEdge, abs(value.translation.width) > 8 { swiping = true }
                }
                .onEnded { value in
                    let wasSwiping = swiping
                    swiping = false
                    swipedAt = .now
                    let dx = value.translation.width
                    guard wasSwiping, abs(dx) > Dimens.swipeThreshold, abs(dx) > abs(value.translation.height) * 1.5 else { return }
                    step(dx < 0 ? 1 : -1)
                }
        )
        .background(Palette.background)
        .navigationTitle(L.s("page_media"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(removing: .title)
        .scrollDismissesKeyboard(.interactively)
        .pageBar(!tabRoot, search: PageSearch(query: $query, active: $searching), prompt: L.f("page_search_in", L.s("page_media"))) { MediaAddMenu() }
        .fileImporter(isPresented: Binding(get: { router.mediaImport }, set: { router.mediaImport = $0 }), allowedContentTypes: [.image, .movie, .audio]) { result in
            if case .success(let url) = result {
                CaptureFlow.save(AttachmentImporter.importFile(at: url, into: model.library.store), kind: .files, link: nil, model: model)
            }
        }
    }

    private func open(_ entry: Entry, among shown: [Entry]) {
        guard tapAllowed else { return }
        let queue = shown.filter { [.image, .video].contains(MediaKind.of($0)) }.map(\.id)
        router.openMedia(entry.id, among: queue.contains(entry.id) ? queue : [])
    }

    private var tapAllowed: Bool {
        !swiping && Date.now.timeIntervalSince(swipedAt) > MenuDimens.tapLock
    }

    private func step(_ delta: Int) {
        let all = MediaFilter.allCases
        guard let index = all.firstIndex(of: filter) else { return }
        let next = index + delta
        if next < 0 { return dismiss() }
        guard next < all.count else { return }
        withAnimation(Motion.short) { filter = all[next] }
    }

    private func counts(_ all: [Entry]) -> [MediaFilter: Int] {
        var result: [MediaFilter: Int] = [.all: all.count]
        for entry in all {
            switch MediaKind.of(entry) {
            case .image: result[.image, default: 0] += 1
            case .video: result[.video, default: 0] += 1
            case .audio: result[.audio, default: 0] += 1
            default: break
            }
        }
        return result
    }
}

struct MediaFilterRow: View {
    @Binding var filter: MediaFilter
    let counts: [MediaFilter: Int]

    var body: some View {
        FilterTabRow(items: MediaFilter.allCases, selection: $filter, label: { L.s($0.label) }, count: { counts[$0] ?? 0 })
    }
}
