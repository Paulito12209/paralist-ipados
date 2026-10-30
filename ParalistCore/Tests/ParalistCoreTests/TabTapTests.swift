// Zusammenhang: Library/TabTap.swift
import Testing
@testable import ParalistCore

struct TabTapTests {
    @Test func anotherTabSwitches() {
        #expect(TabTap.action(current: "overview", tapped: "calendar", depth: 0, compact: false) == .switchTab)
        #expect(TabTap.action(current: "overview", tapped: "calendar", depth: 2, compact: true) == .switchTab)
    }

    @Test func sameTabWithOpenPagesPopsToRoot() {
        #expect(TabTap.action(current: "tasks", tapped: "tasks", depth: 1, compact: false) == .popToRoot)
        #expect(TabTap.action(current: "tasks", tapped: "tasks", depth: 3, compact: true) == .popToRoot)
    }

    @Test func sameTabAtRootScrollsToTop() {
        #expect(TabTap.action(current: "calendar", tapped: "calendar", depth: 0, compact: false) == .scrollToTop)
    }

    @Test func compactBarDoesNothing() {
        #expect(TabTap.action(current: "calendar", tapped: "calendar", depth: 0, compact: true) == .none)
    }
}
