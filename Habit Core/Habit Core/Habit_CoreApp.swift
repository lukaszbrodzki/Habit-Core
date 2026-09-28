import SwiftUI
import SwiftData

@main
struct Habit_CoreApp: App {
    @State private var theme = AppTheme.shared
    @State private var syncMonitor = CloudSyncMonitor.shared
    @State private var notifications = NotificationManager.shared

    private let container: ModelContainer = {
        let schema = Schema([Habit.self, HabitEntry.self])
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppGroup.identifier
        ) else {
            fatalError("Could not resolve App Group container — check the App Groups capability")
        }
        let storeURL = groupURL.appendingPathComponent("HabitCore.sqlite")
        let configuration = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .automatic)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
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
                .preferredColorScheme(theme.colorScheme)
        }
        .modelContainer(container)
    }
}
