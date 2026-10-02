import SwiftUI

/// Shared between the app and the widget extension targets. `nonisolated` because the app target
/// defaults to MainActor isolation, and these constants are read from SwiftData model defaults.
nonisolated enum AppGroup {
    static let identifier = "group.com.lukbro.atomichabits.HabitCore"
}

/// Keys/defaults read by both the app and the widget — one definition so they can't drift apart.
nonisolated enum SharedDefaults {
    static let combinedGridColorHexKey = "combinedGridColorHex"
    static let defaultColorHex = "#4A90D9"

    /// Settings → Statistics → "Count only recent".
    static let statsLimitEnabledKey = "statsLimitEnabled"
    static let statsLimitCountKey = "statsLimitCount"
    static let defaultStatsLimitCount = 30
    static let statsLimitRange = 1...3650

    /// How many recent occurrences count toward stats, or `nil` for the whole history.
    static func statsLimit(in defaults: UserDefaults? = UserDefaults(suiteName: AppGroup.identifier)) -> Int? {
        guard let defaults, defaults.bool(forKey: statsLimitEnabledKey) else { return nil }
        let stored = defaults.integer(forKey: statsLimitCountKey)
        let count = stored == 0 ? defaultStatsLimitCount : stored
        return min(max(count, statsLimitRange.lowerBound), statsLimitRange.upperBound)
    }
}

extension Color {
    init?(hex: String) {
        var raw = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.hasPrefix("#") { raw = String(raw.dropFirst()) }
        guard raw.count == 6, let rgb = UInt64(raw, radix: 16) else { return nil }
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8)  & 0xFF) / 255
        let b = Double( rgb        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    /// Picked for perceptual distance (CIEDE2000 ≥ 17 between any two), so no two swatches look
    /// alike on small grid tiles. Habits created with older palette colors keep rendering them.
    static let habitColorHexes: [String] = [
        "#E5484D",  // Red
        "#F28C28",  // Orange
        "#E0B81F",  // Gold
        "#8DB82B",  // Lime
        "#2E9E4F",  // Green
        "#14A3A3",  // Teal
        "#5BC8F0",  // Sky
        "#4A90D9",  // Blue (default)
        "#283C8F",  // Navy
        "#7B4FE0",  // Purple
        "#B9A3E3",  // Lavender
        "#C2359A",  // Magenta
        "#F27BA8",  // Pink
        "#8B5E3C",  // Brown
        "#4A4E55",  // Graphite
    ]
}
