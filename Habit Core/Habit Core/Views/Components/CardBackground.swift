import SwiftUI

extension View {
    /// The one card style used across Today and Tracker — system material rather than a custom
    /// fill + shadow, so cards adapt to light/dark and the system's glass treatment.
    func cardBackground(cornerRadius: CGFloat = 16) -> some View {
        background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}
