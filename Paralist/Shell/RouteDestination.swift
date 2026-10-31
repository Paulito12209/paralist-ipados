// Zusammenhang: Shell/Router.swift, Pages/*, Entry/EntryPage.swift, Flashcards/StudyPage.swift, Chat/ChatListPage.swift, Chat/ChatThreadPage.swift, Pages/TrashPage.swift, Flashcards/StudyPage.swift
import ParalistCore
import SwiftUI

struct RouteDestinations: ViewModifier {
    func body(content: Content) -> some View {
        content.navigationDestination(for: Route.self) { route in
            destination(route)
                .hidesPhoneTabBar()
                .background { (route.isDetail ? Palette.surface : Palette.background).ignoresSafeArea() }
        }
    }

    @ViewBuilder
    private func destination(_ route: Route) -> some View {
        switch route {
        case .entry(let id): EntryDestination(id: id, nested: true)
        case .cover(let id): EntryDestination(id: id, cover: true, nested: true)
        case .list(let kind): ListPage(kind: kind)
        case .overview: OverviewPage()
        case .calendar: CalendarPage()
        case .tasks: TasksPage()
        case .study(let deck): StudyPage(deck: deck)
        case .progress: ProgressPage()
        case .settings: SettingsPage()
        case .trash: TrashPage()
        case .tabArrange: TabArrangePage()
        case .feedback: FeedbackPage()
        case .media: MediaPage()
        case .flashcards: FlashcardsPage()
        case .chats: ChatListPage()
        case .chat(let id): ChatThreadPage(id: id)
        }
    }
}

private extension Route {
    var isDetail: Bool {
        switch self {
        case .entry, .cover, .study, .chat: return true
        default: return false
        }
    }
}

struct HidesPhoneTabBar: ViewModifier {
    func body(content: Content) -> some View {
        content.toolbar(.hidden, for: .tabBar)
    }
}

extension View {
    func hidesPhoneTabBar() -> some View { modifier(HidesPhoneTabBar()) }

    func routeDestinations() -> some View { modifier(RouteDestinations()) }
}
