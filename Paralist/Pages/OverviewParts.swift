// Zusammenhang: Pages/OverviewPage.swift, Pages/OverviewSections.swift (OverviewFeed, OverviewHeadRow), Pages/ListPage.swift (GroupLabel), Theme/Dimens.swift (OverviewDimens)
import ParalistCore
import SwiftUI

struct TileGrid: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    var body: some View {
        let columns = [GridItem(.flexible(), spacing: OverviewDimens.tileGap), GridItem(.flexible(), spacing: OverviewDimens.tileGap)]
        LazyVGrid(columns: columns, spacing: OverviewDimens.tileGap) {
            ForEach(ListKind.tiles) { kind in
                Button { router.open(.list(kind)) } label: { tile(kind) }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, OverviewDimens.tileEdge)
    }

    private func tile(_ kind: ListKind) -> some View {
        let count = model.count(kind)
        return VStack(alignment: .leading, spacing: OverviewDimens.tileIconGap) {
            Spacer(minLength: 0)
            tileIcon(kind).foregroundStyle(tint(kind))
            HStack(alignment: .lastTextBaseline, spacing: OverviewDimens.tileCountGap) {
                Text(ListTitles.of(kind)).foregroundStyle(Palette.onSurface).lineLimit(1)
                if count > 0 { Text("\(count)").foregroundStyle(Palette.muted) }
            }
            .font(Typo.dm(17))
        }
        .padding(OverviewDimens.tilePadding)
        .frame(maxWidth: .infinity, minHeight: OverviewDimens.tileHeight, alignment: .leading)
        .background(Palette.tile, in: RoundedRectangle(cornerRadius: OverviewDimens.tileRadius))
        .contentShape(RoundedRectangle(cornerRadius: OverviewDimens.tileRadius))
    }

    @ViewBuilder
    private func tileIcon(_ kind: ListKind) -> some View {
        switch kind {
        case .projects: Image("XoolRocket").renderingMode(.template).resizable().scaledToFit().frame(width: 24, height: 24)
        case .resources: Image("XoolCube").renderingMode(.template).resizable().scaledToFit().frame(width: 24, height: 24)
        default: Image(systemName: ListTitles.icon(kind)).font(.system(size: 22))
        }
    }

    private func tint(_ kind: ListKind) -> Color {
        switch kind {
        case .projects: return TypeLook.of(.project).color
        case .areas: return TypeLook.of(.area).color
        case .resources: return TypeLook.of(.file).color
        default: return Palette.onSurfaceVariant
        }
    }
}

struct OverviewTabs: View {
    let tabs: [OverviewTab]
    @Binding var tab: String
    let feed: OverviewFeed
    @Environment(AppModel.self) private var model
    @Namespace private var selection

    var body: some View {
        Group {
            if tabs.count == 1, let only = tabs.first {
                HStack(spacing: 8) {
                    Text(model.tabTitle(only))
                        .font(Typo.dm(15, .medium))
                        .foregroundStyle(Palette.muted)
                        .lineLimit(1)
                        .accessibilityAddTraits(.isHeader)
                    OverviewSourcePill(feed: feed)
                }
                .frame(maxWidth: .infinity)
            } else if tabs.count >= OverviewDimens.tabsLeading {
                scrolling
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 0) { slots(fill: true) }
                    scrolling
                }
            }
        }
        .frame(height: OverviewDimens.tabHeight)
        .padding(.horizontal, OverviewDimens.tabsEdge)
        .padding(.top, OverviewDimens.listTop - OverviewDimens.tilesToList)
        .padding(.bottom, OverviewDimens.listGap)
    }

    private var scrolling: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 0) { slots(fill: false) }
            }
            .scrollIndicators(.hidden)
            .onAppear { proxy.scrollTo(tab, anchor: .center) }
            .onChange(of: tab) { withAnimation(Motion.short) { proxy.scrollTo(tab, anchor: .center) } }
        }
    }

    private func slots(fill: Bool) -> some View {
        ForEach(tabs) { item in
            slot(item, fill: fill).id(item.id)
        }
    }

    private func slot(_ item: OverviewTab, fill: Bool) -> some View {
        let active = tab == item.id
        return HStack(spacing: 8) {
            Button {
                withAnimation(Motion.short) { tab = item.id }
            } label: {
                HStack(spacing: 6) {
                    CappedWidth(limit: fill ? .infinity : OverviewDimens.tabMaxWidth) {
                        Text(model.tabTitle(item)).font(Typo.dm(16, .medium)).lineLimit(1)
                    }
                    if !active { GlyphIcon(model.tabIcon(item), size: 14, weight: .medium) }
                }
                .foregroundStyle(active ? Palette.level : Palette.subtle)
                .overlay(alignment: .bottom) {
                    if active {
                        Circle().fill(Palette.level)
                            .frame(width: OverviewDimens.tabDot, height: OverviewDimens.tabDot)
                            .offset(y: OverviewDimens.tabDot + OverviewDimens.tabDotGap)
                            .matchedGeometryEffect(id: "dot", in: selection)
                    }
                }
                .padding(.horizontal, active ? 0 : 14)
                .frame(maxWidth: fill && !active ? .infinity : nil)
                .frame(height: OverviewDimens.tabHeight)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(active ? .isSelected : [])
            if active { OverviewSourcePill(feed: feed) }
        }
        .padding(.horizontal, active ? 14 : 0)
        .frame(maxWidth: fill ? .infinity : nil)
    }
}

