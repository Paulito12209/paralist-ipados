// Zusammenhang: Shell/Router.swift (topRequest), Shell/PageBar.swift, Pages/TaskStage.swift, Pages/TaskFolder.swift, Pages/TaskViewSheet.swift, Entries/InlineAdd.swift (InlineAddRow), Shell/SectionChrome.swift, App/AppModel.swift, App/AppPrefs.swift (taskView), ParalistCore Library/TaskView.swift
import ParalistCore
import SwiftUI

struct TasksPage: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @State private var adding = false
    @State private var archive = false
    @State private var showsPin = false
    @State private var customizing = false
    @State private var hint = false
    @State private var query = ""
    @State private var searching = false
    @Environment(\.tabRoot) private var tabRoot
    @State private var position = ScrollPosition()

    var body: some View {
        let setting = model.prefs.taskView
        let all = model.all.filter { $0.type == .task }
        let groups = setting.arrange(SearchQuery.filter(all, query: query), archive: archive, today: model.today, zone: .current)
        let count = groups.reduce(0) { $0 + $1.1.count }
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if tabRoot { SectionHeader() }
                    PageTitle(text: L.s("nav_tasks")).padding(.horizontal, Dimens.titleEdge)
                    TaskStage(activeCount: TaskViewSetting.active(all).count, archivedCount: setting.archived(all, today: model.today, zone: .current).count,
                              pinned: TaskViewSetting.pinned(all).first, archive: $archive, showsPin: $showsPin) { router.open(.entry($0.id)) }
                        .padding(.top, TaskDimens.stageTop)
                    TaskGroupRow(label: L.s(TaskViewSheet.groupRowLabel(setting.sort)), count: showsPin ? count : 0, pulse: !model.prefs.tasksHintSeen) {
                        hint = !model.prefs.tasksHintSeen
                        model.prefs.tasksHintSeen = true
                        customizing = true
                    }
                    .id(PageSearchAnchor.id)
                    if count == 0 && !adding && !query.isEmpty {
                        Text(L.s("search_no_results")).font(Typo.bodyMedium).foregroundStyle(Palette.subtle)
                            .padding(.horizontal, Dimens.titleEdge).padding(.top, 12)
                    } else if count == 0 && !adding {
                        if archive {
                            EmptyHint(icon: AppIcons.archive, info: L.s("tasks_archive_empty"))
                        } else {
                            EmptyState(text: L.s("empty_tasks")) { adding = true }.frame(minHeight: 300)
                        }
                    }
                    ForEach(Array(groups.enumerated()), id: \.offset) { group in
                        if let status = group.element.0 { TaskGroupLabel(status: status, count: group.element.1.count) }
                        ForEach(expanded(group.element)) { task in
                            PanelCard {
                                EntryRow(entry: task, metrics: .card, statusLook: true, dimmed: archive, showsType: false,
                                         onToggleDone: archive ? nil : { model.setDone(task.id, !task.isDone) }) {
                                    router.open(.entry(task.id))
                                }
                            }
                            .contextMenu {
                                if !archive {
                                    ForEach(TaskStatus.allCases.filter(TaskViewSetting.statuses.contains), id: \.self) { status in
                                        Button { model.setStatus(task.id, status) } label: {
                                            Label(L.s(StatusLook.of(status).label), systemImage: StatusLook.of(status).icon)
                                        }
                                    }
                                    Divider()
                                }
                                EntryQuickMenu(entry: task)
                            }
                        }
                    }
                    if !archive && query.isEmpty {
                        PanelCard {
                            InlineAddRow(type: .task, label: L.s("add_new_task"), editing: $adding, metrics: .card) { title in model.save(model.newEntry(.task, title: title)) }
                        }
                        .id(InlineAdd.anchor)
                    }
                    Color.clear.frame(height: 240).contentShape(Rectangle()).onTapGesture { if !archive { adding = true } }
                    PageSearchRoom(active: searching)
                }
                .headerRoom()
            }
            .pageSearchScroll(proxy, active: searching, query: query)
            .inlineAddLift(adding, rows: count, proxy: proxy)
            .scrollPosition($position)
            .onChange(of: router.topRequest(.tasks)) { _, _ in
                guard tabRoot else { return }
                withAnimation(Motion.dock) { position.scrollTo(edge: .top) }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Palette.background)
        .navigationTitle(L.s("nav_tasks"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(removing: .title)
        .overlay { if hint && customizing { TaskHintVeil().transition(.opacity) } }
        .animation(.easeOut(duration: 0.2), value: hint && customizing)
        .sheet(isPresented: $customizing, onDismiss: { hint = false }) { TaskViewSheet() }
        .pageBar(!tabRoot, search: PageSearch(query: $query, active: $searching), prompt: L.f("page_search_in", L.s("nav_tasks")), addLabel: L.s("add_new_task")) {
            router.compose(ComposerRequest(type: .task))
        }
    }

    private func expanded(_ group: (TaskStatus?, [Entry])) -> [Entry] {
        guard let status = group.0, model.prefs.isCollapsed(key: TaskGroupLabel.key(status)) else { return group.1 }
        return []
    }
}

