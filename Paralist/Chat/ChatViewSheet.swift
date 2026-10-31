// Zusammenhang: Chat/ChatListPage.swift, Pages/ViewSheet.swift (gleicher Aufbau), App/AppPrefs.swift (chatView), ParalistCore Chat/ChatView.swift
import ParalistCore
import SwiftUI

extension ChatFilter {
    var label: String {
        switch self {
        case .all: return "list_all"
        case .pinned: return "list_pinned"
        case .linked: return "chat_linked"
        }
    }
}

struct ChatViewSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let setting = model.prefs.chatView
        NavigationStack {
            List {
                Text(L.s("view_sort"))
                    .font(Typo.bodyMedium).foregroundStyle(Palette.muted)
                    .padding(.top, 18).padding(.bottom, 2)
                    .option()
                Picker(selection: Binding(get: { setting.sort }, set: { model.prefs.chatView = ChatViewSetting(sort: $0) })) {
                    Text(L.s("view_sort_created")).tag(ParalistCore.SortOrder.created)
                    Text(L.s("view_sort_updated")).tag(ParalistCore.SortOrder.updated)
                    Text(L.s("view_sort_title")).tag(ParalistCore.SortOrder.title)
                } label: { row(AppIcons.sortBy, L.s("view_sort_by")) }
                .frame(minHeight: 52)
                .option()
                Picker(selection: Binding(get: { setting.ascending }, set: { model.prefs.chatView = ChatViewSetting(sort: setting.sort, ascending: $0) })) {
                    Text(L.s(setting.sort == .title ? "view_order_az" : "view_order_newest")).tag(setting.sort == .title)
                    Text(L.s(setting.sort == .title ? "view_order_za" : "view_order_oldest")).tag(setting.sort != .title)
                } label: { row(AppIcons.sortDirection, L.s("view_order")) }
                .frame(minHeight: 52)
                .option()
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
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Dimens.sheetRadius)
    }

    private func row(_ icon: String, _ label: String) -> some View {
        HStack(spacing: 14) {
            GlyphIcon(icon, size: 18).foregroundStyle(Palette.onSurfaceVariant).frame(width: 26)
            Text(label).font(Typo.bodyLarge).foregroundStyle(Palette.onSurface)
        }
    }
}

private extension View {
    func option() -> some View {
        listRowInsets(ViewSheet.insets)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}
