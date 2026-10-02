import XCTest
import SwiftData
@testable import Habit_Core

/// The "All Habits" series exactly as the Tracker and the widget build it
/// (`HabitStats.allHabitsDays`), on fixed dates.
@MainActor
final class AllHabitsTests: XCTestCase {

    /// 2 daily + weekly (deadline = today's weekday) + monthly (deadline on the 12th).
    /// A is done every day, B never, W once inside its current week, M once in its month.
    func testMixedFrequenciesCountOnlyOnDeadlines() throws {
        let s = try TestStore()
        let today = s.date(2026, 3, 16)
        let start = s.date(2026, 3, 9)
        let a = s.habit(.daily, createdAt: start)
        s.habit(.daily, createdAt: start)
        let w = s.habit(.weekly, createdAt: start) { $0.weekDay = s.cal.component(.weekday, from: today) }
        let m = s.habit(.monthly, createdAt: start) { $0.monthDay = 12 }
        for offset in 0...7 { s.complete(a, on: s.day(-offset, from: today)) }
        s.complete(w, on: s.date(2026, 3, 11))
        s.complete(m, on: s.date(2026, 3, 10))
        try s.context.save()

        let habits = try s.context.fetch(FetchDescriptor<Habit>())
        let days = HabitStats.allHabitsDays(habits: habits, range: .lastYear, today: today)

        XCTAssertEqual(days.map(\.date), (0...7).map { s.day($0, from: start) })
        XCTAssertTrue(days.allSatisfy(\.hadDue))
        let expected: [Double] = [
            1.0 / 3,   // 9th:  A, B, W (W's previous week, not done)
            0.5,       // 10th: A, B
            0.5,       // 11th: A, B — W done today, but it only counts on its deadline
            2.0 / 3,   // 12th: A, B, M (done on the 10th)
            0.5, 0.5, 0.5,
            2.0 / 3,   // 16th: A, B, W (done on the 11th, inside this week)
        ]
        for (day, rate) in zip(days, expected) {
            XCTAssertEqual(day.rate, rate, accuracy: 0.0001, "\(day.date)")
        }
        XCTAssertEqual(HabitStats.summary(of: days).perfectDays, 0)
    }

    func testWindowStartsAtEarliestActiveHabitAndIgnoresArchived() throws {
        let s = try TestStore()
        let today = s.date(2026, 3, 16)
        s.habit(.daily, createdAt: s.day(-3, from: today))
        let archived = s.habit(.daily, createdAt: s.day(-30, from: today)) { $0.isArchived = true }
        s.complete(archived, on: s.day(-1, from: today))
        try s.context.save()

        let days = HabitStats.allHabitsDays(
            habits: try s.context.fetch(FetchDescriptor<Habit>()), range: .lastYear, today: today
        )
        XCTAssertEqual(days.first?.date, s.day(-3, from: today))
        XCTAssertEqual(days.count, 4)
        // Only the active (never completed) habit is due — the archived completion must not count.
        XCTAssertTrue(days.allSatisfy { $0.hadDue && $0.rate == 0 })
    }

    func testStartAndEndDatesInsideTheWindow() throws {
        let s = try TestStore()
        let today = s.date(2026, 3, 16)
        let origin = s.day(-6, from: today)
        let a = s.habit(.daily, createdAt: origin)
        s.habit(.daily, createdAt: origin) {          // starts 2 days ago
            $0.hasStartDate = true
            $0.startDate = s.day(-2, from: today)
        }
        s.habit(.daily, createdAt: origin) {          // ended 4 days ago (inclusive)
            $0.hasEndDate = true
            $0.endDate = s.day(-4, from: today)
        }
        for offset in 0...6 { s.complete(a, on: s.day(-offset, from: today)) }
        try s.context.save()

        let days = HabitStats.allHabitsDays(
            habits: try s.context.fetch(FetchDescriptor<Habit>()), range: .lastYear, today: today
        )
        // Only A is done, so rate = 1 / number of habits due that day.
        XCTAssertEqual(days.map(\.rate), [0.5, 0.5, 0.5, 1, 0.5, 0.5, 0.5])
    }

    func testHabitAddedTodayCountsFromToday() throws {
        let s = try TestStore()
        let today = s.date(2026, 3, 16)
        let h = s.habit(.daily, createdAt: s.date(2026, 3, 16, hour: 9))
        try s.context.save()

        var days = HabitStats.allHabitsDays(habits: [h], range: .lastYear, today: today)
        XCTAssertEqual(days, [HabitStats.Day(date: s.day(0, from: today), rate: 0, hadDue: true)])

        s.complete(h, on: today)
        try s.context.save()
        days = HabitStats.allHabitsDays(habits: [h], range: .lastYear, today: today)
        XCTAssertEqual(days.map(\.rate), [1])
    }

    func testRangeClampsOldHabits() throws {
        let s = try TestStore()
        let today = s.date(2026, 3, 16)
        let h = s.habit(.daily, createdAt: s.day(-400, from: today))

        let widget = HabitStats.allHabitsDays(habits: [h], range: .lastDays(84), today: today)
        XCTAssertEqual(widget.count, 84)
        XCTAssertEqual(widget.first?.date, s.day(-83, from: today))
        XCTAssertEqual(widget.last?.date, s.day(0, from: today))

        let tracker = HabitStats.allHabitsDays(habits: [h], range: .lastYear, today: today)
        XCTAssertEqual(tracker.first?.date, s.cal.startOfDay(for: s.date(2025, 3, 16)))
    }

    func testNoActiveHabitsGivesEmptySeries() throws {
        let s = try TestStore()
        let archived = s.habit(.daily, createdAt: s.date(2026, 3, 1)) { $0.isArchived = true }
        XCTAssertEqual(HabitStats.allHabitsDays(habits: [], range: .lastYear), [])
        XCTAssertEqual(HabitStats.allHabitsDays(habits: [archived], range: .lastYear), [])
    }
}
