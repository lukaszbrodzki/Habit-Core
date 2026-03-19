import Foundation
import SwiftData

enum FrequencyType: String, Codable, CaseIterable {
    case daily, weekly, monthly, custom

    var localizedName: String {
        switch self {
        case .daily:   return String(localized: "frequency.daily")
        case .weekly:  return String(localized: "frequency.weekly")
        case .monthly: return String(localized: "frequency.monthly")
        case .custom:  return String(localized: "frequency.custom")
        }
    }
}

@Model
final class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var habitDescription: String = ""
    var colorHex: String = "#4A90D9"
    /// Stored as raw string for CloudKit compatibility
    var frequencyRaw: String = FrequencyType.daily.rawValue
    /// For .custom: repeat every N days
    var customDays: Int = 2
    /// For .weekly: Calendar.weekday (1=Sun, 2=Mon … 7=Sat)
    var weekDay: Int = 2
    /// For .monthly: day of month (1–31)
    var monthDay: Int = 1
    var endDate: Date? = nil
    var hasEndDate: Bool = false
    var isArchived: Bool = false
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \HabitEntry.habit)
    var entries: [HabitEntry] = []

    var frequency: FrequencyType {
        get { FrequencyType(rawValue: frequencyRaw) ?? .daily }
        set { frequencyRaw = newValue.rawValue }
    }

    init(
        name: String = "",
        habitDescription: String = "",
        colorHex: String = "#4A90D9",
        frequency: FrequencyType = .daily,
        customDays: Int = 2,
        weekDay: Int = 2,
        monthDay: Int = 1,
        endDate: Date? = nil,
        hasEndDate: Bool = false,
        sortOrder: Int = 0
    ) {
        self.name = name
        self.habitDescription = habitDescription
        self.colorHex = colorHex
        self.frequencyRaw = frequency.rawValue
        self.customDays = customDays
        self.weekDay = weekDay
        self.monthDay = monthDay
        self.endDate = endDate
        self.hasEndDate = hasEndDate
        self.sortOrder = sortOrder
    }
}
