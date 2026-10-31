// Zusammenhang: Shell/SplitRootView.swift, Shell/SplitTopBar.swift, Shell/DetailHost.swift (DetailRootClose), Shell/Router.swift (closeDetail, detailPath), Shell/RouterSplit.swift (closePane, toggleExpanded, stack), Entry/EntryToolbar.swift (SplitExpandButton), Icons/AppIcons.swift (canvasBack, paneExpand, paneCollapse), Theme/SplitDimens.swift, Theme/Palette.swift (padTabActive), docs/ipad.md
import SwiftUI

struct SplitCircle<Label: View>: View {
    let title: String
    var active = false
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button(action: action) {
            label()
                .foregroundStyle(Palette.onSurface)
                .frame(width: SplitDimens.button, height: SplitDimens.button)
                .background { if active { Circle().fill(Palette.padTabActive) } }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Circle())
        .accessibilityLabel(title)
        .accessibilityAddTraits(active ? .isSelected : [])
    }
}

struct SplitGlyph: View {
    let asset: String
    var tint: Color = Palette.onSurface

    var body: some View {
        Image(asset).renderingMode(.template).resizable().scaledToFit()
            .frame(width: TabBarDimens.assetIcon, height: TabBarDimens.assetIcon)
            .foregroundStyle(tint)
    }
}

struct DetailRootClose: ViewModifier {
    let inline: Bool
    @Environment(Router.self) private var router
    @Environment(\.detailPane) private var pane

    func body(content: Content) -> some View {
        content.toolbar {
            if inline, router.stack(pane).isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    Button { router.closePane(pane) } label: { Image(systemName: AppIcons.canvasBack) }
                        .accessibilityLabel(L.s("create_close"))
                }
                if SplitExpandButton.shown(router, pane) {
                    ToolbarItem(placement: .topBarLeading) { SplitExpandButton() }
                }
            }
        }
    }
}

struct SplitExpandButton: View {
    @Environment(Router.self) private var router

    static func shown(_ router: Router, _ pane: DetailPane) -> Bool {
        router.split && pane == .primary && router.linked == nil
    }

    var body: some View {
        Button { router.toggleExpanded() } label: {
            Image(systemName: router.expanded ? AppIcons.paneCollapse : AppIcons.paneExpand).foregroundStyle(Palette.onSurface)
        }
        .accessibilityLabel(L.s(router.expanded ? "ipad_collapse" : "ipad_expand"))
    }
}

struct SplitHandle: View {
    let onDrag: (CGFloat) -> Void
    let onEnd: () -> Void

    var body: some View {
        Capsule()
            .fill(Palette.onSurfaceVariant.opacity(0.45))
            .frame(width: SplitDimens.handleWidth, height: SplitDimens.handleHeight)
            .frame(width: SplitDimens.gap)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle().inset(by: -SplitDimens.handleReach))
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onChanged { onDrag($0.translation.width) }
                    .onEnded { _ in onEnd() }
            )
            .accessibilityLabel(L.s("ipad_resize"))
    }
}
