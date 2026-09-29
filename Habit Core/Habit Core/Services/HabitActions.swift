import Foundation
import OSLog
import SwiftData

/// Every user-driven habit mutation goes through here, so each one consistently saves, logs a
/// failed save, and re-evaluates the daily reminder. (Widget timelines reload on
/// `ModelContext.didSave` in ContentView.) Views only decide *when* to call these.
struct HabitActions {
    let context: ModelContext
    var notifications: NotificationManager = .shared

    private static let logger = Logger(subsystem: "com.lukbro.atomichabits.Habit-Core", category: "persistence")

    /// Marks the current period done, or undoes it if it's already done.
    func toggleCompletion(of habit: Habit, now: Date = Date()) {
        guard habit.canMarkToday, let period = habit.period(for: now) else { return }

        if let entry = habit.completedEntry(in: period) {
            context.delete(entry)
        } else {
            let entry = HabitEntry(periodStart: period.start, periodEnd: period.end, habit: habit)
            entry.isCompleted = true
            entry.completedAt = now
            context.insert(entry)
            habit.entries?.append(entry)
        }
        commit()
    }

    func archive(_ habit: Habit) {
        habit.isArchived = true
        commit()
    }

    func restore(_ habit: Habit) {
        habit.isArchived = false
        commit()
    }

    /// Clears all history and restarts the habit from today.
    func reset(_ habit: Habit) {
        habit.entries?.forEach { context.delete($0) }
        habit.entries?.removeAll()
        habit.createdAt = Date()
        habit.hasStartDate = false
        habit.startDate = nil
        commit()
    }

    func delete(_ habit: Habit) {
        context.delete(habit)
        commit()
    }

    /// Persists whatever the caller changed (new/edited habit, reordering) and runs the usual
    /// follow-ups.
    func commit() {
        do {
            try context.save()
        } catch {
            // No user content in the message — just the failure, for Console/diagnostics.
            Self.logger.error("Saving habits failed: \(error.localizedDescription, privacy: .public)")
        }
        notifications.refreshDailyReminder(context: context)
    }
}
