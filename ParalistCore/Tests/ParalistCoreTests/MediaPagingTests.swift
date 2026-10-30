// Zusammenhang: Library/MediaPaging.swift
import Testing
@testable import ParalistCore

struct MediaPagingTests {
    private let queue = ["a", "b", "c"]

    @Test func neighborsStayInsideTheQueue() {
        #expect(MediaPaging.neighbor(of: "b", in: queue, step: 1) == "c")
        #expect(MediaPaging.neighbor(of: "b", in: queue, step: -1) == "a")
        #expect(MediaPaging.neighbor(of: "a", in: queue, step: -1) == nil)
        #expect(MediaPaging.neighbor(of: "c", in: queue, step: 1) == nil)
        #expect(MediaPaging.neighbor(of: "x", in: queue, step: 1) == nil)
        #expect(MediaPaging.neighbor(of: "a", in: [], step: 1) == nil)
    }

    @Test func flingDecidesTheDirection() {
        #expect(MediaPaging.step(fling: -200, width: 400) == 1)
        #expect(MediaPaging.step(fling: 200, width: 400) == -1)
        #expect(MediaPaging.step(fling: 100, width: 400) == 0)
        #expect(MediaPaging.step(fling: -140, width: 400) == 0)
    }

    @Test func endOfQueueResists() {
        #expect(MediaPaging.shift(drag: 120, hasNeighbor: true) == 120)
        #expect(MediaPaging.shift(drag: 120, hasNeighbor: false) == 30)
    }
}
