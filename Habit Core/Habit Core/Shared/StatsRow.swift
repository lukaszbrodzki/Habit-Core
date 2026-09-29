import SwiftUI

/// Value-over-label stat, shared by the app and the widget (dual target membership).
struct StatChip: View {
    enum Style {
        case regular
        /// Tighter fonts for the widget's small header.
        case compact
    }

    let value: String
    let label: String
    var style: Style = .regular

    var body: some View {
        VStack(alignment: .leading, spacing: style == .regular ? 1 : 0) {
            Text(value)
                .font(style == .regular ? .subheadline.weight(.semibold) : .caption.weight(.semibold))
            Text(label)
                .font(style == .regular ? .caption2 : .system(size: 9))
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

/// The three-stat row (completed / rate / streak) used by every grid.
struct StatsRow: View {
    struct Item {
        let value: String
        let label: String
    }

    let items: [Item]
    var style: StatChip.Style = .regular
    var spacing: CGFloat = 16

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(items.indices, id: \.self) { i in
                StatChip(value: items[i].value, label: items[i].label, style: style)
            }
        }
    }
}
