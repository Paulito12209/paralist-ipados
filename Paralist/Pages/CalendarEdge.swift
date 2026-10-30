// Zusammenhang: Entry/EdgePicker.swift (EdgePickerView, Kerbe und Leuchten), Pages/CalendarPage.swift, ParalistCore Planning/CalendarLayout.swift (CalendarMode), Theme/CalendarDimens.swift (edgeAutoTuck, edgeBeacon*), Theme/Palette.swift (edgeGlow), Icons/AppIcons.swift
import ParalistCore
import SwiftUI

struct CalendarEdge: View {
    @Binding var mode: CalendarMode
    let wake: Int
    @State private var tucked = false
    @State private var shown = 0

    var body: some View {
        EdgePickerView(selected: $mode, options: CalendarMode.allCases, title: L.s("cal_view_picker"), label: { L.s($0.labelKey) },
                       icon: { Image(systemName: $0.icon).font(.system(size: EdgePicker.icon, weight: .semibold)) },
                       glow: true, spread: true, full: Dimens.calendarNotchHeight, tucked: tucked)
        .offset(x: tucked ? Dimens.edgeNotchWidth - Dimens.edgePeek : 0)
        .allowsHitTesting(!tucked)
        .animation(Motion.dock, value: tucked)
        .overlay(alignment: .trailing) {
            if tucked {
                Color.clear.frame(width: Dimens.edgePeekHit).contentShape(Rectangle())
                    .onTapGesture {
                        tucked = false
                        shown += 1
                    }
            }
        }
        .task(id: shown) {
            tucked = false
            try? await Task.sleep(for: Dimens.edgeAutoTuck)
            if !Task.isCancelled { tucked = true }
        }
        .onChange(of: mode) { shown += 1 }
        .onChange(of: wake) { shown += 1 }
    }
}

private extension CalendarMode {
    var labelKey: String {
        switch self {
        case .day: return "cal_mode_day"
        case .week: return "cal_mode_week"
        case .month: return "cal_mode_month"
        }
    }

    var icon: String {
        switch self {
        case .day: return AppIcons.calendarDay
        case .week: return AppIcons.calendarWeek
        case .month: return AppIcons.calendarMonth
        }
    }
}
