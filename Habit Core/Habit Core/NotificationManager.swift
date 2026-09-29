import Foundation
import SwiftData
import UserNotifications

/// A single daily reminder (set in Settings) rather than one per habit — fires only if some
/// active habit is still due when re-evaluated. Purely local (UNCalendarNotificationTrigger),
/// no APNs/remote push, so no extra entitlement beyond runtime authorization is needed.
///
/// Re-evaluated (not a repeating trigger) whenever something relevant changes — the app becoming active,
/// a habit toggled/added/edited/deleted, or the reminder setting itself — so it can be
/// cancelled the moment nothing is left to do. The trade-off: if the app is never opened on a
/// given day, that day's reminder never gets (re)scheduled. Acceptable for now since opening the
/// app is how you mark habits done in the first place; revisit with BGTaskScheduler if it matters.
///
/// IMPORTANT: all UNUserNotificationCenter calls here go through the `async throws` APIs inside a
/// `Task`, never the completion-handler/fire-and-forget variants. Calling e.g. `add(_:)` (no
/// `await`) right after `removePendingNotificationRequests` can deadlock the calling thread on a
/// real device: `add`'s legacy path does a synchronous dispatch onto UserNotifications' internal
/// queue, which can still be owned by the remove call's in-flight XPC round-trip to
/// usernotificationsd. The `async` variants suspend cooperatively instead of blocking the thread,
/// which avoids that whole class of hang. (Reproduces on device, not the Simulator, since the
/// Simulator's notification daemon doesn't hit the same contention.)
@Observable
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private static let identifier = "dailyReminder"

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @ObservationIgnored private var reminderTask: Task<Void, Never>?

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        refreshAuthorizationStatus()
    }

    /// Asks for permission, then re-evaluates the reminder — otherwise a freshly granted
    /// permission wouldn't schedule anything until the next unrelated refresh.
    func requestAuthorization(thenRefresh context: ModelContext) {
        Task {
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            authorizationStatus = settings.authorizationStatus
            refreshDailyReminder(context: context)
        }
    }

    /// Re-reads the system authorization status — call whenever the app becomes active, since the
    /// user may have changed it in the Settings app while we were backgrounded.
    func refreshAuthorizationStatus() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            authorizationStatus = settings.authorizationStatus
        }
    }

    func refreshDailyReminder(context: ModelContext) {
        let habits = (try? context.fetch(
            FetchDescriptor<Habit>(predicate: #Predicate<Habit> { !$0.isArchived })
        )) ?? []
        refreshDailyReminder(habits: habits)
    }

    func refreshDailyReminder(habits: [Habit]) {
        // Read everything SwiftData/settings-related synchronously up front — Habit is not safe to
        // touch off the main actor. Only the actual UNUserNotificationCenter work happens in the Task.
        let settings = ReminderSettings.shared
        var triggerComponents: DateComponents?

        if settings.isEnabled,
           habits.contains(where: { $0.canMarkToday && !$0.isCompletedToday }) {
            let cal = Calendar.current
            let time = cal.dateComponents([.hour, .minute], from: settings.time)
            if let hour = time.hour, let minute = time.minute,
               let fireDate = cal.date(bySettingHour: hour, minute: minute, second: 0, of: Date()),
               fireDate > Date() {
                triggerComponents = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            }
        }

        // Serialized: each refresh waits for the previous one, so an older Task suspended on
        // `add` can't re-add a reminder after a newer one has already removed it.
        let previous = reminderTask
        reminderTask = Task {
            await previous?.value
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])

            // Authorization is read fresh here rather than from `authorizationStatus`, which on a
            // cold start may still be `.notDetermined` (it's filled in by its own async Task).
            let status = await center.notificationSettings().authorizationStatus
            authorizationStatus = status
            guard let comps = triggerComponents,
                  status == .authorized || status == .provisional
            else { return }

            let content = UNMutableNotificationContent()
            content.title = String(localized: "notification.reminder.title")
            content.body = String(localized: "notification.reminder.body")
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(identifier: Self.identifier, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
