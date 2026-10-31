// Zusammenhang: ParalistCore Store/TrashRules.swift, App/AppModel.swift (trash, restoreAll, deleteForever), Pages/SettingsPage.swift, Shell/RouteDestination.swift (hidesPhoneTabBar)
import ParalistCore
import SwiftUI

struct TrashPage: View {
    @Environment(AppModel.self) private var model
    @State private var selection = Set<String>()
    @State private var filter: EntryType?
    @State private var confirm = false
    @State private var editMode: EditMode = .active

    var body: some View {
        let items = model.trash()
        let types = EntryType.allCases.filter { t in items.contains { $0.entry.type == t } }
        let shown = items.filter { filter == nil || $0.entry.type == filter }
        List(selection: $selection) {
            Section {
                Text(L.f("trash_hint", TrashRules.retentionDays)).font(Typo.bodySmall).foregroundStyle(Palette.muted)
                if !types.isEmpty {
                    Picker(L.s("trash_all"), selection: $filter) {
                        Text(L.s("trash_all")).tag(EntryType?.none)
                        ForEach(types, id: \.self) { Text(L.s(TypeLook.of($0).label)).tag(EntryType?.some($0)) }
                    }
                    .pickerStyle(.menu)
                }
            }
            .selectionDisabled()
            if items.isEmpty {
                Text(L.s("trash_empty")).font(Typo.bodyLarge).foregroundStyle(Palette.onSurfaceVariant).selectionDisabled()
            }
            ForEach(shown, id: \.entry.id) { item in
                let look = TypeLook.of(item.entry)
                HStack(spacing: 12) {
                    GlyphIcon(look.icon.outlined, size: 17).foregroundStyle(look.color).frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.entry.title.isEmpty ? L.s("list_untitled") : item.entry.title).font(Typo.bodyLarge).lineLimit(1)
                        Text(L.s(look.label) + " · " + L.f("trash_deleted_on", item.deletedAt.formatted(date: .abbreviated, time: .omitted)) + " · " + L.f("trash_days_left", TrashRules.daysLeft(item.deletedAt, now: Date())))
                            .font(Typo.bodySmall).foregroundStyle(Palette.muted).lineLimit(2)
                    }
                }
                .tag(item.entry.id)
            }
        }
        .environment(\.editMode, $editMode)
        .paneTitle("trash_title")
        .toolbar {
            if !shown.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    let all = Set(shown.map(\.entry.id))
                    Button(L.s(selection.isSuperset(of: all) ? "trash_select_none" : "trash_select_all")) {
                        selection = selection.isSuperset(of: all) ? [] : all
                    }
                }
            }
            if !selection.isEmpty {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button(L.s("trash_restore")) {
                        model.restoreAll(Array(selection))
                        selection = []
                    }
                    Spacer()
                    Text(L.f("trash_selected", selection.count)).font(Typo.bodyMedium)
                    Spacer()
                    Button(L.s("trash_delete_forever"), role: .destructive) { confirm = true }.tint(Palette.error)
                }
            }
        }
        .hidesPhoneTabBar()
        .alert(L.s("trash_delete_forever"), isPresented: $confirm) {
            Button(L.s("trash_delete_forever"), role: .destructive) {
                model.deleteForever(Array(selection))
                selection = []
            }
            Button(L.s("dialog_cancel"), role: .cancel) {}
        } message: { Text(L.f("trash_delete_confirm", selection.count)) }
    }
}
