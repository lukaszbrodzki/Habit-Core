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
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                        ForEach(Color.habitColorHexes, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 40, height: 40)
                                .overlay {
                                    if hex == t.combinedGridColorHex {
                                        Image(systemName: "checkmark")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { t.combinedGridColorHex = hex }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle(String(localized: "tracker.combined.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}
