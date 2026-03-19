import Foundation

extension Habit {

    // MARK: - Period

    struct Period: Equatable {
        let start: Date
        let end: Date

        func contains(_ date: Date) -> Bool {
            date >= start && date <= end
        }
    }

    /// Returns the habit's current (or most-recent) period relative to `date`.
    func period(for date: Date = Date()) -> Period? {
        let cal = Calendar.current

        switch frequency {

        case .daily:
            let start = cal.startOfDay(for: date)
            guard let end = cal.date(byAdding: .day, value: 1, to: start)?
                .addingTimeInterval(-1) else { return nil }
            return Period(start: start, end: end)

        case .weekly:
            // Find the most-recent occurrence of weekDay on or before date.
            var comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            comps.weekday = weekDay
            guard var target = cal.date(from: comps) else { return nil }
            if target > date {
                target = cal.date(byAdding: .weekOfYear, value: -1, to: target) ?? target
            }
            let start = cal.startOfDay(for: target)
            guard let end = cal.date(byAdding: .day, value: 1, to: start)?
                .addingTimeInterval(-1) else { return nil }
            return Period(start: start, end: end)

        case .monthly:
            var comps = cal.dateComponents([.year, .month], from: date)
            let daysInMonth = cal.range(of: .day, in: .month, for: date)?.count ?? 28
            comps.day = min(monthDay, daysInMonth)
            guard var target = cal.date(from: comps) else { return nil }
            if target > date {
                // Shift to previous month
                comps.month = (comps.month ?? 1) - 1
                target = cal.date(from: comps) ?? target
            }
            let start = cal.startOfDay(for: target)
            guard let end = cal.date(byAdding: .day, value: 1, to: start)?
                .addingTimeInterval(-1) else { return nil }
            return Period(start: start, end: end)

        case .custom:
            let origin = cal.startOfDay(for: createdAt)
            let today  = cal.startOfDay(for: date)
            let diff   = cal.dateComponents([.day], from: origin, to: today).day ?? 0
            let idx    = diff / customDays
            guard
                let pStart = cal.date(byAdding: .day, value: idx * customDays, to: origin),
                let pLastDay = cal.date(byAdding: .day, value: (idx + 1) * customDays - 1, to: origin),
                let pEnd = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: pLastDay))?
                    .addingTimeInterval(-1)
            else { return nil }
            return Period(start: pStart, end: pEnd)
        }
    }

    // MARK: - Derived state

    var canMarkToday: Bool {
        guard !isArchived else { return false }
        if hasEndDate, let ed = endDate, Date() > ed { return false }
        guard let p = period(for: Date()) else { return false }
        return Date() <= p.end
    }

    var isCompletedToday: Bool {
        guard let p = period(for: Date()) else { return false }
        return isCompleted(in: p)
    }

    func isCompleted(in period: Period) -> Bool {
        entries.contains { $0.isCompleted && $0.periodStart >= period.start && $0.periodStart <= period.end }
    }

    /// Deadline date for Today-view display (end of current period).
    var dueDate: Date? { period(for: Date())?.end }

    /// Sort key for Today view: 0 = due & incomplete, 1 = not due, 2 = completed.
    var todaySortPriority: Int {
        if isCompletedToday { return 2 }
        return canMarkToday ? 0 : 1
    }

    // MARK: - History periods (newest first)

    /// Returns all periods from createdAt up to `date`, newest first.
    /// Limited to the past year and at most 400 iterations.
    func allPeriods(upTo date: Date = Date()) -> [Period] {
        let cal = Calendar.current
        let cutoff = cal.date(byAdding: .year, value: -1, to: date) ?? date
        let habitStart = cal.startOfDay(for: createdAt)
        let lowerBound = max(habitStart, cutoff)

        var periods: [Period] = []
        var cursor = date
        var iterations = 0

        while cursor >= lowerBound && iterations < 400 {
            guard let p = period(for: cursor) else { break }
            periods.append(p)
            guard let prev = cal.date(byAdding: .day, value: -1, to: p.start),
                  prev >= lowerBound else { break }
            cursor = prev
            iterations += 1
        }
        return periods  // newest first
    }
}

// MARK: - Date helpers

private func max(_ a: Date, _ b: Date) -> Date { a > b ? a : b }
