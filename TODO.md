# TODO

## Before App Store release

1. ~~Accessibility labels~~ — done: `.accessibilityLabel` added to all icon-only buttons
   (add/edit/gearshape/xmark/checkmark/toggle in TodayView, HabitGridSection, AddHabitView,
   TrackerView, CombinedGridSettingsView, HabitTodayRow). Known remaining gap: the color-swatch
   pickers (AddHabitView, CombinedGridSettingsView) use `.onTapGesture` on plain Circles, which
   VoiceOver can't reach — would need converting to real accessible controls, left out of this pass.
2. ~~Haptics~~ — done: `.sensoryFeedback` on the habit completion toggle in HabitTodayRow
   (`.success` on complete, light `.impact` on undo)
3. CloudKit — deploy schema to Production (CloudKit Console → Schema → Deploy)
4. Onboarding — brief first-run flow before the app is otherwise empty
5. Push notifications — APNs entitlement + UNUserNotificationCenter, ask permission after onboarding
   (may need a new `Habit.reminderTime`-style field)
6. Widget (WidgetKit) — home screen widget, needs App Group to share the SwiftData/CloudKit
   container with the main app

## Legal (owned by user — website in progress)

- Terms of Use + Privacy Policy specific to Habit Core (no accounts, no financial data, CloudKit
  private DB only — do NOT reuse the Wallet Log pages as-is, see chat 2026-09-27)
