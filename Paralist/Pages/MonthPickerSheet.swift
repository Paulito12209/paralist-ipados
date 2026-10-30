// Zusammenhang: Pages/CalendarPage.swift (dateRow, MonthStrip), ParalistCore Planning/CalendarLayout.swift (Day.moved), Theme/Dimens.swift
import ParalistCore
import SwiftUI

struct MonthPickerSheet: View {
    let selected: Day
    let today: Day
    let onPick: (Int, Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var year: Int

    init(selected: Day, today: Day, onPick: @escaping (Int, Int) -> Void) {
        self.selected = selected
        self.today = today
        self.onPick = onPick
        _year = State(initialValue: selected.year)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(L.s("cal_pick_date")).font(Typo.titleLarge).foregroundStyle(Palette.onSurface)
            HStack(spacing: 24) {
                Spacer(minLength: 0)
                arrow(AppIcons.chevronLeft, "cal_year_previous") { year -= 1 }
                Text(String(year)).font(Typo.dm(24)).foregroundStyle(Palette.onSurface).frame(minWidth: 80)
                arrow(AppIcons.chevronRight, "cal_year_next") { year += 1 }
                Spacer(minLength: 0)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(1...12, id: \.self) { month in pill(month) }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.surface)
    }

    private func arrow(_ icon: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.onSurfaceVariant)
                .frame(width: Dimens.touchTarget, height: Dimens.touchTarget)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L.s(label))
    }

    private func pill(_ month: Int) -> some View {
        let chosen = year == selected.year && month == selected.month
        let current = year == today.year && month == today.month
        return Button {
            onPick(year, month)
            dismiss()
        } label: {
            Text(name(month))
                .font(Typo.labelLarge)
                .foregroundStyle(chosen ? Palette.onPrimary : Palette.onSurface)
                .frame(maxWidth: .infinity, minHeight: Dimens.monthPillHeight)
                .background(chosen ? Palette.primary : .clear, in: Capsule())
                .overlay { if current && !chosen { Capsule().stroke(Palette.primary, lineWidth: 1.5) } }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(chosen ? .isSelected : [])
    }

    private func name(_ month: Int) -> String {
        Day(year: year, month: month, day: 1).at(hour: 12, in: .current).formatted(.dateTime.month(.abbreviated).locale(L.locale))
    }
}
