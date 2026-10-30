// Zusammenhang: Library/BarCollapse.swift
import Testing
@testable import ParalistCore

struct BarCollapseTests {
    private func run(_ offsets: [Double]) -> BarCollapse {
        var bar = BarCollapse(threshold: 24)
        for offset in offsets { bar.scrolled(to: offset) }
        return bar
    }

    @Test func startsExpanded() {
        #expect(!BarCollapse(threshold: 24).collapsed)
    }

    @Test func smallScrollDownKeepsBarOpen() {
        #expect(!run([5, 12, 23]).collapsed)
    }

    @Test func scrollingDownPastThresholdCollapses() {
        #expect(run([10, 20, 24]).collapsed)
        #expect(run([100]).collapsed)
    }

    @Test func scrollingUpByThresholdExpands() {
        #expect(run([200, 190, 180]).collapsed)
        #expect(!run([200, 190, 176]).collapsed)
    }

    @Test func thresholdCountsFromLastTurn() {
        #expect(!run([10, 0.5, 20]).collapsed)
        #expect(!run([20, 10, 30]).collapsed)
        #expect(run([20, 10, 34]).collapsed)
        #expect(run([200, 180, 300, 290]).collapsed)
    }

    @Test func bounceAtBottomEndKeepsBarCollapsed() {
        var bar = BarCollapse(threshold: 24)
        for offset in [20.0, 50, 71, 110, 130, 90, 71] { bar.scrolled(to: offset, end: 71) }
        #expect(bar.collapsed)
    }

    @Test func reachingTopExpands() {
        #expect(!run([200, 205, 0]).collapsed)
        #expect(!run([200, -12]).collapsed)
    }

    @Test func resetExpandsAndRestartsFromOffset() {
        var bar = run([300])
        bar.reset(at: 300)
        #expect(!bar.collapsed)
        bar.scrolled(to: 320)
        #expect(!bar.collapsed)
        bar.scrolled(to: 324)
        #expect(bar.collapsed)
    }
}
