// Zusammenhang: App/AppPaths.swift, Entry/EntryHero.swift, App/AppModel.swift, Pages/SettingsPage.swift, Pages/MenuPage.swift, Pages/TasksPage.swift, Chat/ChatListPage.swift (chatView), Shell/TabSlotMenu.swift (tabOrder), Shell/AppTabBar.swift (tabLabels, navHintSeen, chatHintSeen), Pages/SettingsNavigation.swift, ParalistCore Planning/DayPeriods.swift, ParalistCore Library/TaskView.swift, Library/TabBarOrder.swift, Library/OverviewLayout.swift (overviewLayout), Pages/OverviewPage.swift, Pages/ViewSheet.swift (entryView), Entries/EmptyViews.swift (emptyInfoHidden)
import Foundation
import Observation
import ParalistCore
import SwiftUI

enum ThemeMode: String, CaseIterable {
    case system = "SYSTEM", light = "LIGHT", dark = "DARK"

    var scheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum BriefingSchedule: String, CaseIterable {
    case off = "aus", sunday = "sonntag", monday = "montag"
}

@MainActor
@Observable
final class AppPrefs {
    private let defaults: UserDefaults

    var themeMode: ThemeMode { didSet { defaults.set(themeMode.rawValue, forKey: "theme_mode") } }
    var language: AppLanguage {
        didSet {
            defaults.set(language.tag, forKey: "app_language")
            UserDefaults.standard.set([language == .chinese ? "zh-Hans" : language.tag], forKey: "AppleLanguages")
            L.apply(language)
        }
    }
    var profileName: String { didSet { defaults.set(profileName, forKey: "profile_name") } }
    var joinedDay: Day
    var markedList: ListKind { didSet { defaults.set(markedList.key, forKey: "marked_list") } }
    var overviewList: ListKind { didSet { defaults.set(overviewList.key, forKey: "overview_list") } }
    var overviewLayout: OverviewLayout { didSet { defaults.set(overviewLayout.encoded, forKey: "overview_tabs") } }
    var overviewHintSeen: Bool { didSet { defaults.set(overviewHintSeen, forKey: "overview_edge_hint_seen") } }
    var emptyInfoHidden: Bool { didSet { defaults.set(emptyInfoHidden, forKey: "empty_info_hidden") } }
    var newCardsPerDay: Int { didSet { defaults.set(newCardsPerDay, forKey: "new_cards_per_day") } }
    var briefingSchedule: BriefingSchedule { didSet { defaults.set(briefingSchedule.rawValue, forKey: "briefing_schedule") } }
    var briefingHour: Int { didSet { defaults.set(briefingHour, forKey: "briefing_hour") } }
    var briefingMinute: Int { didSet { defaults.set(briefingMinute, forKey: "briefing_minute") } }
    var lockScreenDetails: Bool { didSet { defaults.set(lockScreenDetails, forKey: "lock_screen_details") } }
    var suggestions: Bool { didSet { defaults.set(suggestions, forKey: "place_suggestions") } }
    var briefingSeenWeek: Int { didSet { defaults.set(briefingSeenWeek, forKey: "briefing_seen_week") } }
    var avatarStamp: Double { didSet { defaults.set(avatarStamp, forKey: "avatar_stamp") } }
    var pinLimit: Int { didSet { defaults.set(pinLimit, forKey: "pin_limit") } }
    var blackMediaBackdrop: Bool { didSet { defaults.set(blackMediaBackdrop, forKey: "media_black_backdrop") } }
    var coverHintSeen: Bool { didSet { defaults.set(coverHintSeen, forKey: "cover_hint_seen") } }
    var chatThinking: ChatThinking { didSet { defaults.set(chatThinking.rawValue, forKey: "chat_thinking") } }
    var chatView: ChatViewSetting { didSet { defaults.set(chatView.encoded, forKey: "chat_view") } }
    var periods: DayPeriods { didSet { for p in DayPeriod.allCases { defaults.set(periods[p], forKey: "period_\(p.key)") } } }
    var taskView: TaskViewSetting { didSet { defaults.set(taskView.encoded, forKey: "tasks_view") } }
    var tasksHintSeen: Bool { didSet { defaults.set(tasksHintSeen, forKey: "tasks_hint_seen") } }
    var tabOrder: TabBarOrder { didSet { defaults.set(tabOrder.encoded, forKey: "tab_order") } }
    var tabLabels: Bool { didSet { defaults.set(tabLabels, forKey: "tab_labels") } }
    var navHintSeen: Bool { didSet { defaults.set(navHintSeen, forKey: "nav_hint_seen") } }
    var chatHintSeen: Bool { didSet { defaults.set(chatHintSeen, forKey: "chat_hint_seen") } }
    private(set) var views: [ListKind: ViewSetting] = [:]
    private(set) var entryViews: [String: ViewSetting] = [:]
    private(set) var collapsed: Set<String> { didSet { defaults.set(Array(collapsed).sorted(), forKey: "view_collapsed") } }

