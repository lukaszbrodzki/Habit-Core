#if DEBUG
import SwiftData
import SwiftUI
import WidgetKit

/// Marketing-grade demo data for App Store screenshots (Debug only, simulator). Wipes the store
/// and reseeds deterministically on every launch, so each capture starts from the same state.
enum ScreenshotSeeder {
    private struct Demo {
        let en: String
        let pl: String
        let enNote: String
        let plNote: String
        let colorHex: String
        let frequency: FrequencyType
        var weekDay = 2
        var monthDay = 1
        var customDays = 3
        /// Chance a past period was completed.
        let rate: Double
        /// Whether today's (current) period is already done — gives Focus a realistic mix.
        let doneToday: Bool
    }

    private static let demos: [Demo] = [
        Demo(en: "Morning run", pl: "Poranny bieg", enNote: "5 km before work", plNote: "5 km przed pracą",
             colorHex: "#4A90D9", frequency: .daily, rate: 0.82, doneToday: false),
        Demo(en: "Read 20 pages", pl: "Czytanie 20 stron", enNote: "", plNote: "",
             colorHex: "#2E9E4F", frequency: .daily, rate: 0.9, doneToday: true),
        Demo(en: "Meditate", pl: "Medytacja", enNote: "10 minutes", plNote: "10 minut",
             colorHex: "#7B4FE0", frequency: .daily, rate: 0.74, doneToday: false),
        Demo(en: "Drink 2 l of water", pl: "Wypij 2 l wody", enNote: "", plNote: "",
             colorHex: "#14A3A3", frequency: .daily, rate: 0.93, doneToday: true),
        Demo(en: "Gym", pl: "Siłownia", enNote: "Strength training", plNote: "Trening siłowy",
             colorHex: "#F28C28", frequency: .weekly, weekDay: 7, rate: 0.88, doneToday: false),
        Demo(en: "Call parents", pl: "Telefon do rodziców", enNote: "", plNote: "",
             colorHex: "#F27BA8", frequency: .weekly, weekDay: 1, rate: 0.85, doneToday: true),
        Demo(en: "Budget review", pl: "Przegląd budżetu", enNote: "", plNote: "",
             colorHex: "#E0B81F", frequency: .monthly, monthDay: 1, rate: 1.0, doneToday: true),
    ]

    static var isPolish: Bool { Locale.current.language.languageCode?.identifier == "pl" }

    /// Demo habit names, in the launch language — also used to prefill the Add Habit screenshot.
    static var addPresetName: String { isPolish ? "Joga" : "Yoga" }
    static var addPresetNote: String { isPolish ? "Rozciąganie i oddech" : "Stretching and breathing" }

    static func seed(_ context: ModelContext) {
        try? context.delete(model: HabitEntry.self)
        try? context.delete(model: Habit.self)

        let cal = Calendar.current
        let now = Date()
        let createdAt = cal.date(byAdding: .day, value: -119, to: cal.startOfDay(for: now)) ?? now
        var rng = SeededGenerator(seed: 42)

        for (index, demo) in demos.enumerated() {
            let habit = Habit(
                name: isPolish ? demo.pl : demo.en,
                habitDescription: isPolish ? demo.plNote : demo.enNote,
                colorHex: demo.colorHex,
                frequency: demo.frequency,
                customDays: demo.customDays,
                weekDay: demo.weekDay,
                monthDay: demo.monthDay,
                sortOrder: index
            )
            habit.createdAt = createdAt
            context.insert(habit)

            for period in habit.allPeriods(upTo: now) {
                let isCurrent = period.contains(now)
                let done = isCurrent ? demo.doneToday : Double.random(in: 0..<1, using: &rng) < demo.rate
                guard done else { continue }
                let entry = HabitEntry(periodStart: period.start, periodEnd: period.end, habit: habit)
                entry.isCompleted = true
                entry.completedAt = period.start
                context.insert(entry)
            }
        }
        try? context.save()

        AppTheme.shared.preference = .dark
        AppTheme.shared.combinedGridColorHex = "#2E9E4F"
        ReminderSettings.shared.isEnabled = false
        StatsSettings.shared.isLimited = false
    }

    /// Renders the real widget content at Home Screen sizes into the app's Documents folder
    /// (`widget_small.png`, `widget_medium_all.png`, `widget_medium_single.png`).
    @MainActor
    static func renderWidgets(_ context: ModelContext) {
        let habits = (try? context.fetch(FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { !$0.isArchived },
            sortBy: [SortDescriptor(\.sortOrder)]
        ))) ?? []
        guard habits.count > 1 else { return }
        let docs = URL.documentsDirectory
        let renders: [(String, HabitWidgetMode, WidgetFamily, CGSize)] = [
            ("widget_small", .make(habits: habits, selection: habits[1].id, limit: nil, colorHex: ""),
             .systemSmall, CGSize(width: 170, height: 170)),
            ("widget_medium_all", .make(habits: habits, selection: nil, limit: nil, colorHex: "#2E9E4F"),
             .systemMedium, CGSize(width: 364, height: 170)),
            ("widget_medium_single", .make(habits: habits, selection: habits[0].id, limit: nil, colorHex: ""),
             .systemMedium, CGSize(width: 364, height: 170)),
        ]
        for (name, mode, family, size) in renders {
            let view = HabitWidgetContent(mode: mode, family: family)
                .padding(6)   // approximates WidgetKit's content margins around the widget's own padding
                .frame(width: size.width, height: size.height)
                .background(Color(red: 0.11, green: 0.11, blue: 0.12), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .environment(\.colorScheme, .dark)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 3
            renderer.isOpaque = false
            guard let image = renderer.uiImage, let data = image.pngData() else { continue }
            try? data.write(to: docs.appendingPathComponent("\(name).png"))
        }
    }
}

/// Deterministic RNG so every seeded run produces the same grids.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
#endif
