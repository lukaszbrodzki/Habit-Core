import Foundation
import SwiftData

/// The widget's own accessor for the shared App Group store. Unlike the main app, failures here
/// must not crash — a widget that crash-loops on every timeline refresh is worse than an empty one.
enum WidgetModelStore {
    static let container: ModelContainer? = {
        let schema = Schema([Habit.self, HabitEntry.self])
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppGroup.identifier
        ) else { return nil }
        let storeURL = groupURL.appendingPathComponent("HabitCore.sqlite")
        let configuration = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .automatic)
        return try? ModelContainer(for: schema, configurations: [configuration])
    }()
}