    init() {
        let defaults = AppPaths.defaults
        self.defaults = defaults
        themeMode = ThemeMode(rawValue: defaults.string(forKey: "theme_mode") ?? "") ?? .system
        let language = AppLanguage.fromTag(defaults.string(forKey: "app_language")) ?? L.systemLanguage
        self.language = language
        L.apply(language)
        profileName = defaults.string(forKey: "profile_name") ?? ""
        let today = Day.of(Date(), in: .current)
        if defaults.object(forKey: "joined_epoch_day") == nil { defaults.set(today.epochDay, forKey: "joined_epoch_day") }
        joinedDay = Day(epochDay: defaults.integer(forKey: "joined_epoch_day"))
        let marked = ListKind.fromKey(defaults.string(forKey: "marked_list")) ?? .pinned
        let lists = ListKind.fromKey(defaults.string(forKey: "overview_list")) ?? .inbox
        markedList = marked
        overviewList = lists
        let legacy = OverviewLayout.legacyStyle(defaults.string(forKey: "overview_layout")) ?? .stacked
        overviewLayout = OverviewLayout.decode(defaults.string(forKey: "overview_tabs"), fallback: .standard(marked: marked, lists: lists, style: legacy))
        overviewHintSeen = defaults.bool(forKey: "overview_edge_hint_seen")
        emptyInfoHidden = defaults.bool(forKey: "empty_info_hidden")
        newCardsPerDay = defaults.object(forKey: "new_cards_per_day") == nil ? StudyQueue.defaultNewPerDay : min(max(defaults.integer(forKey: "new_cards_per_day"), 0), 200)
        let schedule = BriefingSchedule(rawValue: defaults.string(forKey: "briefing_schedule") ?? "") ?? .sunday
        briefingSchedule = schedule
        briefingHour = defaults.object(forKey: "briefing_hour") == nil ? (schedule == .monday ? 8 : 18) : defaults.integer(forKey: "briefing_hour")
        briefingMinute = defaults.integer(forKey: "briefing_minute")
        lockScreenDetails = defaults.bool(forKey: "lock_screen_details")
        suggestions = defaults.object(forKey: "place_suggestions") == nil ? true : defaults.bool(forKey: "place_suggestions")
        briefingSeenWeek = defaults.object(forKey: "briefing_seen_week") == nil ? -1 : defaults.integer(forKey: "briefing_seen_week")
        avatarStamp = defaults.double(forKey: "avatar_stamp")
        pinLimit = AppPaths.pinLimit
        blackMediaBackdrop = defaults.bool(forKey: "media_black_backdrop")
        coverHintSeen = defaults.bool(forKey: "cover_hint_seen")
        chatThinking = ChatThinking.fromKey(defaults.string(forKey: "chat_thinking"))
        chatView = ChatViewSetting.decode(defaults.string(forKey: "chat_view"))
        var periods = DayPeriods.standard
        for p in DayPeriod.allCases where defaults.object(forKey: "period_\(p.key)") != nil { periods[p] = defaults.integer(forKey: "period_\(p.key)") }
        self.periods = periods
        let seen = defaults.bool(forKey: "tasks_hint_seen")
        tasksHintSeen = seen
        taskView = TaskViewSetting.decode(defaults.string(forKey: "tasks_view")).adoptingDefaultDone(unlessCustomized: seen)
        tabOrder = TabBarOrder.decode(defaults.string(forKey: "tab_order"), known: AppTab.allCases.map(\.key), standard: AppTab.standardOrder)
        tabLabels = defaults.object(forKey: "tab_labels") == nil ? true : defaults.bool(forKey: "tab_labels")
        navHintSeen = defaults.bool(forKey: "nav_hint_seen")
        chatHintSeen = defaults.bool(forKey: "chat_hint_seen")
        collapsed = Set(defaults.stringArray(forKey: "view_collapsed") ?? [])
        for (id, raw) in defaults.dictionary(forKey: "view_entries") as? [String: String] ?? [:] {
            let parts = raw.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard parts.count == 4 else { continue }
            entryViews[id] = ViewSetting(sort: ParalistCore.SortOrder.fromKey(parts[0]), ascending: parts[1] == "auf",
                                         grouping: Grouping.fromKey(parts[2]), hidden: ViewSetting.hidden(fromKey: parts[3]))
        }
        for kind in ListKind.allCases {
            let direction = defaults.string(forKey: "view_dir_\(kind.key)")
            let hidden = defaults.string(forKey: "view_hide_\(kind.key)")
            views[kind] = ViewSetting(sort: ParalistCore.SortOrder.fromKey(defaults.string(forKey: "view_sort_\(kind.key)")),
                                      ascending: direction.map { $0 == "auf" },
                                      grouping: Grouping.fromKey(defaults.string(forKey: "view_group_\(kind.key)")),
                                      hidden: hidden.map(ViewSetting.hidden(fromKey:)) ?? ViewSetting.standard(for: kind).hidden)
        }
    }

