# TODO

## Before App Store release

1. Accessibility labels — `.accessibilityLabel` on icon-only buttons (gearshape/xmark/checkmark in
   AddHabitView, TrackerView, CombinedGridSettingsView, ConfirmByTypingView)
2. Haptics — feedback on habit completion toggle
3. CloudKit — deploy schema to Production (CloudKit Console → Schema → Deploy)
4. Onboarding — brief first-run flow before the app is otherwise empty
5. Push notifications — APNs entitlement + UNUserNotificationCenter, ask permission after onboarding
   (may need a new `Habit.reminderTime`-style field)
6. Widget (WidgetKit) — home screen widget, needs App Group to share the SwiftData/CloudKit
   container with the main app

## Legal (owned by user — website in progress)

- Terms of Use + Privacy Policy specific to Habit Core (no accounts, no financial data, CloudKit
  private DB only — do NOT reuse the Wallet Log pages as-is, see chat 2026-09-27)
