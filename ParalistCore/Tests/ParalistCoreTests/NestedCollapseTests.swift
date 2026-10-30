// Zusammenhang: Planning/NestedCollapse.swift
import Foundation
import Testing
@testable import ParalistCore

struct NestedCollapseTests {
    @Test func upwardScrollCollapsesTitleFirst() {
        let r = NestedCollapse.step(collapse: 0, limit: 80, top: 0, old: 300, new: 330)
        #expect(r == NestedCollapse(collapse: 30, offset: 300))
    }

    @Test func gridScrollsOnceTitleIsGone() {
        let r = NestedCollapse.step(collapse: 70, limit: 80, top: 0, old: 300, new: 330)
        #expect(r == NestedCollapse(collapse: 80, offset: 320))
        #expect(NestedCollapse.step(collapse: 80, limit: 80, top: 0, old: 320, new: 350) == NestedCollapse(collapse: 80, offset: 350))
    }

    @Test func downwardScrollMovesGridBeforeTitle() {
        #expect(NestedCollapse.step(collapse: 80, limit: 80, top: 0, old: 300, new: 260) == NestedCollapse(collapse: 80, offset: 260))
    }

    @Test func pullingPastTopBringsTitleBack() {
        #expect(NestedCollapse.step(collapse: 80, limit: 80, top: 0, old: 10, new: -20) == NestedCollapse(collapse: 60, offset: 0))
        #expect(NestedCollapse.step(collapse: 10, limit: 80, top: 0, old: 0, new: -20) == NestedCollapse(collapse: 0, offset: -10))
    }

    @Test func startShowsOneHourAboveAnchor() {
        #expect(NestedCollapse.startOffset(anchorMinute: 12 * 60, hourHeight: 60) == 660)
        #expect(NestedCollapse.startOffset(anchorMinute: 30, hourHeight: 60) == 0)
    }
}
