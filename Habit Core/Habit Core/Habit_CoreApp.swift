import SwiftUI
import SwiftData

@main
struct Habit_CoreApp: App {
    @State private var theme = AppTheme.shared
    @State private var syncMonitor = CloudSyncMonitor.shared
    @State private var notifications = NotificationManager.shared
    @State private var reminders = ReminderSettings.shared

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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(theme)
                .environment(syncMonitor)
                .environment(notifications)
                .environment(reminders)
                .preferredColorScheme(theme.colorScheme)
        }
        .modelContainer(container)
    }
}
