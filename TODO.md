# TODO

## Before App Store release

1. ~~Accessibility labels~~ — done: `.accessibilityLabel` added to all icon-only buttons
   (add/edit/gearshape/xmark/checkmark/toggle in TodayView, HabitGridSection, AddHabitView,
   TrackerView, CombinedGridSettingsView, HabitTodayRow). Known remaining gap: the color-swatch
   pickers (AddHabitView, CombinedGridSettingsView) use `.onTapGesture` on plain Circles, which
   VoiceOver can't reach — would need converting to real accessible controls, left out of this pass.
2. ~~Haptics~~ — done: `.sensoryFeedback` on the habit completion toggle in HabitTodayRow
   (`.success` on complete, light `.impact` on undo)
3. CloudKit — found mid-fix that sync was silently broken:
   - ~~`.modelContainer(for:cloudKitDatabase:)` isn't a real overload~~ — fixed in Habit_CoreApp.swift,
     now builds ModelContainer explicitly with `ModelConfiguration(cloudKitDatabase: .automatic)`
   - ~~`Habit.entries` must be optional for CloudKit~~ — fixed (`[HabitEntry]?`)
   - ~~a. Link a real container in Signing & Capabilities~~ — done
     (`iCloud.lukbro.atomichabits.Habit-Core`)
   - ~~b. Generate Development schema~~ — done, verified both in CloudKit Console (CD_Habit,
     CD_HabitEntry record types) and in-app via the new CloudSyncMonitor/Settings status (confirmed
     "Synced" on a physical iPhone)
   - **c. CloudKit Console → Schema → Deploy to Production** — only remaining manual step, requires
     Apple Developer login
4. ~~Onboarding~~ — skipped by decision: empty-state copy in Focus ("No Habits Yet" / "Tap + to add
   your first habit.") already covers the first-run question, a full onboarding flow would be
   overkill for a single-purpose app like this
5. ~~Push notifications~~ — done, as a single global "Daily Reminder" in Settings (not per-habit):
   `NotificationManager.refreshDailyReminder` schedules one local notification for today only if
   some active habit still has `canMarkToday && !isCompletedToday`, else cancels it. Recomputed on
   app launch, habit toggle/add/edit/delete/restore, and reminder setting changes. Permission
   requested on app launch (per explicit decision, not after first habit). Local-only, no APNs
   entitlement needed.
   - **Known limitation**: no repeating/background trigger, so a day the app is never opened won't
     get that day's reminder (re)scheduled. Revisit with `BGTaskScheduler` if it matters in practice.
6. Widget (WidgetKit) — home screen widget, needs App Group to share the SwiftData/CloudKit
   container with the main app

## Legal (owned by user — website in progress)

- Terms of Use + Privacy Policy specific to Habit Core (no accounts, no financial data, CloudKit
  private DB only — do NOT reuse the Wallet Log pages as-is, see chat 2026-09-27)