struct TaskHintVeil: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            Palette.scrim.opacity(scheme == .dark ? ComposerDimens.dimDark : ComposerDimens.dimLight)
            VStack(spacing: 10) {
                Text(L.s("tasks_hint_title")).font(Typo.titleLarge).foregroundStyle(Palette.onSurface)
                Text(L.s("tasks_hint_body")).font(Typo.bodyLarge).foregroundStyle(Palette.onSurfaceVariant)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, TaskDimens.hintEdge)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .containerRelativeFrame(.vertical) { length, _ in length * TaskDimens.hintShare }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .combine)
    }
}

struct TaskGroupRow: View {
    let label: String
    let count: Int
    var pulse = false
    let customize: () -> Void
    @State private var waving = false

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Text(label).font(Typo.titleMedium).foregroundStyle(Palette.onSurface)
            if count > 0 { Text("\(count)").font(Typo.titleMedium).foregroundStyle(Palette.muted) }
            Spacer(minLength: 0)
            Button(action: customize) {
                XoolSlidersIcon(color: Palette.subtle)
                    .frame(width: OverviewDimens.viewIcon, height: OverviewDimens.viewIcon)
                    .frame(width: OverviewDimens.viewButton, height: OverviewDimens.viewButton)
                    .background(Palette.tabActive, in: Circle())
                    .overlay {
                        if pulse {
                            Circle().stroke(Palette.level, lineWidth: 2)
                                .scaleEffect(waving ? TaskDimens.pulseScale : 1)
                                .opacity(waving ? 0 : 0.9)
                            Circle().fill(Palette.level).frame(width: MenuDimens.updateDot, height: MenuDimens.updateDot)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        }
                    }
                    .frame(height: OverviewDimens.headHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onAppear { withAnimation(.easeOut(duration: TaskDimens.pulseSeconds).repeatForever(autoreverses: false)) { waving = true } }
            .accessibilityLabel(L.s("view_customize"))
        }
        .padding(.leading, Dimens.titleEdge)
        .padding(.trailing, Dimens.pageEdge)
        .padding(.bottom, TaskDimens.groupRowBottom)
    }
}

struct TaskGroupLabel: View {
    let status: TaskStatus
    let count: Int
    @Environment(AppModel.self) private var model

    static func key(_ status: TaskStatus) -> String { "\(ListKind.tasks.key)/status/\(status.key)" }

    var body: some View {
        let collapsed = model.prefs.isCollapsed(key: Self.key(status))
        let look = StatusLook.of(status)
        Button {
            withAnimation(Motion.short) { model.prefs.toggleCollapsed(key: Self.key(status)) }
        } label: {
            HStack(spacing: 6) {
                Text(L.s(look.label))
                Text("\(count)").foregroundStyle(Palette.subtle)
                Image(systemName: AppIcons.chevronRight)
                    .font(.system(size: 11, weight: .semibold))
                    .rotationEffect(.degrees(collapsed ? 0 : 90))
                Spacer(minLength: 0)
            }
            .font(Typo.labelLarge).foregroundStyle(Palette.muted)
            .padding(.leading, 24).padding(.top, 12).padding(.bottom, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(L.s(collapsed ? "view_group_collapsed" : "view_group_expanded"))
    }
}
