# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

Build and run via Xcode (Cmd+R) or from the terminal:

```bash
# Build
xcodebuild -project "Habit Core/Habit Core.xcodeproj" -scheme "Habit Core" \
  -destination "platform=iOS Simulator,name=iPhone 16" build

# Run all tests
xcodebuild test -project "Habit Core/Habit Core.xcodeproj" -scheme "Habit Core" \
  -destination "platform=iOS Simulator,name=iPhone 16"

# Run a single test class
xcodebuild test -project "Habit Core/Habit Core.xcodeproj" -scheme "Habit Core" \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -only-testing:"Habit CoreTests/YourTestClass"
```

No linter or external package dependencies (pure Apple frameworks).

## Architecture

**Stack**: SwiftUI + SwiftData + CloudKit (private iCloud sync), iOS 26.2+.
**Localization**: String Catalogs (`Localizable.xcstrings`), languages: `en`, `pl`.

### Entry point
`Habit_CoreApp.swift` — `@main` app struct. Provides a `.modelContainer(for: [Habit.self, HabitEntry.self], cloudKitDatabase: .automatic)` and injects the `AppTheme` `@Observable` singleton via `.environment(theme)`.

### Data models (SwiftData)
- **`Models/Habit.swift`** — `@Model` with `id`, `name`, `habitDescription`, `colorHex`, `frequencyRaw` (String backing `FrequencyType` enum), `customDays`, `weekDay`, `monthDay`, `endDate`, `hasEndDate`, `isArchived`, `sortOrder`, `createdAt`, and a cascade-delete `entries: [HabitEntry]` relationship.
- **`Models/HabitEntry.swift`** — `@Model` with `periodStart`, `periodEnd`, `completedAt`, `isCompleted`, and an optional `habit` back-reference.
- All SwiftData properties have defaults (CloudKit requirement — no `@Attribute(.unique)`).

### Business logic
`Extensions/Habit+Period.swift` — all period/deadline calculation lives here:
- `period(for:)` — returns `Period(start:end:)` for the habit's current period relative to a given date. Handles all four `FrequencyType` cases.
- `allPeriods(upTo:)` — returns periods newest-first, capped at 1 year / 400 iterations (used by the tracker grid).
- `canMarkToday`, `isCompletedToday`, `isCompleted(in:)`, `dueDate`, `todaySortPriority` — derived state used by views.

### App-wide theme
`Persistence.swift` contains `AppTheme` (`@Observable` singleton) and `ColorSchemePreference` enum. Stored in `UserDefaults`.

### Views
```
Views/
  Today/
    TodayView.swift          — List of all active habits sorted by urgency
    HabitTodayRow.swift      — Row with completion toggle; enforces deadline
  Tracker/
    TrackerView.swift        — Per-habit sections + combined grid toggle
    HabitGridSection.swift   — Header, ContributionGrid, stats for one habit
    ContributionGrid.swift   — GitHub-style grid (ContributionGrid) + CombinedGrid
  Settings/
    SettingsView.swift       — Theme picker, archive & reorder buttons, legal links
    ArchivedHabitsView.swift — Restore or permanently delete archived habits
    ReorderHabitsView.swift  — Drag-to-reorder list; updates Habit.sortOrder
  AddEdit/
    AddHabitView.swift       — Sheet for add (editing=nil) and edit (editing=habit)
```

### Color helpers
`Extensions/Color+Hex.swift` — `Color(hex:)` initializer and `Color.habitColorHexes` palette (10 preset hex strings).

### Navigation
`ContentView.swift` — `TabView` with three `Tab {}` items (iOS 18 API): Today, Tracker, Settings. Each tab root uses `NavigationStack`.

## CloudKit notes
- Schema must be deployed to Production in CloudKit Console before App Store release.
- All SwiftData model properties must have defaults or be optional (already the case).
- Only private CloudKit database is supported with SwiftData.

## Next phases (not yet implemented)
1. Push notifications (requires APNs entitlement + UNUserNotificationCenter setup, then AppStore Connect config).
2. Home Screen & Lock Screen widgets (WidgetKit target).
