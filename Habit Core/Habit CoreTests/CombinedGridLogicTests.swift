import XCTest
import SwiftData
@testable import Habit_Core

/// Reproduces CombinedGrid.completionRate (private, in Views/Tracker/ContributionGrid.swift)
/// against synthetic data to verify the intensity actually varies day to day.
final class CombinedGridLogicTests: XCTestCase {

    private func completionRate(on date: Date, habits: [Habit]) -> Double {
        let cal = Calendar.current
        let active = habits.filter { !$0.isArchived }

        let due = active.filter { habit in
            guard let p = habit.period(for: date) else { return false }
            return cal.isDate(p.end, inSameDayAs: date)
        }
        guard !due.isEmpty else { return 0 }

        let done = due.filter { habit in
            guard let p = habit.period(for: date) else { return false }
            return habit.isCompleted(in: p)
        }
        return Double(done.count) / Double(due.count)
    }

    func testDailyHabitsProduceVaryingRates() throws {
        let container = try ModelContainer(
            for: Habit.self, HabitEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let ctx = ModelContext(container)
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let created = cal.date(byAdding: .day, value: -10, to: today)!

        let habitA = Habit(name: "A", frequency: .daily)
        habitA.createdAt = created
        let habitB = Habit(name: "B", frequency: .daily)
        habitB.createdAt = created
        ctx.insert(habitA)
        ctx.insert(habitB)

        // A completed on even day-offsets, B always completed.
        for offset in 0...9 {
            let day = cal.date(byAdding: .day, value: -offset, to: today)!
            guard let pA = habitA.period(for: day), let pB = habitB.period(for: day) else { continue }
            if offset % 2 == 0 {
                let e = HabitEntry(periodStart: pA.start, periodEnd: pA.end, habit: habitA)
                e.isCompleted = true
                ctx.insert(e)
            }
            let eB = HabitEntry(periodStart: pB.start, periodEnd: pB.end, habit: habitB)
            eB.isCompleted = true
            ctx.insert(eB)
        }
        try ctx.save()

        var rates: [Double] = []
        for offset in 0...9 {
            let day = cal.date(byAdding: .day, value: -offset, to: today)!
            rates.append(completionRate(on: day, habits: [habitA, habitB]))
        }

        print("rates (offset 0..9, today first):", rates)
        // Even offsets: both done -> 1.0. Odd offsets: only B done -> 0.5.
        XCTAssertEqual(rates[0], 1.0)
        XCTAssertEqual(rates[1], 0.5)
        XCTAssertTrue(Set(rates).count > 1, "Expected varying completion rates, got all identical: \(rates)")
    }

    func testWeeklyHabitIsOnlyDueOnDeadlineDay() throws {
        let container = try ModelContainer(
            for: Habit.self, HabitEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let ctx = ModelContext(container)
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let created = cal.date(byAdding: .day, value: -30, to: today)!

        let habit = Habit(name: "Weekly", frequency: .weekly, weekDay: 2) // Monday
        habit.createdAt = created
        ctx.insert(habit)
        try ctx.save()

        var dueCount = 0
        for offset in 0...29 {
            let day = cal.date(byAdding: .day, value: -offset, to: today)!
            let rate = completionRate(on: day, habits: [habit])
            if cal.component(.weekday, from: day) == 2 {
                dueCount += 1
            } else {
                XCTAssertEqual(rate, 0, "Non-deadline day should have rate 0 (not due)")
            }
        }
        print("weekly habit had a deadline on \(dueCount)/30 days")
        XCTAssertTrue(dueCount >= 4 && dueCount <= 5)
    }
}
