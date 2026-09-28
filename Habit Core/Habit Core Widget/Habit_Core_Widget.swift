import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

/// Plain-value snapshot of a Habit, safe to hold after the fetching ModelContext goes away.
struct HabitSnapshot: Identifiable {
    let id: UUID
    let name: String
    let colorHex: String
    let isCompletedToday: Bool
    let canMarkToday: Bool
    /// Last 14 days, oldest first — used by the medium single-habit mini grid.
    let recentDays: [(date: Date, completed: Bool)]
}

enum HabitWidgetMode {
    /// `nil` snapshot means the configured habit no longer exists (deleted) or there are none yet.
    case singleHabit(HabitSnapshot?)
    case allHabits(dueToday: Int, doneToday: Int, items: [HabitSnapshot])
}

struct HabitWidgetEntry: TimelineEntry {
    let date: Date
    let mode: HabitWidgetMode
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> HabitWidgetEntry {
        HabitWidgetEntry(date: Date(), mode: .singleHabit(nil))
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> HabitWidgetEntry {
        makeEntry(configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<HabitWidgetEntry> {
        let entry = makeEntry(configuration: configuration)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }

    private func makeEntry(configuration: ConfigurationAppIntent) -> HabitWidgetEntry {
        guard let container = WidgetModelStore.container else {
            return HabitWidgetEntry(date: Date(), mode: .singleHabit(nil))
        }
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { !$0.isArchived },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let habits = (try? context.fetch(descriptor)) ?? []

        if configuration.habit.id == HabitEntity.allHabitsID {
            let due = habits.filter { $0.canMarkToday || $0.isCompletedToday }
            let done = due.filter { $0.isCompletedToday }
            let sorted = due.sorted { $0.todaySortPriority < $1.todaySortPriority }
            let items = sorted.map { snapshot(for: $0, includeHistory: false) }
            return HabitWidgetEntry(date: Date(), mode: .allHabits(dueToday: due.count, doneToday: done.count, items: items))
        } else {
            let match = habits.first { $0.id == configuration.habit.id }
            let snap = match.map { snapshot(for: $0, includeHistory: true) }
            return HabitWidgetEntry(date: Date(), mode: .singleHabit(snap))
        }
    }

    private func snapshot(for habit: Habit, includeHistory: Bool) -> HabitSnapshot {
        var days: [(date: Date, completed: Bool)] = []
        if includeHistory {
            let cal = Calendar.current
            let today = cal.startOfDay(for: Date())
            days = (0..<14).reversed().compactMap { offset in
                guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
                let completed = habit.period(for: day).map { habit.isCompleted(in: $0) } ?? false
                return (day, completed)
            }
        }
        return HabitSnapshot(
            id: habit.id,
            name: habit.name,
            colorHex: habit.colorHex,
            isCompletedToday: habit.isCompletedToday,
            canMarkToday: habit.canMarkToday,
            recentDays: days
        )
    }
}

struct Habit_Core_WidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: Provider.Entry

    var body: some View {
        switch entry.mode {
        case .singleHabit(let habit):
            if let habit {
                if family == .systemSmall {
                    SingleHabitSmallView(habit: habit)
                } else {
                    SingleHabitMediumView(habit: habit)
                }
            } else {
                Text("No habit selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        case .allHabits(let dueToday, let doneToday, let items):
            if family == .systemSmall {
                AllHabitsSmallView(dueToday: dueToday, doneToday: doneToday)
            } else {
                AllHabitsMediumView(items: items)
            }
        }
    }
}

private struct SingleHabitSmallView: View {
    let habit: HabitSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(Color(hex: habit.colorHex) ?? .blue).frame(width: 8, height: 8)
                Text(habit.name).font(.caption).fontWeight(.semibold).lineLimit(1)
            }
            Spacer()
            HStack {
                Spacer()
                Button(intent: ToggleHabitIntent(habitID: habit.id)) {
                    Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 34))
                        .foregroundStyle(habit.isCompletedToday ? (Color(hex: habit.colorHex) ?? .blue) : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(!habit.canMarkToday && !habit.isCompletedToday)
                Spacer()
            }
            Spacer()
        }
        .padding()
    }
}

private struct SingleHabitMediumView: View {
    let habit: HabitSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Circle().fill(Color(hex: habit.colorHex) ?? .blue).frame(width: 8, height: 8)
                Text(habit.name).font(.subheadline).fontWeight(.semibold).lineLimit(1)
                Spacer()
                Button(intent: ToggleHabitIntent(habitID: habit.id)) {
                    Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(habit.isCompletedToday ? (Color(hex: habit.colorHex) ?? .blue) : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(!habit.canMarkToday && !habit.isCompletedToday)
            }
            Spacer()
            HStack(spacing: 3) {
                ForEach(habit.recentDays, id: \.date) { day in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(day.completed ? (Color(hex: habit.colorHex) ?? .blue) : Color.secondary.opacity(0.2))
                        .frame(height: 14)
                }
            }
        }
        .padding()
    }
}

private struct AllHabitsSmallView: View {
    let dueToday: Int
    let doneToday: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("All Habits").font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text("\(doneToday)/\(dueToday)")
                .font(.system(size: 32, weight: .bold))
            Text("done today").font(.caption2).foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}

private struct AllHabitsMediumView: View {
    let items: [HabitSnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if items.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("All done today 🎉").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(items.prefix(4)) { habit in
                    HStack(spacing: 8) {
                        Button(intent: ToggleHabitIntent(habitID: habit.id)) {
                            Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(habit.isCompletedToday ? (Color(hex: habit.colorHex) ?? .blue) : .secondary)
                        }
                        .buttonStyle(.plain)
                        Text(habit.name)
                            .font(.caption)
                            .strikethrough(habit.isCompletedToday)
                            .foregroundStyle(habit.isCompletedToday ? .secondary : .primary)
                            .lineLimit(1)
                        Spacer()
                    }
                }
            }
        }
        .padding()
    }
}

struct Habit_Core_Widget: Widget {
    let kind: String = "Habit_Core_Widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            Habit_Core_WidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Habit")
        .description("Track a habit, or all of them, from your Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    Habit_Core_Widget()
} timeline: {
    HabitWidgetEntry(date: .now, mode: .singleHabit(nil))
}
