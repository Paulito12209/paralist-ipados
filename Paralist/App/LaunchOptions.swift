// Zusammenhang: App/ParalistApp.swift, App/DemoSeed.swift, Shell/SplitRootView.swift (SplitMetrics), docs/ipad.md, .github/workflows/ios.yml (Screenshots)
import ParalistCore
import SwiftUI
import UIKit

enum LaunchOptions {
    private static var args: [String] { ProcessInfo.processInfo.arguments }

    private static func value(_ key: String) -> String? {
        guard let i = args.firstIndex(of: key), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    static var scheme: ColorScheme? {
        switch value("-appearance") {
        case "dark": return .dark
        case "light": return .light
        default: return nil
        }
    }

    static var mascotTopics: Set<MascotTopic>? {
        guard AppPaths.isDemo, let list = value("-mascot") else { return nil }
        let names: [String: MascotTopic] = ["flashcards": .flashcards, "project": .project, "tasks": .tasks]
        return Set(list.split(separator: ",").compactMap { names[String($0)] })
    }

    static var chatText: String? { AppPaths.isDemo ? value("-text") : nil }

    @MainActor
    static func apply(_ router: Router, _ model: AppModel) {
        guard AppPaths.isDemo else { return }
        guard let orientation = value("-orientation") else {
            router.split = SplitMetrics.list(for: SplitMetrics.sceneWidth) != nil
            show(router, model)
            return
        }
        rotate(orientation)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            show(router, model)
        }
    }

    @MainActor
    private static func rotate(_ name: String) {
        let mask: UIInterfaceOrientationMask = name == "landscape" ? .landscape : .portrait
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        scene?.requestGeometryUpdate(.iOS(interfaceOrientations: mask)) { _ in }
    }

    @MainActor
    private static func show(_ router: Router, _ model: AppModel) {
        guard let screen = value("-screen") else { return }
        var layout = OverviewLayout.standard()
        if screen == "overviewstacked" {
            layout.addTab(id: "demo-tab-umzug", name: "Umzug")
            layout.toggle(.entry("demo-project-0001"), in: "demo-tab-umzug")
            layout.toggle(.list(.tasks), in: "demo-tab-umzug")
            layout.addTab(id: "demo-tab-finanzen", source: .entry("demo-area-00000002"))
            layout.addTab(id: "demo-tab-eingang", source: .list(.inbox))
            layout.setHidden(OverviewTab.markedId, false)
        }
        model.prefs.overviewLayout = layout
        model.prefs.overviewHintSeen = screen != "overview"
        switch screen {
        case "calendar": router.select(.calendar)
        case "tasks": router.select(.tasks)
        case "menu": router.menuOpen = true
        case "create": router.openCreate()
        case "search": router.searchOpen = true
        case "split":
            router.select(.overview)
            router.open(.entry(DemoSeed.videoId))
        case "entry": router.open(.entry(DemoSeed.videoId))
        case "task": router.open(.entry(DemoSeed.taskId))
        case "photo": router.open(.entry(DemoSeed.photoId))
        case "deck": router.open(.entry("demo-deck-00000001"))
        case "bookmark": router.compose(ComposerRequest(type: .bookmark, url: "https://youtu.be/dQw4w9WgXcQ", title: "Never Gonna Give You Up"))
        case "progress": router.open(.progress)
        case "briefing": router.openBriefing()
        case "flashcards": router.open(.flashcards)
        case "settings": router.open(.settings)
        case "feedback":
            router.open(.settings)
            router.open(.feedback)
        case "chats": router.open(.chats)
        case "chat":
            router.open(.chats)
            router.open(.chat(DemoSeed.chatId))
        case "chatnew":
            router.open(.chats)
            router.open(.chat(model.chats.newId()))
        case "chatplan":
            router.open(.chats)
            router.open(.chat(DemoSeed.planChatId))
        case "chatwait":
            router.open(.chats)
            router.open(.chat(DemoSeed.chatId))
            model.chats.demoWaiting(DemoSeed.chatId)
        case "chatfail":
            router.open(.chats)
            router.open(.chat(DemoSeed.chatId))
            model.chats.demoFailed(DemoSeed.chatId)
        default: router.select(.overview)
        }
    }
}
