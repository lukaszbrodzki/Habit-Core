import SwiftUI
import SwiftData

struct HabitTodayRow: View {
    let habit: Habit
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notifications

    private var accentColor: Color {
        Color(hex: habit.colorHex) ?? .blue
    }

    var body: some View {
        HStack(spacing: 14) {
            // Completion button
            Button {
                toggleCompletion()
            } label: {
                Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(habit.isCompletedToday ? accentColor : .secondary)
                    .animation(.bouncy, value: habit.isCompletedToday)
            }
            .buttonStyle(.plain)
            .disabled(!habit.canMarkToday)
            .accessibilityLabel(String(
                format: NSLocalizedString(
                    habit.isCompletedToday ? "accessibility.habit.markundone.format" : "accessibility.habit.markdone.format",
                    comment: ""
                ),
                habit.name
            ))
            .sensoryFeedback(trigger: habit.isCompletedToday) { _, isCompleted in
                isCompleted ? .success : .impact(weight: .light)
            }

            // Text
            VStack(alignment: .leading, spacing: 3) {
                Text(habit.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(habit.isCompletedToday ? .secondary : .primary)
                    .strikethrough(habit.isCompletedToday, color: .secondary)

                if !habit.habitDescription.isEmpty {
                    Text(habit.habitDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let due = habit.dueDate, !habit.isCompletedToday {
                    Text(due, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(due < Date() ? .red : .secondary)
                }
            }

            Spacer()

            // Color stripe
            RoundedRectangle(cornerRadius: 3)
                .fill(accentColor)
                .frame(width: 4, height: 40)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .cardBackground(cornerRadius: 14)
        .opacity(habit.canMarkToday || habit.isCompletedToday ? 1 : 0.45)
    }

    // MARK: - Actions

    private func toggleCompletion() {
        HabitActions(context: modelContext, notifications: notifications).toggleCompletion(of: habit)
    }
}
