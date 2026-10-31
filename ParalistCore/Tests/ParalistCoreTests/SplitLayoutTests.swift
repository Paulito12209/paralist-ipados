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
}
