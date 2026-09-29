import SwiftUI
import SwiftData

struct ArchivedHabitsView: View {
    @Query(filter: #Predicate<Habit> { $0.isArchived })
    private var archived: [Habit]

    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notifications
    @Environment(\.dismiss)      private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(archived, id: \.id) { habit in
                    row(for: habit)
                }
            }
            .overlay {
                if archived.isEmpty {
                    ContentUnavailableView(
                        String(localized: "archived.empty.title"),
                        systemImage: "archivebox"
                    )
                }
            }
            .navigationTitle(String(localized: "settings.archived"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "button.done")) { dismiss() }
                }
            }
        }
    }

    private var actions: HabitActions {
        HabitActions(context: modelContext, notifications: notifications)
    }

    private func row(for habit: Habit) -> some View {
        HStack {
            HabitColorDot(colorHex: habit.colorHex)

            Text(habit.name)

            Spacer()

            Button(String(localized: "settings.restore")) {
                actions.restore(habit)
            }
            .foregroundStyle(Color.accentColor)
            .buttonStyle(.borderless)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                actions.delete(habit)
            } label: {
                Label(String(localized: "button.delete"), systemImage: "trash")
            }
        }
    }
}
