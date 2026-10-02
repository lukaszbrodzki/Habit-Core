import XCTest
import SwiftData
@testable import Habit_Core

/// Settings → "Count only recent": which periods count toward a habit's grid and stats.
@MainActor
final class StatsWindowTests: XCTestCase {

    /// The example from the feature discussion: 11 daily occurrences, `f` then ten `t`.
    func testCountLastNDropsOlderOccurrences() throws {
        let s = try TestStore()
        let now = s.date(2026, 3, 16)
        let h = s.habit(.daily, createdAt: s.day(-10, from: now))
        for offset in 0...9 { s.complete(h, on: s.day(-offset, from: now)) }   // oldest day missed
        try s.context.save()

        let all = HabitStats.countedPeriods(of: h, limit: nil, now: now).completions
        XCTAssertEqual(all, [false] + Array(repeating: true, count: 10))
        XCTAssertEqual(HabitStats.summary(of: all), .init(completed: 10, total: 11, ratePercent: 91, streak: 10))

        let last10 = HabitStats.countedPeriods(of: h, limit: 10, now: now).completions
        XCTAssertEqual(HabitStats.summary(of: last10), .init(completed: 10, total: 10, ratePercent: 100, streak: 10))
    }

    func testCurrentPeriodCountsOnlyOnceDone() throws {
        let s = try TestStore()
        let now = s.date(2026, 3, 16, hour: 9)
        let h = s.habit(.daily, createdAt: s.day(-2, from: now))
        s.complete(h, on: s.day(-2, from: now))
        s.complete(h, on: s.day(-1, from: now))
        try s.context.save()

        XCTAssertEqual(HabitStats.countedPeriods(of: h, limit: nil, now: now).completions, [true, true])

        s.complete(h, on: now)
        try s.context.save()
        XCTAssertEqual(HabitStats.countedPeriods(of: h, limit: nil, now: now).completions, [true, true, true])
    }

    func testWeeklyDoneEarlyCountsBeforeTheDeadline() throws {
        let s = try TestStore()
        let deadline = s.date(2026, 3, 16)
        let midweek = s.day(-4, from: deadline)
        let h = s.habit(.weekly, createdAt: s.day(-20, from: deadline)) {
            $0.weekDay = s.cal.component(.weekday, from: deadline)
        }
        s.complete(h, on: midweek)
        try s.context.save()

        let counted = HabitStats.countedPeriods(of: h, limit: 1, now: midweek)
        XCTAssertEqual(counted.completions, [true])
        XCTAssertTrue(s.cal.isDate(try XCTUnwrap(counted.periods.last).end, inSameDayAs: deadline))
    }

    func testLimitLargerThanHistoryKeepsEverything() throws {
        let s = try TestStore()
        let now = s.date(2026, 3, 16)
        let h = s.habit(.daily, createdAt: s.day(-2, from: now))
        try s.context.save()

        // T-2, T-1 missed; today untouched (in progress) → not counted.
        XCTAssertEqual(HabitStats.countedPeriods(of: h, limit: 30, now: now).completions, [false, false])
    }

    func testHistoryIsNoLongerCappedAtOneYear() throws {
        let s = try TestStore()
        let now = s.date(2026, 3, 16)
        let h = s.habit(.daily, createdAt: s.day(-500, from: now))
        XCTAssertEqual(h.allPeriods(upTo: now).count, 501)
    }

    func testStatsLimitSettingReadsSharedDefaults() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "StatsWindowTests"))
        defaults.removePersistentDomain(forName: "StatsWindowTests")
        XCTAssertNil(SharedDefaults.statsLimit(in: defaults))                       // off by default

        defaults.set(true, forKey: SharedDefaults.statsLimitEnabledKey)
        XCTAssertEqual(SharedDefaults.statsLimit(in: defaults), SharedDefaults.defaultStatsLimitCount)

        defaults.set(10, forKey: SharedDefaults.statsLimitCountKey)
        XCTAssertEqual(SharedDefaults.statsLimit(in: defaults), 10)

        defaults.set(-5, forKey: SharedDefaults.statsLimitCountKey)                 // clamped
        XCTAssertEqual(SharedDefaults.statsLimit(in: defaults), 1)
        defaults.removePersistentDomain(forName: "StatsWindowTests")
    }
}
