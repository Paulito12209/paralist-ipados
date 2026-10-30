// Zusammenhang: Pages/CalendarParts.swift (CalendarGrid), ParalistCore Planning/CalendarLayout.swift (CalendarStrip, StripItem), Entries/TypeLook.swift (TypeLook, StatusLook), Theme/Dimens.swift
import ParalistCore
import SwiftUI

struct CalendarStripRow: View {
    let days: [Day]
    let rows: [Entry]
    let onOpen: (String) -> Void
    @State private var scrolled = false

    var body: some View {
        let byId = Dictionary(rows.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let items = days.map { CalendarStrip.items(rows, day: $0, zone: .current) }
        let total = items.reduce(0) { $0 + $1.count }
        if total > 0 {
            HStack(alignment: days.count == 1 ? .center : .top, spacing: 0) {
                badge(total)
                if days.count == 1 {
                    dayPills(items[0], byId)
                } else {
                    weekChips(items, byId)
                }
            }
            .padding(.vertical, Dimens.stripGap)
        } else {
            Color.clear.frame(height: Dimens.stripGap)
        }
    }

    private func badge(_ total: Int) -> some View {
        Text("\(total)")
            .font(Typo.dm(12, .semibold))
            .foregroundStyle(Palette.onSurfaceVariant)
            .frame(minWidth: Dimens.stripBadge, minHeight: Dimens.stripBadge)
            .background(Palette.calendarBadge, in: Capsule())
            .padding(.leading, Dimens.pageEdge)
            .padding(.top, days.count == 1 ? 0 : 2)
            .frame(width: Dimens.calendarGutter, alignment: .leading)
            .accessibilityLabel(L.f("cal_strip_count", total))
    }

    private func dayPills(_ items: [StripItem], _ byId: [String: Entry]) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(items) { item in
                    if let entry = byId[item.id] { pill(entry, L.s(item.labelKey)) }
                }
            }
            .padding(.trailing, Dimens.pageEdge)
        }
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: Bool.self) { $0.contentOffset.x + $0.contentInsets.leading > 1 } action: { _, now in
            withAnimation(Motion.short) { scrolled = now }
        }
        .mask {
            HStack(spacing: 0) {
                LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                    .frame(width: scrolled ? Dimens.stripFade : 0)
                Color.black
            }
        }
    }

    private func weekChips(_ items: [[StripItem]], _ byId: [String: Entry]) -> some View {
        HStack(alignment: .top, spacing: 2) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, dayItems in
                VStack(spacing: 2) {
                    ForEach(dayItems.prefix(Dimens.stripChipMax)) { item in
                        if let entry = byId[item.id] { chip(entry) }
                    }
                    if dayItems.count > Dimens.stripChipMax {
                        Text(L.f("cal_more", dayItems.count - Dimens.stripChipMax)).font(Typo.labelSmall).foregroundStyle(Palette.muted)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.trailing, Dimens.calendarTrail)
    }

    private func pill(_ e: Entry, _ label: String) -> some View {
        Button { onOpen(e.id) } label: {
            HStack(spacing: 10) {
                icon(e)
                Text(e.title.isEmpty ? L.s("list_untitled") : e.title).font(Typo.bodyMedium).foregroundStyle(Palette.onSurface).lineLimit(1)
                Text(label).font(Typo.labelSmall).foregroundStyle(Palette.muted).lineLimit(1).fixedSize()
            }
            .padding(.horizontal, 12)
            .frame(height: Dimens.stripPillHeight)
            .frame(maxWidth: Dimens.stripPillMax)
            .background(Palette.calendarPill, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func chip(_ e: Entry) -> some View {
        let look = TypeLook.of(e.type)
        return Button { onOpen(e.id) } label: {
            Text(e.title.isEmpty ? L.s("list_untitled") : e.title)
                .font(Typo.labelSmall)
                .foregroundStyle(Palette.onSurface)
                .lineLimit(1)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, minHeight: Dimens.stripChipHeight, alignment: .leading)
                .background(look.color.opacity(0.22), in: RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func icon(_ e: Entry) -> some View {
        if let status = e.status, status != .open {
            let look = StatusLook.of(status, for: e.type)
            Image(systemName: look.icon).font(.system(size: 16)).foregroundStyle(look.color)
        } else {
            let look = TypeLook.of(e.type)
            GlyphIcon(look.icon.outlined, size: 16).foregroundStyle(look.color)
        }
    }
}
