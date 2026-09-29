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
        case "#4A90D9": return String(localized: "color.blue")
        case "#9B59B6": return String(localized: "color.purple")
        case "#27AE60": return String(localized: "color.green")
        case "#E67E22": return String(localized: "color.orange")
        case "#E74C3C": return String(localized: "color.red")
        case "#1ABC9C": return String(localized: "color.teal")
        case "#E91E63": return String(localized: "color.pink")
        case "#3F51B5": return String(localized: "color.indigo")
        case "#F39C12": return String(localized: "color.amber")
        case "#795548": return String(localized: "color.brown")
        case "#00BCD4": return String(localized: "color.cyan")
        case "#C0CA33": return String(localized: "color.lime")
        case "#AD1457": return String(localized: "color.raspberry")
        case "#607D8B": return String(localized: "color.bluegrey")
        case "#1565C0": return String(localized: "color.cobalt")
        default:        return hex
        }
    }
}
