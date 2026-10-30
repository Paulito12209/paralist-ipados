// Zusammenhang: Shell/SplitRootView.swift, Shell/DetailHost.swift (DetailRootClose), Shell/Router.swift (closeDetail, detailPath), Icons/AppIcons.swift (splitEmpty, canvasBack), docs/ipad.md
import SwiftUI

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
        .background(Palette.surfaceContainer.ignoresSafeArea())
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
