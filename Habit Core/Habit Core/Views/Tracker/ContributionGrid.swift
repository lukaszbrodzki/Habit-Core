import SwiftUI

/// Contribution grid for a single habit. Each square = one counted period (day / week / month /
/// custom cycle), wrapped into rows of `columns`.
struct ContributionGrid: View {
    /// One flag per counted period, oldest first (see `HabitStats.countedPeriods`).
    let completions: [Bool]
    let color: Color

    var body: some View {
        HeatmapGrid(cells: completions.map { HeatmapPalette.completion($0, color: color) }, columns: 20)
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
        HeatmapGrid(cells: days.map { HeatmapPalette.rate($0.rate, color: color) }, columns: 20)
            .padding(.vertical, 2)
    }
}
