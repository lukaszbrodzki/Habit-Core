import Foundation
import SwiftData

/// The widget's own accessor for the shared App Group store. Unlike the main app, failures here
/// must not crash — a widget that crash-loops on every timeline refresh is worse than an empty one.
enum WidgetModelStore {
    static let container: ModelContainer? = try? SharedStore.makeContainer()
}
