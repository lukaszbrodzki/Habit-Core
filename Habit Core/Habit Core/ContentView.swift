import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(NotificationManager.self) private var notifications

    var body: some View {
        TabView {
            Tab(String(localized: "tab.today"), systemImage: "dot.scope") {
                TodayView()
            }
            Tab(String(localized: "tab.tracker"), systemImage: "rectangle.grid.3x3.fill") {
                TrackerView()
            }
            Tab(String(localized: "tab.settings"), systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
        // Covers cold start (`initial`) and returning from background — the user may have changed
        // notification permission in the Settings app, and a new day may need a new reminder.
        .onChange(of: scenePhase, initial: true) { _, newPhase in
            guard newPhase == .active else { return }
            notifications.refreshAuthorizationStatus()
            notifications.refreshDailyReminder(context: modelContext)
        }
        // One place for every habit/entry mutation (toggle, add/edit, archive, reorder, delete),
        // so the widget never lags up to a full timeline interval behind the app.
        .onReceive(NotificationCenter.default.publisher(for: ModelContext.didSave)) { _ in
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
