import XCTest
import SwiftData
@testable import Habit_Core

@MainActor
final class HabitActionsTests: XCTestCase {

    func testToggleCompletionMarksAndUnmarksCurrentPeriod() throws {
        let s = try TestStore()
        let h = s.habit(.daily, createdAt: s.day(-1))
        let actions = HabitActions(context: s.context)

        actions.toggleCompletion(of: h)
        XCTAssertTrue(h.isCompletedToday)
        XCTAssertEqual(h.entries?.count, 1)

        actions.toggleCompletion(of: h)
        XCTAssertFalse(h.isCompletedToday)
    }

    func testToggleIsIgnoredBeforeStartDate() throws {
        let s = try TestStore()
        let h = s.habit(.daily, createdAt: s.day(-1)) {
            $0.hasStartDate = true
            $0.startDate = s.day(2)
        }
        HabitActions(context: s.context).toggleCompletion(of: h)
        XCTAssertEqual(h.entries?.count ?? 0, 0)
    }

    func testArchiveAndRestore() throws {
        let s = try TestStore()
        let h = s.habit(.daily, createdAt: s.day(-1))
        let actions = HabitActions(context: s.context)

        actions.archive(h)
        XCTAssertTrue(h.isArchived)
        XCTAssertFalse(h.canMarkToday)

        actions.restore(h)
        XCTAssertFalse(h.isArchived)
    }

    func testResetClearsHistoryAndRestartsToday() throws {
        let s = try TestStore()
        let h = s.habit(.daily, createdAt: s.day(-10))
        s.complete(h, on: s.day(-3))
        try s.context.save()

        HabitActions(context: s.context).reset(h)
        XCTAssertEqual(h.entries?.count ?? 0, 0)
        XCTAssertTrue(s.cal.isDateInToday(h.createdAt))
    }
}
