// Zusammenhang: ParalistCore Planning/ReminderPlanner.swift, ParalistCore Library/ReminderNotes.swift, Reminders/NotificationHandler.swift, App/AppModel.swift, Pages/SettingsPage.swift
import Foundation
import ParalistCore
import UserNotifications

@MainActor
final class ReminderScheduler {
    static let categoryEntry = "paralist.eintrag"
    static let categoryTask = "paralist.aufgabe"
    static let actionDone = "paralist.erledigt"
    static let actionLater = "paralist.spaeter"
    static let actionMorning = "paralist.morgen"
    static let briefingId = "paralist.briefing"
    private let center = UNUserNotificationCenter.current()
    var lockScreenDetails = false {
        didSet { registerCategories() }
    }

    init() {
        registerCategories()
    }

    private func registerCategories() {
        let options: UNNotificationCategoryOptions = lockScreenDetails ? [.hiddenPreviewsShowTitle] : []
        let placeholder = L.s("notif_public")
        let done = UNNotificationAction(identifier: Self.actionDone, title: L.s("notif_action_done"))
        let later = UNNotificationAction(identifier: Self.actionLater, title: L.s("notif_action_later"))
        let morning = UNNotificationAction(identifier: Self.actionMorning, title: L.s("notif_action_morning"))
        center.setNotificationCategories([
            UNNotificationCategory(identifier: Self.categoryTask, actions: [done, later, morning], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: placeholder, options: options),
            UNNotificationCategory(identifier: Self.categoryEntry, actions: [later, morning], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: placeholder, options: options),
        ])
    }

    func ensurePermission() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        case .denied: return false
        default: return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        }
    }

    func isAuthorized() async -> Bool {
        let status = await center.notificationSettings().authorizationStatus
        return status == .authorized || status == .provisional
    }

    func reschedule(_ entry: Entry) {
        cancel(entry.id)
        let planned = ReminderPlanner.plan(entry, now: Date(), zone: .current)
        for (slot, reminder) in planned.prefix(ReminderPlanner.maxPerEntry).enumerated() {
            schedule(entry, at: reminder.at, kind: reminder.kind, slot: slot)
        }
    }

    func rescheduleAll(_ entries: [Entry]) {
        center.removeAllPendingNotificationRequests()
        entries.forEach(reschedule)
    }

    func cancel(_ id: String) {
        center.removePendingNotificationRequests(withIdentifiers: (0...ReminderPlanner.maxPerEntry).map { "eintrag.\(id).\($0)" } + ["eintrag.\(id).99"])
    }

    func snooze(_ entry: Entry, until: Date, body: String? = nil) {
        schedule(entry, at: until, kind: .custom, slot: 99, body: body)
    }

    private func schedule(_ entry: Entry, at: Date, kind: ReminderKind, slot: Int, body: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = entry.title.isEmpty ? L.s("list_untitled") : entry.title
        let today = Day.of(Date(), in: .current)
        switch kind {
        case .due: content.body = (entry.due.map { $0 < today } ?? false) ? L.s("notif_overdue") : L.s("notif_due")
        default: content.body = body ?? entry.reminderNote(at: at) ?? L.s("reminder_bell")
        }
        content.sound = .default
        content.categoryIdentifier = entry.type == .task ? Self.categoryTask : Self.categoryEntry
        content.threadIdentifier = kind.rawValue
        content.userInfo = ["eintrag": entry.id, "art": kind.rawValue]
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: at)
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        center.add(UNNotificationRequest(identifier: "eintrag.\(entry.id).\(slot)", content: content, trigger: trigger))
    }

    func scheduleBriefing(_ prefs: AppPrefs, briefing: WeekBriefing) {
        center.removePendingNotificationRequests(withIdentifiers: [Self.briefingId])
        guard prefs.briefingSchedule != .off else { return }
        let content = UNMutableNotificationContent()
        content.title = L.s("briefing_notification_title")
        content.body = L.f("briefing_notification_text", briefing.eventCount, briefing.tasks.count)
        content.sound = .default
        content.userInfo = ["eintrag": "briefing"]
        var parts = DateComponents()
        parts.weekday = prefs.briefingSchedule == .sunday ? 1 : 2
        parts.hour = prefs.briefingHour
        parts.minute = prefs.briefingMinute
        center.add(UNNotificationRequest(identifier: Self.briefingId, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)))
    }
}