    func view(_ kind: ListKind) -> ViewSetting { views[kind] ?? ViewSetting.standard(for: kind) }

    func setView(_ kind: ListKind, _ setting: ViewSetting) {
        views[kind] = setting
        defaults.set(setting.sort.rawValue, forKey: "view_sort_\(kind.key)")
        defaults.set(setting.ascending ? "auf" : "ab", forKey: "view_dir_\(kind.key)")
        defaults.set(setting.grouping.rawValue, forKey: "view_group_\(kind.key)")
        defaults.set(ViewSetting.hiddenKey(setting.hidden), forKey: "view_hide_\(kind.key)")
    }

    func entryView(_ id: String) -> ViewSetting { entryViews[id] ?? ViewSetting.standard(for: .all) }

    func setEntryView(_ id: String, _ setting: ViewSetting) {
        entryViews[id] = setting
        let stored = entryViews.mapValues { s in [s.sort.rawValue, s.ascending ? "auf" : "ab", s.grouping.rawValue, ViewSetting.hiddenKey(s.hidden)].joined(separator: "|") }
        defaults.set(stored, forKey: "view_entries")
    }

    func isCollapsed(_ kind: ListKind, _ type: EntryType) -> Bool { isCollapsed(key: "\(kind.key)/\(type.key)") }

    func isCollapsed(key: String) -> Bool { collapsed.contains(key) }

    func toggleCollapsed(key: String) {
        if collapsed.contains(key) { collapsed.remove(key) } else { collapsed.insert(key) }
    }

    func expanded(_ kind: ListKind, _ group: (EntryType?, [Entry])) -> [Entry] {
        guard let type = group.0, isCollapsed(kind, type) else { return group.1 }
        return []
    }

    func toggleCollapsed(_ kind: ListKind, _ type: EntryType) { toggleCollapsed(key: "\(kind.key)/\(type.key)") }

    func setName(_ name: String) {
        profileName = String(name.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces).prefix(60))
    }
}
