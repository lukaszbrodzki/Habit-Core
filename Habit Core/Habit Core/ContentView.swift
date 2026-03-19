import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab(String(localized: "tab.today"), systemImage: "target") {
                TodayView()
            }
            Tab(String(localized: "tab.tracker"), systemImage: "chart.bar.fill") {
                TrackerView()
            }
            Tab(String(localized: "tab.settings"), systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
    }
}
