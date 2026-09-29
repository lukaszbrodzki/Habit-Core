import SwiftUI

/// Rounded-square heatmap laid out in rows, oldest-to-newest left-to-right. Shared by the app's
/// Tracker grids and the widget (dual target membership) so they keep one visual language.
struct HeatmapGrid: View {
    let cells: [Color]
    let columns: Int
    let tileSize: CGFloat
    var gap: CGFloat = HeatmapPalette.gap

    private var rows: [ArraySlice<Color>] {
        stride(from: 0, to: cells.count, by: columns).map {
            cells[$0..<min($0 + columns, cells.count)]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: gap) {
            ForEach(rows.indices, id: \.self) { r in
                HStack(spacing: gap) {
                    ForEach(rows[r].indices, id: \.self) { c in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(rows[r][c])
                            .frame(width: tileSize, height: tileSize)
                    }
                }
            }
        }
    }
}

enum HeatmapPalette {
    static let gap: CGFloat = 3

    /// No data for that slot (future period, or padding before the habit existed).
    static let empty = Color.secondary.opacity(0.12)
    static let missed = Color.secondary.opacity(0.2)

    /// Per-habit tile: `nil` = no data, `false` = missed, `true` = completed.
    static func completion(_ completed: Bool?, color: Color) -> Color {
        switch completed {
        case true:  return color
        case false: return missed
        case nil:   return empty
        }
    }

    /// Combined tile: intensity scales with the day's completion rate; `nil` = no data.
    static func rate(_ rate: Double?, color: Color) -> Color {
        guard let rate else { return empty }
        return color.opacity(0.12 + rate * 0.88)
    }
}
