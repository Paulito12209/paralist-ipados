// Zusammenhang: Library/TabBarLayout.swift
import Testing
@testable import ParalistCore

struct TabBarLayoutTests {
    private func lift(_ inset: Double) -> Double {
        TabBarLayout.lift(safeAreaBottom: inset, clearance: 22, dip: 12, rest: 8)
    }

    @Test func homeIndicatorLetsTheBarDipIntoTheSafeArea() {
        #expect(lift(34) == -12)
    }

    @Test func withoutHomeIndicatorTheBarKeepsASmallRest() {
        #expect(lift(0) == 8)
    }

    @Test func shallowInsetsKeepTheClearance() {
        #expect(lift(20) == 2)
        #expect(lift(22) == 0)
    }

    @Test func keyboardSizedInsetsNeverDipFurther() {
        #expect(lift(300) == -12)
    }

    @Test func reserveFollowsTheLift() {
        #expect(TabBarLayout.reserve(lift: -12, height: 62, docked: false, compact: false, compactHeight: 52, pillHeight: 38, gap: 10) == 50)
        #expect(TabBarLayout.reserve(lift: 8, height: 62, docked: false, compact: false, compactHeight: 52, pillHeight: 38, gap: 10) == 70)
        #expect(TabBarLayout.reserve(lift: 8, height: 62, docked: true, compact: false, compactHeight: 52, pillHeight: 38, gap: 10) == 118)
        #expect(TabBarLayout.reserve(lift: 8, height: 62, docked: true, compact: true, compactHeight: 52, pillHeight: 38, gap: 10) == 60)
    }

    private func drop(_ inset: Double) -> Double {
        TabBarLayout.pillDrop(safeAreaBottom: inset, lift: lift(inset), barHeight: 48, pillHeight: 32, rest: 14, clearance: 22)
    }

    @Test func pillLandsAtRestOnHomeIndicatorDevices() {
        #expect(drop(34) == 16)
        #expect(34 + lift(34) + 8 - drop(34) == 14)
    }

    @Test func pillLandsAtRestWithoutHomeIndicator() {
        #expect(drop(0) == 2)
        #expect(0 + lift(0) + 8 - drop(0) == 14)
    }

    @Test func shallowInsetsDropLikeHomeIndicator() {
        #expect(drop(20) == 16)
    }

    @Test func keyboardSizedInsetsDropNoFurther() {
        #expect(drop(300) == 16)
    }

    @Test func pillNeverRisesAboveTheBar() {
        #expect(TabBarLayout.pillDrop(safeAreaBottom: 0, lift: 0, barHeight: 32, pillHeight: 32, rest: 14, clearance: 22) == 0)
    }
}
