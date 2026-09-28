import SwiftUI

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
            Self.defaults.set(combinedGridColorHex, forKey: "combinedGridColorHex")
        }
    }

    /// Single daily reminder, sent only if some habit is still due when it fires.
    var reminderEnabled: Bool {
        didSet {
            Self.defaults.set(reminderEnabled, forKey: "reminderEnabled")
        }
    }

    /// Only the time-of-day components are used.
    var reminderTime: Date {
        didSet {
            Self.defaults.set(reminderTime, forKey: "reminderTime")
        }
    }

    private init() {
        let raw = Self.defaults.string(forKey: "colorSchemePreference") ?? ""
        preference = ColorSchemePreference(rawValue: raw) ?? .system
        combinedGridColorHex = Self.defaults.string(forKey: "combinedGridColorHex") ?? "#4A90D9"
        reminderEnabled = Self.defaults.bool(forKey: "reminderEnabled")
        reminderTime = Self.defaults.object(forKey: "reminderTime") as? Date
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
