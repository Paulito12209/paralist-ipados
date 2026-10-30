// Zusammenhang: Library/EdgePicker.swift
import Testing
@testable import ParalistCore

struct EdgePickerTests {
    @Test func neighboursSitOneStepFromThePill() {
        #expect(EdgePicker.step() == 45)
        #expect(EdgePicker.center(of: 1, selected: 1) == 0)
        #expect(EdgePicker.center(of: 2, selected: 1) == 45)
        #expect(EdgePicker.center(of: 0, selected: 1) == -45)
        #expect(EdgePicker.center(of: 2, selected: 0) == 77)
    }

    @Test func widePillPushesNeighboursOut() {
        #expect(EdgePicker.step(pill: EdgePicker.pillWide) == 70)
        #expect(EdgePicker.center(of: 0, selected: 1, pill: EdgePicker.pillWide) == -70)
    }

    @Test func tapPicksTheNearestSlot() {
        #expect(EdgePicker.nearest(to: 0, selected: 1, count: 3) == 1)
        #expect(EdgePicker.nearest(to: -40, selected: 1, count: 3) == 0)
        #expect(EdgePicker.nearest(to: 30, selected: 1, count: 3) == 2)
        #expect(EdgePicker.nearest(to: 12, selected: 1, count: 3) == 1)
    }

    @Test func dragSnapsAndStaysInRange() {
        #expect(EdgePicker.afterDrag(50, selected: 1, count: 3) == 0)
        #expect(EdgePicker.afterDrag(-50, selected: 1, count: 3) == 2)
        #expect(EdgePicker.afterDrag(400, selected: 1, count: 3) == 0)
        #expect(EdgePicker.afterDrag(-400, selected: 0, count: 3) == 2)
        #expect(EdgePicker.afterDrag(10, selected: 2, count: 3) == 2)
        #expect(EdgePicker.afterDrag(100, selected: 0, count: 0) == 0)
    }

    @Test func endOptionsStopAtTheReach() {
        #expect(EdgePicker.shift(selected: 0, count: 3, reach: 76) == -53)
        #expect(EdgePicker.shift(selected: 1, count: 3, reach: 76) == 0)
        #expect(EdgePicker.shift(selected: 2, count: 3, reach: 76) == 53)
        #expect(EdgePicker.shift(selected: 0, count: 3, reach: 76, pill: EdgePicker.pillWide) == -28)
        #expect(EdgePicker.shift(selected: 0, count: 0, reach: 76) == 0)
    }

    @Test func twoOptionsSitCentered() {
        #expect(EdgePicker.shift(selected: 1, count: 2, reach: 52) == 16)
        #expect(EdgePicker.shift(selected: 0, count: 2, reach: 52) == -16)
    }

    @Test func textOptionOnlyWithText() {
        #expect(EdgePicker.options(hasText: false) == [.cover, .actions])
        #expect(EdgePicker.options(hasText: true) == [.cover, .actions, .text])
    }

    @Test func linksOptionComesLast() {
        #expect(EdgePicker.options(hasText: true, hasLinks: true) == [.cover, .actions, .text, .links])
        #expect(EdgePicker.options(hasText: false, hasLinks: true) == [.cover, .actions, .links])
    }

    @Test func fourOptionsScrollInsideThreeHighNotch() {
        #expect(EdgePicker.height(count: 4, full: 280) == 280)
        #expect(EdgePicker.shift(selected: 0, count: 4, reach: 76) == 0)
        #expect(EdgePicker.shift(selected: 3, count: 4, reach: 76) == 0)
        #expect(EdgePicker.shift(selected: 0, count: 3, reach: 76) == -53)
    }

    @Test func outerOptionsFadeSlightly() {
        #expect(EdgePicker.fade(at: 0, half: 140) == 1)
        #expect(EdgePicker.fade(at: -45, half: 140) == 1)
        #expect(EdgePicker.fade(at: 140, half: 140) == EdgePicker.faintest)
        #expect(EdgePicker.fade(at: 200, half: 140) == EdgePicker.faintest)
        let mid = EdgePicker.fade(at: 77, half: 140)
        #expect(mid < 1 && mid > EdgePicker.faintest)
    }

    @Test func notchGrowsWithOptions() {
        #expect(EdgePicker.height(count: 3, full: 280) == 280)
        #expect(EdgePicker.height(count: 2, full: 280) == 232)
    }

    @Test func canvasOrderIsCoverActionsTextLinks() {
        #expect(EntryCanvas.allCases.map(\.rawValue) == [0, 1, 2, 3])
        #expect(EntryCanvas.text.label == "canvas_text")
        #expect(EntryCanvas.links.label == "entry_links")
    }

    @Test func spreadPlacesOptionsEvenly() {
        #expect(EdgePicker.spread(0, count: 3, reach: 60) == -60)
        #expect(EdgePicker.spread(1, count: 3, reach: 60) == 0)
        #expect(EdgePicker.spread(2, count: 3, reach: 60) == 60)
        #expect(EdgePicker.spreadSlot(at: -50, count: 3, reach: 60) == 0)
        #expect(EdgePicker.spreadSlot(at: 25, count: 3, reach: 60) == 1)
        #expect(EdgePicker.spreadSlot(at: 200, count: 3, reach: 60) == 2)
    }
}
