import AppIntents
import SwiftData
import WidgetKit

/// Marks a habit done/not-done for today, straight from the widget — no app launch.
struct ToggleHabitIntent: AppIntent {
    static var title: LocalizedStringResource { "Toggle Habit" }

    @Parameter(title: "Habit ID")
    var habitID: String

    init() {}

    init(habitID: UUID) {
        self.habitID = habitID.uuidString
    }

    func perform() async throws -> some IntentResult {
        guard let container = WidgetModelStore.container, let uuid = UUID(uuidString: habitID) else {
            return .result()
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Habit>(predicate: #Predicate<Habit> { $0.id == uuid })
        guard let habit = try? context.fetch(descriptor).first else { return .result() }

        if habit.isCompletedToday {
            if let p = habit.period(for: Date()),
               let entry = habit.entries?.first(where: {
                   $0.isCompleted && $0.periodStart >= p.start && $0.periodStart <= p.end
               }) {
                context.delete(entry)
            }
        } else if habit.canMarkToday, let p = habit.period(for: Date()) {
            let entry = HabitEntry(periodStart: p.start, periodEnd: p.end, habit: habit)
            entry.isCompleted = true
            entry.completedAt = Date()
            context.insert(entry)
            habit.entries?.append(entry)
        }

        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
