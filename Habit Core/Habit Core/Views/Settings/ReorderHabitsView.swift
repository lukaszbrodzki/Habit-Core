import SwiftUI
import SwiftData

struct ReorderHabitsView: View {
    var habits: [Habit]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @State private var ordered: [Habit] = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(ordered) { habit in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color(hex: habit.colorHex) ?? .blue)
                            .frame(width: 10, height: 10)
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
        try? modelContext.save()
    }
}
