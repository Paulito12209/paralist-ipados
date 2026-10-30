// Zusammenhang: ParalistCore Planning/ReminderPlanner.swift, Composer/ComposerParts.swift, Entry/EntryPage.swift, Components/DateSheet.swift
import ParalistCore
import SwiftUI

struct ReminderSheet: View {
    @Binding var reminders: [Date]
    let eventStart: Date?
    @Binding var offset: EventOffset
    @State private var picking = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let eventStart {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(EventOffset.allCases, id: \.self) { option in
                                    Button { choose(option, eventStart) } label: {
                                        Text(L.s(label(option))).font(Typo.labelLarge)
                                            .padding(.horizontal, 14).frame(height: 32)
                                            .background(offset == option ? Palette.secondaryContainer : .clear, in: Capsule())
                                            .overlay { if offset != option { Capsule().stroke(Palette.outlineVariant) } }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
                Section {
                    ForEach(Array(ReminderPlanner.quickChoices(now: Date(), zone: .current).enumerated()), id: \.offset) { item in
                        let choice = item.element
                        Button { add(choice.1) } label: {
                            HStack(spacing: 16) {
                                Image(systemName: AppIcons.bell.outlined).foregroundStyle(Palette.onSurfaceVariant)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(L.s(quickLabel(choice.0))).font(Typo.bodyLarge).foregroundStyle(Palette.onSurface)
                                    Text(L.dateTime(choice.1)).font(Typo.bodySmall).foregroundStyle(Palette.muted)
                                }
                            }
                        }
                    }
                    Button { picking = true } label: {
                        Label(L.s("reminder_pick_time"), systemImage: AppIcons.event).font(Typo.bodyLarge).foregroundStyle(Palette.onSurface)
                    }
                }
                if !reminders.isEmpty {
                    Section(L.s("reminder_bell")) {
                        ForEach(reminders, id: \.self) { at in
                            HStack(spacing: 16) {
                                Image(systemName: AppIcons.bell.filled).foregroundStyle(Palette.primary)
                                Text(L.dateTime(at)).font(Typo.bodyLarge)
                                Spacer()
                                Button { reminders.removeAll { $0 == at } } label: { Image(systemName: AppIcons.close) }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(L.s("reminder_remove"))
                            }
                        }
                    }
                }
            }
            .navigationTitle(L.s("reminder_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: AppIcons.check) }
                }
            }
            .sheet(isPresented: $picking) {
                DateSheet(title: L.s("reminder_pick_time"), initial: Day.of(Date(), in: .current).adding(days: 1).at(hour: 9, in: .current), withTime: true, canClear: false) { date in
                    if let date { add(date) }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func add(_ at: Date) {
        if !reminders.contains(at) { reminders = (reminders + [at]).sorted() }
    }

    private func choose(_ option: EventOffset, _ start: Date) {
        if let old = offset.before(start) { reminders.removeAll { $0 == old } }
        offset = option
    }

    private func label(_ option: EventOffset) -> String {
        switch option {
        case .none: return "reminder_none"
        case .min5: return "reminder_before_5"
        case .min15: return "reminder_before_15"
        case .hour1: return "reminder_before_60"
        case .day1: return "reminder_before_day"
        }
    }

    private func quickLabel(_ q: QuickReminder) -> String {
        switch q {
        case .tonight: return "reminder_tonight"
        case .lateTonight: return "reminder_late_tonight"
        case .tomorrowMorning: return "reminder_tomorrow"
        case .weekEnd: return "reminder_week_end"
        case .weekStart: return "reminder_week_start"
        }
    }
}