struct CappedWidth: Layout {
    let limit: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let first = subviews.first else { return .zero }
        return first.sizeThatFits(ProposedViewSize(width: min(proposal.width ?? limit, limit), height: proposal.height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, proposal: ProposedViewSize(bounds.size))
    }
}

struct OverviewHeader: View {
    let tabs: [OverviewTab]
    @Binding var tab: String
    let feed: OverviewFeed
    let onAdd: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            OverviewTabs(tabs: tabs, tab: $tab, feed: feed)
            OverviewSortRow(feed: feed, onAdd: onAdd)
        }
        .padding(.horizontal, OverviewDimens.panelEdge)
    }
}

struct PinnedSection<Head: View, Content: View>: View {
    var tail = OverviewDimens.headTail
    @ViewBuilder let head: () -> Head
    @ViewBuilder let content: () -> Content
    @State private var headBottom: CGFloat = 0
    @State private var bodyTop: CGFloat = 0

    private var pinned: Bool { headBottom - bodyTop > 1 }

    var body: some View {
        Section {
            Color.clear.frame(height: 0)
                .onGeometryChange(for: CGFloat.self) { $0.frame(in: .scrollView).minY } action: { bodyTop = $0 }
            content()
        } header: {
            head()
                .background {
                    Palette.background
                        .padding(.top, pinned ? -OverviewDimens.pinnedCover : 0)
                        .padding(.bottom, pinned ? tail : 0)
                }
                .overlay(alignment: .bottom) {
                    if pinned {
                        LinearGradient(colors: [Palette.background, Palette.background.opacity(0)], startPoint: .top, endPoint: .bottom)
                            .frame(height: OverviewDimens.pinnedFade)
                            .offset(y: OverviewDimens.pinnedFade - tail)
                            .allowsHitTesting(false)
                            .transition(.opacity)
                    }
                }
                .animation(Motion.short, value: pinned)
                .onGeometryChange(for: CGFloat.self) { $0.frame(in: .scrollView).maxY } action: { headBottom = $0 }
        }
    }
}

struct PanelCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, OverviewDimens.panelEdge)
            .padding(.top, OverviewDimens.rowGap)
    }
}

struct GroupLabel: View {
    let kind: ListKind
    let type: EntryType
    let count: Int
    var scope: String?
    @Environment(AppModel.self) private var model

    var body: some View {
        let key = "\(scope ?? kind.key)/\(type.key)"
        let collapsed = model.prefs.isCollapsed(key: key)
        Button {
            withAnimation(Motion.short) { model.prefs.toggleCollapsed(key: key) }
        } label: {
            HStack(spacing: 6) {
                Text(L.s(TypeLook.of(type).label))
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

struct FillZone: View {
    let empty: Bool
    let feed: OverviewFeed
    let height: CGFloat
    let action: (() -> Void)?

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear.frame(height: height)
                .contentShape(Rectangle())
                .onTapGesture { action?() }
            if empty {
                EmptyInfoButton(info: feed.emptyInfo(canAdd: action != nil))
                    .padding(.top, OverviewDimens.infoTop)
            }
        }
        .frame(maxWidth: .infinity, minHeight: OverviewDimens.zoneMinHeight)
                .padding(.horizontal, OverviewDimens.panelEdge)
        .padding(.top, OverviewDimens.rowGap)
    }
}
