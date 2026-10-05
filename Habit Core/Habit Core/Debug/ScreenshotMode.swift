import Foundation

/// Launch-argument switches used only to capture App Store screenshots from the simulator
/// (see `AppStoreConnect/screenshots/README.md`). Release builds always get the defaults, so
/// none of this can affect real users.
///
/// - `UI_TESTING_SEED_DATA` — replace the store with localized demo habits, dark theme.
/// - `UI_TESTING_INITIAL_TAB=<today|tracker|settings>` — start on that tab.
/// - `UI_TESTING_SHOW_COMBINED` — Tracker opens on All Habits.
/// - `UI_TESTING_OPEN_ADD` — Focus opens the Add Habit sheet, prefilled.
/// - `UI_TESTING_RENDER_WIDGETS` — write widget PNGs to the app's Documents folder.
enum ScreenshotMode {
    #if DEBUG
    private static let args = ProcessInfo.processInfo.arguments

    static let seedData = args.contains("UI_TESTING_SEED_DATA")
    static let showCombined = args.contains("UI_TESTING_SHOW_COMBINED")
    static let openAdd = args.contains("UI_TESTING_OPEN_ADD")
    static let renderWidgets = args.contains("UI_TESTING_RENDER_WIDGETS")
    static let initialTab: AppTab = args
        .first { $0.hasPrefix("UI_TESTING_INITIAL_TAB=") }
        .flatMap { AppTab(rawValue: String($0.dropFirst("UI_TESTING_INITIAL_TAB=".count))) }
        ?? .today
    #else
    static let seedData = false
    static let showCombined = false
    static let openAdd = false
    static let renderWidgets = false
    static let initialTab = AppTab.today
    #endif
}

enum AppTab: String, Hashable {
    case today, tracker, settings
}
