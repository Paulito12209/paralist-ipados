// Zusammenhang: Pages/ProgressPage.swift, ParalistCore Planning/XpLog.swift (perDay)
import Charts
import ParalistCore
import SwiftUI

struct ProgressChart: View {
    let values: [Int]
    let today: Day

    var body: some View {
        let start = today.adding(days: -(values.count - 1))
        let points = values.enumerated().map { ChartPoint(day: start.adding(days: $0.offset).at(hour: 12, in: .current), value: $0.element) }
        Chart(points) { point in
            BarMark(x: .value("Tag", point.day, unit: .day), y: .value("XP", point.value), width: .ratio(0.6))
                .foregroundStyle(Palette.primary)
                .cornerRadius(9)
        }
        .chartYScale(domain: 0...max(5, (values.max() ?? 0)))
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: values.count <= 7 ? 1 : (values.count <= 30 ? 7 : 30))) { value in
                if values.count <= 7 {
                    AxisValueLabel(centered: true) { if let date = value.as(Date.self) { Text(Self.weekday(date)) } }
                } else {
                    AxisValueLabel(format: Date.FormatStyle.dateTime.day().month(.defaultDigits).locale(L.locale))
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { _ in
                AxisGridLine().foregroundStyle(Palette.outlineVariant.opacity(0.6))
                AxisValueLabel()
            }
        }
    }
}

extension ProgressChart {
    static func weekday(_ date: Date) -> String {
        if L.locale.language.languageCode?.identifier == "de" {
            return String(date.formatted(.dateTime.weekday(.abbreviated).locale(L.locale)).replacingOccurrences(of: ".", with: "").prefix(2))
        }
        return date.formatted(.dateTime.weekday(.narrow).locale(L.locale))
    }
}

struct ChartPoint: Identifiable {
    let day: Date
    let value: Int
    var id: Date { day }
}
