import SwiftUI

struct HabitGridSection: View {
    let habit: Habit
    let onEdit: () -> Void

    private var periods: [Habit.Period] { habit.allPeriods() }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(alignment: .top) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: habit.colorHex) ?? .blue)
                        .frame(width: 10, height: 10)
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
            }

            // Grid
            if periods.isEmpty {
                Text(String(localized: "tracker.nodata"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ContributionGrid(habit: habit, periods: periods)
            }

            // Stats row
            statsRow
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    private var statsRow: some View {
        let total     = periods.count
        let completed = periods.filter { habit.isCompleted(in: $0) }.count
        let pct       = total > 0 ? Int(Double(completed) / Double(total) * 100) : 0
        let streak    = habit.longestStreak(in: periods)

        return HStack(spacing: 16) {
            statChip(
                value: "\(completed)/\(total)",
                label: String(localized: "tracker.stat.completed")
            )
            statChip(
                value: "\(pct)%",
                label: String(localized: "tracker.stat.rate")
            )
            statChip(
                value: "\(streak)",
                label: String(localized: "tracker.stat.streak")
            )
            Spacer()
        }
    }

    private func statChip(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value).font(.subheadline.weight(.semibold))
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}
