// Zusammenhang: Entries/EntryRow.swift, Entries/TypeLook.swift, App/L.swift, Icons/AppIcons.swift, Search/SearchResultRow.swift, Theme/Dimens.swift, ParalistCore Library/EntryCaption.swift, Resources/Assets.xcassets/LinkLogos
import ParalistCore
import SwiftUI
import UIKit

struct CaptionLine: View {
    let caption: EntryCaption?
    let text: Text

    var body: some View {
        HStack(spacing: Dimens.rowLogoGap) {
            if let logo = EntrySubtitle.logo(caption) {
                Image(logo).resizable().scaledToFit()
                    .frame(width: Dimens.rowLogo, height: Dimens.rowLogo)
                    .clipShape(RoundedRectangle(cornerRadius: Dimens.rowLogoRadius, style: .continuous))
                    .accessibilityHidden(true)
            }
            text
        }
    }
}

enum EntrySubtitle {
    static func label(_ caption: EntryCaption?) -> String? {
        switch caption {
        case .type(let type): return L.s(TypeLook.of(type).label)
        case .brand(let name, _): return name
        case .domain(let host): return host
        case .file(let kind): return L.s(fileKey(kind))
        case nil: return nil
        }
    }

    static func logo(_ caption: EntryCaption?) -> String? {
        guard case .brand(_, let logos) = caption else { return nil }
        return logos.first { UIImage(named: $0) != nil }
    }

    private static func fileKey(_ kind: FileKindLabel) -> String {
        switch kind {
        case .photo: return "create_photo"
        case .video: return "create_video"
        case .audio: return "create_audio"
        case .pdf: return "file_kind_pdf"
        case .file: return "type_file"
        }
    }

    static func text(_ entry: Entry, typeLabel: String?) -> Text {
        let today = Day.of(Date(), in: .current)
        let created = L.f("entry_created_on", dayText(Day.of(entry.created, in: .current), today: today))
        let base = [typeLabel, created].compactMap { $0 }.joined(separator: " · ")
        guard let when = whenLabel(entry, today: today) else { return Text(base) }
        return Text("\(base) · \(Image(systemName: AppIcons.dateSet)) \(when)")
    }

    static func whenLabel(_ entry: Entry, today: Day) -> String? {
        if entry.type == .event, let start = entry.start {
            let day = dayText(Day.of(start, in: .current), today: today, relative: true)
            return entry.allDay ? day : day + " " + L.time(start)
        }
        guard let due = entry.due else { return nil }
        let day = dayText(due, today: today, relative: true)
        guard entry.dueTime != nil, let date = entry.dueDate(in: .current) else { return day }
        return day + " " + L.time(date)
    }

    private static func dayText(_ day: Day, today: Day, relative: Bool = false) -> String {
        if relative && day == today { return L.s("cal_today") }
        if relative && day == today.adding(days: 1) { return L.s("date_tomorrow") }
        var style = Date.FormatStyle(locale: L.locale).day().month(.abbreviated)
        if day.year != today.year { style = style.year() }
        return day.at(hour: 12, in: .current).formatted(style)
    }
}
