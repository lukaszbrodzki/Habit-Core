import Foundation
import SwiftData
@testable import Habit_Core

/// In-memory store + fixed-date helpers shared by the unit tests.
@MainActor
struct TestStore {
    let container: ModelContainer
    let context: ModelContext
    let cal = Calendar.current

    init() throws {
        container = try ModelContainer(
            for: Habit.self, HabitEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
    }

    func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        cal.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    func day(_ offset: Int, from base: Date = Date()) -> Date {
        cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: base))!
    }

    @discardableResult
    func habit(_ frequency: FrequencyType, createdAt: Date, configure: (Habit) -> Void = { _ in }) -> Habit {
        let habit = Habit(name: "Test", frequency: frequency)
        habit.createdAt = createdAt
        configure(habit)
        context.insert(habit)
        return habit
    }

    func complete(_ habit: Habit, on date: Date) {
        guard let p = habit.period(for: date) else { return }
        let entry = HabitEntry(periodStart: p.start, periodEnd: p.end, habit: habit)
        entry.isCompleted = true
        context.insert(entry)
    }
}
