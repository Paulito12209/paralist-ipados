// Zusammenhang: Shell/SectionChrome.swift (tabRoot), Shell/Router.swift (topRequest), Shell/PageBar.swift, Pages/CalendarParts.swift, Pages/CalendarCollapse.swift (Titel klappt vor dem Raster), Pages/CalendarMonth.swift (Monatsansicht), Pages/CalendarEdge.swift (Edge Picker), Pages/CalendarStrip.swift, Pages/MonthPickerSheet.swift, Pages/WeekPickerSheet.swift, ParalistCore Planning/CalendarLayout.swift, ParalistCore Planning/CalendarChrome.swift, App/AppModel.swift (calendar)
import ParalistCore
import SwiftUI

struct CalendarPage: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @AppStorage("calendar_selected") private var selectedDay = Day.of(Date(), in: .current).epochDay
    @AppStorage("calendar_mode") private var modeRaw = CalendarMode.day.rawValue
    @State private var chrome = CalendarChrome()
    @State private var lastOffset: CGFloat = 0
    @State private var lastMax: CGFloat = 0
    @State private var pickingWeek = false
    @State private var pickingMonth = false
    @State private var monthOpen = false
    @State private var collapse: CGFloat = 0
    @State private var titleHeight: CGFloat = 0
    @State private var pullUsed = false
    @State private var gridAtTop = false
    @State private var visit = 0
    @State private var leftMoves: Int?
    @State private var leftDay: Day?
    @State private var visibleMonth: MonthKey?
    @State private var edgeWake = 0
    @Environment(\.tabRoot) private var tabRoot

    private var mode: CalendarMode { CalendarMode(rawValue: modeRaw) ?? .day }

    var body: some View {
        let selected = Day(epochDay: selectedDay)
        let today = model.today
        let rows = model.calendar(around: selected)
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                if tabRoot, !router.split { SectionHeader() }
                PageTitle(text: L.s("nav_calendar")).padding(.leading, Dimens.titleEdge)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { titleHeight = $0 }
            .frame(height: titleHeight > 0 ? max(0, titleHeight - collapse) : nil, alignment: .bottom)
            .opacity(titleHeight > 0 ? 1 - collapse / titleHeight : 1)
            .clipped()
            dateRow(selected, today)
            if mode == .month {
                MonthWeekdayHeader(selected: selected)
            } else if monthOpen {
                MonthStrip(year: selected.year, month: selected.month, selected: selected, today: today) { day in
                    pick(day)
                    withAnimation(Motion.page) { monthOpen = false }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            } else {
                WeekStrip(selected: selected, today: today, busy: busyDays(rows), onPickWeek: { pickingWeek = true }, onSelect: pick)
            }
            Divider().overlay(Palette.outlineVariant)
            content(selected, today, rows)
        }
        .background(Palette.calendarPage)
        .overlay(alignment: .bottomTrailing) {
            CalendarEdge(mode: modeBinding, wake: edgeWake)
                .padding(.bottom, tabRoot ? router.tabBarReserve + Dimens.edgePickerLift : Dimens.edgePickerLift)
        }
        .pageBar(!tabRoot, search: nil, prompt: L.s("search_hint"), addLabel: L.s("add_new_event")) {
            router.compose(ComposerRequest(type: .event, day: selected))
        }
        .navigationTitle(L.s("nav_calendar"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(removing: .title)
        .onAppear { if !tabRoot { arrive() } }
        .onDisappear { if !tabRoot { leave() } }
        .onChange(of: shownAsTab, initial: true) { was, shown in
            guard tabRoot else { return }
            if shown { arrive() } else if was { leave() }
        }
        .onChange(of: chrome) { _, now in
            guard tabRoot else { return }
            router.setScrolled(.calendar, now.collapsed)
            router.setCompact(now.compact)
        }
        .onChange(of: router.topRequest(.calendar)) { _, _ in
            guard tabRoot else { return }
            withAnimation(Motion.bars) { reset() }
        }
        .sheet(isPresented: $pickingWeek) {
            WeekPickerSheet(selected: selected, today: today, onPick: pick)
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(Dimens.sheetRadius)
        }
        .sheet(isPresented: $pickingMonth) {
            MonthPickerSheet(selected: selected, today: today) { year, month in
                withAnimation(Motion.page) {
                    selectedDay = selected.moved(toYear: year, month: month).epochDay
                    monthOpen = mode != .month
                }
            }
            .presentationDetents([.height(Dimens.monthSheetHeight)])
            .presentationCornerRadius(Dimens.sheetRadius)
        }
    }

    @ViewBuilder
    private func content(_ selected: Day, _ today: Day, _ rows: [Entry]) -> some View {
        if mode == .month {
            CalendarMonth(selected: selected, today: today, onPick: { day in
                withAnimation(Motion.page) {
                    selectedDay = day.epochDay
                    modeRaw = CalendarMode.day.rawValue
                }
            }, onVisible: { visibleMonth = $0 }, onScroll: scrolled, collapse: collapse, collapseLimit: titleHeight, onCollapse: collapsed, onSettle: settle)
            .id("\(modeRaw)-\(mode.anchor(selected).epochDay)-\(visit)")
            .transition(.opacity)
        } else {
            CalendarGrid(days: mode.days(around: selected), today: today, rows: rows, onCreate: { day, hour in
                router.composer = ComposerRequest(type: .event, day: day, hour: hour)
            }, onOpen: { id in
                router.open(.entry(id))
            }, onScroll: scrolled, onSwipe: { step in
                withAnimation(Motion.page) { selectedDay += step * mode.swipeDays }
            }, collapse: collapse, collapseLimit: titleHeight, onCollapse: collapsed, onSettle: settle)
            .id("\(modeRaw)-\(mode.anchor(selected).epochDay)-\(visit)")
            .transition(.opacity)
        }
    }

    private var modeBinding: Binding<CalendarMode> {
        Binding(get: { mode }, set: { new in withAnimation(Motion.page) { modeRaw = new.rawValue } })
    }

    private func dateRow(_ selected: Day, _ today: Day) -> some View {
        HStack(spacing: 8) {
            Button { pickingMonth = true } label: {
                HStack(spacing: 6) {
                    Text(dateTitle(selected, today)).font(Typo.dm(17)).foregroundStyle(Palette.onSurfaceVariant).lineLimit(1).minimumScaleFactor(0.8)
                    Image(systemName: AppIcons.expandMore).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.muted)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L.s("cal_pick_date"))
            Spacer(minLength: 8)
            todayButton(selected == today && (mode != .month || visibleMonth == MonthKey.of(today)), today)
        }
        .padding(.leading, Dimens.titleEdge)
        .padding(.trailing, Dimens.pageEdge)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func todayButton(_ isToday: Bool, _ today: Day) -> some View {
        if isToday {
            Label(L.s("cal_today"), systemImage: AppIcons.todayCheck)
                .font(Typo.labelLarge)
                .foregroundStyle(Palette.onPrimaryContainer)
                .padding(.horizontal, 12)
                .frame(height: Dimens.stripPillHeight)
                .background(Palette.primaryContainer, in: Capsule())
        } else {
            Button {
                pick(today)
                if mode == .month { visit += 1 }
            } label: {
                Text(L.s("cal_today"))
                    .font(Typo.labelLarge)
                    .foregroundStyle(Palette.onSurface)
                    .padding(.horizontal, 14)
                    .frame(height: Dimens.stripPillHeight)
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Capsule())
        }
    }

    private func dateTitle(_ day: Day, _ today: Day) -> String {
        if mode == .month {
            let month = visibleMonth ?? MonthKey.of(day)
            var style = Date.FormatStyle(locale: L.locale).month(.wide)
            if month.year != today.year { style = style.year() }
            return month.first.at(hour: 12, in: .current).formatted(style)
        }
        var style = Date.FormatStyle(locale: L.locale).weekday(.wide).day().month(.wide)
        if day.year != today.year { style = style.year() }
        return day.at(hour: 12, in: .current).formatted(style)
    }

    private func pick(_ day: Day) {
        withAnimation(Motion.short) { selectedDay = day.epochDay }
    }

    private func scrolled(_ spot: ScrollSpot, _ armed: Bool) {
        let delta = spot.y - lastOffset
        let shift = spot.max - lastMax
        lastOffset = spot.y
        lastMax = spot.max
        gridAtTop = spot.y <= 0.5
        updatePull()
        guard armed else { return }
        let moved = chrome.scrolled(offset: spot.y + collapse, delta: delta, maxOffset: spot.max + titleHeight, maxShift: shift, step: Dimens.collapseStep, jump: Dimens.collapseJump, endSlack: Dimens.calendarEndSlack)
        apply(compact: moved.compact)
    }

    private var titleGone: Bool { titleHeight > 0 && collapse >= titleHeight - 1 }

    private func apply(compact: Bool) {
        let next = CalendarChrome(collapsed: titleGone, compact: titleGone && compact)
        guard next != chrome else { return }
        withAnimation(Motion.bars) { chrome = next }
    }

    private var shownAsTab: Bool { router.tab == .calendar && router.path(.calendar).isEmpty }

    private func leave() {
        leftMoves = router.moves
        leftDay = model.today
    }

    private func arrive() {
        defer { leftMoves = nil }
        if let leftMoves, leftDay == model.today, router.moves - leftMoves <= Dimens.calendarKeepMoves { return }
        reset()
    }

    private func reset() {
        selectedDay = model.today.epochDay
        collapse = 0
        monthOpen = false
        chrome = CalendarChrome()
        visit += 1
        edgeWake += 1
    }

    private func settle() {
        if collapse > 0, collapse < titleHeight {
            let target = collapse > titleHeight / 2 ? titleHeight : 0
            withAnimation(Motion.bars) { collapsed(target) }
        }
        pullUsed = false
        updatePull()
    }

    private func updatePull() {
        guard tabRoot else { return }
        let blocked = pullUsed || !gridAtTop || collapse > 0
        if router.pullBlocked != blocked { router.pullBlocked = blocked }
    }

    private func collapsed(_ value: CGFloat) {
        if value < collapse { pullUsed = true }
        collapse = value
        updatePull()
        if value >= titleHeight, monthOpen { withAnimation(Motion.bars) { monthOpen = false } }
        apply(compact: chrome.compact)
    }

    private func busyDays(_ rows: [Entry]) -> Set<Day> {
        var days = Set<Day>()
        for e in rows {
            if let s = e.start { days.insert(Day.of(s, in: .current)) }
            if let d = e.due { days.insert(d) }
        }
        return days
    }
}
