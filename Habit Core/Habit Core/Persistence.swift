import SwiftUI
import WidgetKit

// MARK: - App-wide theme state

@Observable
final class AppTheme {
    static let shared = AppTheme()

    /// Shared App Group suite so the widget extension can read `combinedGridColorHex`.
    private static let defaults = UserDefaults(suiteName: AppGroup.identifier) ?? .standard

    var preference: ColorSchemePreference {
        didSet {
            Self.defaults.set(preference.rawValue, forKey: "colorSchemePreference")
        }
    }

    var colorScheme: ColorScheme? {
        switch preference {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return nil
        }
    }

    /// Accent color for the Tracker's combined "All Habits" heatmap (also used by the widget).
    var combinedGridColorHex: String {
        didSet {
            Self.defaults.set(combinedGridColorHex, forKey: SharedDefaults.combinedGridColorHexKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private init() {
        let raw = Self.defaults.string(forKey: "colorSchemePreference") ?? ""
        preference = ColorSchemePreference(rawValue: raw) ?? .system
        combinedGridColorHex = Self.defaults.string(forKey: SharedDefaults.combinedGridColorHexKey)
            ?? SharedDefaults.defaultColorHex
    }
}

// MARK: - Daily reminder settings

/// Kept apart from `AppTheme` — appearance and reminders change for unrelated reasons.
/// Same UserDefaults keys as before the split, so existing settings carry over.
@Observable
final class ReminderSettings {
    static let shared = ReminderSettings()

    private static let defaults = UserDefaults(suiteName: AppGroup.identifier) ?? .standard

    /// Single daily reminder, sent only if some habit is still due when it fires.
    var isEnabled: Bool {
        didSet {
            Self.defaults.set(isEnabled, forKey: "reminderEnabled")
        }
    }

    /// Only the time-of-day components are used.
    var time: Date {
        didSet {
            Self.defaults.set(time, forKey: "reminderTime")
        }
    }

    private init() {
        isEnabled = Self.defaults.bool(forKey: "reminderEnabled")
        time = Self.defaults.object(forKey: "reminderTime") as? Date
            ?? Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    }
}

enum ColorSchemePreference: String, CaseIterable {
    case system, light, dark

    var localizedName: String {
        switch self {
        case .system: return String(localized: "theme.system")
        case .light:  return String(localized: "theme.light")
        case .dark:   return String(localized: "theme.dark")
        }
    }
}

// MARK: - Statistics window

/// Settings → Statistics → "Count only recent". Stored in the App Group suite so the widget
/// (via `SharedDefaults.statsLimit()`) counts exactly the same occurrences as the app.
@Observable
final class StatsSettings {
    static let shared = StatsSettings()

    private static let defaults = UserDefaults(suiteName: AppGroup.identifier) ?? .standard

    var isLimited: Bool {
        didSet {
            Self.defaults.set(isLimited, forKey: SharedDefaults.statsLimitEnabledKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    var count: Int {
        didSet {
            let clamped = min(max(count, SharedDefaults.statsLimitRange.lowerBound), SharedDefaults.statsLimitRange.upperBound)
            // Assigning inside didSet doesn't re-trigger it, so the clamped value is saved below.
            if clamped != count { count = clamped }
            Self.defaults.set(count, forKey: SharedDefaults.statsLimitCountKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// What the stats code takes: the recent-occurrence limit, or `nil` for the whole history.
    var limit: Int? { isLimited ? count : nil }

    private init() {
        isLimited = Self.defaults.bool(forKey: SharedDefaults.statsLimitEnabledKey)
        let stored = Self.defaults.integer(forKey: SharedDefaults.statsLimitCountKey)
        count = stored == 0 ? SharedDefaults.defaultStatsLimitCount : stored
    }
}
