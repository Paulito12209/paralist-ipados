// Zusammenhang: ParalistCore Chat/ChatThinking.swift
import Testing
@testable import ParalistCore

struct ChatThinkingTests {
    @Test func standardIsFast() {
        #expect(ChatThinking.standard == .fast)
    }

    @Test func missingOrUnknownKeyFallsBackToStandard() {
        #expect(ChatThinking.fromKey(nil) == .fast)
        #expect(ChatThinking.fromKey("") == .fast)
        #expect(ChatThinking.fromKey("turbo") == .fast)
    }

    @Test func keysRoundTrip() {
        for level in ChatThinking.allCases {
            #expect(ChatThinking.fromKey(level.rawValue) == level)
        }
    }

    @Test func orderRunsFromFastToThorough() {
        #expect(ChatThinking.allCases == [.fast, .balanced, .thorough])
    }
}
