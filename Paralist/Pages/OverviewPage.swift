// Zusammenhang: Shell/Router.swift (topRequest), Shell/SectionChrome.swift (tabRoot), Shell/PageBar.swift, Pages/OverviewParts.swift, Pages/OverviewSections.swift, Pages/OverviewTabLabel.swift (OverviewHeadRow, OverviewShowAllRow), Pages/OverviewEdge.swift (Edge Picker), Pages/OverviewSwitchSheet.swift, Entries/ListAdd.swift, Entries/EntryRow.swift, Entries/InlineAdd.swift, Entries/RowSwipe.swift, Entries/SwipeRecognizers.swift, ParalistCore Library/ListKind.swift, Entry/LinkSheet.swift, Shell/AppSheets.swift (linking)
import ParalistCore
import SwiftUI

struct OverviewPage: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @State private var tab = OverviewTab.listsId
    @State private var quickAdd: String?
    @State private var swiping = false
    @State private var swipedAt = Date.distantPast
    @State private var swipes = RowSwipeState()
    @State private var viewport: CGFloat = 0
    @State private var width: CGFloat = 0
    @State private var option: OverviewEdgeOption?
    @State private var fillTop: CGFloat = 0
    @Environment(\.tabRoot) private var tabRoot
    @State private var position = ScrollPosition()

    private var inline: Bool {
        router.split && OverviewInline.showsOptions(container: Double(width), window: Double(SplitMetrics.sceneWidth))
    }

    var body: some View {
        let stacked = model.prefs.overviewLayout.style == .stacked
        let tabs = model.prefs.overviewLayout.visibleTabs
        let current = tabs.first { $0.id == tab } ?? tabs.first { $0.id == OverviewTab.listsId } ?? tabs[0]
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    if tabRoot, !router.split { SectionHeader() }
                    PageTitle(text: L.s("nav_overview")).padding(.horizontal, Dimens.titleEdge)
                    TileGrid()
                    Spacer().frame(height: stacked ? 0 : OverviewDimens.tilesToList)
                    if stacked {
                        ForEach(tabs) { item in stackedSection(item, fills: tabs.count == 1, first: item.id == tabs.first?.id) }
                        if tabs.count > 1 { Color.clear.frame(height: OverviewDimens.stackedTail) }
                    } else {
                        let feed = model.overviewFeed(current)
                        PinnedSection {
                            OverviewHeader(tabs: tabs, tab: Binding(get: { current.id }, set: { tab = $0 }), feed: feed, onAdd: addAction(feed))
                        } content: {
                            rows(feed)
                            restZone(feed)
                        }
                    }
                }
                .coordinateSpace(.named(Self.content))
                .padding(.bottom, tabRoot ? router.tabBarFloor : 0)
                .headerRoom()
            }
            .scrollPosition($position)
            .inlineAddLift(quickAdd != nil, id: InlineAdd.anchor + (quickAdd ?? ""), rows: model.all.count, proxy: proxy)
        }
        .onChange(of: router.topRequest(.overview)) { _, _ in
            guard tabRoot else { return }
            withAnimation(Motion.dock) { position.scrollTo(edge: .top) }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { viewport = $0 }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .environment(\.overviewOptionAction, inline ? { option = $0 } : nil)
        .modifier(OverviewOptionSheet(option: $option, focus: stacked ? tabs[0] : current, tabs: stacked ? tabs.map(\.id) : [current.id]))
        .scrollDismissesKeyboard(.interactively)
        .rowSwipeFeedback(swipes)
        .rowSwipeGesture(swipes)
        .gesture(
            SidePanRecognizer(edge: tabRoot ? 0 : Dimens.swipeBackEdge) {
                swiping = true
                swipedAt = .now
            } onEnd: { t, vx, _ in
                swiping = false
                swipedAt = .now
                let step = TabSwipe.step(dx: t.width, dy: t.height, vx: vx)
                guard !stacked, !swipes.recent, step != 0, let index = tabs.firstIndex(where: { $0.id == current.id }) else { return }
                let next = min(max(index + step, 0), tabs.count - 1)
                withAnimation(Motion.short) { tab = tabs[next].id }
            }
        )
        .overlay(alignment: .bottomTrailing) {
            if !inline {
                OverviewEdge(sheet: $option)
                    .padding(.bottom, tabRoot ? router.tabBarReserve + Dimens.edgePickerLift : Dimens.edgePickerLift)
            }
        }
        .pageBar(!tabRoot, search: nil, prompt: L.s("search_hint"), addLabel: L.s("nav_create")) { router.openCreate() }
        .background(Palette.background)
        .navigationTitle(L.s("nav_overview"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(removing: .title)
    }

    @ViewBuilder
    private func stackedSection(_ item: OverviewTab, fills: Bool, first: Bool) -> some View {
        let feed = model.overviewFeed(item)
        PinnedSection {
            VStack(spacing: 0) {
                OverviewHeadRow(feed: feed, top: first ? OverviewDimens.listTop : OverviewDimens.groupTop)
                OverviewSortRow(feed: feed, onAdd: addAction(feed))
            }
        } content: {
            rows(feed, limit: model.prefs.overviewLayout.sectionLimit)
            if fills {
                restZone(feed)
            } else if feed.rows.isEmpty {
                FillZone(empty: true, feed: feed, height: OverviewDimens.groupFill, action: addAction(feed))
            } else {
                Color.clear.frame(height: OverviewDimens.groupGap)
            }
        }
    }

    @ViewBuilder
    private func rows(_ feed: OverviewFeed, limit: Int? = nil) -> some View {
        let cut = limit.map { OverviewSectionLimit.cut(groups: feed.groups, limit: $0) } ?? (feed.groups, 0)
        ForEach(cut.0.enumerated().map { (feed.tab.id + "#\($0.offset)", $0.element) }, id: \.0) { item in
            let group = item.1
            if let type = group.0 {
                GroupLabel(kind: feed.kind ?? .all, type: type, count: group.1.count, scope: feed.groupScope)
            }
            ForEach(feed.entries(group, prefs: model.prefs).map { (feed.tab.id + "/" + $0.id, $0) }, id: \.0) { row in
                let entry = row.1
                PanelCard {
                    EntryRow(entry: entry, metrics: .card, showsType: feed.showsType) {
                        if tapAllowed { router.open(.entry(entry.id)) }
                    }
                }
                .contextMenu { EntryQuickMenu(entry: entry) }
                .armedSwipe(entry.id, swipes)
            }
        }
        if cut.1 > 0 {
            PanelCard { OverviewShowAllRow(count: feed.rows.count) { showAll(feed) } }
        }
        if addAction(feed) != nil {
            PanelCard {
                let label = feed.kind.map { ListAdd.of($0).label } ?? L.s("add_new_note")
                if let type = inlineType(feed) {
                    InlineAddRow(type: type, label: label, editing: Binding(get: { quickAdd == feed.tab.id }, set: { if !$0 || tapAllowed { quickAdd = $0 ? feed.tab.id : nil } }), metrics: .card) { title in
                        InlineAdd.save(type, title: title, root: feed.kind == nil ? feed.root : nil, model: model)
                    }
                } else {
                    QuickAddRow(label: label, metrics: .card) { add(feed) }
                }
            }
            .id(InlineAdd.anchor + feed.tab.id)
        }
    }

    private static let content = "overviewContent"

    private func restZone(_ feed: OverviewFeed) -> some View {
        let floor = tabRoot ? router.tabBarFloor : 0
        return FillZone(empty: feed.rows.isEmpty, feed: feed, height: max(OverviewDimens.groupFill, viewport - fillTop - floor), action: addAction(feed))
            .onGeometryChange(for: CGFloat.self) { $0.frame(in: .named(Self.content)).minY } action: { fillTop = $0 }
    }

    private var tapAllowed: Bool {
        !swiping && !swipes.recent && Date.now.timeIntervalSince(swipedAt) > 0.4
    }

    private func showAll(_ feed: OverviewFeed) {
        guard tapAllowed else { return }
        if let kind = feed.kind { router.open(.list(kind)) } else if let root = feed.root { router.open(.entry(root.id)) }
    }

    private func addAction(_ feed: OverviewFeed) -> (() -> Void)? {
        if let kind = feed.kind { return ListAdd.creates(kind) ? { add(feed) } : nil }
        return feed.root == nil ? nil : { add(feed) }
    }

    private func add(_ feed: OverviewFeed) {
        guard tapAllowed else { return }
        if inlineType(feed) != nil { return withAnimation(Motion.short) { quickAdd = feed.tab.id } }
        if let kind = feed.kind { ListAdd.of(kind).run(router: router, model: model) }
    }

    private func inlineType(_ feed: OverviewFeed) -> EntryType? {
        if let kind = feed.kind { return InlineAdd.type(of: ListAdd.of(kind)) }
        return feed.root == nil ? nil : .note
    }
}

struct EntryQuickMenu: View {
    let entry: Entry
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    var body: some View {
        Button { model.update(entry.id) { var e = $0; e.favorite.toggle(); return e } } label: {
            Label(L.s("tool_favorite"), systemImage: entry.favorite ? AppIcons.favorite.filled : AppIcons.favorite.outlined)
        }
        Button { model.update(entry.id) { var e = $0; e.pinned.toggle(); return e } } label: {
            Label(L.s("tool_pin"), systemImage: entry.pinned ? AppIcons.pin.filled : AppIcons.pin.outlined)
        }
        if EntryParent.applies(to: entry.type) {
            Button { router.placing = LinkRequest(id: entry.id) } label: {
                Label(L.s("composer_place_title"), systemImage: AppIcons.place)
            }
        }
        Button { router.linking = LinkRequest(id: entry.id) } label: {
            Label { Text(L.s("entry_link")) } icon: { Image(AppIcons.assetName(AppIcons.link) ?? "").renderingMode(.template) }
        }
        Button { model.update(entry.id) { var e = $0; e.archived.toggle(); return e } } label: {
            Label(L.s(entry.archived ? "entry_unarchive" : "entry_archive"), systemImage: entry.archived ? AppIcons.fromArchive : AppIcons.toArchive)
        }
        Button(role: .destructive) { model.moveToTrash(entry.id) } label: {
            Label(L.s("entry_delete"), systemImage: AppIcons.delete)
        }
    }
}
