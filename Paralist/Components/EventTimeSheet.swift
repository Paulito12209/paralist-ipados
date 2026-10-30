// Zusammenhang: Composer/ComposerParts.swift, Entry/EntryParts.swift, Intents/NewEntryIntent.swift, ParalistCore Planning/DayPeriods.swift (EventTimes), Library/ComposerDraft.swift
import ParalistCore
import SwiftUI

enum EventLabel {
    static func of(start: Date, end: Date?, allDay: Bool) -> String {
        let day = Day.of(start, in: .current)
        if allDay { return L.date(day) }
        let finish = EventTimes.end(start: start, end: end)
        let last = Day.of(finish, in: .current)
        if last == day { return L.date(day) + " " + L.time(start) + "–" + L.time(finish) }
        return L.date(day) + " " + L.time(start) + " – " + L.date(last) + " " + L.time(finish)
    }

    static func suggestedStart(on day: Day? = nil) -> Date {
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let base = day ?? Day.of(now, in: .current)
        return base.at(hour: min(hour + 1, 23), in: .current)
    }
}

struct EventTimeSheet: View {
    var canClear = true
    let onDone: (Date?, Date?, Bool) -> Void
    @State private var from: Date
    @State private var to: Date
    @State private var allDay: Bool
    @Environment(\.dismiss) private var dismiss

    init(start: Date, end: Date?, allDay: Bool, canClear: Bool = true, onDone: @escaping (Date?, Date?, Bool) -> Void) {
        self.canClear = canClear
        self.onDone = onDone
        _from = State(initialValue: start)
        _to = State(initialValue: EventTimes.end(start: start, end: end))
        _allDay = State(initialValue: allDay)
    }

    var body: some View {
        NavigationStack {
            Form {
                Toggle(L.s("cal_all_day"), isOn: $allDay)
                DatePicker(L.s("event_start"), selection: $from, displayedComponents: allDay ? [.date] : [.date, .hourAndMinute])
                if !allDay {
                    DatePicker(L.s("event_end"), selection: $to, in: from.addingTimeInterval(60)..., displayedComponents: [.date, .hourAndMinute])
                }
            }
            .tint(Palette.primary)
            .onChange(of: from) { old, new in to = EventTimes.moved(end: to, from: old, to: new) }
            .navigationTitle(L.s("composer_date"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if canClear {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(L.s("composer_date_clear"), role: .destructive) {
                            onDone(nil, nil, false)
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L.s("dialog_ok")) {
                        if allDay {
                            onDone(Day.of(from, in: .current).startOfDay(in: .current), nil, true)
                        } else {
                            onDone(from, EventTimes.end(start: from, end: to), false)
                        }
                        dismiss()
                    }
                    .buttonStyle(.glassProminent)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
