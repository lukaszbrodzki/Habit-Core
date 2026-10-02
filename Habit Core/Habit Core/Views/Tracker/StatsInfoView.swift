import SwiftUI

/// "How stats are calculated" — explains the All Habits grid and its numbers (the rules live in
/// `HabitStats`; keep this text in sync if they change).
struct StatsInfoView: View {
    @Environment(\.dismiss) private var dismiss

    private let sections: [(icon: String, title: String, body: String)] = [
        ("square.grid.3x3.fill", String(localized: "statsinfo.tile.title"), String(localized: "statsinfo.tile.body")),
        ("calendar", String(localized: "statsinfo.due.title"), String(localized: "statsinfo.due.body")),
        ("checkmark.seal", String(localized: "statsinfo.free.title"), String(localized: "statsinfo.free.body")),
        ("sun.max", String(localized: "statsinfo.today.title"), String(localized: "statsinfo.today.body")),
        ("number", String(localized: "statsinfo.stats.title"), String(localized: "statsinfo.stats.body")),
        ("archivebox", String(localized: "statsinfo.archived.title"), String(localized: "statsinfo.archived.body")),
        ("clock.arrow.circlepath", String(localized: "statsinfo.recent.title"), String(localized: "statsinfo.recent.body")),
    ]

    var body: some View {
        NavigationStack {
            List(sections, id: \.title) { section in
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(section.title)
                            .font(.headline)
                        Text(section.body)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                } icon: {
                    Image(systemName: section.icon)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .navigationTitle(String(localized: "statsinfo.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "button.done")) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
