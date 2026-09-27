import SwiftUI
import SwiftData

struct TrackerView: View {
    @Query(
        filter: #Predicate<Habit> { !$0.isArchived },
        sort: [SortDescriptor(\Habit.sortOrder)]
    )
    private var habits: [Habit]

    @State private var showCombined = false
    @State private var showCombinedSettings = false
    @State private var habitToEdit: Habit?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    if showCombined {
                        // Combined view
                        let grid = CombinedGrid(habits: habits)
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top) {
                                Text(String(localized: "tracker.combined.title"))
                                    .font(.headline)
                                Spacer()
                                Button {
                                    showCombinedSettings = true
                                } label: {
                                    Image(systemName: "gearshape")
                                        .foregroundStyle(.secondary)
                                        .padding(6)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                            combinedStatsRow(grid.stats)
                            grid
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
            .appBackground()
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
            .sheet(isPresented: $showCombinedSettings) {
                CombinedGridSettingsView()
            }
        }
    }

    private func combinedStatsRow(_ stats: CombinedGrid.Stats) -> some View {
        HStack(spacing: 16) {
            StatChip(
                value: "\(stats.perfectDays)/\(stats.totalDays)",
                label: String(localized: "tracker.stat.perfectdays")
            )
            StatChip(
                value: "\(stats.ratePercent)%",
                label: String(localized: "tracker.stat.rate")
            )
            StatChip(
                value: "\(stats.streak)",
                label: String(localized: "tracker.stat.streak")
            )
            Spacer()
        }
    }
}
