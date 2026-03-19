import SwiftUI

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
    ]
}
