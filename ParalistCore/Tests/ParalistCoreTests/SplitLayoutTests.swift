// Zusammenhang: Library/SplitLayout.swift
import Testing
@testable import ParalistCore

struct SplitLayoutTests {
    private func side(_ total: Double) -> Double? {
        SplitLayout.sideWidth(total: total, minSide: 320, minMain: 440)
    }

    @Test func sideTakesAThirdOfWideWindows() {
        #expect(side(1200) == 400)
        #expect(side(1620) == 540)
    }

    @Test func sideKeepsItsMinimumWidth() {
        #expect(side(900) == 320)
        #expect(side(960) == 320)
    }

    @Test func narrowWindowsFallBackToCompact() {
        #expect(side(750) == nil)
        #expect(side(639) == nil)
        #expect(side(0) == nil)
        #expect(side(-10) == nil)
    }

    @Test func mainMayBeExactlyAsNarrowAsTheMinimum() {
        #expect(side(760) == 320)
        #expect(side(759) == nil)
    }

    @Test func mainKeepsTwoThirdsOfWideWindows() throws {
        let total = 1024.0
        let width = try #require(side(total))
        #expect(abs((total - width) - total * 2 / 3) < 0.001)
    }

    @Test func menuPanelIsAThirdButAtLeastTheMinimum() {
        #expect(SplitLayout.panelWidth(total: 1366, minSide: 320) == 1366.0 / 3)
        #expect(SplitLayout.panelWidth(total: 820, minSide: 320) == 320)
        #expect(SplitLayout.panelWidth(total: 200, minSide: 320) == 200)
    }

    private func leading(_ total: Double, _ share: Double) -> Double {
        SplitLayout.leadingWidth(total: total, share: share, minLeading: 440, minTrailing: 320)
    }

    @Test func dividerFollowsTheShare() {
        #expect(leading(1200, 2.0 / 3) == 800)
        #expect(leading(1200, 0.5) == 600)
    }

    @Test func dividerKeepsBothSidesAtTheirMinimum() {
        #expect(leading(1200, 0.1) == 440)
        #expect(leading(1200, 0.95) == 880)
    }

    @Test func dividerSplitsByShareWhenBothMinimumsDoNotFit() {
        #expect(leading(600, 0.5) == 300)
        #expect(leading(600, 1.5) == 600)
        #expect(leading(0, 0.5) == 0)
    }

    @Test func mainShrinksToAThirdButNotBelowTheSideMinimum() {
        #expect(SplitLayout.mainMinimum(total: 1320, minSide: 320) == 440)
        #expect(SplitLayout.mainMinimum(total: 900, minSide: 320) == 320)
        #expect(SplitLayout.leadingWidth(total: 1320, share: 0.1, minLeading: SplitLayout.mainMinimum(total: 1320, minSide: 320), minTrailing: 320) == 440)
    }
}
