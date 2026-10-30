// Zusammenhang: Pages/CalendarPage.swift (Monatsansicht), Pages/CalendarParts.swift (ScrollSpot, gleiches Raster), Pages/CalendarCollapse.swift, Pages/CalendarStrip.swift (WeekdayName), ParalistCore Planning/MonthAgenda.swift, ParalistCore Planning/CalendarLayout.swift (MonthGrid), App/AppModel.swift (calendar(month:)), Entries/TypeLook.swift, Theme/CalendarDimens.swift
import ParalistCore
import SwiftUI

struct CalendarMonth: View {
    let selected: Day
    let today: Day
    let onPick: (Day) -> Void
    let onVisible: (MonthKey) -> Void
    var onScroll: (ScrollSpot, Bool) -> Void = { _, _ in }
    var collapse: CGFloat = 0
    var collapseLimit: CGFloat = 0
    var onCollapse: (CGFloat) -> Void = { _ in }
    var onSettle: () -> Void = {}
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @Environment(\.tabRoot) private var tabRoot
    @State private var position = ScrollPosition(idType: Int.self)
    @State private var armed = false

    var body: some View {
        let months = MonthAgenda.months(around: selected, before: Dimens.monthsBefore, after: Dimens.monthsAfter)
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(months) { month in
                    MonthBlock(month: month, rows: model.calendar(month: month), selected: selected, today: today, onPick: onPick)
                        .id(month.id)
                }
            }
            .scrollTargetLayout()
            .background { CalendarCollapse(collapse: collapse, limit: collapseLimit, onCollapse: onCollapse) }
            .padding(.bottom, tabRoot ? Dimens.calendarTail(lift: router.tabBarLift) : Dimens.stripGap)
        }
        .scrollPosition($position, anchor: .top)
        .onScrollGeometryChange(for: ScrollSpot.self) { geo in
            ScrollSpot(y: geo.contentOffset.y + geo.contentInsets.top,
                       max: geo.contentSize.height + geo.contentInsets.top + geo.contentInsets.bottom - geo.containerSize.height)
        } action: { _, spot in onScroll(spot, armed) }
        .onScrollPhaseChange { _, phase in
            if phase == .idle { onSettle() }
        }
        .onScrollTargetVisibilityChange(idType: Int.self) { ids in
            if let first = ids.first, let month = months.first(where: { $0.id == first }) { onVisible(month) }
        }
        .onAppear {
            position.scrollTo(id: MonthKey.of(selected).id, anchor: .top)
            onVisible(MonthKey.of(selected))
            Task { @MainActor in armed = true }
        }
    }
}

struct MonthWeekdayHeader: View {
    let selected: Day

    var body: some View {
        HStack(spacing: 0) {
            Text(L.s("week_label")).font(Typo.labelSmall).foregroundStyle(Palette.muted)
                .hourAligned()
            ForEach(Week.of(selected).days, id: \.self) { day in
                Text(WeekdayName.short(day)).font(Typo.labelSmall).foregroundStyle(Palette.muted).frame(maxWidth: .infinity)
            }
        }
        .padding(.leading, Dimens.pageEdge)
        .padding(.trailing, Dimens.calendarTrail)
        .padding(.vertical, 10)
    }
}

private struct MonthBlock: View {
    let month: MonthKey
    let rows: [Entry]
    let selected: Day
    let today: Day
    let onPick: (Day) -> Void

    var body: some View {
        let weeks = MonthGrid.weeks(year: month.year, month: month.month)
        let byId = Dictionary(rows.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(Typo.dm(17, .semibold))
                .foregroundStyle(Palette.onSurface)
                .padding(.leading, Dimens.calendarGutter + 8)
                .padding(.top, Dimens.stripGap * 2)
                .padding(.bottom, Dimens.stripGap)
            HStack(alignment: .top, spacing: 0) {
                VStack(spacing: 0) {
                    ForEach(weeks, id: \.self) { week in
                        Text("\(week.isoWeek)").font(Typo.labelSmall).foregroundStyle(Palette.muted)
                            .padding(.top, 10)
                            .hourAligned()
                            .frame(height: Dimens.monthCellHeight, alignment: .top)
                    }
                }
                .padding(.leading, Dimens.pageEdge)
                VStack(spacing: 0) {
                    ForEach(Array(weeks.enumerated()), id: \.element) { index, week in
                        HStack(spacing: 0) {
                            ForEach(week.days, id: \.self) { day in
                                cell(day, byId)
                            }
                        }
                        .frame(height: Dimens.monthCellHeight)
                        .overlay(alignment: .top) {
                            if index > 0 { Rectangle().fill(Palette.calendarLine).frame(height: Dimens.calendarColumnLine) }
                        }
                    }
                }
                .background(Palette.calendarGrid, in: RoundedRectangle(cornerRadius: Dimens.calendarGridRadius))
                .padding(.trailing, Dimens.calendarTrail)
            }
        }
    }

    private var title: String {
        let style = Date.FormatStyle(locale: L.locale).month(.wide)
        let name = month.first.at(hour: 12, in: .current).formatted(month.year == today.year ? style : style.year())
        return name.prefix(1).uppercased() + name.dropFirst()
    }

    @ViewBuilder
    private func cell(_ day: Day, _ byId: [String: Entry]) -> some View {
        if MonthGrid.isInside(day, year: month.year, month: month.month) {
            let ids = MonthAgenda.ids(rows, day: day, zone: .current)
            Button { onPick(day) } label: {
                VStack(alignment: .leading, spacing: 2) {
                    number(day)
                    ForEach(ids.prefix(Dimens.monthChipMax), id: \.self) { id in
                        if let entry = byId[id] { chip(entry) }
                    }
                    if ids.count > Dimens.monthChipMax {
                        Text(L.f("cal_more", ids.count - Dimens.monthChipMax)).font(Typo.dm(10)).foregroundStyle(Palette.muted)
                            .padding(.leading, 3)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 2)
                .padding(.top, 6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(day.at(hour: 12, in: .current).formatted(Date.FormatStyle(locale: L.locale).weekday(.wide).day().month(.wide)))
            .accessibilityValue(L.f("cal_strip_count", ids.count))
        } else {
            Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func number(_ day: Day) -> some View {
        let isSelected = day == selected
        let isToday = day == today
        return Text("\(day.day)")
            .font(Typo.dm(13, isSelected || isToday ? .semibold : .regular))
            .foregroundStyle(isSelected ? Palette.onPrimary : isToday ? Palette.primary : Palette.onSurface)
            .frame(width: Dimens.monthDayBadge, height: Dimens.monthDayBadge)
            .background { if isSelected { Circle().fill(Palette.primary) } }
            .overlay { if isToday && !isSelected { Circle().stroke(Palette.primary, lineWidth: 1.5) } }
            .frame(maxWidth: .infinity)
    }

    private func chip(_ e: Entry) -> some View {
        let look = TypeLook.of(e.type)
        return Text(e.title.isEmpty ? L.s("list_untitled") : e.title)
            .font(Typo.dm(10))
            .foregroundStyle(Palette.onSurface)
            .lineLimit(1)
            .padding(.horizontal, 3)
            .frame(maxWidth: .infinity, minHeight: Dimens.monthChipHeight, maxHeight: Dimens.monthChipHeight, alignment: .leading)
            .background(look.color.opacity(0.22), in: RoundedRectangle(cornerRadius: 3))
    }
}
