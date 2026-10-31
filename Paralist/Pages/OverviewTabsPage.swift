// Zusammenhang: Pages/OverviewSwitchSheet.swift (Knopf Tabs, OverviewSourcePicker), Pages/OverviewSections.swift (tabTitle, tabIcon, tabKind), Pages/SettingsPage.swift (OverviewTabOptions), ParalistCore Library/OverviewOptions.swift, App/AppPrefs.swift (overviewLayout), ParalistCore Library/OverviewLayout.swift, Theme/OverviewSectionDimens.swift
import ParalistCore
import SwiftUI

struct OverviewTabsPage: View {
    @Environment(AppModel.self) private var model
    @State private var renaming: String?
    @State private var draft = ""
    @State private var picking: String?
    @State private var limitOpen = false

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
            Section { OverviewTabOptions(limitOpen: $limitOpen) }
        }
        .listStyle(.insetGrouped)
        .environment(\.editMode, .constant(.active))
        .navigationTitle(L.s("overview_tabs"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $picking) { OverviewSourcePicker(tabId: $0, creating: true) }
        .navigationDestination(isPresented: $limitOpen) { OverviewLimitPage() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { picking = Self.newId() } label: { Image(systemName: AppIcons.add) }
                    .disabled(!layout.canAddTab)
                    .accessibilityLabel(L.s("overview_tab_from_source"))
            }
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
            VStack(alignment: .leading, spacing: 0) {
                Text(model.tabTitle(tab)).font(Typo.bodyLarge).foregroundStyle(tab.hidden ? Palette.muted : Palette.onSurface).lineLimit(1)
                Text(model.tabKind(tab)).font(Typo.dm(12)).foregroundStyle(Palette.muted)
            }
            Spacer(minLength: 0)
            if tab.canRename {
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
}

struct OverviewTabOptions: View {
    @Binding var limitOpen: Bool
    @Environment(AppModel.self) private var model

    var body: some View {
        let limit = model.prefs.overviewLayout.sectionLimit
        Picker(selection: Binding(get: { model.prefs.overviewLayout.tabDisplay }, set: { model.prefs.overviewLayout.tabDisplay = $0 })) {
            ForEach(OverviewTabDisplay.allCases, id: \.self) { Text(L.s(Self.label($0))).tag($0) }
        } label: { Label(L.s("overview_tab_display"), systemImage: AppIcons.overviewTabs) }
        Button { limitOpen = true } label: {
            LabeledContent {
                HStack(spacing: 6) {
                    Text(limit.map { "\($0)" } ?? L.s("overview_limit_all"))
                    Image(systemName: AppIcons.chevronRight).font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.subtle)
                }
                .foregroundStyle(Palette.onSurfaceVariant)
            } label: { Label(L.s("overview_section_limit"), systemImage: AppIcons.overviewStacked).foregroundStyle(Palette.onSurface) }
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
    }

    static func label(_ display: OverviewTabDisplay) -> String {
        switch display {
        case .both: return "overview_display_both"
        case .name: return "overview_display_name"
        case .icon: return "overview_display_icon"
        }
    }
}

struct OverviewLimitPage: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let limit = model.prefs.overviewLayout.sectionLimit
        List {
            Section {
                choice(L.s("overview_limit_all"), chosen: limit == nil) { model.prefs.overviewLayout.sectionLimit = nil }
                choice(L.s("overview_limit_custom"), chosen: limit != nil) {
                    if limit == nil { model.prefs.overviewLayout.sectionLimit = OverviewSectionLimit.individual }
                }
            } footer: {
                Text(L.s("overview_section_limit_hint")).font(Typo.bodyMedium).foregroundStyle(Palette.onSurfaceVariant)
            }
            if let limit {
                Section {
                    LabeledContent {
                        Text("\(limit)").font(Typo.titleMedium).foregroundStyle(Palette.primary)
                    } label: { Text(L.s("overview_section_limit")) }
                    Slider(value: Binding(get: { Double(OverviewSectionLimit.index(limit)) },
                                          set: { model.prefs.overviewLayout.sectionLimit = OverviewSectionLimit.steps[Int($0.rounded())] }),
                           in: 0...Double(OverviewSectionLimit.steps.count - 1), step: 1)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(L.s("overview_section_limit"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func choice(_ title: String, chosen: Bool, action: @escaping () -> Void) -> some View {
        Button { withAnimation(Motion.short) { action() } } label: {
            HStack {
                Text(title).font(Typo.bodyLarge).foregroundStyle(Palette.onSurface)
                Spacer(minLength: 0)
                if chosen { Image(systemName: AppIcons.check).font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.primary) }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
