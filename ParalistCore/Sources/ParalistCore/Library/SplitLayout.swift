// Zusammenhang: Paralist/Shell/SplitRootView.swift (SplitMetrics, Hauptcontainer, rechte Seite, Menü-Panel), Paralist/Shell/RootView.swift, Paralist/Shell/Router.swift (split), Paralist/Theme/SplitDimens.swift, Tests SplitLayoutTests.swift, docs/ipad.md
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
}
