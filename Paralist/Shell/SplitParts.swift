// Zusammenhang: Shell/SplitRootView.swift, Shell/SplitTopBar.swift, Shell/DetailHost.swift (DetailRootClose), Shell/Router.swift (closeDetail, detailPath), Icons/AppIcons.swift (canvasBack), Theme/SplitDimens.swift, Theme/Palette.swift (padTabActive), docs/ipad.md
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

    func body(content: Content) -> some View {
        content.toolbar {
            if inline, router.detailPath.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    Button { router.closeDetail() } label: { Image(systemName: AppIcons.canvasBack) }
                        .accessibilityLabel(L.s("create_close"))
                }
            }
        }
    }
}
