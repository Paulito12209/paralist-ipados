// Zusammenhang: Paralist/Shell/DetailHost.swift, Paralist/Shell/MediaPager.swift, Paralist/Shell/Router.swift (mediaQueue), Paralist/Pages/MediaPage.swift, Tests MediaPagingTests.swift
import Foundation

public enum MediaPaging {
    public static let commitShare: Double = 0.35
    public static let resistance: Double = 0.25

    public static func neighbor(of id: String, in queue: [String], step: Int) -> String? {
        guard let index = queue.firstIndex(of: id) else { return nil }
        let next = index + step
        return queue.indices.contains(next) ? queue[next] : nil
    }

    public static func step(fling: Double, width: Double) -> Int {
        if fling < -width * commitShare { return 1 }
        if fling > width * commitShare { return -1 }
        return 0
    }

    public static func shift(drag: Double, hasNeighbor: Bool) -> Double {
        hasNeighbor ? drag : drag * resistance
    }
}
