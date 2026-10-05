import SwiftUI
import SwiftData

@main
struct Habit_CoreApp: App {
    @State private var theme = AppTheme.shared
    @State private var syncMonitor = CloudSyncMonitor.shared
    @State private var notifications = NotificationManager.shared
    @State private var reminders = ReminderSettings.shared
    @State private var stats = StatsSettings.shared

    private let container: ModelContainer = {
        do {
            return try SharedStore.makeContainer()
        } catch {
            // Unrecoverable misconfiguration (missing App Group capability or schema mismatch).
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        CloudSyncMonitor.shared.start()
        #if DEBUG
        if ScreenshotMode.seedData {
            let context = container.mainContext
            ScreenshotSeeder.seed(context)
            if ScreenshotMode.renderWidgets { ScreenshotSeeder.renderWidgets(context) }
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(theme)
                .environment(syncMonitor)
                .environment(notifications)
                .environment(reminders)
                .environment(stats)
                .preferredColorScheme(theme.colorScheme)
        }
        .modelContainer(container)
    }
}
