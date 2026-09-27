import SwiftUI
import SwiftData

@main
struct Habit_CoreApp: App {
    @State private var theme = AppTheme.shared
    @State private var syncMonitor = CloudSyncMonitor.shared

    private let container: ModelContainer = {
        let schema = Schema([Habit.self, HabitEntry.self])
        let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
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
                .preferredColorScheme(theme.colorScheme)
        }
        .modelContainer(container)
    }
}
