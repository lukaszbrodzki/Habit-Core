import SwiftUI

/// Rounded-square heatmap laid out in rows, oldest-to-newest left-to-right. Shared by the app's
/// Tracker grids and the widget (dual target membership) so they keep one visual language.
///
/// With `tileSize == nil` the grid fills the width it's offered: the column count stays fixed and
/// tiles grow or shrink with the screen, so left and right margins always match. Pass an explicit
/// `tileSize` when the caller has already sized tiles (the widget does, to fit its height too).
struct HeatmapGrid: View {
    let cells: [Color]
    let columns: Int
    var tileSize: CGFloat? = nil
    var gap: CGFloat = HeatmapPalette.gap

    var body: some View {
        if let tileSize {
            FixedTileLayout(columns: columns, gap: gap, tile: tileSize) { tiles }
        } else {
            FillingWidthLayout(columns: columns, gap: gap) { tiles }
        }
    }

    private var tiles: some View {
        ForEach(cells.indices, id: \.self) { i in
            RoundedRectangle(cornerRadius: 3).fill(cells[i])
        }
    }
}

/// Places square tiles row by row; shared by both layouts below.
nonisolated private func placeTiles(_ subviews: LayoutSubviews, in bounds: CGRect, columns: Int, gap: CGFloat, tile: CGFloat) {
    for (i, subview) in subviews.enumerated() {
        let origin = CGPoint(
            x: bounds.minX + CGFloat(i % columns) * (tile + gap),
            y: bounds.minY + CGFloat(i / columns) * (tile + gap)
        )
        subview.place(at: origin, proposal: ProposedViewSize(width: tile, height: tile))
    }
}

nonisolated private func gridHeight(count: Int, columns: Int, gap: CGFloat, tile: CGFloat) -> CGFloat {
    let rows = (count + columns - 1) / max(1, columns)
    return rows == 0 ? 0 : CGFloat(rows) * tile + CGFloat(rows - 1) * gap
}

/// Tile size derived from the proposed width (fixed column count).
private struct FillingWidthLayout: Layout {
    let columns: Int
    let gap: CGFloat
    /// Used only when no width is proposed (e.g. ideal-size measurement).
    private let fallbackTile: CGFloat = 13

    private func tile(for width: CGFloat) -> CGFloat {
        max(0, (width - CGFloat(columns - 1) * gap) / CGFloat(max(1, columns)))
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? CGFloat(columns) * fallbackTile + CGFloat(columns - 1) * gap
        return CGSize(width: width, height: gridHeight(count: subviews.count, columns: columns, gap: gap, tile: tile(for: width)))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        placeTiles(subviews, in: bounds, columns: columns, gap: gap, tile: tile(for: bounds.width))
    }
}

/// Caller-provided tile size.
private struct FixedTileLayout: Layout {
    let columns: Int
    let gap: CGFloat
    let tile: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let used = min(subviews.count, columns)
        let width = used == 0 ? 0 : CGFloat(used) * tile + CGFloat(used - 1) * gap
        return CGSize(width: width, height: gridHeight(count: subviews.count, columns: columns, gap: gap, tile: tile))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        placeTiles(subviews, in: bounds, columns: columns, gap: gap, tile: tile)
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
