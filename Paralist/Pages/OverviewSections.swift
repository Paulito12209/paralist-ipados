// Zusammenhang: Pages/OverviewPage.swift, Pages/OverviewParts.swift (OverviewTabs, OverviewHeader), Pages/OverviewSwitchSheet.swift, Pages/OverviewTabsPage.swift, App/AppPrefs.swift (overviewLayout, entryView, collapsed), ParalistCore Library/OverviewLayout.swift, ParalistCore Library/OverviewScope.swift, Entries/ListAdd.swift, Entries/TypeLook.swift, Theme/OverviewSectionDimens.swift
import ParalistCore
import SwiftUI

struct OverviewFeed {
    let tab: OverviewTab
    let source: OverviewSource?
    let root: Entry?
    let groups: [(EntryType?, [Entry])]

    var kind: ListKind? { source?.kind }
    var rows: [Entry] { groups.flatMap(\.1) }
    var showsType: Bool { kind?.showsType() ?? true }
    var groupScope: String { kind?.key ?? source?.key ?? tab.id }
    var single = false

    func emptyInfo(canAdd: Bool) -> String {
        if let kind { return ListAdd.hint(kind, tappable: canAdd) }
        if canAdd { return L.s("overview_empty_tap") }
        return L.s(source == nil ? "overview_tab_empty" : "overview_entry_empty")
    }

    @MainActor func entries(_ group: (EntryType?, [Entry]), prefs: AppPrefs) -> [Entry] {
        guard let type = group.0, prefs.isCollapsed(key: "\(groupScope)/\(type.key)") else { return group.1 }
        return []
    }
}

extension AppModel {
    func overviewExists(_ id: String) -> Bool { entry(id).map { !$0.archived } ?? false }

    func overviewSource(_ tab: OverviewTab) -> OverviewSource? { tab.current(existing: overviewExists) }

    func overviewFeed(_ tab: OverviewTab) -> OverviewFeed {
        var feed = baseFeed(tab)
        feed.single = tab.shown(existing: overviewExists).count == 1
        return feed
    }

    private func baseFeed(_ tab: OverviewTab) -> OverviewFeed {
        let source = overviewSource(tab)
        switch source {
        case .list(let kind):
            return OverviewFeed(tab: tab, source: source, root: nil, groups: prefs.view(kind).arrange(list(kind)))
        case .entry(let id):
            let root = entry(id)
            let rows = OverviewScope.contents(of: id, in: all)
            return OverviewFeed(tab: tab, source: source, root: root, groups: rows.isEmpty ? [] : prefs.entryView(id).arrange(rows))
        case nil:
            return OverviewFeed(tab: tab, source: nil, root: nil, groups: [])
        }
    }

    func tabTitle(_ tab: OverviewTab) -> String {
        switch tab.id {
        case OverviewTab.markedId: return L.s("tab_marked")
        case OverviewTab.listsId: return L.s("overview_tab_list")
        default: return tab.namedBySource ? overviewSource(tab).map(sourceTitle) ?? "" : tab.name
        }
    }

    func tabIcon(_ tab: OverviewTab) -> String { overviewSource(tab).map(sourceIcon) ?? AppIcons.add }

    func sourceTitle(_ source: OverviewSource) -> String {
        switch source {
        case .list(let kind): return ListTitles.of(kind)
        case .entry(let id): return entry(id)?.title ?? ""
        }
    }

    func sourceIcon(_ source: OverviewSource) -> String {
        switch source {
        case .list(let kind): return ListTitles.icon(kind)
        case .entry(let id): return entry(id).map { TypeLook.of($0).icon.outlined } ?? AppIcons.link
        }
    }

    func sourceCount(_ source: OverviewSource) -> Int {
        switch source {
        case .list(let kind): return list(kind).filter(prefs.view(kind).shows).count
        case .entry(let id): return OverviewScope.contents(of: id, in: all).filter(prefs.entryView(id).shows).count
        }
    }
}

struct OverviewSectionToggle: View {
    let title: String
    let count: Int
    var icon: String?
    let collapsed: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 6) {
                Text(title).lineLimit(1)
                if collapsed, let icon { GlyphIcon(icon, size: 14, weight: .medium) }
                if collapsed, count > 0 { Text("\(count)").foregroundStyle(Palette.subtle) }
                Spacer(minLength: 0)
            }
            .font(Typo.dm(15, .medium))
            .foregroundStyle(Palette.muted)
            .frame(height: OverviewDimens.tabHeight)
            .padding(.leading, Dimens.titleEdge)
            .padding(.trailing, OverviewDimens.tabsEdge)
            .padding(.top, OverviewDimens.listTop)
            .padding(.bottom, OverviewDimens.listGap)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isHeader)
        .accessibilityValue(L.s(collapsed ? "view_group_collapsed" : "view_group_expanded"))
    }
}

