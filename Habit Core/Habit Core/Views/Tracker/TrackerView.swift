import SwiftUI
import SwiftData

struct TrackerView: View {
    @Query(
        filter: #Predicate<Habit> { !$0.isArchived },
        sort: [SortDescriptor(\Habit.sortOrder)]
    )
    private var habits: [Habit]

    @Environment(AppTheme.self) private var theme
    @Environment(StatsSettings.self) private var stats

    @State private var showCombined = false
    @State private var showCombinedSettings = false
    @State private var showStatsInfo = false
    @State private var habitToEdit: Habit?
    @State private var habitPendingDeletion: Habit?

    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notifications

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    if showCombined {
                        // Combined view — days computed once, shared by the grid and the stats.
                        let days = combinedDays
                        let stats = HabitStats.summary(of: days)
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
                                .accessibilityLabel(String(localized: "accessibility.combined.settings"))
                            }
                            HStack {
                                StatsRow(items: [
                                    .init(value: "\(stats.perfectDays)/\(stats.totalDays)",
                                          label: String(localized: "tracker.stat.perfectdays")),
                                    .init(value: "\(stats.ratePercent)%", label: String(localized: "tracker.stat.rate")),
                                    .init(value: "\(stats.streak)", label: String(localized: "tracker.stat.streak")),
                                ])
                                Spacer()
                            }
                            CombinedGrid(days: days, color: Color(hex: theme.combinedGridColorHex) ?? .accentColor)
                        }
                        .padding(14)
                        .cardBackground()
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
                // Trailing, next to the view toggle — HIG: the trailing edge holds buttons that
                // open nearby inspectors; the leading edge is for navigation. Only relevant to
                // the All Habits view, whose numbers it explains.
                if showCombined {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showStatsInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                        }
                        .accessibilityLabel(String(localized: "statsinfo.title"))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCombined.toggle()
                    } label: {
                        Image(systemName: showCombined ? "rectangle.grid.1x2" : "square.grid.3x3")
                    }
                    .accessibilityLabel(String(localized: showCombined
                        ? "accessibility.tracker.showindividual"
                        : "accessibility.tracker.showcombined"))
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
            .sheet(item: $habitToEdit, onDismiss: deletePendingHabit) { habit in
                AddHabitView(editing: habit) { habitPendingDeletion = $0 }
            }
            .sheet(isPresented: $showCombinedSettings) {
                CombinedGridSettingsView()
            }
            .sheet(isPresented: $showStatsInfo) {
                StatsInfoView()
            }
        }
    }

    private func deletePendingHabit() {
        guard let habit = habitPendingDeletion else { return }
        habitPendingDeletion = nil
        HabitActions(context: modelContext, notifications: notifications).delete(habit)
    }

    private var combinedDays: [HabitStats.Day] {
        HabitStats.allHabitsDays(habits: habits, limit: stats.limit)
    }
}
