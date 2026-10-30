// Zusammenhang: Pages/ViewSheet.swift, Pages/SectionStage.swift (EntryStage), Pages/TasksPage.swift (TaskGroupRow), Shell/PageBar.swift, Pages/FilterTabRow.swift, Pages/OverviewParts.swift (PanelCard, GroupLabel), Entries/EntryRow.swift (RowMetrics, QuickAddRow), Entries/ListAdd.swift, Entries/InlineAdd.swift, Entries/EmptyViews.swift (EmptyHint), Entries/RowSwipe.swift, Entries/SwipeRecognizers.swift, Pages/OverviewPage.swift (EntryQuickMenu), Shell/Router.swift, Capture/CaptureFlow.swift, ParalistCore Library/ListKind.swift
import ParalistCore
import SwiftUI

struct ListPage: View {
    let kind: ListKind
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @State private var filter = ListFilter.all
    @State private var swiping = false
    @State private var swipedAt = Date.distantPast
    @State private var swipes = RowSwipeState()
    @State private var query = ""
    @State private var searching = false
    @State private var showsPin = false
    @State private var customizing = false
    @State private var stageFrame = CGRect.zero
    @State private var adding = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let all = model.list(kind)
        let tabs = ListFilter.visible(for: kind, in: all)
        let active = tabs.contains(filter) ? filter : .all
        let setting = model.prefs.view(kind)
        let found = SearchQuery.filter(all.filter(active.matches), query: query)
        let groups = setting.arrange(found)
        let count = groups.reduce(0) { $0 + $1.1.count }
        let addition = ListAdd.of(kind, filter: active)
        ScrollViewReader { proxy in
            List {
                PageTitle(text: ListTitles.of(kind))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Dimens.titleEdge)
                    .rowSwipeHost(swipes)
                    .plainRow()
                EntryStage(kind: kind, count: count, glyph: ListTitles.icon(kind), pinned: Ordering.pinnedLead(found.filter(setting.shows)), showsPin: $showsPin) {
                    router.open(.entry($0.id))
                }
                .padding(.top, TaskDimens.stageTop)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { stageFrame = $0.divided(atDistance: TaskDimens.stageBottom, from: .maxYEdge).remainder }
                .plainRow()
                TaskGroupRow(label: L.s(Self.sortLabel(setting.sort)), count: showsPin ? count : 0) { customizing = true }
                    .id(PageSearchAnchor.id)
                    .clearRow()
                if tabs.count > 1 {
                    FilterTabRow(items: tabs, selection: Binding(get: { active }, set: { filter = $0 }), label: \.label) { tab in
                        all.filter(tab.matches).count
                    }
                    .plainRow()
                }
                ForEach(Array(groups.enumerated()), id: \.offset) { group in
                    if let type = group.element.0 { GroupLabel(kind: kind, type: type, count: group.element.1.count).plainRow() }
                    ForEach(model.prefs.expanded(kind, group.element)) { entry in
                        PanelCard {
                            EntryRow(entry: entry, metrics: .card, dimmed: kind == .archive && entry.isDone, showsType: kind.showsType(filter: active)) { if tapAllowed { router.open(.entry(entry.id)) } }
                        }
                        .contextMenu { EntryQuickMenu(entry: entry) }
                        .armedSwipe(entry.id, swipes)
                        .plainRow()
                    }
                }
                if kind != .archive && query.isEmpty {
                    PanelCard {
                        if let type = InlineAdd.type(of: addition) {
                            InlineAddRow(type: type, label: addition.label, editing: $adding, metrics: .card) { title in
                                InlineAdd.save(type, title: title, model: model)
                            }
                        } else {
                            QuickAddRow(label: addition.label, metrics: .card) { add(active) }
                        }
                    }
                    .id(InlineAdd.anchor)
                    .plainRow()
                }
                if count == 0 && query.isEmpty {
                    EmptyHint(icon: ListTitles.icon(kind), info: ListAdd.hint(kind), action: kind == .archive ? nil : { add(active) }).plainRow()
                } else if count == 0 {
                    Text(L.s("search_no_results")).font(Typo.bodyMedium).foregroundStyle(Palette.subtle)
                        .padding(.horizontal, Dimens.titleEdge).padding(.top, 12)
                        .plainRow()
                }
                PageSearchRoom(active: searching).plainRow()
            }
            .pageSearchScroll(proxy, active: searching, query: query)
            .inlineAddLift(adding, rows: count, proxy: proxy)
        }
        .listStyle(.plain)
        .scrollDismissesKeyboard(.interactively)
        .environment(\.defaultMinListRowHeight, 0)
        .scrollContentBackground(.hidden)
        .background(Palette.background)
        .rowSwipeFeedback(swipes)
        .background(ContentPopGate(enabled: tabs.count < 2))
        .gesture(
            SidePanRecognizer(edge: Dimens.swipeBackEdge, skip: { stageFrame.contains($0) }) {
                swiping = true
                swipedAt = .now
            } onEnd: { t, vx, startX in
                swiping = false
                swipedAt = .now
                guard !swipes.recent, tabs.count > 1 else { return }
                let step = TabSwipe.step(dx: t.width, dy: t.height, vx: vx)
                if step < 0, startX < SwipeDimens.backZone { return dismiss() }
                self.step(step, in: tabs, from: active)
            }
        )
        .navigationTitle(ListTitles.of(kind))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(removing: .title)
        .sheet(isPresented: $customizing) { ViewSheet(kind: kind) }
        .pageBar(search: PageSearch(query: $query, active: $searching), prompt: L.f("page_search_in", ListTitles.of(kind)), addLabel: addition.label) { addition.run(router: router, model: model) }
    }

    static func sortLabel(_ sort: ParalistCore.SortOrder) -> String {
        switch sort {
        case .updated: return "tasks_recent_updated"
        case .created: return "tasks_recent_created"
        case .title: return "tasks_by_title"
        }
    }

    private var tapAllowed: Bool {
        !swiping && !swipes.recent && Date.now.timeIntervalSince(swipedAt) > MenuDimens.tapLock
    }

    private func step(_ delta: Int, in tabs: [ListFilter], from active: ListFilter) {
        guard delta != 0, let index = tabs.firstIndex(of: active) else { return }
        let next = index + delta
        guard next >= 0, next < tabs.count else { return }
        withAnimation(Motion.short) { filter = tabs[next] }
    }

    private func add(_ filter: ListFilter) {
        let addition = ListAdd.of(kind, filter: filter)
        if InlineAdd.type(of: addition) != nil { return withAnimation(Motion.short) { adding = true } }
        addition.run(router: router, model: model)
    }
}

extension View {
    func plainRow() -> some View {
        listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Palette.background)
    }

    func clearRow() -> some View {
        listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