struct OverviewSourcePill: View {
    let feed: OverviewFeed
    @Environment(AppModel.self) private var model
    @State private var switching = false

    var body: some View {
        if let source = feed.source {
            if feed.single {
                Text("\(feed.rows.count)")
                    .font(Typo.dm(14, .medium))
                    .foregroundStyle(Palette.muted)
                    .padding(.horizontal, 10)
                    .frame(minWidth: OverviewDimens.switchPillHeight, minHeight: OverviewDimens.switchPillHeight)
                    .background(Palette.tabActive, in: Capsule())
                    .accessibilityLabel(L.f("entries_count", feed.rows.count))
            } else {
                Button { switching = true } label: {
                    HStack(spacing: 6) {
                        Text(model.sourceTitle(source)).foregroundStyle(Palette.onSurface).lineLimit(1)
                        if !feed.rows.isEmpty { Text("\(feed.rows.count)").foregroundStyle(Palette.muted) }
                    }
                    .font(Typo.dm(14, .medium))
                    .padding(.horizontal, 10)
                    .frame(height: OverviewDimens.switchPillHeight)
                    .background(Palette.tabActive, in: Capsule())
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L.s("overview_switch"))
                .accessibilityValue(model.sourceTitle(source))
                .sheet(isPresented: $switching) {
                    OverviewSwitchSheet(tabs: [feed.tab.id]).presentationDetents([.medium, .large])
                }
            }
        }
    }
}

struct OverviewHeadRow: View {
    let feed: OverviewFeed
    let title: String
    let onTitle: () -> Void

    var body: some View {
        if feed.source != nil {
            HStack(spacing: 8) {
                Button(action: onTitle) {
                    Text(title).font(Typo.dm(15, .medium)).foregroundStyle(Palette.muted).lineLimit(1)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(.isHeader)
                OverviewSourcePill(feed: feed)
                Spacer(minLength: 12)
            }
            .frame(height: OverviewDimens.tabHeight)
            .padding(.leading, Dimens.titleEdge)
            .padding(.trailing, OverviewDimens.tabsEdge)
            .padding(.top, OverviewDimens.listTop)
            .padding(.bottom, OverviewDimens.listGap)
        }
    }
}

struct OverviewSortRow: View {
    let feed: OverviewFeed
    let onAdd: (() -> Void)?
    @Environment(AppModel.self) private var model

    var body: some View {
        if let source = feed.source {
            HStack(spacing: 6) {
                Text(L.s(ListPage.sortLabel(sort(source)))).font(Typo.titleMedium).foregroundStyle(Palette.onSurface)
                Spacer(minLength: 12)
                if let onAdd {
                    Button(action: onAdd) {
                        Image(systemName: AppIcons.add)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Palette.onSurfaceVariant)
                            .frame(width: OverviewDimens.viewButton, height: OverviewDimens.viewButton)
                            .background(Palette.tabActive, in: Circle())
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L.s("overview_add_here"))
                }
            }
            .frame(height: OverviewDimens.viewButton)
            .padding(.leading, Dimens.titleEdge)
            .padding(.trailing, OverviewDimens.tabsEdge)
            .padding(.bottom, OverviewDimens.headBottom)
        }
    }

    private func sort(_ source: OverviewSource) -> ParalistCore.SortOrder {
        switch source {
        case .list(let kind): return model.prefs.view(kind).sort
        case .entry(let id): return model.prefs.entryView(id).sort
        }
    }
}

struct OverviewPickRow: View {
    let icon: String
    let tint: Color
    let title: String
    var subtitle: String?
    var count = 0
    let chosen: Bool

    var body: some View {
        HStack(spacing: 12) {
            GlyphIcon(icon, size: 20).foregroundStyle(tint)
                .frame(width: OverviewDimens.pickerIcon)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Typo.bodyLarge).foregroundStyle(Palette.onSurface).lineLimit(1)
                if let subtitle { Text(subtitle).font(Typo.bodyMedium).foregroundStyle(Palette.muted) }
            }
            Spacer(minLength: 0)
            if count > 0 { Text("\(count)").font(Typo.bodyMedium).foregroundStyle(Palette.muted) }
            if chosen {
                Image(systemName: AppIcons.check).font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.primary)
            }
        }
        .contentShape(Rectangle())
    }
}
