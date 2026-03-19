import SwiftUI
import SwiftData

struct ArchivedHabitsView: View {
    @Query(filter: #Predicate<Habit> { $0.isArchived })
    private var archived: [Habit]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if archived.isEmpty {
                    ContentUnavailableView(
                        String(localized: "archived.empty.title"),
                        systemImage: "archivebox"
                    )
                } else {
                    List(archived) { habit in
                        HStack {
                            Circle()
                                .fill(Color(hex: habit.colorHex) ?? .blue)
                                .frame(width: 10, height: 10)

                            Text(habit.name)

                            Spacer()

                            Button(String(localized: "settings.restore")) {
                                habit.isArchived = false
                                try? modelContext.save()
                            }
                            .foregroundStyle(.accentColor)
                            .buttonStyle(.borderless)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(habit)
                                try? modelContext.save()
                            } label: {
                                Label(String(localized: "button.delete"), systemImage: "trash")
                            }
                        }
                    }
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
}
