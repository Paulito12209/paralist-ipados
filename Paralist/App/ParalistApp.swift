// Zusammenhang: App/AppModel.swift, Shell/Router.swift, Shell/RootView.swift, Reminders/NotificationHandler.swift, App/LaunchOptions.swift, ParalistCore Links/IncomingLink.swift, Paralist.entitlements, ParalistWidgets/EntryWidget.swift, Intents/ParalistShortcuts.swift
import AppIntents
import ParalistCore
import SwiftUI
import UserNotifications
import WidgetKit

@main
struct ParalistApp: App {
    @State private var model: AppModel
    @State private var router: Router
    @Environment(\.scenePhase) private var phase

    init() {
        let model = AppModel()
        let router = Router()
        router.shows = { model.prefs.tabOrder.shows($0.key) }
        router.tab = model.prefs.tabOrder.tabs.first.flatMap(AppTab.init(rawValue:)) ?? .overview
        _model = State(initialValue: model)
        _router = State(initialValue: router)
        AppDependencyManager.shared.add(dependency: model)
        AppDependencyManager.shared.add(dependency: router)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(router)
                .preferredColorScheme(LaunchOptions.scheme ?? model.prefs.themeMode.scheme)
                .environment(\.locale, L.locale)
                .id(model.prefs.language)
                .tint(Palette.primary)
                .scrollIndicators(.hidden)
                .onAppear {
                    NotificationHandler.shared.model = model
                    NotificationHandler.shared.router = router
                    UNUserNotificationCenter.current().delegate = NotificationHandler.shared
                    LaunchOptions.apply(router, model)
                    Task { await UpdateChecker.run(model) }
                    ParalistShortcuts.updateAppShortcutParameters()
                }
                .onOpenURL { url in IncomingLinks.handle(url, router: router, model: model) }
                .onChange(of: phase) { _, now in
                    if now == .active { model.reload() }
                    if now == .background {
                        WidgetCenter.shared.reloadAllTimelines()
                        ParalistShortcuts.updateAppShortcutParameters()
                    }
                }
        }
    }
}

enum IncomingLinks {
    @MainActor
    static func handle(_ url: URL, router: Router, model: AppModel) {
        if url.isFileURL {
            if url.pathExtension.lowercased() == BackupFormat.fileExtension || url.pathExtension.lowercased() == "zip" {
                router.backup = BackupFile(url: url)
            }
            return
        }
        switch IncomingLink.parse(url) {
        case .entry(let id):
            router.open(.entry(id))
        case .briefing:
            router.openBriefing()
        case .share(let text, let title):
            let shared = SharedText.parse(text, subject: title)
            router.compose(ComposerRequest(type: shared.url != nil ? .bookmark : .note, url: shared.url, title: shared.title))
        case nil:
            break
        }
    }
}
