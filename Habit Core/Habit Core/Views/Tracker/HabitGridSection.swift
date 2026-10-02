import SwiftUI

struct HabitGridSection: View {
    let habit: Habit
    let onEdit: () -> Void

    @Environment(StatsSettings.self) private var stats

    var body: some View {
        // Computed once per body pass, then shared by the grid and the stats row. Only counted
        // periods are shown, so the grid matches the numbers under it.
        let completions = HabitStats.countedPeriods(of: habit, limit: stats.limit).completions
        let summary = HabitStats.summary(of: completions)

        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(alignment: .top) {
                HStack(spacing: 8) {
                    HabitColorDot(colorHex: habit.colorHex)
                        .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.name)
                            .font(.headline)

                        if !habit.habitDescription.isEmpty {
                            Text(habit.habitDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text(habit.frequency.localizedName)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                Button {
                    onEdit()
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(.secondary)
                        .padding(6)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(format: NSLocalizedString("accessibility.edithabit.format", comment: ""), habit.name))
            }

            // Grid
            if completions.isEmpty {
                Text(String(localized: "tracker.nodata"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ContributionGrid(
                    completions: completions,
                    color: Color(hex: habit.colorHex) ?? .accentColor
                )
            }

            HStack {
                StatsRow(items: [
                    .init(value: "\(summary.completed)/\(summary.total)", label: String(localized: "tracker.stat.completed")),
                    .init(value: "\(summary.ratePercent)%", label: String(localized: "tracker.stat.rate")),
                    .init(value: "\(summary.streak)", label: String(localized: "tracker.stat.streak")),
                ])
                Spacer()
            }
        }
        .padding(14)
        .cardBackground()
    }
}
