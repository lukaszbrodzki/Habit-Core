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
   - **Still needs manual action (requires Apple Developer login, can't be done from the CLI):**
     a. Xcode → target "Habit Core" → Signing & Capabilities → iCloud → check CloudKit → "+" under
        Containers to create/select one (entitlements currently have an empty
        `com.apple.developer.icloud-container-identifiers`, i.e. no container was ever linked)
     b. Run the app once on a device/simulator signed into iCloud to generate the Development schema
     c. CloudKit Console → Schema → Deploy to Production
4. Onboarding — brief first-run flow before the app is otherwise empty
5. Push notifications — APNs entitlement + UNUserNotificationCenter, ask permission after onboarding
   (may need a new `Habit.reminderTime`-style field)
6. Widget (WidgetKit) — home screen widget, needs App Group to share the SwiftData/CloudKit
   container with the main app

## Legal (owned by user — website in progress)

- Terms of Use + Privacy Policy specific to Habit Core (no accounts, no financial data, CloudKit
  private DB only — do NOT reuse the Wallet Log pages as-is, see chat 2026-09-27)
