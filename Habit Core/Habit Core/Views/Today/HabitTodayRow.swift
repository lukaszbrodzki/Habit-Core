import SwiftUI
import SwiftData

struct HabitTodayRow: View {
    @Bindable var habit: Habit
    @Environment(\.modelContext) private var modelContext

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
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        .opacity(habit.canMarkToday || habit.isCompletedToday ? 1 : 0.45)
    }

    // MARK: - Actions

    private func toggleCompletion() {
        guard habit.canMarkToday else { return }

        if habit.isCompletedToday {
            // Remove the entry for the current period
            if let p = habit.period(for: Date()),
               let entry = habit.entries.first(where: {
                   $0.isCompleted && $0.periodStart >= p.start && $0.periodStart <= p.end
               }) {
                modelContext.delete(entry)
            }
        } else {
            if let p = habit.period(for: Date()) {
                let entry = HabitEntry(periodStart: p.start, periodEnd: p.end, habit: habit)
                entry.isCompleted = true
                entry.completedAt = Date()
                modelContext.insert(entry)
                habit.entries.append(entry)
            }
        }

        try? modelContext.save()
    }
}
