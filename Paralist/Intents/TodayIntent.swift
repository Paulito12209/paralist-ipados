// Zusammenhang: Paralist/Intents/ParalistShortcuts.swift, Paralist/App/AppModel.swift, Paralist/App/AppPrefs.swift (lockScreenDetails), Paralist/App/L.swift, ParalistCore Planning/TodayDigest.swift
import AppIntents
import ParalistCore
import UIKit

struct TodayIntent: AppIntent {
    static let title: LocalizedStringResource = "siri_today_title"
    static let description = IntentDescription("siri_today_description")
    static let supportedModes: IntentModes = .background

    @Dependency
    var model: AppModel

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        if !model.prefs.lockScreenDetails && !UIApplication.shared.isProtectedDataAvailable {
            return .result(dialog: IntentDialog("\(L.s("siri_today_locked"))"))
        }
        model.reload()
        let digest = TodayDigest.build(model.all, today: model.today, zone: .current)
        return .result(dialog: IntentDialog("\(Self.speech(digest))"))
    }

    static func speech(_ digest: TodayDigest) -> String {
        guard !digest.isEmpty else { return L.s("siri_today_empty") }
        var parts = digest.items.map(line)
        if digest.more > 0 { parts.append(L.f("siri_today_more", digest.more)) }
        return L.f("siri_today_list", parts.formatted(.list(type: .and).locale(L.locale)))
    }

    private static func line(_ item: TodayDigest.Item) -> String {
        let title = item.entry.title.isEmpty ? L.s("list_untitled") : item.entry.title
        switch item {
        case .event(_, let time?): return L.f("siri_today_at", L.time(time), title)
        case .event: return title
        case .task(_, overdue: true): return L.f("siri_today_overdue", title)
        case .task: return title
        }
    }
}
