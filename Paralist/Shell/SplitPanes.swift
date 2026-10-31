// Zusammenhang: Shell/SplitRootView.swift (SplitPane), Shell/DetailHost.swift (inline, second), Shell/SplitParts.swift (SplitCircle, SplitGlyph), Shell/Router.swift (detailEpoch, secondEpoch, paneShare), Shell/RouterSplit.swift (leaveRail, railShown), Shell/TabSlotMenu.swift (TabSlotLook), ParalistCore Library/SplitLayout.swift (panes, drag), Theme/SplitDimens.swift, docs/ipad.md
import ParalistCore
import SwiftUI

struct SplitRail: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    var body: some View {
        VStack(spacing: SplitDimens.railGap) {
            SplitCircle(title: L.s("menu_open"), action: router.openMenu) { SplitGlyph(asset: "XoolMenu") }
                .padding(.bottom, SplitDimens.railGap)
            ForEach(model.prefs.tabOrder.tabs.compactMap(AppTab.init(rawValue:)), id: \.self) { tab in
                let active = router.tab == tab
                SplitCircle(title: TabSlotLook.title(tab), active: active, action: { router.leaveRail(tab) }) {
                    Image(systemName: TabSlotLook.icon(tab).resolve(active)).font(.system(size: 17, weight: .medium))
                }
            }
            SplitCircle(title: L.s("search_submit"), action: { router.searchOpen = true }) {
                Image(systemName: AppIcons.search).font(.system(size: 17, weight: .medium))
            }
            Spacer(minLength: 0)
            SplitCircle(title: L.s("nav_create"), action: { router.openCreate() }) { SplitGlyph(asset: "XoolPlus", tint: Palette.level) }
        }
        .padding(.vertical, SplitDimens.fabInset)
        .frame(width: SplitDimens.rail)
        .splitPane()
    }
}

struct SplitPanes: View {
    let width: CGFloat
    @Environment(Router.self) private var router
    @State private var start: Double?

    var body: some View {
        let parts = SplitLayout.panes(total: Double(width), share: router.paneShare, minPane: Double(SplitDimens.minPane), divider: Double(SplitDimens.divider))
        let paired = router.second != nil
        HStack(spacing: 0) {
            DetailHost(inline: true).id(router.detailEpoch)
                .splitPane()
                .frame(width: paired ? CGFloat(parts.first) : width)
            if paired {
                handle
                DetailHost(inline: true, second: true).id(router.secondEpoch)
                    .splitPane()
                    .frame(width: CGFloat(parts.second))
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
    }

    private var handle: some View {
        Capsule()
            .fill(Palette.outlineVariant)
            .frame(width: SplitDimens.handle, height: SplitDimens.handleHeight)
            .frame(width: SplitDimens.divider)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        let from = start ?? router.paneShare
                        start = from
                        router.paneShare = SplitLayout.drag(from: from, by: Double(value.translation.width), total: Double(width),
                                                            minPane: Double(SplitDimens.minPane), divider: Double(SplitDimens.divider))
                    }
                    .onEnded { _ in start = nil }
            )
            .accessibilityElement()
            .accessibilityLabel(L.s("ipad_pane_divider"))
            .accessibilityValue("\(Int((router.paneShare * 100).rounded())) %")
            .accessibilityAdjustableAction { direction in
                let step = direction == .increment ? 0.05 : -0.05
                router.paneShare = SplitLayout.drag(from: router.paneShare, by: step * Double(width - SplitDimens.divider), total: Double(width),
                                                    minPane: Double(SplitDimens.minPane), divider: Double(SplitDimens.divider))
            }
    }
}
