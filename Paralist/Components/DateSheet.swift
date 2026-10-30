// Zusammenhang: Composer/ComposerSheet.swift, Entry/EntryPage.swift, Entry/ReminderSheet.swift, Components/EventTimeSheet.swift
import ParalistCore
import SwiftUI

struct DateSheet: View {
    let title: String
    let initial: Date
    var withTime = false
    var canClear = true
    let onDone: (Date?) -> Void
    @State private var date = Date()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if withTime {
                        DatePicker(title, selection: $date, in: Date()..., displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                        Divider()
                        DatePicker(L.s("composer_time"), selection: $date, in: Date()..., displayedComponents: [.hourAndMinute])
                            .font(Typo.bodyLarge)
                            .padding(.vertical, 12)
                    } else {
                        DatePicker(title, selection: $date, displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                    }
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if canClear {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(L.s("composer_date_clear"), role: .destructive) {
                            onDone(nil)
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L.s("dialog_ok")) {
                        onDone(date)
                        dismiss()
                    }
                    .buttonStyle(.glassProminent)
                }
            }
        }
        .onAppear { date = initial }
        .presentationDetents(withTime ? [.large] : [.medium, .large])
    }
}

struct TimeSheet: View {
    let initial: Date
    var canClear = true
    let onDone: (Date?) -> Void
    @State private var time = Date()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DatePicker(L.s("composer_time"), selection: $time, displayedComponents: [.hourAndMinute])
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .navigationTitle(L.s("composer_time"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if canClear {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(L.s("composer_time_clear"), role: .destructive) {
                                onDone(nil)
                                dismiss()
                            }
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(L.s("dialog_ok")) {
                            onDone(time)
                            dismiss()
                        }
                        .buttonStyle(.glassProminent)
                    }
                }
        }
        .onAppear { time = initial }
        .presentationDetents([.height(320)])
    }
}
