import SwiftUI

/// Lets the user pick the accent color for the Tracker's combined "All Habits" heatmap.
struct CombinedGridSettingsView: View {
    @Environment(AppTheme.self) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "addhabit.section.color")) {
                    @Bindable var t = theme
                    ColorSwatchPicker(selection: $t.combinedGridColorHex)
                }
            }
            .navigationTitle(String(localized: "tracker.combined.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(String(localized: "button.close"))
                }
            }
        }
    }
}
