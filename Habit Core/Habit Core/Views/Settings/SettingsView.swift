import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {
    @Environment(AppTheme.self) private var theme
    @Environment(CloudSyncMonitor.self) private var syncMonitor
    @Environment(NotificationManager.self) private var notifications
    @Environment(ReminderSettings.self) private var reminders
    @Environment(StatsSettings.self) private var stats
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Habit> { !$0.isArchived },
        sort: [SortDescriptor(\Habit.sortOrder)]
    )
    private var habits: [Habit]

    @State private var showArchived  = false
    @State private var showReorder   = false
    @State private var showStatsInfo = false
    /// Edit buffer for "Recent occurrences": empty while editing (current value shows as the
    /// placeholder), committed to `StatsSettings.count` when editing ends.
    @State private var countText = ""
    @FocusState private var countFocused: Bool

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

                // Reminders
                Section(String(localized: "settings.section.reminders")) {
                    if notifications.authorizationStatus == .denied {
                        Text(String(localized: "settings.reminder.denied"))
                            .foregroundStyle(.secondary)
                        Button(String(localized: "settings.reminder.opensettings")) {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    } else {
                        @Bindable var r = reminders
                        Toggle(String(localized: "settings.reminder.toggle"), isOn: $r.isEnabled)
                        if r.isEnabled {
                            DatePicker(
                                String(localized: "settings.reminder.time"),
                                selection: $r.time,
                                displayedComponents: .hourAndMinute
                            )
                        }
                    }
                }

                // Statistics window
                Section {
                    @Bindable var st = stats
                    Toggle(isOn: $st.isLimited) {
                        HStack(spacing: 6) {
                            Text(String(localized: "settings.stats.recentonly"))
                            Button {
                                showStatsInfo = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(.secondary)
                            }
                            // Borderless so only the icon is tappable, not the whole row.
                            .buttonStyle(.borderless)
                            .accessibilityLabel(String(localized: "settings.stats.info"))
                            .popover(isPresented: $showStatsInfo) {
                                Text(String(localized: "settings.stats.footer"))
                                    .font(.footnote)
                                    .padding()
                                    .frame(idealWidth: 300)
                                    .fixedSize(horizontal: false, vertical: true)
                                    // A real bubble on iPhone too, instead of a full sheet.
                                    .presentationCompactAdaptation(.popover)
                            }
                        }
                    }
                    if st.isLimited {
                        LabeledContent(String(localized: "settings.stats.count")) {
                            TextField("\(st.count)", text: $countText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 100)
                                .focused($countFocused)
                                .onAppear { countText = "\(st.count)" }
                                .onChange(of: countFocused) { _, focused in
                                    if focused {
                                        countText = ""
                                    } else {
                                        commitCount()
                                    }
                                }
                        }
                    }
                } header: {
                    Text(String(localized: "settings.section.statistics"))
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

                // iCloud sync status
                Section(String(localized: "settings.section.icloud")) {
                    HStack {
                        Text(String(localized: "settings.icloud.status"))
                        Spacer()
                        Text(syncStatusText)
                            .foregroundStyle(syncStatusColor)
                    }
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
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                // The number pad has no return key — give it a way to finish editing.
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(String(localized: "button.done")) { countFocused = false }
                }
            }
            .appBackground()
            .navigationTitle(String(localized: "tab.settings"))
            .sheet(isPresented: $showArchived) {
                ArchivedHabitsView()
            }
            .sheet(isPresented: $showReorder) {
                ReorderHabitsView(habits: habits)
            }
            .onChange(of: reminders.isEnabled) { _, enabled in
                if enabled && notifications.authorizationStatus == .notDetermined {
                    notifications.requestAuthorization(thenRefresh: modelContext)
                } else {
                    notifications.refreshDailyReminder(habits: habits)
                }
            }
            .onChange(of: reminders.time) {
                notifications.refreshDailyReminder(habits: habits)
            }
        }
    }

    /// Keeps the previous value if the field was left empty or invalid; out-of-range numbers are
    /// clamped by `StatsSettings`.
    private func commitCount() {
        if let value = Int(countText.filter(\.isNumber)), value > 0 {
            stats.count = value
        }
        countText = "\(stats.count)"
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (\(b))"
    }

    private var syncStatusText: String {
        switch syncMonitor.status {
        case .idle:
            return String(localized: "settings.icloud.idle")
        case .syncing:
            return String(localized: "settings.icloud.syncing")
        case .success:
            return String(localized: "settings.icloud.synced")
        case .failed(let message):
            return message
        }
    }

    private var syncStatusColor: Color {
        switch syncMonitor.status {
        case .idle:    return .secondary
        case .syncing: return .blue
        case .success: return .green
        case .failed:  return .red
        }
    }
}
