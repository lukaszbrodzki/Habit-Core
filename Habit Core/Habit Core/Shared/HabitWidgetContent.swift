import SwiftUI
import WidgetKit

// Widget content shared by the widget extension and the app (dual target membership). The app
// uses it only in Debug, to render real widget images for App Store screenshots.

/// Enough tiles for the widest widget grid (13 × 5), with headroom.
let widgetHistoryTiles = 84

/// Plain-value snapshot of a Habit, safe to hold after the fetching ModelContext goes away.
/// `summary` covers every counted period (same numbers as the app's Tracker, honouring
/// Settings → "Count only recent"); `recentPeriods` is just the tail of it the grid can show.
struct HabitSnapshot: Identifiable {
    let id: UUID
    let name: String
    let colorHex: String
    let recentPeriods: [Bool]
    let summary: HabitStats.HabitSummary
}

enum HabitWidgetMode {
    /// `nil` snapshot means the configured habit no longer exists (deleted) or there are none yet.
    case singleHabit(HabitSnapshot?)
    /// Per-day completion across all active habits (tail the grid can show, oldest first) and the
    /// summary over every counted day.
    case allHabits(colorHex: String, days: [HabitStats.Day], summary: HabitStats.CombinedSummary)
}

extension HabitWidgetMode {
    /// What the widget shows for `habits` (active, in display order): one habit (`selection`) or,
    /// with `selection == nil`, All Habits in `colorHex`. Honours Settings → "Count only recent".
    static func make(habits: [Habit], selection: UUID?, limit: Int?, colorHex: String) -> HabitWidgetMode {
        guard let selection else {
            let days = HabitStats.allHabitsDays(habits: habits, limit: limit)
            return .allHabits(
                colorHex: colorHex,
                days: Array(days.suffix(widgetHistoryTiles)),
                summary: HabitStats.summary(of: days)
            )
        }
        guard let habit = habits.first(where: { $0.id == selection }) else { return .singleHabit(nil) }
        let completions = HabitStats.countedPeriods(of: habit, limit: limit).completions
        return .singleHabit(HabitSnapshot(
            id: habit.id,
            name: habit.name,
            colorHex: habit.colorHex,
            recentPeriods: Array(completions.suffix(widgetHistoryTiles)),
            summary: HabitStats.summary(of: completions)
        ))
    }
}

/// The widget's content for a given family. `family` is passed in (not read from the
/// environment) so the app can render it outside WidgetKit.
struct HabitWidgetContent: View {
    let mode: HabitWidgetMode
    let family: WidgetFamily

    private var columns: Int { family == .systemSmall ? 6 : 13 }
    // Medium is much wider than tall but not taller than small, so one fewer row keeps
    // width-based sizing (full-width tiles) from overflowing the available height.
    private var rowCount: Int { family == .systemSmall ? 6 : 5 }
    private var showFullStats: Bool { family != .systemSmall }

    var body: some View {
        switch mode {
        case .singleHabit(let habit):
            if let habit {
                // Stats match the app (all counted periods); the grid shows the most recent ones that fit.
                let summary = habit.summary
                let color = Color(hex: habit.colorHex) ?? .blue
                WidgetGridCard(
                    title: habit.name,
                    stats: [
                        .init(value: "\(summary.completed)/\(summary.total)", label: String(localized: "tracker.stat.completed")),
                        .init(value: "\(summary.ratePercent)%", label: String(localized: "tracker.stat.rate")),
                        .init(value: "\(summary.streak)", label: String(localized: "widget.stat.streak")),
                    ],
                    cells: habit.recentPeriods.map { HeatmapPalette.completion($0, color: color) },
                    columns: columns,
                    rowCount: rowCount,
                    showFullStats: showFullStats
                )
            } else {
                Text(String(localized: "widget.noselection"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        case .allHabits(let colorHex, let days, let summary):
            let color = Color(hex: colorHex) ?? .accentColor
            WidgetGridCard(
                title: String(localized: "tracker.combined.title"),
                stats: [
                    .init(value: "\(summary.perfectDays)/\(summary.totalDays)", label: String(localized: "widget.stat.perfect")),
                    .init(value: "\(summary.ratePercent)%", label: String(localized: "tracker.stat.rate")),
                    .init(value: "\(summary.streak)", label: String(localized: "widget.stat.streak")),
                ],
                cells: days.map { HeatmapPalette.rate($0.rate, color: color) },
                columns: columns,
                rowCount: rowCount,
                showFullStats: showFullStats
            )
        }
    }
}

/// Header + full-width heatmap. Tile size always comes from width alone (edge-to-edge tiles);
/// if the header leaves less height than `rowCount` rows need, the oldest rows are dropped rather
/// than shrinking every tile. The grid always renders its full capacity: real tiles come first
/// (most recent last), any remaining slots are neutral placeholders.
private struct WidgetGridCard: View {
    let title: String
    let stats: [StatsRow.Item]
    let cells: [Color]
    let columns: Int
    let rowCount: Int
    let showFullStats: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            GeometryReader { geo in
                let gap = HeatmapPalette.gap
                let tile = (geo.size.width - CGFloat(columns - 1) * gap) / CGFloat(columns)
                let maxRows = max(1, min(rowCount, Int((geo.size.height + gap) / (tile + gap))))
                let capacity = columns * maxRows
                let real = Array(cells.suffix(capacity))
                let padded = real + Array(repeating: HeatmapPalette.empty, count: max(0, capacity - real.count))
                HeatmapGrid(cells: padded, columns: columns, tileSize: tile)
            }
        }
        .padding(10)
    }

    @ViewBuilder private var header: some View {
        if showFullStats {
            HStack(spacing: 12) {
                Text(title).font(.caption).fontWeight(.semibold).lineLimit(1)
                Spacer(minLength: 4)
                StatsRow(items: stats, style: .compact, spacing: 12)
            }
        } else {
            HStack {
                Text(title).font(.caption2).fontWeight(.semibold).lineLimit(1)
                Spacer()
                if let first = stats.first {
                    Text(first.value)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

