// Zusammenhang: Planning/WeekGrid.swift, Paralist/Pages/CalendarPage.swift, Paralist/Shell/Router.swift (compact, setScrolled)
import Foundation

public struct CalendarChrome: Equatable, Sendable {
    public var collapsed: Bool
    public var compact: Bool

    public init(collapsed: Bool = false, compact: Bool = false) {
        self.collapsed = collapsed
        self.compact = compact
    }

    public static let layoutShift = 0.5

    public func scrolled(offset: Double, delta: Double, maxOffset: Double, maxShift: Double = 0, step: Double, jump: Double, endSlack: Double) -> CalendarChrome {
        if offset <= 0 { return CalendarChrome() }
        guard abs(maxShift) <= Self.layoutShift else { return self }
        if maxOffset > 0 && offset >= maxOffset - endSlack { return CalendarChrome(collapsed: true, compact: false) }
        guard abs(delta) > step, abs(delta) < jump else { return self }
        return delta > 0 ? CalendarChrome(collapsed: true, compact: true) : CalendarChrome()
    }
}
