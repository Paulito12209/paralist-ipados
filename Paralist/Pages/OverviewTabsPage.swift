// Zusammenhang: Pages/OverviewSwitchSheet.swift (Knopf Tabs, OverviewSourcePicker), Pages/OverviewSections.swift (tabTitle, tabIcon), App/AppPrefs.swift (overviewLayout), ParalistCore Library/OverviewLayout.swift, Theme/OverviewSectionDimens.swift
import ParalistCore
import SwiftUI

struct OverviewTabsPage: View {
    @Environment(AppModel.self) private var model
    @State private var naming = false
    @State private var renaming: String?
    @State private var draft = ""
    @State private var filling: String?
    @State private var picking: String?

    var body: some View {
        let layout = model.prefs.overviewLayout
        List {
            Section {
                ForEach(layout.tabs) { tab in
                    row(tab, layout: layout).deleteDisabled(tab.isBuiltIn)
                }
                .onMove { from, to in model.prefs.overviewLayout.moveTabs(from: Array(from), to: to) }
                .onDelete { offsets in
                    withAnimation(Motion.short) { offsets.map { layout.tabs[$0].id }.forEach { model.prefs.overviewLayout.removeTab($0) } }
                }
            } footer: {
                Text(L.s("overview_tabs_hint")).font(Typo.bodyMedium).foregroundStyle(Palette.onSurfaceVariant)
            }
        }
        .listStyle(.insetGrouped)
        .environment(\.editMode, .constant(.active))
        .navigationTitle(L.s("overview_tabs"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $filling) { OverviewSourcePicker(tabId: $0) }
        .navigationDestination(item: $picking) { OverviewSourcePicker(tabId: $0, creating: true) }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { picking = Self.newId() } label: { Label(L.s("overview_tab_from_source"), systemImage: AppIcons.overviewSwitch) }
                    Button {
                        draft = ""
                        naming = true
                    } label: { Label(L.s("overview_tab_custom"), systemImage: AppIcons.edit) }
                } label: { Image(systemName: AppIcons.add) }
                .disabled(!layout.canAddTab)
                .accessibilityLabel(L.s("overview_tab_new"))
            }
        }
        .alert(L.s("overview_tab_new"), isPresented: $naming) {
            TextField(L.s("overview_tab_name"), text: $draft)
            Button(L.s("dialog_cancel"), role: .cancel) {}
            Button(L.s("dialog_save")) { create() }
        }
        .alert(L.s("overview_tab_rename"), isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
            TextField(L.s("overview_tab_name"), text: $draft)
            Button(L.s("dialog_cancel"), role: .cancel) {}
            Button(L.s("dialog_save")) {
                if let renaming { model.prefs.overviewLayout.rename(renaming, draft) }
            }
        }
    }

    private func row(_ tab: OverviewTab, layout: OverviewLayout) -> some View {
        HStack(spacing: 12) {
            GlyphIcon(model.tabIcon(tab), size: 20).foregroundStyle(tab.hidden ? Palette.muted : Palette.onSurfaceVariant)
                .frame(width: OverviewDimens.pickerIcon)
            VStack(alignment: .leading, spacing: 2) {
                Text(model.tabTitle(tab)).font(Typo.bodyLarge).foregroundStyle(tab.hidden ? Palette.muted : Palette.onSurface).lineLimit(1)
                if tab.hidden { Text(L.s("tabbar_hidden")).font(Typo.bodyMedium).foregroundStyle(Palette.muted) }
            }
            Spacer(minLength: 0)
            if !tab.isBuiltIn {
                Button {
                    draft = tab.name
                    renaming = tab.id
                } label: { icon(AppIcons.edit) }
                .buttonStyle(.borderless)
                .accessibilityLabel(L.s("overview_tab_rename"))
            }
            Button {
                withAnimation(Motion.short) { model.prefs.overviewLayout.setHidden(tab.id, !tab.hidden) }
            } label: { icon(tab.hidden ? AppIcons.tabHidden : AppIcons.tabShown) }
            .buttonStyle(.borderless)
            .disabled(!tab.hidden && !layout.canHide(tab.id))
            .accessibilityLabel(L.s(tab.hidden ? "overview_show" : "overview_hide"))
        }
    }

    private func icon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 16))
            .foregroundStyle(Palette.onSurfaceVariant)
            .frame(width: OverviewDimens.pickerIcon, height: OverviewDimens.pickerIcon)
            .contentShape(Rectangle())
    }

    private static func newId() -> String { "tab-" + UUID().uuidString.prefix(8).lowercased() }

    private func create() {
        let id = Self.newId()
        guard model.prefs.overviewLayout.addTab(id: id, name: draft) else { return }
        filling = id
    }
}
