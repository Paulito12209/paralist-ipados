// Zusammenhang: Library/SplitLayout.swift
import Testing
@testable import ParalistCore

struct SplitLayoutTests {
    private func list(_ total: Double) -> Double? {
        SplitLayout.listWidth(total: total, minList: 320, minDetail: 440)
    }

    @Test func listTakesAThirdOfWideWindows() {
        #expect(list(1200) == 400)
        #expect(list(1620) == 540)
    }

    @Test func listKeepsItsMinimumWidth() {
        #expect(list(900) == 320)
        #expect(list(960) == 320)
    }

    @Test func narrowWindowsFallBackToCompact() {
        #expect(list(750) == nil)
        #expect(list(639) == nil)
        #expect(list(0) == nil)
        #expect(list(-10) == nil)
    }

    @Test func detailMayBeExactlyAsNarrowAsTheMinimum() {
        #expect(list(760) == 320)
        #expect(list(759) == nil)
    }

    @Test func detailKeepsTwoThirdsOfWideWindows() throws {
        let total = 1024.0
        let width = try #require(list(total))
        #expect(abs((total - width) - total * 2 / 3) < 0.001)
    }
}

struct SplitPaneTests {
    @Test func railLeavesTheRestForTheDetail() {
        #expect(SplitLayout.beside(total: 1300, rail: 72, gap: 10) == 1218)
        #expect(SplitLayout.beside(total: 50, rail: 72, gap: 10) == 0)
    }

    @Test func panesStartHalfAndHalf() {
        let parts = SplitLayout.panes(total: 1010, share: 0.5, minPane: 320, divider: 10)
        #expect(parts.first == 500)
        #expect(parts.second == 500)
    }

    @Test func eachPaneKeepsItsMinimum() {
        let left = SplitLayout.panes(total: 1010, share: 0.05, minPane: 320, divider: 10)
        #expect(left.first == 320)
        #expect(left.second == 680)
        let right = SplitLayout.panes(total: 1010, share: 0.99, minPane: 320, divider: 10)
        #expect(right.first == 680)
        #expect(right.second == 320)
    }

    @Test func tooNarrowSplitsEvenly() {
        #expect(SplitLayout.share(0.9, total: 600, minPane: 320) == 0.5)
        #expect(SplitLayout.share(0.9, total: 0, minPane: 320) == 0.5)
    }

    @Test func dragMovesTheShareWithinBounds() {
        #expect(abs(SplitLayout.drag(from: 0.5, by: 100, total: 1010, minPane: 320, divider: 10) - 0.6) < 0.0001)
        #expect(abs(SplitLayout.drag(from: 0.5, by: -400, total: 1010, minPane: 320, divider: 10) - 0.32) < 0.0001)
        #expect(abs(SplitLayout.drag(from: 0.5, by: 900, total: 1010, minPane: 320, divider: 10) - 0.68) < 0.0001)
    }
}
