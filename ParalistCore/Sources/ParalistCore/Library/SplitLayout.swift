// Zusammenhang: Paralist/Shell/SplitRootView.swift (SplitMetrics), Paralist/Shell/RootView.swift, Paralist/Shell/Router.swift (split), Paralist/Theme/SplitDimens.swift, Tests SplitLayoutTests.swift, docs/ipad.md
import Foundation

public enum SplitLayout {
    public static func listWidth(total: Double, minList: Double, minDetail: Double) -> Double? {
        guard total > 0 else { return nil }
        let list = max(minList, total / 3)
        return total - list >= minDetail ? list : nil
    }
}
