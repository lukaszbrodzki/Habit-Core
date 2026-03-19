import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppTheme.self) private var theme
    @Query(
        filter: #Predicate<Habit> { !$0.isArchived },
        sort: [SortDescriptor(\Habit.sortOrder)]
    )
    private var habits: [Habit]

    @State private var showArchived  = false
    @State private var showReorder   = false

    var body: some View {
        NavigationStack {
            List {
                // Appearance
                Section(String(localized: "settings.section.appearance")) {
                    @Bindable var t = theme
                    Picker(String(localized: "settings.theme"), selection: $t.preference) {
                        ForEach(ColorSchemePreference.allCases, id: \.self) {
                            Text($0.localizedName).tag($0)
                        }
                    }
                }

                // Habits management
                Section(String(localized: "settings.section.habits")) {
                    Button(String(localized: "settings.archived")) {
                        showArchived = true
                    }
                    .foregroundStyle(.primary)

                    Button(String(localized: "settings.reorder")) {
                        showReorder = true
                    }
                    .foregroundStyle(.primary)
                }

                // Legal
                Section(String(localized: "settings.section.legal")) {
                    // Replace URLs before App Store submission
                    Link(String(localized: "settings.terms"),
                         destination: URL(string: "https://example.com/terms")!)
                    Link(String(localized: "settings.privacy"),
                         destination: URL(string: "https://example.com/privacy")!)
                }

                // App info
                Section {
                    HStack {
                        Text(String(localized: "settings.version"))
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(String(localized: "tab.settings"))
            .sheet(isPresented: $showArchived) {
                ArchivedHabitsView()
            }
            .sheet(isPresented: $showReorder) {
                ReorderHabitsView(habits: habits)
            }
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (\(b))"
    }
}
