// Zusammenhang: ParalistCore Planning/XpLog.swift, Pages/ProgressChart.swift, Components/LevelRing.swift
import ParalistCore
import SwiftUI

struct ProgressPage: View {
    @Environment(AppModel.self) private var model
    @State private var range = 7

    var body: some View {
        let log = model.xpLog
        let total = XpLog.total(log)
        let info = XpLog.level(total)
        let kinds = XpLog.totalsByKind(log)
        let streak = XpLog.streak(log, today: model.today, zone: .current)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        ZStack {
                            Circle().stroke(Palette.surfaceHighest, lineWidth: 8)
                            Circle().trim(from: 0, to: info.progress).stroke(Palette.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round)).rotationEffect(.degrees(-90))
                            Text("\(info.level)").font(Typo.headlineMedium)
                        }
                        .frame(width: 88, height: 88)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L.f("progress_level", info.level)).font(Typo.titleLarge)
                            Text("\(total) " + L.s("progress_points")).font(Typo.bodyLarge).foregroundStyle(Palette.onSurfaceVariant)
                            if let to = info.to { Text(L.f("progress_next_level", to)).font(Typo.bodySmall).foregroundStyle(Palette.muted) }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(8)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                        stat("\(kinds[.created] ?? 0)", nil, L.s("progress_created"), Palette.level)
                        stat("\(kinds[.done] ?? 0)", nil, L.s("progress_done"), Palette.done)
                        stat("\(kinds[.reviewed] ?? 0)", nil, L.s("progress_reviewed"), Palette.reviewed)
                        stat("\(streak)", L.f("streak_days", streak).replacingOccurrences(of: "\(streak)", with: "").trimmingCharacters(in: .whitespaces), L.s("progress_streak"), Palette.error)
                    }
                }
                .padding(8)
                .background(Palette.tile, in: RoundedRectangle(cornerRadius: Dimens.cardRadius))
                sectionTitle("progress_chart_title")
                VStack(alignment: .leading, spacing: 12) {
                    Text(L.s("progress_chart_hint")).font(Typo.bodySmall).foregroundStyle(Palette.muted)
                    Picker("", selection: $range) {
                        Text(L.s("progress_range_7")).tag(7)
                        Text(L.s("progress_range_30")).tag(30)
                        Text(L.s("progress_range_90")).tag(90)
                    }
                    .pickerStyle(.segmented)
                    ProgressChart(values: XpLog.perDay(log, days: range, today: model.today, zone: .current), today: model.today)
                        .frame(height: 200)
                        .padding(.top, 16)
                }
                .padding(16)
                .background(Palette.tile, in: RoundedRectangle(cornerRadius: Dimens.cardRadius))
                sectionTitle("progress_rules_title")
                VStack(alignment: .leading, spacing: 0) {
                    rule(AppIcons.addCircle, Palette.level, "progress_created", L.f("progress_rule_created", 1, 5), detail: rulesDetail)
                    rule(AppIcons.task.outlined, Palette.done, "progress_done", L.f("progress_rule_done", XpLog.donePoints))
                    rule(AppIcons.school, Palette.reviewed, "progress_reviewed", L.f("progress_rule_reviewed", XpLog.reviewPoints))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
                .background(Palette.tile, in: RoundedRectangle(cornerRadius: Dimens.cardRadius))
                sectionTitle("progress_history")
                VStack(spacing: 0) {
                    ForEach(Array(log.prefix(30).enumerated()), id: \.offset) { item in
                        if item.offset > 0 { Divider().overlay(Palette.outlineVariant.opacity(0.4)).padding(.horizontal, 16) }
                        history(item.element)
                    }
                }
                .background(Palette.tile, in: RoundedRectangle(cornerRadius: Dimens.cardRadius))
            }
            .padding(.horizontal, Dimens.pageEdge)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .contentMargins(.top, 8, for: .scrollContent)
        .background(Palette.background)
        .navigationTitle(L.s("page_progress"))
        .navigationBarTitleDisplayMode(.large)
    }

    private var rulesDetail: String {
        "\(L.s("type_project")), \(L.s("type_area")) 5 · \(L.s("type_deck")) 3 · \(L.s("type_bookmark")), \(L.s("type_document")), \(L.s("type_file")) 2 · \(L.s("type_note")), \(L.s("type_task")) 1"
    }

    private func sectionTitle(_ key: String) -> some View {
        Text(L.s(key)).font(Typo.titleSmall).foregroundStyle(Palette.muted).padding(.leading, 8).padding(.top, 24).padding(.bottom, 8)
    }

    private func stat(_ value: String, _ unit: String?, _ label: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value).font(Typo.titleLarge)
                if let unit, !unit.isEmpty { Text(unit).font(Typo.bodyMedium) }
            }
            .foregroundStyle(tint)
            Text(label).font(Typo.bodySmall).foregroundStyle(Palette.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(tint.opacity(Dimens.tileTintAlpha), in: RoundedRectangle(cornerRadius: Dimens.tileRadius))
    }

    private func rule(_ icon: String, _ tint: Color, _ label: String, _ text: String, detail: String? = nil) -> some View {
        HStack(alignment: .top, spacing: 12) {
            AppIcons.image(icon).resizable().scaledToFit().frame(width: 20, height: 20).foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(L.s(label)).font(Typo.labelLarge)
                Text(text).font(Typo.bodySmall).foregroundStyle(Palette.onSurfaceVariant)
                if let detail { Text(detail).font(Typo.bodySmall).foregroundStyle(Palette.muted) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16).padding(.vertical, 10)
    }

    private func history(_ event: XpEvent) -> some View {
        let (icon, tint, label): (String, Color, String) = {
            switch event.kind {
            case .created: return (AppIcons.addCircle, Palette.level, L.s("progress_created"))
            case .done: return (AppIcons.task.outlined, Palette.done, L.s("progress_done"))
            case .reviewed: return (AppIcons.school, Palette.reviewed, L.s("progress_reviewed"))
            }
        }()
        return HStack(spacing: 12) {
            AppIcons.image(icon).resizable().scaledToFit().frame(width: 20, height: 20).foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title.isEmpty ? label : event.title).font(Typo.bodyMedium).lineLimit(1)
                Text([L.dateTime(event.at), event.type.map { L.s(TypeLook.of($0).label) }].compactMap { $0 }.joined(separator: " · "))
                    .font(Typo.bodySmall).foregroundStyle(Palette.muted)
            }
            Spacer()
            Text("+\(event.amount)").font(Typo.labelLarge).foregroundStyle(Palette.primary)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}
