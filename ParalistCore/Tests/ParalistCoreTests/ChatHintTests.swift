// Zusammenhang: ParalistCore Chat/ChatHint.swift
import Testing
@testable import ParalistCore

struct ChatHintTests {
    @Test func nothingOnceSeen() {
        #expect(ChatHint.placement(seen: true, chatsInTabBar: false, threadEmpty: true) == .none)
        #expect(ChatHint.placement(seen: true, chatsInTabBar: true) == .none)
    }

    @Test func dotsFollowTheWayToChats() {
        let viaMenu = ChatHint.placement(seen: false, chatsInTabBar: false)
        #expect(viaMenu.menuDot && viaMenu.chatsRowDot && !viaMenu.chatsTabDot && viaMenu.newChatPulse)
        let viaTab = ChatHint.placement(seen: false, chatsInTabBar: true)
        #expect(!viaTab.menuDot && !viaTab.chatsRowDot && viaTab.chatsTabDot && viaTab.newChatPulse)
    }

    @Test func introOnlyInAnEmptyThread() {
        #expect(ChatHint.placement(seen: false, chatsInTabBar: false, threadEmpty: true).intro)
        #expect(!ChatHint.placement(seen: false, chatsInTabBar: false, threadEmpty: false).intro)
    }
}
