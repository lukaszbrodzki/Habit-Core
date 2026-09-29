import XCTest
import SwiftData
@testable import Habit_Core

@MainActor
final class HabitStatsTests: XCTestCase {

    func testDayWindowIsClampedToCutoff() throws {
        let s = try TestStore()
        let today = s.date(2026, 3, 10)
        let days = HabitStats.dayWindow(since: s.date(2025, 1, 1), notBefore: s.date(2026, 3, 8), through: today)
        XCTAssertEqual(days, [s.day(-2, from: today), s.day(-1, from: today), s.day(0, from: today)])
    }

    func testCombinedDaysVaryWithCompletions() throws {
        let s = try TestStore()
        let a = s.habit(.daily, createdAt: s.day(-10))
        let b = s.habit(.daily, createdAt: s.day(-10))
        for offset in 0...9 {
            if offset % 2 == 0 { s.complete(a, on: s.day(-offset)) }
            s.complete(b, on: s.day(-offset))
        }
        try s.context.save()

        let days = HabitStats.combinedDays(habits: [a, b], days: [s.day(-1), s.day(0)])
        XCTAssertEqual(days.map(\.rate), [0.5, 1.0])
        XCTAssertEqual(days.map(\.hadDue), [true, true])
    }

    func testWeeklyHabitIsOnlyDueOnDeadlineDay() throws {
        let s = try TestStore()
        let h = s.habit(.weekly, createdAt: s.day(-30)) { $0.weekDay = 2 }   // Monday
        let window = (0...29).map { s.day(-$0) }
        let days = HabitStats.combinedDays(habits: [h], days: window)
        for day in days {
            XCTAssertEqual(day.hadDue, s.cal.component(.weekday, from: day.date) == 2)
        }
    }

    func testCombinedSummaryCountsNothingDueAsPerfect() {
        let d = Date()
        let days = [
            HabitStats.Day(date: d, rate: 1, hadDue: true),
            HabitStats.Day(date: d, rate: 0, hadDue: false),
            HabitStats.Day(date: d, rate: 0.5, hadDue: true),
            HabitStats.Day(date: d, rate: 1, hadDue: true),
        ]
        let summary = HabitStats.summary(of: days)
        XCTAssertEqual(summary, .init(perfectDays: 3, totalDays: 4, ratePercent: 83, streak: 2))
    }

    func testHabitSummary() {
        XCTAssertEqual(
            HabitStats.summary(of: [true, true, false, true]),
            .init(completed: 3, total: 4, ratePercent: 75, streak: 2)
        )
        XCTAssertEqual(HabitStats.summary(of: []), .init(completed: 0, total: 0, ratePercent: 0, streak: 0))
    }

    func testCompletionIndexMatchesIsCompleted() throws {
        let s = try TestStore()
        let h = s.habit(.weekly, createdAt: s.day(-60)) { $0.weekDay = 4 }
        for offset in stride(from: 0, through: 60, by: 9) { s.complete(h, on: s.day(-offset)) }
        try s.context.save()

        let periods = h.allPeriods()
        XCTAssertEqual(HabitStats.completions(of: h, in: periods), periods.map(h.isCompleted(in:)))
    }
}
