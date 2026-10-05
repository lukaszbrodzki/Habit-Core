import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(
        filter: #Predicate<Habit> { !$0.isArchived },
        sort: [SortDescriptor(\Habit.sortOrder)]
    )
    private var habits: [Habit]

    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notifications

    @State private var showingAddHabit = ScreenshotMode.openAdd

    private var sorted: [Habit] {
        habits.sorted {
            if $0.todaySortPriority != $1.todaySortPriority {
                return $0.todaySortPriority < $1.todaySortPriority
            }
            let a = $0.dueDate ?? .distantFuture
            let b = $1.dueDate ?? .distantFuture
            return a < b
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty {
                    ContentUnavailableView(
                        String(localized: "today.empty.title"),
                        systemImage: "checkmark.circle",
                        description: Text(String(localized: "today.empty.description"))
                    )
                } else {
                    List(sorted) { habit in
                        HabitTodayRow(habit: habit)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .swipeActions(edge: .trailing) {
                                Button {
                                    HabitActions(context: modelContext, notifications: notifications).archive(habit)
                                } label: {
                                    Label(String(localized: "button.archive"), systemImage: "archivebox")
                                }
                                .tint(.orange)
                            }
                    }
                    .listStyle(.plain)
                    .refreshOnNewDay()
                }
            }
            .appBackground()
            .navigationTitle(String(localized: "tab.today"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddHabit = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel(String(localized: "addhabit.title.add"))
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
        }
    }
}
