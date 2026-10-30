// Zusammenhang: Theme/Dimens.swift, Entry/EdgePicker.swift (edgeGlow*, edgeBeacon*), Pages/CalendarMonth.swift, Pages/CalendarEdge.swift, Pages/CalendarPage.swift, Pages/CalendarParts.swift, Pages/CalendarStripRow.swift, Pages/CalendarStrip.swift, Pages/MonthPickerSheet.swift
import SwiftUI

extension Dimens {
    static let hourHeight: CGFloat = 60
    static let hourLabelWidth: CGFloat = 56
    static let calendarGutter: CGFloat = pageEdge + weekLabelWidth
    static let calendarGridRadius: CGFloat = 14
    static let calendarDash: CGFloat = 3
    static let calendarLine: CGFloat = 1
    static let calendarColumnLine: CGFloat = 0.5
    static let hourLabelHeight: CGFloat = 16
    static let calendarBlockGap: CGFloat = 2
    static let stripPillHeight: CGFloat = 36
    static let stripPillMax: CGFloat = 240
    static let stripBadge: CGFloat = 24
    static let stripChipHeight: CGFloat = 18
    static let stripChipMax = 3
    static let monthCell: CGFloat = 36
    static let monthRowGap: CGFloat = 6
    static let monthPillHeight: CGFloat = 40
    static let monthSheetHeight: CGFloat = 380
    static func calendarTail(lift: CGFloat) -> CGFloat { TabBarDimens.height + lift + TabBarDimens.gap + TabBarDimens.searchPill + 16 }
    static let calendarEndSlack: CGFloat = 24
    static let stripGap: CGFloat = 12
    static let stripFade: CGFloat = 24
    static let calendarStartMinute = 8 * 60
    static let calendarKeepMoves = 1
    static let nowDot: CGFloat = 8
    static let calendarTrail: CGFloat = 16
    static let weekLabelGap: CGFloat = 12
    static let edgeGlowPeriod: Double = 2.4
    static let edgeGlowOpacity: Double = 0.55
    static let edgeGlowSpan: CGFloat = 0.8
    static let edgeBeaconPeriod: Double = 12
    static let edgeBeaconBase: Double = 0.6
    static let edgeAutoTuck: Duration = .seconds(3)
    static let edgeAnnounce: Duration = .seconds(1.2)
    static let calendarNotchHeight: CGFloat = edgeNotchHeight - 16
    static let monthCellHeight: CGFloat = 92
    static let monthChipHeight: CGFloat = 15
    static let monthChipMax = 3
    static let monthDayBadge: CGFloat = 24
    static let monthsBefore = 24
    static let monthsAfter = 36
}
