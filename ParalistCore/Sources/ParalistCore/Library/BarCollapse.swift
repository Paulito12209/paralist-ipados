// Zusammenhang: Paralist/Entry/EntryPage.swift (barCollapsed), Paralist/Entry/EntryToolbar.swift (EntryBottomBar), Paralist/Theme/EntryBarDimens.swift (entryBarCollapseScroll), Tests BarCollapseTests.swift, docs/detailseite.md
import Foundation

public struct BarCollapse: Equatable, Sendable {
    public let threshold: Double
    public private(set) var collapsed = false
    private var anchor: Double = 0
    private var last: Double = 0
    private var down = true

    public init(threshold: Double) {
        self.threshold = threshold
    }

    public mutating func reset(at offset: Double) {
        collapsed = false
        anchor = max(offset, 0)
        last = max(offset, 0)
        down = true
    }

    public mutating func scrolled(to raw: Double, end: Double = .infinity) {
        let offset = min(raw, max(end, 0))
        if offset <= 0 {
            reset(at: 0)
            return
        }
        guard offset != last else { return }
        let goingDown = offset > last
        if goingDown != down {
            down = goingDown
            anchor = last
        }
        last = offset
        if down, !collapsed, offset - anchor >= threshold {
            collapsed = true
        } else if !down, collapsed, anchor - offset >= threshold {
            collapsed = false
        }
    }
}
