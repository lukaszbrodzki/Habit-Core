import SwiftUI

private struct AppBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(gradient.ignoresSafeArea())
    }

    @ViewBuilder
    private var gradient: some View {
        if colorScheme == .dark {
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.10, green: 0.09, blue: 0.16), location: 0.0),
                    .init(color: Color(red: 0.07, green: 0.07, blue: 0.11), location: 0.5),
                    .init(color: Color(red: 0.04, green: 0.04, blue: 0.07), location: 1.0),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color(.systemGroupedBackground)
        }
    }
}

extension View {
    func appBackground() -> some View {
        modifier(AppBackgroundModifier())
    }
}
