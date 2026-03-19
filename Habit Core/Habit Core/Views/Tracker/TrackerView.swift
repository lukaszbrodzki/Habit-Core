import SwiftUI
import SwiftData

struct TrackerView: View {
    @Query(
        filter: #Predicate<Habit> { !$0.isArchived },
        sort: [SortDescriptor(\Habit.sortOrder)]
    )
    private var habits: [Habit]

    @State private var showCombined = false
    @State private var habitToEdit: Habit?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    if showCombined {
                        // Combined view
                        VStack(alignment: .leading, spacing: 10) {
                            Text(String(localized: "tracker.combined.title"))
                                .font(.headline)
                            CombinedGrid(habits: habits)
                        }
                        .padding(14)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    } else {
                        ForEach(habits) { habit in
                            HabitGridSection(habit: habit) {
                                habitToEdit = habit
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(String(localized: "tab.tracker"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCombined.toggle()
                    } label: {
                        Image(systemName: showCombined ? "rectangle.grid.1x2" : "square.grid.3x3")
                    }
                }
            }
            .overlay {
                if habits.isEmpty {
                    ContentUnavailableView(
                        String(localized: "tracker.empty.title"),
                        systemImage: "chart.bar",
                        description: Text(String(localized: "tracker.empty.description"))
                    )
                }
            }
            .sheet(item: $habitToEdit) { habit in
                AddHabitView(editing: habit)
            }
        }
    }
}
