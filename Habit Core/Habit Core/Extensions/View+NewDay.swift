import SwiftUI

/// Rebuilds the modified view when the calendar day changes — at midnight while the app is open,
/// or when it comes back to the foreground on a later day. Needed because "today"-dependent
/// state (`isCompletedToday`, `canMarkToday`, `dueDate`, sorting) is computed from `Date()` at
/// render time, and nothing SwiftUI observes changes when the date does.
private struct RefreshOnNewDay: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    @State private var day = Calendar.current.startOfDay(for: Date())

    func body(content: Content) -> some View {
        content
            .id(day)
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
                updateDay()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { updateDay() }
            }
    }

    private func updateDay() {
        let today = Calendar.current.startOfDay(for: Date())
        if today != day { day = today }
    }
}

extension View {
    func refreshOnNewDay() -> some View {
        modifier(RefreshOnNewDay())
    }
}
