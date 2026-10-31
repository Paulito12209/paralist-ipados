// Zusammenhang: Paralist/Shell/SplitRootView.swift (SplitMetrics, Reiterseite), Paralist/Shell/SplitPanes.swift (Leiste, zwei Detailseiten, Trenner), Paralist/Shell/RootView.swift, Paralist/Shell/Router.swift (split, paneShare), Paralist/Theme/SplitDimens.swift, Tests SplitLayoutTests.swift, docs/ipad.md
import Foundation

public enum SplitLayout {
    public static func listWidth(total: Double, minList: Double, minDetail: Double) -> Double? {
        guard total > 0 else { return nil }
        let list = max(minList, total / 3)
        return total - list >= minDetail ? list : nil
    }

    public static func beside(total: Double, rail: Double, gap: Double) -> Double {
        max(0, total - rail - gap)
    }

    public static func share(_ share: Double, total: Double, minPane: Double) -> Double {
        guard total > 0, total >= 2 * minPane else { return 0.5 }
        let low = minPane / total
        return min(max(share, low), 1 - low)
    }

    public static func panes(total: Double, share: Double, minPane: Double, divider: Double) -> (first: Double, second: Double) {
        let room = max(0, total - divider)
        let first = (room * self.share(share, total: room, minPane: minPane)).rounded()
        return (first, room - first)
    }

    public static func drag(from start: Double, by translation: Double, total: Double, minPane: Double, divider: Double) -> Double {
        let room = max(0, total - divider)
        guard room > 0 else { return 0.5 }
        return share(start + translation / room, total: room, minPane: minPane)
    }
}
