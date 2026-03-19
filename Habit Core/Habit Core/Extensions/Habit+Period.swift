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

    /// Returns the active period for `date`.
    ///
    /// - **Daily**: the calendar day itself.
    /// - **Weekly** (e.g. every Tuesday): the 7-day window whose deadline is the
    ///   *next* Tuesday on or after `date`. So on a Wednesday the window is
    ///   Wed → following Tue, giving the user the whole week until the deadline.
    /// - **Monthly** (e.g. every 1st): the ~month-long window whose deadline is
    ///   the *next* occurrence of `monthDay` on or after `date`.
    /// - **Custom** (every N days): the N-day slot from `createdAt`.
    func period(for date: Date = Date()) -> Period? {
        let cal = Calendar.current

        switch frequency {

        // MARK: Daily
        case .daily:
            let start = cal.startOfDay(for: date)
            guard let end = cal.date(byAdding: .day, value: 1, to: start)?
                .addingTimeInterval(-1) else { return nil }
            return Period(start: start, end: end)

        // MARK: Weekly
        case .weekly:
            // Deadline = this day if today IS the weekDay, otherwise next occurrence.
            let deadlineDate: Date
            if cal.component(.weekday, from: date) == weekDay {
                deadlineDate = date
            } else {
                var matchComps = DateComponents()
                matchComps.weekday = weekDay
                guard let next = cal.nextDate(
                    after: date,
                    matching: matchComps,
                    matchingPolicy: .nextTimePreservingSmallerComponents
                ) else { return nil }
                deadlineDate = next
            }

            let deadlineStart = cal.startOfDay(for: deadlineDate)
            guard let end = cal.date(byAdding: .day, value: 1, to: deadlineStart)?
                .addingTimeInterval(-1) else { return nil }
            // Window starts 6 days before the deadline (7-day window)
            guard let start = cal.date(byAdding: .day, value: -6, to: deadlineStart)
            else { return nil }
            return Period(start: start, end: end)

        // MARK: Monthly
        case .monthly:
            // Deadline = next occurrence of monthDay on or after `date`
            let deadline = nextMonthDay(onOrAfter: date, cal: cal)
            guard let deadline else { return nil }

            let deadlineStart = cal.startOfDay(for: deadline)
            guard let end = cal.date(byAdding: .day, value: 1, to: deadlineStart)?
                .addingTimeInterval(-1) else { return nil }

            // Window starts the day after the *previous* monthly deadline
            let prevDeadline = prevMonthDay(before: deadline, cal: cal)
            let start: Date
            if let prevDeadline {
                let prevStart = cal.startOfDay(for: prevDeadline)
                start = cal.date(byAdding: .day, value: 1, to: prevStart) ?? deadlineStart
            } else {
                start = cal.startOfDay(for: createdAt)
            }
            return Period(start: start, end: end)

        // MARK: Custom
        case .custom:
            let origin = cal.startOfDay(for: createdAt)
            let today  = cal.startOfDay(for: date)
            let diff   = cal.dateComponents([.day], from: origin, to: today).day ?? 0
            let idx    = diff / customDays
            guard
                let pStart   = cal.date(byAdding: .day, value:  idx      * customDays, to: origin),
                let pLastDay = cal.date(byAdding: .day, value: (idx + 1) * customDays - 1, to: origin),
                let pEnd     = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: pLastDay))?
                    .addingTimeInterval(-1)
            else { return nil }
            return Period(start: pStart, end: pEnd)
        }
    }

    // MARK: - Monthly deadline helpers

    private func nextMonthDay(onOrAfter date: Date, cal: Calendar) -> Date? {
        let dayStart = cal.startOfDay(for: date)
        var comps    = cal.dateComponents([.year, .month], from: date)

        // Try this month
        let daysThis = cal.range(of: .day, in: .month, for: date)?.count ?? 28
        comps.day    = min(monthDay, daysThis)
        if let candidate = cal.date(from: comps),
           cal.startOfDay(for: candidate) >= dayStart {
            return candidate
        }

        // Move to next month
        comps.month  = (comps.month ?? 1) + 1
        comps.day    = 1
        guard let nextMonthDate = cal.date(from: comps) else { return nil }
        let daysNext = cal.range(of: .day, in: .month, for: nextMonthDate)?.count ?? 28
        comps.day    = min(monthDay, daysNext)
        return cal.date(from: comps)
    }

    private func prevMonthDay(before deadline: Date, cal: Calendar) -> Date? {
        var comps   = cal.dateComponents([.year, .month], from: deadline)
        comps.month = (comps.month ?? 1) - 1
        comps.day   = 1
        guard let prevMonthDate = cal.date(from: comps) else { return nil }
        let days    = cal.range(of: .day, in: .month, for: prevMonthDate)?.count ?? 28
        comps.day   = min(monthDay, days)
        return cal.date(from: comps)
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
        entries.contains {
            $0.isCompleted && $0.periodStart >= period.start && $0.periodStart <= period.end
        }
    }

    /// Deadline date for Today-view display.
    var dueDate: Date? { period(for: Date())?.end }

    /// Longest consecutive streak of completed periods (chronological order).
    func longestStreak(in periods: [Period]) -> Int {
        var longest = 0
        var current = 0
        for period in periods.reversed() {   // reversed = oldest first
            if isCompleted(in: period) {
                current += 1
                if current > longest { longest = current }
            } else {
                current = 0
            }
        }
        return longest
    }

    /// Sort key for Today view: 0 = due & incomplete, 1 = not due, 2 = completed.
    var todaySortPriority: Int {
        if isCompletedToday { return 2 }
        return canMarkToday ? 0 : 1
    }

    // MARK: - History periods (newest first)

    /// All periods from `createdAt` up to `date`, newest first.
    /// Capped at 1 year / 400 iterations.
    func allPeriods(upTo date: Date = Date()) -> [Period] {
        let cal        = Calendar.current
        let cutoff     = cal.date(byAdding: .year, value: -1, to: date) ?? date
        let habitStart = cal.startOfDay(for: createdAt)
        let lowerBound = habitStart > cutoff ? habitStart : cutoff

        var periods    = [Period]()
        var cursor     = date
        var iterations = 0

        while cursor >= lowerBound && iterations < 400 {
            guard let p = period(for: cursor) else { break }
            periods.append(p)
            guard let prev = cal.date(byAdding: .day, value: -1, to: p.start),
                  prev >= lowerBound else { break }
            cursor = prev
            iterations += 1
        }
        return periods
    }
}
