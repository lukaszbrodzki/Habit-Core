import SwiftUI
import SwiftData

@main
struct Habit_CoreApp: App {
    @State private var theme = AppTheme.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(theme)
                .preferredColorScheme(theme.colorScheme)
        }
        .modelContainer(for: [Habit.self, HabitEntry.self], cloudKitDatabase: .automatic)
    }
}
