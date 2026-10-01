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

## Branches (same workflow as WalletLog)

- `main` — only versions released to users. Updated solely by merging `acceptance` (`--no-ff`) at release time, then tagged with the version (e.g. `1.0`).
- `acceptance` — what gets archived and uploaded to App Store Connect / TestFlight. Receives working branches via `--no-ff` merges.
- Working branches — one per version/feature, named `<version>-<feature>` (e.g. `1.1.0-lockscreen-widgets`), branched from `acceptance`.

Never commit directly to `main` or `acceptance`. Bump `CURRENT_PROJECT_VERSION` before each TestFlight upload.

## Architecture

**Stack**: SwiftUI + SwiftData + CloudKit (private iCloud sync), iOS 26.2+, Swift 6 language mode (app target defaults to MainActor isolation).
**Localization**: String Catalogs (`Localizable.xcstrings`), languages: `en`, `pl`.

### Entry point
`Habit_CoreApp.swift` — `@main` app struct. Builds a `ModelContainer` whose SQLite store lives in the App Group container (`HabitCore.sqlite`, shared with the widget) with `ModelConfiguration(..., cloudKitDatabase: .automatic)` (via `SharedStore`), and injects the `AppTheme`, `ReminderSettings`, `CloudSyncMonitor` and `NotificationManager` `@Observable` singletons via `.environment(...)`.

### Data models (SwiftData)
- **`Models/Habit.swift`** — `@Model` with `id`, `name`, `habitDescription`, `colorHex`, `frequencyRaw` (String backing `FrequencyType` enum), `customDays`, `weekDay`, `monthDay`, `endDate`, `hasEndDate`, `isArchived`, `sortOrder`, `createdAt`, and a cascade-delete `entries: [HabitEntry]` relationship.
- **`Models/HabitEntry.swift`** — `@Model` with `periodStart`, `periodEnd`, `completedAt`, `isCompleted`, and an optional `habit` back-reference.
- All SwiftData properties have defaults (CloudKit requirement — no `@Attribute(.unique)`).

### Business logic
`Extensions/Habit+Period.swift` — all period/deadline calculation lives here:
- `period(for:)` — returns `Period(start:end:)` for the habit's current period relative to a given date. Handles all four `FrequencyType` cases.
- `allPeriods(upTo:)` — returns periods newest-first, capped at 1 year / 400 iterations (used by the tracker grid).
- `canMarkToday`, `isCompletedToday`, `isCompleted(in:)`, `completedEntry(in:)`, `isDue(on:)`, `dueDate`, `todaySortPriority` — derived state used by views.

`Shared/` — files with **dual target membership** (app + widget; listed in the widget's membership exceptions in `project.pbxproj`):
- `HabitStats.swift` — all grid/stat math (day windows, per-period completions, combined daily rates, summaries/streaks) + `CompletionIndex`. Never re-implement these in a view or the widget.
- `HeatmapGrid.swift` (+ `HeatmapPalette`), `StatsRow.swift` (`StatChip`, `StatsRow`) — shared UI.
- `SharedStore.swift` — the one `ModelContainer` factory (schema, App Group URL, file name).

`Services/HabitActions.swift` — every habit mutation (toggle, archive/restore, reset, delete, commit after add/edit/reorder): saves, logs failures via `Logger`, refreshes the reminder. Views must not call `modelContext.save()` directly.

### App-wide theme
`Persistence.swift` contains `AppTheme` (appearance + combined grid color), `ReminderSettings` (daily reminder toggle/time) — both `@Observable` singletons injected via environment — and the `ColorSchemePreference` enum. Stored in the App Group `UserDefaults` suite.

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
    AddHabitView.swift       — Sheet for add (editing=nil) and edit (editing=habit); archive/reset/delete
  Components/
    HabitColorDot, ColorSwatchPicker, CardBackground (`.cardBackground()` — the one card style)
```

### Color helpers
`Extensions/Color+Hex.swift` — `Color(hex:)` initializer, `Color.habitColorHexes` palette (15 preset hex strings), plus `AppGroup` and `SharedDefaults` constants shared with the widget.

### Navigation
`ContentView.swift` — `TabView` with three `Tab {}` items (iOS 18 API): Today, Tracker, Settings. Each tab root uses `NavigationStack`.

## CloudKit notes
- Schema must be deployed to Production in CloudKit Console before App Store release.
- All SwiftData model properties must have defaults or be optional (already the case).
- Only private CloudKit database is supported with SwiftData.

### Reminders
`NotificationManager.swift` — one local daily reminder (no APNs), re-evaluated when the app becomes active and after every habit mutation; fires only if something is still due.

### Widget
`Habit Core Widget/` — WidgetKit extension (small + medium), configurable to one habit or "All Habits". Reads the shared App Group store via `WidgetModelStore`; the app reloads its timelines on every `ModelContext.didSave` (see `ContentView.swift`).

## Next phases (not yet implemented)
1. Lock Screen widgets and an interactive (`Button(intent:)`) complete/undo in the widget.
