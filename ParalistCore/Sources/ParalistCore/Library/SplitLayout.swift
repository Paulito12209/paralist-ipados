// Zusammenhang: Paralist/Shell/SplitRootView.swift (SplitMetrics, Hauptcontainer, rechte Seite, Menü-Panel, Ziehgriff), Paralist/Shell/RootView.swift, Paralist/Shell/Router.swift (split), Paralist/Theme/SplitDimens.swift, Tests SplitLayoutTests.swift, docs/ipad.md
import Foundation

public enum SplitLayout {
    public static func sideWidth(total: Double, minSide: Double, minMain: Double) -> Double? {
        guard total > 0 else { return nil }
        let side = max(minSide, total / 3)
        return total - side >= minMain ? side : nil
    }

    public static func panelWidth(total: Double, minSide: Double) -> Double {
        min(max(minSide, total / 3), max(total, 0))
    }

    public static func leadingWidth(total: Double, share: Double, minLeading: Double, minTrailing: Double) -> Double {
        guard total > 0 else { return 0 }
        let upper = total - minTrailing
        guard upper >= minLeading else { return total * min(max(share, 0), 1) }
        return min(max(total * share, minLeading), upper)
    }
}
