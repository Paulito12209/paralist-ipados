// Zusammenhang: Reminders/ReminderScheduler.swift, App/ParalistApp.swift, Shell/Router.swift
import Foundation
import ParalistCore
import UserNotifications

final class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationHandler()
    @MainActor var model: AppModel?
    @MainActor var router: Router?

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let id = response.notification.request.content.userInfo["eintrag"] as? String ?? ""
        let action = response.actionIdentifier
        let body = response.notification.request.content.body
        await MainActor.run { handle(id: id, action: action, body: body) }
    }

    @MainActor
    private func handle(id: String, action: String, body: String) {
        guard let model, let router else { return }
        if id == "briefing" {
            router.openBriefing()
            return
        }
        guard EntryCodec.isValidId(id), let entry = model.entry(id) else { return }
        switch action {
        case ReminderScheduler.actionDone:
            model.setDone(id, true)
        case ReminderScheduler.actionLater:
            model.reminders.snooze(entry, until: Date().addingTimeInterval(3600), body: body)
        case ReminderScheduler.actionMorning:
            model.reminders.snooze(entry, until: model.today.adding(days: 1).at(hour: 8, in: .current), body: body)
        default:
            router.open(.entry(id))
        }
    }
}
