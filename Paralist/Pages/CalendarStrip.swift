// Zusammenhang: Pages/CalendarPage.swift, Pages/CalendarParts.swift (Spaltenbreite), ParalistCore Planning/WeekGrid.swift (Week), ParalistCore Planning/CalendarLayout.swift (MonthGrid), Theme/Dimens.swift
import ParalistCore
import SwiftUI

struct WeekStrip: View {
    let selected: Day
    let today: Day
    let busy: Set<Day>
    let onPickWeek: () -> Void
    let onSelect: (Day) -> Void

    var body: some View {
        let week = Week.of(selected)
        HStack(spacing: 0) {
            Button(action: onPickWeek) { weekLabel(week) }
                .buttonStyle(.plain)
                .accessibilityLabel(L.f("week_short", week.isoWeek))
            ForEach(week.days, id: \.self) { day in
                Button { onSelect(day) } label: {
                    DayCell(day: day, selected: day == selected, today: day == today, busy: busy.contains(day), header: true, dimmed: false)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, Dimens.pageEdge)
        .padding(.trailing, Dimens.calendarTrail)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 20).onEnded { value in
                guard abs(value.translation.width) > 50 else { return }
                onSelect(selected.adding(days: value.translation.width < 0 ? 7 : -7))
            }
        )
    }

    private func weekLabel(_ week: Week) -> some View {
        VStack(spacing: Dimens.weekLabelGap) {
            Text(L.s("week_label")).font(Typo.labelSmall)
            Text("\(week.isoWeek)").font(Typo.dm(16))
        }
        .foregroundStyle(Palette.muted)
        .hourAligned()
        .contentShape(Rectangle())
    }
}

struct MonthStrip: View {
    let year: Int
    let month: Int
    let selected: Day
    let today: Day
    let onSelect: (Day) -> Void

    var body: some View {
        let weeks = MonthGrid.weeks(year: year, month: month)
        VStack(spacing: Dimens.monthRowGap) {
            HStack(spacing: 0) {
                Text(L.s("week_label")).font(Typo.labelSmall).foregroundStyle(Palette.muted).hourAligned()
                ForEach(Week.of(selected).days, id: \.self) { day in
                    Text(WeekdayName.short(day)).font(Typo.labelSmall).foregroundStyle(Palette.muted).frame(maxWidth: .infinity)
                }
            }
            ForEach(weeks, id: \.self) { week in
                HStack(spacing: 0) {
                    Text("\(week.isoWeek)").font(Typo.dm(16)).foregroundStyle(Palette.muted).hourAligned()
                    ForEach(week.days, id: \.self) { day in
                        Button { onSelect(day) } label: {
                            DayCell(day: day, selected: day == selected, today: day == today, busy: false, header: false, dimmed: !MonthGrid.isInside(day, year: year, month: month))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.leading, Dimens.pageEdge)
        .padding(.trailing, Dimens.calendarTrail)
        .padding(.vertical, 8)
    }
}

struct DayCell: View {
    let day: Day
    let selected: Bool
    let today: Bool
    let busy: Bool
    let header: Bool
    let dimmed: Bool

    var body: some View {
        let size = header ? Dimens.dayCell : Dimens.monthCell
        VStack(spacing: 4) {
            if header {
                Text(WeekdayName.short(day)).font(Typo.labelSmall).foregroundStyle(today ? Palette.primary : Palette.muted)
            }
            Text("\(day.day)")
                .font(Typo.dm(16, selected ? .semibold : .regular))
                .foregroundStyle(selected ? Palette.onPrimary : dimmed ? Palette.muted : Palette.onSurface)
                .frame(width: size, height: size)
                .background { if selected { Circle().fill(Palette.primary) } }
                .overlay { if today && !selected { Circle().stroke(Palette.primary, lineWidth: 1.5) } }
            if header {
                Circle().fill(busy ? (selected ? Palette.primary : Palette.onSurfaceVariant) : .clear).frame(width: 5, height: 5)
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

extension View {
    func hourAligned() -> some View {
        ZStack {
            Text(WeekGrid.hourLabel(0)).font(Typo.labelSmall).hidden()
            self
        }
        .frame(width: Dimens.weekLabelWidth, alignment: .leading)
    }
}

enum WeekdayName {
    static func short(_ day: Day) -> String {
        let name = day.at(hour: 12, in: .current).formatted(.dateTime.weekday(.abbreviated).locale(L.locale))
        return String(name.prefix(2)).uppercased()
    }
}
