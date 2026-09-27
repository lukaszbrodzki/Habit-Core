import SwiftUI

/// Contribution grid for a single habit — single row, scrolls horizontally.
/// Each square = one period (day / week / month / custom cycle).
struct ContributionGrid: View {
    let habit: Habit
    /// Periods sorted newest → oldest (from Habit.allPeriods).
    let periods: [Habit.Period]

    private let size: CGFloat = 13
    private let gap: CGFloat  = 3
    private let columns = 20

    /// Oldest first for left-to-right display.
    private var sorted: [Habit.Period] { periods.reversed() }

    private var rows: [[Habit.Period]] {
        stride(from: 0, to: sorted.count, by: columns).map {
            Array(sorted[$0..<min($0 + columns, sorted.count)])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: gap) {
            ForEach(rows.indices, id: \.self) { rowIdx in
                HStack(spacing: gap) {
                    ForEach(rows[rowIdx].indices, id: \.self) { colIdx in
                        square(for: rows[rowIdx][colIdx])
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func square(for period: Habit.Period) -> some View {
        let completed = habit.isCompleted(in: period)
        let future    = period.start > Date()
        return RoundedRectangle(cornerRadius: 3)
            .fill(color(completed: completed, future: future))
            .frame(width: size, height: size)
    }

    private func color(completed: Bool, future: Bool) -> Color {
        if future    { return Color.secondary.opacity(0.12) }
        if completed { return Color(hex: habit.colorHex) ?? .accentColor }
        return Color.secondary.opacity(0.2)
    }
}

/// Combined grid showing completion rate across all habits.
/// Wraps into rows (like ContributionGrid) instead of scrolling on its own —
/// the enclosing TrackerView scroll handles vertical overflow.
struct CombinedGrid: View {
    let habits: [Habit]

    @Environment(AppTheme.self) private var theme

    private let size: CGFloat = 13
    private let gap: CGFloat  = 3
    private let columns = 20

    // Last 365 days, oldest first
    private var days: [Date] {
        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<365)
            .compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
            .reversed()
    }

    private var rows: [[Date]] {
        stride(from: 0, to: days.count, by: columns).map {
            Array(days[$0..<min($0 + columns, days.count)])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: gap) {
            ForEach(rows.indices, id: \.self) { rowIdx in
                HStack(spacing: gap) {
                    ForEach(rows[rowIdx], id: \.self) { day in
                        let rate: Double = completionRate(on: day)
                        let base: Color = Color(hex: theme.combinedGridColorHex) ?? .accentColor
                        RoundedRectangle(cornerRadius: 3)
                            .fill(base.opacity(0.12 + rate * 0.88))
                            .frame(width: size, height: size)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    /// Active habits whose deadline falls on `date`.
    private func dueHabits(on date: Date) -> [Habit] {
        let cal = Calendar.current
        return habits.filter { habit in
            guard !habit.isArchived, let p = habit.period(for: date) else { return false }
            return cal.isDate(p.end, inSameDayAs: date)
        }
    }

    private func completionRate(on date: Date) -> Double {
        let due = dueHabits(on: date)
        guard !due.isEmpty else { return 0 }

        let done = due.filter { habit in
            guard let p = habit.period(for: date) else { return false }
            return habit.isCompleted(in: p)
        }
        return Double(done.count) / Double(due.count)
    }
}

extension CombinedGrid {
    struct Stats {
        /// Days where every due habit was completed, out of days that had any habit due.
        let perfectDays: Int
        let totalDueDays: Int
        /// Average completion rate across days with at least one due habit.
        let ratePercent: Int
        /// Longest run of consecutive days with no unmet habit (days with nothing due don't break it).
        let streak: Int
    }

    var stats: Stats {
        var perfectDays  = 0
        var totalDueDays = 0
        var rateSum       = 0.0
        var streak        = 0
        var best          = 0

        for day in days {
            let due = dueHabits(on: day)
            if due.isEmpty {
                streak += 1
                best = max(best, streak)
                continue
            }
            totalDueDays += 1
            let rate = completionRate(on: day)
            rateSum += rate
            if rate == 1.0 {
                perfectDays += 1
                streak += 1
            } else {
                streak = 0
            }
            best = max(best, streak)
        }

        let pct = totalDueDays > 0 ? Int((rateSum / Double(totalDueDays)) * 100) : 0
        return Stats(perfectDays: perfectDays, totalDueDays: totalDueDays, ratePercent: pct, streak: best)
    }
}
