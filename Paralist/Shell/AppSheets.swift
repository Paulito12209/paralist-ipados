// Zusammenhang: Shell/Router.swift, Shell/CreateOverlay.swift, Capture/CameraPicker.swift, Capture/AudioRecorderSheet.swift, Composer/ComposerSheet.swift, Account/AccountSheet.swift, Search/SearchView.swift, Flashcards/ImportCardsSheet.swift, Shell/DetailHost.swift, Entry/LinkSheet.swift, Pages/OverviewPage.swift (EntryQuickMenu), Pages/BriefingPage.swift, Shell/SplitRootView.swift (detailCovers)
import ParalistCore
import SwiftUI
import UniformTypeIdentifiers

struct AppSheets: ViewModifier {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    func body(content: Content) -> some View {
        @Bindable var router = router
        content
            .createSheets(nested: false)
            .fullScreenCover(isPresented: Binding(get: { router.detailCovers }, set: { if !$0, !router.split { router.closeDetail() } })) {
                DetailHost()
            }
            .sheet(isPresented: $router.accountOpen) {
                AccountSheet()
                    .presentationDetents([.medium, .large])
                    .presentationCornerRadius(Dimens.sheetRadius)
            }
            .sheet(isPresented: $router.briefingOpen) {
                BriefingPage()
                    .presentationDetents([.height(BriefingDimens.sheetStart), .large])
                    .presentationContentInteraction(.resizes)
                    .presentationDragIndicator(.hidden)
                    .presentationCornerRadius(Dimens.sheetRadius)
            }
            .importCardsSheet(inDetail: false)
            .sheet(item: $router.backup) { file in
                BackupImportSheet(url: file.url)
                    .presentationDetents([.medium, .large])
                    .presentationCornerRadius(Dimens.sheetRadius)
                    .interactiveDismissDisabled()
            }
            .sheet(item: $router.linking) { request in
                if let entry = model.entry(request.id) {
                    LinkSheet(entry: entry).presentationCornerRadius(Dimens.sheetRadius)
                }
            }
            .sheet(item: $router.placing) { request in
                if let entry = model.entry(request.id) {
                    EntryPlaceSheet(entry: entry).presentationCornerRadius(Dimens.sheetRadius)
                }
            }
            .overlay {
                if router.searchOpen {
                    SearchView().transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.2), value: router.searchOpen)
    }
}

struct CreateSheets: ViewModifier {
    let nested: Bool
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    func body(content: Content) -> some View {
        let active = router.detailCovers == nested
        let importing = active && router.importing
        let camera = active ? router.camera : nil
        let recording = active && router.recording
        let composer = active ? router.composer : nil
        return content
            .fileImporter(isPresented: Binding(get: { importing }, set: { router.importing = $0 }), allowedContentTypes: [.image, .pdf, .audio, .movie, .plainText]) { result in
                if case .success(let url) = result {
                    CaptureFlow.save(AttachmentImporter.importFile(at: url, into: model.library.store), kind: .files, link: router.createLink, model: model)
                }
            }
            .fullScreenCover(item: Binding(get: { camera }, set: { router.camera = $0 })) { kind in
                CameraPicker(kind: kind).ignoresSafeArea()
            }
            .sheet(isPresented: Binding(get: { recording }, set: { router.recording = $0 })) {
                AudioRecorderSheet()
                    .presentationDetents([.height(300)])
                    .presentationCornerRadius(Dimens.sheetRadius)
                    .interactiveDismissDisabled()
            }
            .overlay {
                if let composer {
                    ComposerSheet(request: composer).id(composer.id).transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.2), value: composer?.id)
    }
}

extension View {
    func appSheets() -> some View { modifier(AppSheets()) }
    func createSheets(nested: Bool) -> some View { modifier(CreateSheets(nested: nested)) }
    func importCardsSheet(inDetail: Bool) -> some View { modifier(ImportCardsPresenter(inDetail: inDetail)) }
}

struct ImportCardsPresenter: ViewModifier {
    let inDetail: Bool
    @Environment(Router.self) private var router

    func body(content: Content) -> some View {
        content.sheet(item: Binding(get: { router.detailCovers == inDetail ? router.importCards : nil }, set: { router.importCards = $0 })) { request in
            ImportCardsSheet(deck: request.deck)
                .presentationDetents([.large])
                .presentationCornerRadius(Dimens.sheetRadius)
        }
    }
}
