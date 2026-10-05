import WidgetKit
import SwiftUI
import SwiftData

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
        return Timeline(entries: [entry], policy: .after(Self.nextRefresh(after: Date())))
    }

    /// Every 30 minutes, but never later than the coming midnight — otherwise the widget could keep
    /// showing yesterday as "today" until the next periodic refresh.
    static func nextRefresh(after now: Date) -> Date {
        let cal = Calendar.current
        let periodic = cal.date(byAdding: .minute, value: 30, to: now) ?? now.addingTimeInterval(1800)
        guard let tomorrow = cal.date(byAdding: .day, value: 1, to: now) else { return periodic }
        return min(periodic, cal.startOfDay(for: tomorrow))
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
        let colorHex = UserDefaults(suiteName: AppGroup.identifier)?.string(forKey: SharedDefaults.combinedGridColorHexKey)
            ?? SharedDefaults.defaultColorHex
        let selection = configuration.habit.id == HabitEntity.allHabitsID ? nil : configuration.habit.id
        return HabitWidgetEntry(date: Date(), mode: .make(
            habits: habits,
            selection: selection,
            limit: SharedDefaults.statsLimit(),
            colorHex: colorHex
        ))
    }
}

struct Habit_Core_WidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: Provider.Entry

    var body: some View {
        HabitWidgetContent(mode: entry.mode, family: family)
    }
}

struct Habit_Core_Widget: Widget {
    let kind: String = "Habit_Core_Widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            Habit_Core_WidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(Text("widget.name"))
        .description(Text("widget.description"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    Habit_Core_Widget()
} timeline: {
    HabitWidgetEntry(date: .now, mode: .singleHabit(nil))
}
