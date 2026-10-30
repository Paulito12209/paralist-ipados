// Zusammenhang: Sources/ParalistCore/Library/RowSwipe.swift
import Testing
@testable import ParalistCore

struct RowSwipeTests {
    @Test func needsThresholdInEitherDirection() {
        #expect(RowSwipe.of(40, threshold: 88) == nil)
        #expect(RowSwipe.of(-87, threshold: 88) == nil)
        #expect(RowSwipe.of(88, threshold: 88) == .leading)
        #expect(RowSwipe.of(-120, threshold: 88) == .trailing)
    }

    @Test func offsetSlowsDownPastLimit() {
        #expect(RowSwipe.offset(100, limit: 140) == 100)
        #expect(RowSwipe.offset(180, limit: 140) == 150)
        #expect(RowSwipe.offset(-180, limit: 140) == -150)
    }
}

struct TabSwipeTests {
    @Test func shortDistanceOrQuickFlickIsEnough() {
        #expect(TabSwipe.step(dx: -50, dy: 4, vx: 0) == 1)
        #expect(TabSwipe.step(dx: 24, dy: 2, vx: 600) == -1)
        #expect(TabSwipe.step(dx: 24, dy: 2, vx: 100) == 0)
    }

    @Test func mostlyVerticalNeverSwitches() {
        #expect(TabSwipe.step(dx: -60, dy: 70, vx: 900) == 0)
    }
}
