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

    static let habitColorHexes: [String] = [
        "#4A90D9",  // Blue
        "#9B59B6",  // Purple
        "#27AE60",  // Green
        "#E67E22",  // Orange
        "#E74C3C",  // Red
        "#1ABC9C",  // Teal
        "#E91E63",  // Pink
        "#3F51B5",  // Indigo
        "#F39C12",  // Amber
        "#795548",  // Brown
        "#00BCD4",  // Cyan
        "#C0CA33",  // Lime
        "#AD1457",  // Raspberry
        "#607D8B",  // Blue Grey
        "#1565C0",  // Cobalt
    ]
}
