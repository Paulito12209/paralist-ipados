// Zusammenhang: Pages/SettingsPage.swift, Pages/TrashPage.swift, Pages/ProgressPage.swift, Shell/SplitRootView.swift (SplitCategories, rechter Stapel), Shell/CategoryPanel.swift, Theme/CategoryDimens.swift
import SwiftUI

struct PaneTitle: ViewModifier {
    let key: String
    @Environment(Router.self) private var router

    func body(content: Content) -> some View {
        if router.split {
            content
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .safeAreaInset(edge: .top, spacing: 0) {
                    Text(L.s(key))
                        .font(Typo.headlineLarge)
                        .foregroundStyle(Palette.onSurface)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, CategoryDimens.padding)
                        .padding(.top, CategoryDimens.titleBottom)
                        .padding(.bottom, CategoryDimens.titleBottom)
                        .accessibilityAddTraits(.isHeader)
                }
        } else {
            content
                .navigationTitle(L.s(key))
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

extension View {
    func paneTitle(_ key: String) -> some View { modifier(PaneTitle(key: key)) }
}
