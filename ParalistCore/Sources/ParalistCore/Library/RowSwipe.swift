// Zusammenhang: Paralist/Entries/RowSwipe.swift (ArmedSwipe), Paralist/Pages/ListPage.swift, Paralist/Pages/OverviewPage.swift (TabSwipe), Tests RowSwipeTests.swift
import Foundation

public enum RowSwipe: Equatable, Sendable {
    case leading, trailing

    public static func of(_ dx: Double, threshold: Double) -> RowSwipe? {
        if dx >= threshold { return .leading }
        if dx <= -threshold { return .trailing }
        return nil
    }

    public static func offset(_ dx: Double, limit: Double) -> Double {
        let reach = abs(dx)
        guard reach > limit else { return dx }
        let eased = limit + (reach - limit) * 0.25
        return dx < 0 ? -eased : eased
    }
}

public enum TabSwipe {
    public static func step(dx: Double, dy: Double, vx: Double, distance: Double = 48, flick: Double = 350) -> Int {
        guard abs(dx) > abs(dy) * 1.2 else { return 0 }
        let far = abs(dx) >= distance
        let quick = abs(dx) >= distance / 3 && abs(vx) >= flick
        guard far || quick else { return 0 }
        return dx < 0 ? 1 : -1
    }
}
