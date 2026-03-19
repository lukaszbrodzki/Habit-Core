import SwiftUI

struct ContentView: View {
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
    }
}
