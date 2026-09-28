import WidgetKit
import SwiftUI
import SwiftData

/// Plain-value snapshot of a Habit, safe to hold after the fetching ModelContext goes away.
/// `recentDays` covers the last 84 days (enough for the widest widget grid), oldest first.
struct HabitSnapshot: Identifiable {
    let id: UUID
    let colorHex: String
    let recentDays: [(date: Date, completed: Bool)]
}

enum HabitWidgetMode {
    /// `nil` snapshot means the configured habit no longer exists (deleted) or there are none yet.
    case singleHabit(HabitSnapshot?)
    /// Per-day completion rate across all active habits, oldest first, same 84-day window.
    case allHabits(colorHex: String, days: [(date: Date, rate: Double)])
}

struct HabitWidgetEntry: TimelineEntry {
    let date: Date
    let mode: HabitWidgetMode
}

private let historyDays = 84

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
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let days = (0..<historyDays).reversed().compactMap { cal.date(byAdding: .day, value: -$0, to: today) }

        if configuration.habit.id == HabitEntity.allHabitsID {
            let colorHex = UserDefaults(suiteName: AppGroup.identifier)?.string(forKey: "combinedGridColorHex") ?? "#4A90D9"
            let rates = days.map { day -> (date: Date, rate: Double) in
                let due = habits.filter { habit in
                    guard !habit.isArchived, let p = habit.period(for: day) else { return false }
                    return cal.isDate(p.end, inSameDayAs: day)
                }
                guard !due.isEmpty else { return (day, 0) }
                let done = due.filter { habit in
                    guard let p = habit.period(for: day) else { return false }
                    return habit.isCompleted(in: p)
                }
                return (day, Double(done.count) / Double(due.count))
            }
            return HabitWidgetEntry(date: Date(), mode: .allHabits(colorHex: colorHex, days: rates))
        } else {
            guard let habit = habits.first(where: { $0.id == configuration.habit.id }) else {
                return HabitWidgetEntry(date: Date(), mode: .singleHabit(nil))
            }
            let recent = days.map { day -> (date: Date, completed: Bool) in
                let completed = habit.period(for: day).map { habit.isCompleted(in: $0) } ?? false
                return (day, completed)
            }
            let snap = HabitSnapshot(id: habit.id, colorHex: habit.colorHex, recentDays: recent)
            return HabitWidgetEntry(date: Date(), mode: .singleHabit(snap))
        }
    }
}

struct Habit_Core_WidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: Provider.Entry

    private var columns: Int { family == .systemSmall ? 6 : 13 }
    // Medium is much wider than tall but not taller than small, so one fewer row keeps
    // width-based sizing (full-width tiles) from overflowing the available height.
    private var rowCount: Int { family == .systemSmall ? 6 : 5 }

    var body: some View {
        switch entry.mode {
        case .singleHabit(let habit):
            if let habit {
                SingleHabitGridView(habit: habit, columns: columns, rowCount: rowCount)
            } else {
                Text("No habit selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        case .allHabits(let colorHex, let days):
            AllHabitsGridView(colorHex: colorHex, days: days, columns: columns, rowCount: rowCount)
        }
    }
}

/// Squares in rows, oldest-to-newest left-to-right — same visual language as the in-app
/// ContributionGrid/CombinedGrid (rounded corners), sized to always fill the widget's full width.
private struct SingleHabitGridView: View {
    let habit: HabitSnapshot
    let columns: Int
    let rowCount: Int

    private let gap: CGFloat = 3

    private var visibleDays: [(date: Date, completed: Bool)] {
        Array(habit.recentDays.suffix(columns * rowCount))
    }

    private var rows: [[(date: Date, completed: Bool)]] {
        stride(from: 0, to: visibleDays.count, by: columns).map {
            Array(visibleDays[$0..<min($0 + columns, visibleDays.count)])
        }
    }

    var body: some View {
        GeometryReader { geo in
            let widthBased = (geo.size.width - CGFloat(columns - 1) * gap) / CGFloat(columns)
            let heightBased = (geo.size.height - CGFloat(rowCount - 1) * gap) / CGFloat(rowCount)
            let size = min(widthBased, heightBased)
            VStack(alignment: .leading, spacing: gap) {
                ForEach(rows.indices, id: \.self) { r in
                    HStack(spacing: gap) {
                        ForEach(rows[r], id: \.date) { day in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(day.completed ? (Color(hex: habit.colorHex) ?? .blue) : Color.secondary.opacity(0.2))
                                .frame(width: size, height: size)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

private struct AllHabitsGridView: View {
    let colorHex: String
    let days: [(date: Date, rate: Double)]
    let columns: Int
    let rowCount: Int

    private let gap: CGFloat = 3

    private var visibleDays: [(date: Date, rate: Double)] {
        Array(days.suffix(columns * rowCount))
    }

    private var rows: [[(date: Date, rate: Double)]] {
        stride(from: 0, to: visibleDays.count, by: columns).map {
            Array(visibleDays[$0..<min($0 + columns, visibleDays.count)])
        }
    }

    var body: some View {
        GeometryReader { geo in
            let widthBased = (geo.size.width - CGFloat(columns - 1) * gap) / CGFloat(columns)
            let heightBased = (geo.size.height - CGFloat(rowCount - 1) * gap) / CGFloat(rowCount)
            let size = min(widthBased, heightBased)
            VStack(alignment: .leading, spacing: gap) {
                ForEach(rows.indices, id: \.self) { r in
                    HStack(spacing: gap) {
                        ForEach(rows[r], id: \.date) { day in
                            RoundedRectangle(cornerRadius: 3)
                                .fill((Color(hex: colorHex) ?? .accentColor).opacity(0.12 + day.rate * 0.88))
                                .frame(width: size, height: size)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
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
        .description("See a habit's recent history, or all of them, from your Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    Habit_Core_Widget()
} timeline: {
    HabitWidgetEntry(date: .now, mode: .singleHabit(nil))
}
