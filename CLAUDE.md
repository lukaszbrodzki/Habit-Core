# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

Build and run via Xcode (Cmd+R) or from the terminal:

```bash
# Build
xcodebuild -project "Habit Core/Habit Core.xcodeproj" -scheme "Habit Core" -destination "platform=iOS Simulator,name=iPhone 16" build

# Run unit tests
xcodebuild test -project "Habit Core/Habit Core.xcodeproj" -scheme "Habit Core" -destination "platform=iOS Simulator,name=iPhone 16"

# Run a single test class
xcodebuild test -project "Habit Core/Habit Core.xcodeproj" -scheme "Habit Core" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:"Habit CoreTests/YourTestClass"
```

No linter or formatter is configured. No external package dependencies (pure Apple frameworks).

## Architecture

**Stack**: SwiftUI + CoreData + CloudKit, iOS 26.2+, no third-party dependencies.

**Entry point**: `Habit Core/Habit_CoreApp.swift` — `@main` app struct that injects `PersistenceController.shared.container.viewContext` into the SwiftUI environment.

**Persistence**: `Habit Core/Persistence.swift` — singleton `PersistenceController` using `NSPersistentCloudKitContainer` for automatic iCloud sync. Uses `inMemory: true` variant for SwiftUI previews and tests.

**Data model**: `Habit_Core.xcdatamodeld` — CoreData schema with CloudKit sync enabled. Currently has a single `Item` entity (timestamp attribute) as a starting point.

**UI pattern**: 100% SwiftUI. Views access CoreData via `@Environment(\.managedObjectContext)` and `@FetchRequest`. No dedicated ViewModels yet — state lives in SwiftUI view structs.

**Navigation**: `NavigationView` + `List` in `ContentView.swift`. Detail navigation via `NavigationLink`.

**Bundle ID**: `com.lukbro.atomichabits.Habit-Core`
**Project file**: `Habit Core/Habit Core.xcodeproj`
