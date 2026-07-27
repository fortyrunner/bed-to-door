import Foundation
import UserNotifications

/// Gentle walking nudges, spread evenly across a time window the user
/// picks — e.g. "3 times a day between 9am and 7pm". Off by default
/// until the user opts in from Settings.
enum NotificationManager {
    static let maxRemindersPerDay = 6

    private static func identifier(for index: Int) -> String { "dailyReminder_\(index)" }

    static func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    /// Schedules `count` reminders, evenly spaced between `startHour` and
    /// `endHour` (24-hour clock). E.g. count=3, startHour=9, endHour=19
    /// schedules reminders around 9:00, 14:00, and 19:00.
    static func scheduleReminders(count: Int, startHour: Int, endHour: Int) {
        cancelAllReminders()
        guard count > 0 else { return }

        let clampedCount = min(count, maxRemindersPerDay)
        let span = max(0, endHour - startHour)
        let center = UNUserNotificationCenter.current()

        for i in 0..<clampedCount {
            let hourOffset = clampedCount == 1 ? 0 : Double(span) * Double(i) / Double(clampedCount - 1)
            let hour = min(23, max(0, startHour + Int(hourOffset.rounded())))

            var components = DateComponents()
            components.hour = hour
            components.minute = 0

            let content = UNMutableNotificationContent()
            content.title = "A little movement counts"
            content.body = clampedCount == 1
                ? "No pressure — even a few steps today keeps things moving."
                : "Check-in \(i + 1) of \(clampedCount): a short walk counts."
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: identifier(for: i), content: content, trigger: trigger)
            center.add(request)
        }
    }

    static func cancelAllReminders() {
        let ids = (0..<maxRemindersPerDay).map(identifier(for:))
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
}
