// Zusammenhang: Paralist/Shell/Router.swift (tabBarLift, tabBarReserve, entryPillDrop), Paralist/Shell/AppTabBar.swift, Paralist/Entry/EntryToolbar.swift (EntryBottomBar), Paralist/Theme/Dimens.swift (TabBarDimens), Tests TabBarLayoutTests.swift
import Foundation

public enum TabBarLayout {
    public static func lift(safeAreaBottom inset: Double, clearance: Double, dip: Double, rest: Double) -> Double {
        guard inset > 0 else { return rest }
        return max(-dip, clearance - inset)
    }

    public static func reserve(lift: Double, height: Double, docked: Bool, compact: Bool, compactHeight: Double, pillHeight: Double, gap: Double) -> Double {
        if docked && compact { return compactHeight + lift }
        let bar = height + lift
        return docked ? bar + gap + pillHeight : bar
    }

    public static func pillDrop(safeAreaBottom inset: Double, lift: Double, barHeight: Double, pillHeight: Double, rest: Double, clearance: Double) -> Double {
        let barBottom = min(inset + lift, clearance)
        return max(0, barBottom + (barHeight - pillHeight) / 2 - rest)
    }
}
