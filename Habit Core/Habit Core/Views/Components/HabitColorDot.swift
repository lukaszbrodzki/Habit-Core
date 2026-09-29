import SwiftUI

/// Small circle in the habit's color, used in list rows and grid headers.
struct HabitColorDot: View {
    let colorHex: String
    var size: CGFloat = 10

    var body: some View {
        Circle()
            .fill(Color(hex: colorHex) ?? .blue)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
