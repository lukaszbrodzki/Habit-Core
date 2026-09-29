import XCTest
@testable import Habit_Core

@MainActor
final class HabitPeriodTests: XCTestCase {

    func testDailyPeriodIsTheWholeCalendarDay() throws {
        let s = try TestStore()
        let h = s.habit(.daily, createdAt: s.date(2026, 3, 1))
        let p = try XCTUnwrap(h.period(for: s.date(2026, 3, 10, hour: 15)))
        XCTAssertEqual(p.start, s.cal.startOfDay(for: s.date(2026, 3, 10)))
        XCTAssertTrue(s.cal.isDate(p.end, inSameDayAs: s.date(2026, 3, 10)))
    }

    func testWeeklyOnDeadlineDayEndsThatDay() throws {
        let s = try TestStore()
        let deadline = s.date(2026, 9, 29)
        let h = s.habit(.weekly, createdAt: s.date(2026, 9, 1)) {
            $0.weekDay = s.cal.component(.weekday, from: deadline)
        }
        let p = try XCTUnwrap(h.period(for: deadline))
        XCTAssertTrue(s.cal.isDate(p.end, inSameDayAs: deadline))
        XCTAssertEqual(p.start, s.day(-6, from: deadline))
    }

    func testWeeklyDayAfterDeadlineRunsUntilNextWeek() throws {
        let s = try TestStore()
        let deadline = s.date(2026, 9, 29)
        let h = s.habit(.weekly, createdAt: s.date(2026, 9, 1)) {
            $0.weekDay = s.cal.component(.weekday, from: deadline)
        }
        let p = try XCTUnwrap(h.period(for: s.day(1, from: deadline)))
        XCTAssertTrue(s.cal.isDate(p.end, inSameDayAs: s.day(7, from: deadline)))
    }

    func testMonthlyDay31ClampsToEndOfFebruary() throws {
        let s = try TestStore()
        let h = s.habit(.monthly, createdAt: s.date(2025, 12, 1)) { $0.monthDay = 31 }
        let p = try XCTUnwrap(h.period(for: s.date(2026, 2, 10)))
        XCTAssertTrue(s.cal.isDate(p.end, inSameDayAs: s.date(2026, 2, 28)))
        XCTAssertEqual(p.start, s.cal.startOfDay(for: s.date(2026, 2, 1)))
    }

    func testMonthlyDay31UsesLeapDay() throws {
        let s = try TestStore()
        let h = s.habit(.monthly, createdAt: s.date(2027, 12, 1)) { $0.monthDay = 31 }
        let p = try XCTUnwrap(h.period(for: s.date(2028, 2, 10)))
        XCTAssertTrue(s.cal.isDate(p.end, inSameDayAs: s.date(2028, 2, 29)))
    }

    func testMonthlyCrossesYearBoundary() throws {
        let s = try TestStore()
        let h = s.habit(.monthly, createdAt: s.date(2026, 11, 1)) { $0.monthDay = 5 }
        let p = try XCTUnwrap(h.period(for: s.date(2026, 12, 20)))
        XCTAssertTrue(s.cal.isDate(p.end, inSameDayAs: s.date(2027, 1, 5)))
        XCTAssertEqual(p.start, s.cal.startOfDay(for: s.date(2026, 12, 6)))
    }

    func testCustomPeriodsAreContiguousSlotsFromStart() throws {
        let s = try TestStore()
        let h = s.habit(.custom, createdAt: s.date(2026, 1, 1)) { $0.customDays = 3 }
        let first = try XCTUnwrap(h.period(for: s.date(2026, 1, 3)))
        let second = try XCTUnwrap(h.period(for: s.date(2026, 1, 4)))
        XCTAssertEqual(first.start, s.cal.startOfDay(for: s.date(2026, 1, 1)))
        XCTAssertEqual(second.start, s.cal.startOfDay(for: s.date(2026, 1, 4)))
        XCTAssertTrue(s.cal.isDate(second.end, inSameDayAs: s.date(2026, 1, 6)))
    }

    func testCustomDaysZeroFromSyncDoesNotCrash() throws {
        let s = try TestStore()
        let h = s.habit(.custom, createdAt: s.date(2026, 1, 1)) { $0.customDays = 0 }
        XCTAssertNotNil(h.period(for: s.date(2026, 1, 5)))
    }

    func testIsDueIsBoundedByStartAndEndDays() throws {
        let s = try TestStore()
        let h = s.habit(.daily, createdAt: s.date(2026, 3, 1)) {
            $0.hasStartDate = true
            $0.startDate = s.date(2026, 3, 10, hour: 18)
            $0.hasEndDate = true
            $0.endDate = s.date(2026, 3, 12, hour: 8)
        }
        XCTAssertFalse(h.isDue(on: s.date(2026, 3, 9)))
        XCTAssertTrue(h.isDue(on: s.date(2026, 3, 10, hour: 9)))    // before the stored time-of-day
        XCTAssertTrue(h.isDue(on: s.date(2026, 3, 12, hour: 22)))   // after the stored time-of-day
        XCTAssertFalse(h.isDue(on: s.date(2026, 3, 13)))
    }

    func testCanMarkTodayIsDayGranular() throws {
        let s = try TestStore()
        let lateToday = s.cal.date(bySettingHour: 23, minute: 59, second: 0, of: Date())!
        let startsLaterToday = s.habit(.daily, createdAt: s.day(-5)) {
            $0.hasStartDate = true
            $0.startDate = lateToday
        }
        let endedEarlierToday = s.habit(.daily, createdAt: s.day(-5)) {
            $0.hasEndDate = true
            $0.endDate = s.cal.startOfDay(for: Date())
        }
        XCTAssertTrue(startsLaterToday.canMarkToday)
        XCTAssertTrue(endedEarlierToday.canMarkToday)
    }
}
