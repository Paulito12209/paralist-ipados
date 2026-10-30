// Zusammenhang: Pages/CalendarPage.swift (WeekStrip), ParalistCore Planning/WeekGrid.swift (Week.all, focus)
import ParalistCore
import SwiftUI

struct WeekPickerSheet: View {
    let selected: Day
    let today: Day
    let onPick: (Day) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var year: Int
    @State private var position: Week?

    init(selected: Day, today: Day, onPick: @escaping (Day) -> Void) {
        self.selected = selected
        self.today = today
        self.onPick = onPick
        _year = State(initialValue: Week.of(selected).isoYear)
        _position = State(initialValue: Week.of(selected))
    }

    var body: some View {
        let chosen = Week.of(selected)
        let current = Week.of(today)
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: Dimens.weekPillMin), spacing: 8)], spacing: 8) {
                    ForEach(Week.all(isoYear: year), id: \.self) { week in
                        pill(week, chosen: week == chosen, current: week == current).id(week)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(Dimens.pageEdge, for: .scrollContent)
            .scrollPosition(id: $position, anchor: .center)
            .onChange(of: year) { _, now in
                let weeks = Week.all(isoYear: now)
                position = [chosen, current].first(where: weeks.contains) ?? weeks.first
            }
            .background(Palette.surface)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { yearMenu }
            }
        }
    }

    private var yearMenu: some View {
        Menu {
            Picker(selection: $year) {
                ForEach(years, id: \.self) { Text(String($0)).tag($0) }
            } label: { EmptyView() }
        } label: {
            HStack(spacing: 6) {
                Text(String(year)).font(Typo.titleMedium).foregroundStyle(Palette.onSurface)
                Image(systemName: AppIcons.expandMore).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.onSurfaceVariant)
            }
        }
    }

    private var years: [Int] {
        let base = Week.of(today).isoYear
        return Array(Set(Array((base - 5)...(base + 5)) + [Week.of(selected).isoYear])).sorted()
    }

    private func pill(_ week: Week, chosen: Bool, current: Bool) -> some View {
        Button {
            onPick(week.focus(today: today))
            dismiss()
        } label: {
            Text(L.f("week_short", week.isoWeek))
                .font(Typo.labelLarge)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(chosen ? Palette.onPrimary : Palette.onSurface)
                .frame(maxWidth: .infinity, minHeight: Dimens.weekPill)
                .background(chosen ? Palette.primary : Palette.surfaceContainer, in: Capsule())
                .overlay { if current && !chosen { Capsule().stroke(Palette.primary, lineWidth: 1.5) } }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(chosen ? .isSelected : [])
    }
}
