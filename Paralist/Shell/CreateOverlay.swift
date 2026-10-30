// Zusammenhang: Shell/RootView.swift, Shell/DetailHost.swift, Shell/AppSheets.swift (CreateSheets), Shell/Router.swift, Composer/CreatePanel.swift, Capture/CaptureFlow.swift, Theme/Dimens.swift, Theme/SplitDimens.swift, Shell/SplitRootView.swift
import ParalistCore
import SwiftUI

struct CreateOverlay: View {
    var nested = false
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @Environment(\.colorScheme) private var scheme
    @State private var drag: CGFloat = 0

    var body: some View {
        if router.createOpen, router.detailCovers == nested {
            ZStack(alignment: .bottom) {
                Color.black.opacity(scheme == .dark ? CreateDimens.dimDark : CreateDimens.dimLight)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { router.closeCreate() }
                    .transition(.opacity)
                    .accessibilityHidden(true)
                CreatePanel(
                    onCapture: { kind in CaptureFlow.start(kind, router: router, model: model) },
                    onPick: { type in router.compose(ComposerRequest(type: type, link: router.createLink)) }
                )
                .frame(maxWidth: router.split ? SplitDimens.createWidth : .infinity)
                .padding(.horizontal, CreateDimens.panelEdge)
                .padding(.top, CreateDimens.panelTop)
                .padding(.bottom, CreateDimens.panelBottom)
                .offset(y: drag)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 12)
                        .onChanged { value in
                            if value.translation.height > 0, value.translation.height > abs(value.translation.width) { drag = value.translation.height }
                        }
                        .onEnded { value in
                            if drag > CreateDimens.closeDrag || value.predictedEndTranslation.height > 300 {
                                router.closeCreate()
                            } else {
                                withAnimation(Motion.create) { drag = 0 }
                            }
                        }
                )
                .transition(.move(edge: .bottom))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea()
            .onAppear { drag = 0 }
        }
    }
}
