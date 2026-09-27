import SwiftUI

// MARK: - App-wide theme state

@Observable
final class AppTheme {
    static let shared = AppTheme()

    var preference: ColorSchemePreference {
        didSet {
            UserDefaults.standard.set(preference.rawValue, forKey: "colorSchemePreference")
        }
    }

    var colorScheme: ColorScheme? {
        switch preference {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return nil
        }
    }

    /// Accent color for the Tracker's combined "All Habits" heatmap.
    var combinedGridColorHex: String {
        didSet {
            UserDefaults.standard.set(combinedGridColorHex, forKey: "combinedGridColorHex")
        }
    }

    /// Single daily reminder, sent only if some habit is still due when it fires.
    var reminderEnabled: Bool {
        didSet {
            UserDefaults.standard.set(reminderEnabled, forKey: "reminderEnabled")
        }
    }

    /// Only the time-of-day components are used.
    var reminderTime: Date {
        didSet {
            UserDefaults.standard.set(reminderTime, forKey: "reminderTime")
        }
    }

    private init() {
        let raw = UserDefaults.standard.string(forKey: "colorSchemePreference") ?? ""
        preference = ColorSchemePreference(rawValue: raw) ?? .system
        combinedGridColorHex = UserDefaults.standard.string(forKey: "combinedGridColorHex") ?? "#4A90D9"
        reminderEnabled = UserDefaults.standard.bool(forKey: "reminderEnabled")
        reminderTime = UserDefaults.standard.object(forKey: "reminderTime") as? Date
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
