import Foundation

/// Grid/stat math shared by the app's Tracker and the widget (dual target membership), so both
/// always show the same numbers for the same data. Pure functions over already-fetched habits.
enum HabitStats {

    // MARK: - Day window

    /// Calendar days from `start` through `today`, oldest first — but never earlier than `cutoff`.
    static func dayWindow(since start: Date, notBefore cutoff: Date, through today: Date = Date()) -> [Date] {
        let cal = Calendar.current
        let end = cal.startOfDay(for: today)
        var cursor = max(cal.startOfDay(for: start), cal.startOfDay(for: cutoff))
        var result: [Date] = []
        while cursor <= end {
            result.append(cursor)
            guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }

    // MARK: - Per-habit (one tile per period)

    /// The periods that count toward a habit's grid and stats, oldest first, with their completion.
    /// The current period is still in progress, so it only counts once it's done (otherwise an
    /// untouched "today" would read as a miss). `limit` = Settings → "Count only recent"
    /// (`nil` = whole history): the most recent `limit` counted periods.
    static func countedPeriods(
        of habit: Habit, limit: Int?, now: Date = Date()
    ) -> (periods: [Habit.Period], completions: [Bool]) {
        var periods = Array(habit.allPeriods(upTo: now).reversed())
        var done = completions(of: habit, in: periods)
        if let current = periods.last, current.contains(now), done.last == false {
            periods.removeLast()
            done.removeLast()
        }
        if let limit {
            periods = Array(periods.suffix(limit))
            done = Array(done.suffix(limit))
        }
        return (periods, done)
    }

    /// Completion of each period, in the same order as `periods`. Builds the completion index
    /// once instead of scanning every entry per period.
    static func completions(of habit: Habit, in periods: [Habit.Period]) -> [Bool] {
        let index = CompletionIndex(habit: habit)
        return periods.map(index.contains)
    }

    struct HabitSummary: Equatable {
        let completed: Int
        let total: Int
        let ratePercent: Int
        /// Longest run of consecutive completed periods.
        let streak: Int
    }

    /// `completions` must be chronological (oldest first) for the streak to be meaningful.
    static func summary(of completions: [Bool]) -> HabitSummary {
        let completed = completions.filter { $0 }.count
        let total = completions.count
        return HabitSummary(
            completed: completed,
            total: total,
            ratePercent: percent(Double(completed), of: Double(total)),
            streak: longestRun(completions)
        )
    }

    // MARK: - Combined (one tile per day, across all habits)

    struct Day: Equatable {
        let date: Date
        /// Share of habits due that day that got done; 0 when nothing was due.
        let rate: Double
        /// Distinguishes "nothing was due" (not a failure) from "due and missed" — both have rate 0.
        let hadDue: Bool

        /// No unmet habit that day (including days with nothing due).
        var isPerfect: Bool { !hadDue || rate == 1 }
    }

    /// The "All Habits" series used by both the Tracker and the widget: one `Day` per calendar day
    /// from the earliest start among the *active* habits through `today`, oldest first. Archived
    /// habits are ignored entirely. Today only counts once nothing due is left (same rule as
    /// `countedPeriods`); `limit` keeps the most recent `limit` counted days (`nil` = all).
    static func allHabitsDays(habits: [Habit], limit: Int?, today: Date = Date()) -> [Day] {
        let active = habits.filter { !$0.isArchived }
        guard let earliest = active.map(\.effectiveStart).min() else { return [] }
        let cal = Calendar.current
        // One spare day, in case today turns out to be still in progress and gets dropped.
        let cutoff = limit.flatMap { cal.date(byAdding: .day, value: -$0, to: today) } ?? earliest
        var days = combinedDays(habits: active, days: dayWindow(since: earliest, notBefore: cutoff, through: today))
        if let last = days.last, cal.isDate(last.date, inSameDayAs: today), !last.isPerfect {
            days.removeLast()
        }
        if let limit { days = Array(days.suffix(limit)) }
        return days
    }

    /// Per-day completion across `habits` for each of `days` (calendar-day starts, oldest first).
    ///
    /// A habit counts on a day exactly when that day is the deadline (last day) of one of its
    /// periods, within its start/end dates — the same rule as `Habit.isDue(on:)`. Walking each
    /// habit's periods instead of asking `isDue` for every day × habit keeps this cheap (a weekly
    /// habit has ~52 periods a year, not 365 day checks), which matters on long histories.
    static func combinedDays(habits: [Habit], days: [Date]) -> [Day] {
        guard let first = days.min(), let last = days.max() else { return [] }
        let cal = Calendar.current
        let windowEnd = cal.date(byAdding: .day, value: 1, to: last)?.addingTimeInterval(-1) ?? last

        var dueCount: [Date: Int] = [:]
        var doneCount: [Date: Int] = [:]
        for habit in habits where !habit.isArchived {
            let index = CompletionIndex(habit: habit)
            let startDay = cal.startOfDay(for: habit.effectiveStart)
            let endDay = habit.hasEndDate ? habit.endDate.map { cal.startOfDay(for: $0) } : nil
            for period in habit.allPeriods(upTo: windowEnd) {
                let deadline = cal.startOfDay(for: period.end)
                guard deadline >= first, deadline <= last, deadline >= startDay else { continue }
                if let endDay, deadline > endDay { continue }
                dueCount[deadline, default: 0] += 1
                if index.contains(period) { doneCount[deadline, default: 0] += 1 }
            }
        }
        return days.map { day in
            let due = dueCount[day] ?? 0
            guard due > 0 else { return Day(date: day, rate: 0, hadDue: false) }
            return Day(date: day, rate: Double(doneCount[day] ?? 0) / Double(due), hadDue: true)
        }
    }

    struct CombinedSummary: Equatable {
        let perfectDays: Int
        let totalDays: Int
        /// Average completion rate across days with at least one due habit.
        let ratePercent: Int
        /// Longest run of perfect days (days with nothing due don't break it).
        let streak: Int
    }

    /// `days` must be chronological (oldest first).
    static func summary(of days: [Day]) -> CombinedSummary {
        let due = days.filter(\.hadDue)
        let rate = percent(due.map(\.rate).reduce(0, +), of: Double(due.count))
        return CombinedSummary(
            perfectDays: days.filter(\.isPerfect).count,
            totalDays: days.count,
            ratePercent: rate,
            streak: longestRun(days.map(\.isPerfect))
        )
    }

    // MARK: - Helpers

    /// Rounded to the nearest whole percent (10/11 → 91%), 0 when there's nothing to count.
    private static func percent(_ part: Double, of whole: Double) -> Int {
        whole > 0 ? Int((part / whole * 100).rounded()) : 0
    }

    private static func longestRun(_ flags: [Bool]) -> Int {
        var longest = 0
        var current = 0
        for flag in flags {
            current = flag ? current + 1 : 0
            longest = max(longest, current)
        }
        return longest
    }
}

/// Sorted `periodStart`s of a habit's completed entries — answers "was this period completed?"
/// with a binary search instead of a linear scan over every entry.
struct CompletionIndex {
    private let starts: [Date]

    init(habit: Habit) {
        starts = (habit.entries ?? []).filter(\.isCompleted).map(\.periodStart).sorted()
    }

    /// Same semantics as `Habit.isCompleted(in:)`: some completed entry starts inside the period.
    func contains(_ period: Habit.Period) -> Bool {
        var low = 0
        var high = starts.count
        while low < high {
            let mid = (low + high) / 2
            if starts[mid] < period.start { low = mid + 1 } else { high = mid }
        }
        return low < starts.count && starts[low] <= period.end
    }
}
