import Foundation
import UserNotifications

/// A single, optional, once-a-day nudge. Off by default until the user
/// opts in from Settings; never more than one per day.
enum NotificationManager {
    static func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    static func scheduleDailyReminder(at time: DateComponents) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])

        let content = UNMutableNotificationContent()
        content.title = "A little movement counts"
        content.body = "No pressure — even a few steps today keeps things moving."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        center.add(request)
    }

    static func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])
    }
}
