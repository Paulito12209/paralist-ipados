// Zusammenhang: Pages/TasksPage.swift, Pages/ViewSheet.swift (gleicher Aufbau), App/AppPrefs.swift (taskView), Entries/TypeLook.swift (StatusLook), ParalistCore Library/TaskView.swift
import ParalistCore
import SwiftUI

struct TaskViewSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let setting = model.prefs.taskView
        NavigationStack {
            List {
                Color.clear.frame(height: 8).listRowInsets(EdgeInsets()).listRowBackground(Color.clear).listRowSeparator(.hidden)
                Picker(selection: binding(\.sort, setting) { s, sort in s.sort = sort; s.ascending = sort.naturalAscending }) {
                    Text(L.s("view_sort_created")).tag(TaskSort.created)
                    Text(L.s("view_sort_updated")).tag(TaskSort.updated)
                    Text(L.s("tasks_sort_due")).tag(TaskSort.due)
                    Text(L.s("view_sort_title")).tag(TaskSort.title)
                } label: { row(AppIcons.sortBy, L.s("view_sort_by")) }
                .plainTaskOption()
                Picker(selection: binding(\.ascending, setting) { s, up in s.ascending = up }) {
                    Text(L.s(Self.orderLabel(setting.sort, ascending: true))).tag(true)
                    Text(L.s(Self.orderLabel(setting.sort, ascending: false))).tag(false)
                } label: { row(AppIcons.sortDirection, L.s("view_order")) }
                .plainTaskOption()
                Picker(selection: binding(\.grouping, setting) { s, g in s.grouping = g }) {
                    Text(L.s("view_group_none")).tag(TaskGrouping.none)
                    Text(L.s("view_group_status")).tag(TaskGrouping.status)
                } label: { row(AppIcons.groupBy, L.s("view_group_by")) }
                .plainTaskOption()
                if setting.grouping == .status {
                    NavigationLink { TaskGroupOrderPage() } label: {
                        HStack(spacing: 14) {
                            row(AppIcons.groupOrder, L.s("tasks_group_order"))
                            Spacer(minLength: 0)
                            Text(setting.groupOrder.map { L.s(StatusLook.of($0).label) }.joined(separator: " · "))
                                .font(Typo.bodySmall).foregroundStyle(Palette.muted).lineLimit(1)
                        }
                    }
                    .plainTaskOption()
                }
                Picker(selection: binding(\.done, setting) { s, d in s.done = d }) {
                    Text(L.s("tasks_done_always")).tag(DoneVisibility.always)
                    Text(L.s("tasks_done_day")).tag(DoneVisibility.sameDay)
                    Text(L.s("tasks_done_week")).tag(DoneVisibility.week)
                    Text(L.s("tasks_done_never")).tag(DoneVisibility.never)
                } label: { row(AppIcons.doneVisibility, L.s("tasks_done_show")) }
                .plainTaskOption()
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 0)
            .pickerStyle(.menu)
            .tint(Palette.primary)
            .navigationTitle(L.s("view_customize"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: AppIcons.close) }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Dimens.sheetRadius)
    }

    static func orderLabel(_ sort: TaskSort, ascending: Bool) -> String {
        switch sort {
        case .title: return ascending ? "view_order_az" : "view_order_za"
        case .due: return ascending ? "tasks_order_soonest" : "tasks_order_latest"
        case .created, .updated: return ascending ? "view_order_oldest" : "view_order_newest"
        }
    }

    static func groupRowLabel(_ sort: TaskSort) -> String {
        switch sort {
        case .created: return "tasks_recent_created"
        case .updated: return "tasks_recent_updated"
        case .due: return "tasks_by_due"
        case .title: return "tasks_by_title"
        }
    }

    private func row(_ icon: String, _ label: String) -> some View {
        HStack(spacing: 14) {
            GlyphIcon(icon, size: 18).foregroundStyle(Palette.onSurfaceVariant).frame(width: 26)
            Text(label).font(Typo.bodyLarge).foregroundStyle(Palette.onSurface)
        }
    }

    private func binding<T>(_ path: KeyPath<TaskViewSetting, T>, _ setting: TaskViewSetting, _ apply: @escaping (inout TaskViewSetting, T) -> Void) -> Binding<T> {
        Binding(get: { setting[keyPath: path] }, set: { value in
            var s = setting
            apply(&s, value)
            withAnimation(Motion.short) { model.prefs.taskView = s }
        })
    }
}

struct TaskGroupOrderPage: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let setting = model.prefs.taskView
        List {
            Text(L.s("tasks_group_order_hint"))
                .font(Typo.bodyMedium)
                .foregroundStyle(Palette.muted)
                .padding(.top, 18)
                .padding(.bottom, 8)
                .listRowInsets(ViewSheet.insets)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .moveDisabled(true)
            ForEach(setting.groupOrder, id: \.self) { status in
                let look = StatusLook.of(status)
                HStack(spacing: 14) {
                    Image(systemName: look.icon).font(.system(size: 20)).foregroundStyle(look.color).frame(width: 26)
                    Text(L.s(look.label)).font(Typo.bodyLarge).foregroundStyle(Palette.onSurface)
                }
                .frame(minHeight: 52)
                .listRowInsets(ViewSheet.insets)
                .listRowBackground(Color.clear)
            }
            .onMove { from, to in
                guard let first = from.first else { return }
                withAnimation(Motion.short) { model.prefs.taskView = setting.moveGroup(from: first, to: to) }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 0)
        .environment(\.editMode, .constant(.active))
        .navigationTitle(L.s("tasks_group_order"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension View {
    func plainTaskOption() -> some View {
        frame(minHeight: 52)
            .listRowInsets(ViewSheet.insets)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}
