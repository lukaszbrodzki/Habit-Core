import SwiftUI
import SwiftData

struct ReorderHabitsView: View {
    var habits: [Habit]

    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notifications
    @Environment(\.dismiss)      private var dismiss

    @State private var ordered: [Habit] = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(ordered) { habit in
                    HStack(spacing: 10) {
                        HabitColorDot(colorHex: habit.colorHex)
                        Text(habit.name)
                        Spacer()
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.secondary)
                    }
                }
                .onMove { from, to in
                    ordered.move(fromOffsets: from, toOffset: to)
                    updateSortOrder()
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle(String(localized: "settings.reorder"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "button.done")) { dismiss() }
                }
            }
            .onAppear { ordered = habits }
        }
    }

    private func updateSortOrder() {
        for (idx, habit) in ordered.enumerated() {
            habit.sortOrder = idx
        }
        HabitActions(context: modelContext, notifications: notifications).commit()
    }
}
