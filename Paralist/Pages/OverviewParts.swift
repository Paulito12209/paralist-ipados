// Zusammenhang: Pages/OverviewPage.swift, Pages/OverviewSections.swift (OverviewFeed), Pages/OverviewTabLabel.swift (OverviewTabLabel, overviewSwitcher), Pages/ListPage.swift (GroupLabel), Theme/Dimens.swift (OverviewDimens)
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
    @State private var switching = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: OverviewDimens.tabGap) {
                    ForEach(tabs) { item in slot(item).id(item.id) }
                }
                .padding(.leading, Dimens.titleEdge)
                .padding(.trailing, OverviewDimens.tabsEdge)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .onAppear { proxy.scrollTo(tab) }
            .onChange(of: tab) { withAnimation(Motion.short) { proxy.scrollTo(tab) } }
        }
        .frame(height: OverviewDimens.tabHeight)
        .padding(.top, OverviewDimens.listTop - OverviewDimens.tilesToList)
        .padding(.bottom, OverviewDimens.listGap)
        .overviewSwitcher($switching, tabs: [tab])
    }

    private func slot(_ item: OverviewTab) -> some View {
        let active = tab == item.id
        let highlight = tabs.count > 1
        let count = active ? feed.rows.count : model.overviewFeed(item).rows.count
        return Button {
            if active {
                switching = true
            } else {
                withAnimation(Motion.short) { tab = item.id }
            }
        } label: {
            OverviewTabLabel(title: model.tabTitle(item), icon: model.tabIcon(item), count: count,
                             tone: !highlight ? .plain : active ? .active : .idle)
                .overlay(alignment: .bottom) {
                    if highlight, active {
                        Circle().fill(Palette.level)
                            .frame(width: OverviewDimens.tabDot, height: OverviewDimens.tabDot)
                            .offset(y: OverviewDimens.tabDot + OverviewDimens.tabDotGap)
                            .matchedGeometryEffect(id: "dot", in: selection)
                    }
                }
                .frame(height: OverviewDimens.tabHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? .isSelected : [])
        .accessibilityHint(active ? L.s("overview_switch") : "")
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
    @State private var headTop: CGFloat = 0

    private var pinned: Bool { headBottom - bodyTop > 1 && headTop < OverviewDimens.pinnedReach }

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
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .scrollView) } action: {
                    headBottom = $0.maxY
                    headTop = $0.minY
                }
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
