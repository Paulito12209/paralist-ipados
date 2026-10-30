// Zusammenhang: Composer/ComposerSheet.swift (Karte, Datumsknopf), Entry/EntryPickers.swift (EntryDateCard als Vorbild), ParalistCore Library/ComposerDraft.swift, App/L.swift, Theme/Dimens.swift (ComposerDimens)
import ParalistCore
import SwiftUI

struct ComposerDateRow: View {
    @Binding var draft: ComposerDraft
    var onReminders: () -> Void = {}

    var body: some View {
        if let day = draft.date {
            HStack(spacing: 0) {
                half(AppIcons.dateSet) {
                    field(L.date(day), set: true, selection: dayBinding(day), components: .date)
                }
                Rectangle().fill(Palette.cardStroke).frame(width: Dimens.canvasCardStroke, height: ComposerDimens.dateDivider)
                half(AppIcons.schedule) {
                    timeFields
                }
                .padding(.leading, ComposerDimens.dateGap)
                if draft.type != .event {
                    Button(action: onReminders) {
                        Image(systemName: draft.reminders.isEmpty ? AppIcons.bell.outlined : AppIcons.bell.filled)
                            .font(.system(size: 15))
                            .foregroundStyle(draft.reminders.isEmpty ? Palette.onSurfaceVariant : Palette.primary)
                            .frame(width: ComposerDimens.dateRow, height: ComposerDimens.dateRow)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L.s("reminder_bell"))
                }
            }
            .font(Typo.bodyLarge)
            .lineLimit(1)
            .frame(minHeight: ComposerDimens.dateRow)
        }
    }

    @ViewBuilder private var timeFields: some View {
        if let start = draft.time(zone: .current) {
            HStack(spacing: ComposerDimens.dateSpanGap) {
                field(L.time(start), set: true, selection: Binding(get: { start }, set: { draft.setTime($0, zone: .current) }), components: .hourAndMinute)
                if draft.type == .event, let end = draft.end(zone: .current) {
                    Text("–").foregroundStyle(Palette.onSurfaceVariant).fixedSize()
                    field(L.time(end), set: true, selection: Binding(get: { end }, set: { draft.setEnd($0, zone: .current) }), components: .hourAndMinute)
                }
            }
            Spacer(minLength: 0)
            Button { draft.setTime(nil, zone: .current) } label: {
                Image(systemName: AppIcons.close).font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Palette.onSurfaceVariant)
                    .frame(width: ComposerDimens.dateClear, height: ComposerDimens.dateClear)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L.s("composer_time_clear"))
        } else {
            Button { suggestTime() } label: {
                Text(L.s("composer_time")).foregroundStyle(Palette.muted)
                    .frame(maxWidth: .infinity, minHeight: ComposerDimens.dateRow, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func suggestTime() {
        guard let day = draft.date else { return }
        draft.setTime(day.at(hour: ComposerDraft.nextHour(Date(), zone: .current) / 60, in: .current), zone: .current)
    }

    private func half<Content: View>(_ icon: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: ComposerDimens.dateIconGap) {
            GlyphIcon(icon, size: 18).foregroundStyle(Palette.onSurfaceVariant)
            content()
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func dayBinding(_ day: Day) -> Binding<Date> {
        Binding(get: { day.at(hour: 12, in: .current) }, set: { draft.setDay(Day.of($0, in: .current), zone: .current) })
    }

    private func field(_ text: String, set: Bool, selection: Binding<Date>, components: DatePickerComponents) -> some View {
        Text(text)
            .foregroundStyle(set ? Palette.onSurface : Palette.muted)
            .overlay {
                DatePicker(text, selection: selection, displayedComponents: components)
                    .labelsHidden()
                    .colorMultiply(.clear)
            }
            .fixedSize()
    }
}
