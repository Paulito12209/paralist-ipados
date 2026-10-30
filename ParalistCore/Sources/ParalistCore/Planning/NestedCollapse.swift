// Zusammenhang: Planning/CalendarChrome.swift, Paralist/Pages/CalendarCollapse.swift, Paralist/Pages/CalendarPage.swift (Titel), Paralist/Pages/CalendarParts.swift (Startposition)
import Foundation

public struct NestedCollapse: Equatable, Sendable {
    public var collapse: Double
    public var offset: Double

    public init(collapse: Double, offset: Double) {
        self.collapse = collapse
        self.offset = offset
    }

    public static func step(collapse: Double, limit: Double, top: Double, old: Double, new: Double) -> NestedCollapse {
        let delta = new - old
        if delta > 0, collapse < limit {
            let take = min(delta, limit - collapse)
            return NestedCollapse(collapse: collapse + take, offset: new - take)
        }
        if new < top, collapse > 0 {
            let take = min(top - new, collapse)
            return NestedCollapse(collapse: collapse - take, offset: new + take)
        }
        return NestedCollapse(collapse: collapse, offset: new)
    }

    public static func startOffset(anchorMinute: Int, hourHeight: Double) -> Double {
        max(0, Double(anchorMinute) / 60 * hourHeight - hourHeight)
    }
}
