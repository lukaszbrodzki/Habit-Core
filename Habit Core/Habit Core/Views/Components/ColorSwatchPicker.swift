import SwiftUI

/// Grid of preset color swatches. Each swatch is a real `Button` (not a tap gesture) so VoiceOver
/// can focus and activate it, and announces the selected one.
struct ColorSwatchPicker: View {
    @Binding var selection: String

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
            ForEach(Color.habitColorHexes, id: \.self) { hex in
                Button {
                    selection = hex
                } label: {
                    Circle()
                        .fill(Color(hex: hex) ?? .blue)
                        .frame(width: 40, height: 40)
                        .overlay {
                            if hex == selection {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Color.habitColorName(for: hex))
                .accessibilityAddTraits(hex == selection ? .isSelected : [])
            }
        }
        .padding(.vertical, 6)
    }
}

extension Color {
    /// VoiceOver name for a preset swatch in `habitColorHexes`.
    static func habitColorName(for hex: String) -> String {
        switch hex {
        case "#E5484D": return String(localized: "color.red")
        case "#F28C28": return String(localized: "color.orange")
        case "#E0B81F": return String(localized: "color.gold")
        case "#8DB82B": return String(localized: "color.lime")
        case "#2E9E4F": return String(localized: "color.green")
        case "#14A3A3": return String(localized: "color.teal")
        case "#5BC8F0": return String(localized: "color.sky")
        case "#4A90D9": return String(localized: "color.blue")
        case "#283C8F": return String(localized: "color.navy")
        case "#7B4FE0": return String(localized: "color.purple")
        case "#B9A3E3": return String(localized: "color.lavender")
        case "#C2359A": return String(localized: "color.magenta")
        case "#F27BA8": return String(localized: "color.pink")
        case "#8B5E3C": return String(localized: "color.brown")
        case "#4A4E55": return String(localized: "color.graphite")
        default:        return hex
        }
    }
}
