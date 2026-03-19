import SwiftUI

/// Contribution grid for a single habit — single row, scrolls horizontally.
/// Each square = one period (day / week / month / custom cycle).
struct ContributionGrid: View {
    let habit: Habit
    /// Periods sorted newest → oldest (from Habit.allPeriods).
    let periods: [Habit.Period]

    private let size: CGFloat = 13
    private let gap: CGFloat  = 3

    /// Oldest first for left-to-right display.
    private var sorted: [Habit.Period] { periods.reversed() }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: gap) {
                ForEach(sorted.indices, id: \.self) { idx in
                    square(for: sorted[idx])
                }
            }
            .padding(.vertical, 2)
        }
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
struct CombinedGrid: View {
    let habits: [Habit]

    private let size: CGFloat = 13
    private let gap: CGFloat  = 3

    // Last 365 days, oldest first
    private var days: [Date] {
        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<365)
            .compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
            .reversed()
    }

    private var columns: [[Date]] {
        var cols: [[Date]] = []
        var col:  [Date]   = []
        for day in days {
            col.append(day)
            if col.count == 7 { cols.append(col); col = [] }
        }
        if !col.isEmpty { cols.append(col) }
        return cols
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: gap) {
                ForEach(columns.indices, id: \.self) { col in
                    VStack(spacing: gap) {
                        ForEach(columns[col], id: \.self) { day in
                            let rate = completionRate(on: day)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.accentColor.opacity(0.12 + rate * 0.88))
                                .frame(width: size, height: size)
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func completionRate(on date: Date) -> Double {
        let cal = Calendar.current
        let active = habits.filter { !$0.isArchived }

        // Habits whose deadline falls on this date
        let due = active.filter { habit in
            guard let p = habit.period(for: date) else { return false }
            return cal.isDate(p.end, inSameDayAs: date)
        }
        guard !due.isEmpty else { return 0 }

        let done = due.filter { habit in
            guard let p = habit.period(for: date) else { return false }
            return habit.isCompleted(in: p)
        }
        return Double(done.count) / Double(due.count)
    }
}
