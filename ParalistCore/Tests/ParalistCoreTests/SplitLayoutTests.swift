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
