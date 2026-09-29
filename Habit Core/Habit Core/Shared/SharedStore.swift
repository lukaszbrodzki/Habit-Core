import Foundation
import SwiftData

/// The one definition of the SwiftData store shared by the app and the widget (dual target
/// membership) — schema, App Group location and file name can't drift apart between them.
enum SharedStore {
    enum StoreError: Error {
        case appGroupUnavailable
    }

    static let schema = Schema([Habit.self, HabitEntry.self])

    static func makeContainer() throws -> ModelContainer {
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppGroup.identifier
        ) else {
            throw StoreError.appGroupUnavailable
        }
        let storeURL = groupURL.appendingPathComponent("HabitCore.sqlite")
        // `.automatic` for both targets: the widget has no iCloud entitlement, so it can't mirror
        // anyway, and opening the same store file with an identical configuration avoids any
        // history-tracking mismatch between the two processes.
        let configuration = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .automatic)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
