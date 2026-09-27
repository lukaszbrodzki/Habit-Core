import Foundation
import SwiftData
import UserNotifications

/// A single daily reminder (set in Settings) rather than one per habit — fires only if some
/// active habit is still due when re-evaluated. Purely local (UNCalendarNotificationTrigger),
/// no APNs/remote push, so no extra entitlement beyond runtime authorization is needed.
///
/// Re-evaluated (not a repeating trigger) whenever something relevant changes — app launch,
/// a habit toggled/added/edited/deleted, or the reminder setting itself — so it can be
/// cancelled the moment nothing is left to do. The trade-off: if the app is never opened on a
/// given day, that day's reminder never gets (re)scheduled. Acceptable for now since opening the
/// app is how you mark habits done in the first place; revisit with BGTaskScheduler if it matters.
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private static let identifier = "dailyReminder"

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func refreshDailyReminder(context: ModelContext) {
        let habits = (try? context.fetch(
            FetchDescriptor<Habit>(predicate: #Predicate<Habit> { !$0.isArchived })
        )) ?? []
        refreshDailyReminder(habits: habits)
    }

    func refreshDailyReminder(habits: [Habit]) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])

        let theme = AppTheme.shared
        guard theme.reminderEnabled else { return }

        let hasIncomplete = habits.contains { $0.canMarkToday && !$0.isCompletedToday }
        guard hasIncomplete else { return }

        let cal = Calendar.current
        let time = cal.dateComponents([.hour, .minute], from: theme.reminderTime)
        guard
            let hour = time.hour, let minute = time.minute,
            let fireDate = cal.date(bySettingHour: hour, minute: minute, second: 0, of: Date()),
            fireDate > Date()
        else { return }

        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.reminder.title")
        content.body = String(localized: "notification.reminder.body")
        content.sound = .default

        center.add(UNNotificationRequest(identifier: Self.identifier, content: content, trigger: trigger))
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
