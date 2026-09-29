import SwiftUI

/// Contribution grid for a single habit. Each square = one period (day / week / month / custom
/// cycle), wrapped into rows of `columns`.
struct ContributionGrid: View {
    /// Oldest first.
    let periods: [Habit.Period]
    /// Parallel to `periods` (see `HabitStats.completions(of:in:)`).
    let completions: [Bool]
    let color: Color

    var body: some View {
        let now = Date()
        let cells = zip(periods, completions).map { period, completed in
            HeatmapPalette.completion(period.start > now ? nil : completed, color: color)
        }
        HeatmapGrid(cells: cells, columns: 20, tileSize: 13)
            .padding(.vertical, 2)
    }
}

/// Combined grid showing each day's completion rate across all habits. Wraps into rows instead
/// of scrolling on its own — the enclosing TrackerView scroll handles vertical overflow.
struct CombinedGrid: View {
    /// Oldest first (see `HabitStats.combinedDays(habits:days:)`).
    let days: [HabitStats.Day]
    let color: Color

    var body: some View {
        HeatmapGrid(cells: days.map { HeatmapPalette.rate($0.rate, color: color) }, columns: 20, tileSize: 13)
            .padding(.vertical, 2)
    }
}
