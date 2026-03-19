import Foundation
import SwiftData

@Model
final class HabitEntry {
    var id: UUID = UUID()
    var periodStart: Date = Date()
    var periodEnd: Date = Date()
    var completedAt: Date? = nil
    var isCompleted: Bool = false

    var habit: Habit? = nil

    init(periodStart: Date, periodEnd: Date, habit: Habit? = nil) {
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.habit = habit
    }
}
