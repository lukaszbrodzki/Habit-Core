import XCTest
import SwiftData
@testable import Habit_Core

/// The "All Habits" series exactly as the Tracker and the widget build it
/// (`HabitStats.allHabitsDays`), on fixed dates.
@MainActor
final class AllHabitsTests: XCTestCase {

    /// 2 daily + weekly (deadline on the 16th's weekday) + monthly (deadline on the 12th).
    /// A is done every day through the 16th, B never, W once inside its week, M once in its month.
    /// "Today" is the 17th: still in progress (nothing done), so it isn't counted yet.
    func testMixedFrequenciesCountOnlyOnDeadlines() throws {
        let s = try TestStore()
        let lastDay = s.date(2026, 3, 16)
        let today = s.date(2026, 3, 17)
        let start = s.date(2026, 3, 9)
        let a = s.habit(.daily, createdAt: start)
        s.habit(.daily, createdAt: start)
        let w = s.habit(.weekly, createdAt: start) { $0.weekDay = s.cal.component(.weekday, from: lastDay) }
        let m = s.habit(.monthly, createdAt: start) { $0.monthDay = 12 }
        for offset in 0...7 { s.complete(a, on: s.day(-offset, from: lastDay)) }
        s.complete(w, on: s.date(2026, 3, 11))
        s.complete(m, on: s.date(2026, 3, 10))
        try s.context.save()

        let habits = try s.context.fetch(FetchDescriptor<Habit>())
        let days = HabitStats.allHabitsDays(habits: habits, limit: nil, today: today)

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
            habits: try s.context.fetch(FetchDescriptor<Habit>()), limit: nil, today: today
        )
        // Today (nothing done yet) is still in progress, so the counted days are T-3...T-1.
        XCTAssertEqual(days.first?.date, s.day(-3, from: today))
        XCTAssertEqual(days.count, 3)
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
            habits: try s.context.fetch(FetchDescriptor<Habit>()), limit: nil, today: today
        )
        // Only A is done, so rate = 1 / number of habits due that day. Today (A done, the
        // late-starting habit not) is still in progress, so it isn't counted.
        XCTAssertEqual(days.map(\.rate), [0.5, 0.5, 0.5, 1, 0.5, 0.5])
    }

    func testHabitAddedTodayCountsFromToday() throws {
        let s = try TestStore()
        let today = s.date(2026, 3, 16)
        let h = s.habit(.daily, createdAt: s.date(2026, 3, 16, hour: 9))
        try s.context.save()

        // Due but not done yet: today is in progress, so nothing counts yet.
        var days = HabitStats.allHabitsDays(habits: [h], limit: nil, today: today)
        XCTAssertEqual(days, [])

        s.complete(h, on: today)
        try s.context.save()
        days = HabitStats.allHabitsDays(habits: [h], limit: nil, today: today)
        XCTAssertEqual(days.map(\.rate), [1])
    }

    func testLimitKeepsMostRecentCountedDays() throws {
        let s = try TestStore()
        let today = s.date(2026, 3, 16)
        let h = s.habit(.daily, createdAt: s.day(-400, from: today))   // never done → today in progress

        let limited = HabitStats.allHabitsDays(habits: [h], limit: 84, today: today)
        XCTAssertEqual(limited.count, 84)
        XCTAssertEqual(limited.first?.date, s.day(-84, from: today))
        XCTAssertEqual(limited.last?.date, s.day(-1, from: today))

        // No limit: the whole history, with no one-year cap.
        let all = HabitStats.allHabitsDays(habits: [h], limit: nil, today: today)
        XCTAssertEqual(all.first?.date, s.day(-400, from: today))
        XCTAssertEqual(all.count, 400)
    }

    func testNoActiveHabitsGivesEmptySeries() throws {
        let s = try TestStore()
        let archived = s.habit(.daily, createdAt: s.date(2026, 3, 1)) { $0.isArchived = true }
        XCTAssertEqual(HabitStats.allHabitsDays(habits: [], limit: nil), [])
        XCTAssertEqual(HabitStats.allHabitsDays(habits: [archived], limit: 10), [])
    }
}
