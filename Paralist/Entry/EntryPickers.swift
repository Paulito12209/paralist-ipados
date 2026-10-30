// Zusammenhang: Entry/EntryCanvasPanel.swift, Entry/EntryParts.swift (EntrySheets), Entry/EntryActions.swift (EntryActionButtons), Pages/OverviewParts.swift (OverviewHead), Entries/TypeLook.swift (StatusLook, TagKindLook), Components/EventTimeSheet.swift, ParalistCore Library/EntryParent.swift, Entry/LinkSheet.swift (EntryPlaceSheet), Theme/Dimens.swift
import ParalistCore
import SwiftUI

struct CanvasPicker: View {
    var icon: String?
    var tint: Color?
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            if let icon { GlyphIcon(icon, size: 15).foregroundStyle(tint ?? Palette.onSurfaceVariant) }
            Text(label).foregroundStyle(Palette.onSurface).lineLimit(1)
            Image(systemName: AppIcons.expandMore).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.onSurfaceVariant)
        }
        .font(Typo.dm(16, .medium))
        .padding(.horizontal, 14)
        .frame(height: OverviewDimens.tabHeight)
        .background(Palette.tabActive, in: Capsule())
        .contentShape(Capsule())
    }
}

struct PlaceRow: View {
    let entry: Entry
    @Binding var sheet: EntrySheet?
    @Environment(AppModel.self) private var model

    var body: some View {
        Button { sheet = .place } label: { CanvasPicker(label: placeLabel) }
            .buttonStyle(.plain)
            .accessibilityLabel(L.s("composer_place_title"))
            .padding(.horizontal, Dimens.entryPlaceInset)
            .frame(maxWidth: .infinity)
    }

    private var placeLabel: String {
        if let place = entry.places.first.flatMap({ model.entry($0) }) {
            return place.title.isEmpty ? L.s("list_untitled") : place.title
        }
        return ChoiceItem.noPlace(for: entry.type).label
    }
}

struct EntryDateCard: View {
    let entry: Entry
    @Binding var sheet: EntrySheet?

    static func shows(_ entry: Entry) -> Bool { entry.type.hasDate }

    var body: some View {
        HStack(spacing: 0) {
            Button { sheet = .date } label: { half(AppIcons.dateSet, dateLabel ?? L.s("composer_date"), set: dateLabel != nil) }
            Rectangle().fill(Palette.cardStroke).frame(width: Dimens.canvasCardStroke).padding(.vertical, 12)
            Button { sheet = entry.type == .event ? .date : .time } label: { half(AppIcons.schedule, timeLabel ?? L.s("composer_time"), set: timeLabel != nil) }
                .disabled(entry.type != .event && entry.due == nil)
        }
        .buttonStyle(.plain)
        .frame(minHeight: Dimens.entryToggleHeight)
        .canvasCard()
        .padding(.horizontal, Dimens.entryInset)
        .padding(.top, Dimens.canvasCardGap)
    }

    private func half(_ icon: String, _ text: String, set: Bool) -> some View {
        HStack(spacing: 12) {
            GlyphIcon(icon, size: 18).foregroundStyle(Palette.onSurfaceVariant)
            Text(text).font(Typo.bodyLarge).foregroundStyle(set ? Palette.onSurface : Palette.muted).lineLimit(1).minimumScaleFactor(0.8)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Dimens.canvasCardPad)
        .frame(maxWidth: .infinity, minHeight: Dimens.entryToggleHeight)
        .contentShape(Rectangle())
    }

    private var dateLabel: String? {
        if let due = entry.due { return L.date(due) }
        if let start = entry.start { return L.date(Day.of(start, in: .current)) }
        return nil
    }

    private var timeLabel: String? {
        if entry.type == .event {
            guard let start = entry.start else { return nil }
            if entry.allDay { return L.s("cal_all_day") }
            let finish = EventTimes.end(start: start, end: entry.end)
            return L.time(start) + "–" + L.time(finish)
        }
        guard entry.dueTime != nil else { return nil }
        return entry.dueDate(in: .current).map(L.time)
    }
}
