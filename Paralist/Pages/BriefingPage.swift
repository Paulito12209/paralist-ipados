// Zusammenhang: ParalistCore Planning/WeekBriefing.swift, App/AppModel.swift (weekBriefing), Pages/BriefingCover.swift, Pages/BriefingWeekBar.swift, Shell/AppSheets.swift, Shell/Router.swift (openBriefing), Entries/TypeLook.swift
import ParalistCore
import SwiftUI

struct BriefingPage: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @State private var week: Week?

    var body: some View {
        let current = week ?? WeekBriefingBuilder.weekFor(model.today)
        let b = model.weekBriefing(for: current)
        let seen = model.prefs.briefingSeenWeek == Week.of(model.today).monday.epochDay
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                BriefingCover(week: current.isoWeek, seen: seen)
                summary(current, b)
                VStack(alignment: .leading, spacing: BriefingDimens.sectionGap) {
                    if !b.deadlines.isEmpty {
                        section(AppIcons.project.outlined, Palette.error, "briefing_deadlines") {
                            ForEach(b.deadlines, id: \.entry.id) { row($0.entry, meta: L.date($0.date), overdue: $0.overdue) }
                        }
                    }
                    section(AppIcons.calendar.outlined, TypeLook.of(.event).color, "briefing_events") { events(b) }
                    section(AppIcons.tasks.outlined, TypeLook.of(.task).color, "briefing_tasks") {
                        if b.tasks.isEmpty { empty("briefing_no_tasks") }
                        ForEach(b.tasks, id: \.entry.id) { t in row(t.entry, meta: t.overdue ? L.s("briefing_overdue") : L.date(t.date), overdue: t.overdue) }
                    }
                    section(AppIcons.addCircle, Palette.primary, "briefing_created") { created(b) }
                }
                .padding(.top, 28)
                .padding(.bottom, BriefingDimens.barHeight + 40)
            }
        }
        .scrollIndicators(.hidden)
        .background(Palette.surface)
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .bottom) { BriefingWeekBar.fade.padding(.bottom, -BriefingDimens.barFade) }
        .overlay(alignment: .bottom) {
            BriefingWeekBar(week: current) { week = current.previous() } next: { week = current.next() } close: { router.briefingOpen = false }
        }
    }

    private func summary(_ week: Week, _ b: WeekBriefing) -> some View {
        let range = week.monday.at(hour: 12, in: .current)..<week.sunday.at(hour: 12, in: .current)
        let newCount = b.createdCounts.values.reduce(0, +)
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Text(range.formatted(Date.IntervalFormatStyle(date: .long, time: .omitted).locale(L.locale)))
                    .font(Typo.bodyLarge).foregroundStyle(Palette.onSurfaceVariant)
                    .padding(.trailing, 6)
                if b.eventCount > 0 { chip(L.f("briefing_events_count", b.eventCount)) }
                if !b.tasks.isEmpty { chip(L.f("chat_draft_tasks", b.tasks.count)) }
                if newCount > 0 { chip(L.f("briefing_created_count", newCount)) }
            }
            .padding(.horizontal, BriefingDimens.edge)
        }
        .padding(.top, 18)
    }

    private func chip(_ text: String) -> some View {
        Text(text).font(Typo.bodyMedium).foregroundStyle(Palette.onSurface)
            .padding(.horizontal, 12).frame(height: BriefingDimens.chipHeight)
            .overlay(Capsule().stroke(Palette.outlineVariant, lineWidth: 1))
    }

    @ViewBuilder
    private func events(_ b: WeekBriefing) -> some View {
        if b.eventCount == 0 { empty("briefing_no_events") }
        ForEach(b.days.filter { !$0.events.isEmpty }, id: \.date) { day in
            HStack(spacing: 6) {
                Text(day.date.at(hour: 12, in: .current).formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(L.locale)))
                if day.date == model.today { Text(L.s("cal_today")).foregroundStyle(Palette.primary) }
            }
            .font(Typo.bodyMedium).foregroundStyle(Palette.muted)
            .padding(.horizontal, BriefingDimens.edge).padding(.top, 6)
            ForEach(day.events) { e in row(e, meta: span(e)) }
        }
    }

    @ViewBuilder
    private func created(_ b: WeekBriefing) -> some View {
        if b.createdCounts.isEmpty { empty("briefing_no_created") } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(EntryType.allCases.filter { b.createdCounts[$0] != nil }, id: \.self) { type in
                        HStack(spacing: 6) {
                            GlyphIcon(TypeLook.of(type).icon.outlined, size: 14).foregroundStyle(TypeLook.of(type).color)
                            Text("\(b.createdCounts[type] ?? 0) " + L.s(TypeLook.of(type).label)).font(Typo.labelMedium)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Palette.surfaceContainer, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, BriefingDimens.edge)
            }
        }
        ForEach(b.created) { e in row(e, meta: e.created.formatted(.dateTime.day().month(.abbreviated).locale(L.locale))) }
    }

    private func span(_ e: Entry) -> String {
        guard !e.allDay, let start = e.start else { return L.s("cal_all_day") }
        guard let end = e.end, end > start else { return L.time(start) }
        return L.time(start) + " – " + L.time(end)
    }

    private func section<Content: View>(_ icon: String, _ tint: Color, _ key: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 14) {
                GlyphIcon(icon, size: BriefingDimens.headerIcon).foregroundStyle(tint)
                Text(L.s(key)).font(Typo.dm(22, .semibold, relativeTo: .title2)).foregroundStyle(Palette.onSurface)
            }
            .padding(.horizontal, BriefingDimens.edge).padding(.bottom, 4)
            content()
        }
    }

    private func empty(_ key: String) -> some View {
        Text(L.s(key)).font(Typo.bodyLarge).foregroundStyle(Palette.muted)
            .padding(.horizontal, BriefingDimens.edge)
    }

    private func row(_ e: Entry, meta: String, overdue: Bool = false) -> some View {
        Button { router.openFromBriefing(.entry(e.id)) } label: {
            HStack(spacing: 16) {
                GlyphIcon(TypeLook.of(e.type).icon.outlined, size: BriefingDimens.rowIcon).foregroundStyle(Palette.onSurfaceVariant)
                Text(e.title.isEmpty ? L.s("list_untitled") : e.title).font(Typo.dm(17)).foregroundStyle(Palette.onSurface).lineLimit(1)
                Spacer(minLength: 8)
                Text(meta).font(Typo.bodyLarge).foregroundStyle(overdue ? Palette.error : Palette.muted).lineLimit(1)
            }
            .padding(.horizontal, BriefingDimens.edge)
            .frame(height: BriefingDimens.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
