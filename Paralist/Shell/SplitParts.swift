// Zusammenhang: Shell/SplitRootView.swift, Shell/SplitTopBar.swift, Shell/SplitPanes.swift, Shell/DetailHost.swift (DetailRootClose, secondPane), Shell/RouterSplit.swift (closeSecond, toggleWide), Entry/EntryToolbar.swift (WideToggle), Icons/AppIcons.swift (splitEmpty, canvasBack, sidebarLeft), Theme/SplitDimens.swift, docs/ipad.md
import SwiftUI

extension EnvironmentValues {
    @Entry var secondPane = false
}

struct SplitPlaceholder: View {
    var body: some View {
        VStack(spacing: SplitDimens.emptyGap) {
            GlyphIcon(AppIcons.splitEmpty, size: EmptyDimens.glyph)
                .foregroundStyle(Palette.onSecondaryContainer)
                .frame(width: EmptyDimens.emblem, height: EmptyDimens.emblem)
                .background(Palette.secondaryContainer, in: Circle())
                .grayscale(1)
                .opacity(EmptyDimens.fade)
                .accessibilityHidden(true)
            Text(L.s("ipad_detail_empty"))
                .font(Typo.bodyLarge)
                .foregroundStyle(Palette.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surfaceContainer)
    }
}

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
                .background { if active { Circle().fill(Palette.tabActive) } }
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

struct WideToggle: View {
    @Environment(Router.self) private var router

    var body: some View {
        Button { router.toggleWide() } label: { Image(systemName: AppIcons.sidebarLeft).foregroundStyle(Palette.onSurface) }
            .accessibilityLabel(L.s(router.detailWide ? "ipad_detail_narrow" : "ipad_detail_wide"))
    }
}

struct DetailRootClose: ViewModifier {
    let inline: Bool
    @Environment(Router.self) private var router
    @Environment(\.secondPane) private var secondPane

    func body(content: Content) -> some View {
        content.toolbar {
            if inline, router.detailPath.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    Button { if secondPane { router.closeSecond() } else { router.closeDetail() } } label: {
                        Image(systemName: secondPane ? AppIcons.close : AppIcons.canvasBack)
                    }
                    .accessibilityLabel(L.s("create_close"))
                }
                if !secondPane, router.second == nil {
                    ToolbarItem(placement: .topBarLeading) { WideToggle() }
                }
            }
        }
    }
}
