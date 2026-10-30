// Zusammenhang: Shell/Router.swift (tapTab, topRequests), Shell/AppTabBar.swift, Library/TabBarLayout.swift
public enum TabTap {
    public enum Action: Equatable, Sendable {
        case switchTab, popToRoot, scrollToTop, none
    }

    public static func action(current: String, tapped: String, depth: Int, compact: Bool) -> Action {
        if tapped != current { return .switchTab }
        if depth > 0 { return .popToRoot }
        return compact ? .none : .scrollToTop
    }
}
