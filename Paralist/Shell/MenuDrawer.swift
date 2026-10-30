// Zusammenhang: Shell/RootView.swift, Shell/Router.swift (menuOpen), Pages/MenuPage.swift, Theme/Dimens.swift (MenuDimens, Motion.drawer)
import SwiftUI

struct MenuDrawer: ViewModifier {
    @Environment(Router.self) private var router
    @Environment(\.colorScheme) private var scheme
    @State private var drag: CGFloat = 0

    func body(content: Content) -> some View {
        GeometryReader { geo in
            let width = geo.size.width - MenuDimens.peek
            let shift = router.menuOpen ? max(0, width - drag) : 0
            ZStack(alignment: .trailing) {
                MenuPage(lead: MenuDimens.peek, drag: $drag, release: release)
                    .safeAreaPadding(geo.safeAreaInsets)
                    .frame(width: geo.size.width)
                    .offset(x: (1 - shift / width) * geo.size.width)
                    .accessibilityHidden(!router.menuOpen)
                content
                    .safeAreaPadding(geo.safeAreaInsets)
                    .overlay {
                        Color.black
                            .opacity(router.menuOpen ? dim : 0)
                            .opacity(1 - drag / width)
                            .animation(router.menuOpen ? Motion.drawerDim : Motion.short, value: router.menuOpen)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: router.menuOpen ? MenuDimens.contentRadius : 0, style: .continuous))
                    .shadow(color: .black.opacity(router.menuOpen ? 0.3 : 0), radius: MenuDimens.shadow)
                    .overlay {
                        if router.menuOpen {
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture { router.closeMenu() }
                                .gesture(closeDrag)
                                .accessibilityHidden(true)
                        }
                    }
                    .offset(x: -shift)
            }
            .ignoresSafeArea()
            .background(Palette.surfaceHigh.ignoresSafeArea())
            .onChange(of: router.menuOpen) { _, open in if open { drag = 0 } }
        }
    }

    private var dim: Double {
        scheme == .dark ? MenuDimens.dimDark : MenuDimens.dimLight
    }

    private var closeDrag: some Gesture {
        DragGesture(minimumDistance: MenuDimens.dragStart, coordinateSpace: .global)
            .onChanged { value in drag = max(0, value.translation.width) }
            .onEnded { value in release(value.predictedEndTranslation.width) }
    }

    private func release(_ predicted: CGFloat) {
        if drag > MenuDimens.closeDrag || predicted > MenuDimens.closeFling {
            router.closeMenu()
        } else {
            withAnimation(Motion.drawer) { drag = 0 }
        }
    }
}

extension View {
    func menuDrawer() -> some View { modifier(MenuDrawer()) }
}
