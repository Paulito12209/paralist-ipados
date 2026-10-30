// Zusammenhang: Paralist/App/AppPrefs.swift (chatHintSeen), Paralist/Shell/AppTabBar.swift, Paralist/Pages/MenuPage.swift, Paralist/Chat/ChatListPage.swift, Paralist/Chat/ChatThreadPage.swift, docs/chat.md
public struct ChatHintPlacement: Equatable, Sendable {
    public var menuDot = false
    public var chatsRowDot = false
    public var chatsTabDot = false
    public var newChatPulse = false
    public var intro = false

    public static let none = ChatHintPlacement()
}

public enum ChatHint {
    public static func placement(seen: Bool, chatsInTabBar: Bool, threadEmpty: Bool = false) -> ChatHintPlacement {
        guard !seen else { return .none }
        var placement = ChatHintPlacement()
        placement.menuDot = !chatsInTabBar
        placement.chatsRowDot = !chatsInTabBar
        placement.chatsTabDot = chatsInTabBar
        placement.newChatPulse = true
        placement.intro = threadEmpty
        return placement
    }
}
