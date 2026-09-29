# iOS review - changelog (Habit Core)

## 2026-09-29
Plik/lokalizacja: Habit Core/Habit Core/PrivacyInfo.xcprivacy, Habit Core/Habit Core Widget/PrivacyInfo.xcprivacy (nowe)
Zmiana: Dodany privacy manifest w appce i widgecie: UserDefaults z powodami 1C8F.1 i CA92.1, NSPrivacyTracking=false, puste CollectedDataTypes.
Powód: K1 - brak deklaracji required-reason API (UserDefaults w suite App Group).

## 2026-09-29
Plik/lokalizacja: Habit Core/Habit Core/NotificationManager.swift (refreshDailyReminder, requestAuthorization(thenRefresh:)), ContentView.swift
Zmiana: Autoryzacja odczytywana świeżo wewnątrz Taska. Taski serializowane przez `reminderTask` (`await previous?.value`). Po udzieleniu zgody przypomnienie jest przeliczane. Odświeżanie przy `scenePhase == .active` (`initial: true`) w ContentView.
Powód: K2 - przypomnienie kasowane przy zimnym starcie i nieplanowane po pierwszej zgodzie. W1 - wyścig między Taskami remove/add.

## 2026-09-29
Plik/lokalizacja: Habit Core/Habit Core/ContentView.swift, Persistence.swift (AppTheme.combinedGridColorHex)
Zmiana: `WidgetCenter.shared.reloadAllTimelines()` po `ModelContext.didSave` i po zmianie koloru wspólnej siatki.
Powód: W2 - widget nieodświeżany po zmianach w appce (do 30 min opóźnienia).

## 2026-09-29
Plik/lokalizacja: Habit Core/Habit Core/Shared/HabitStats.swift (nowy, oba targety), Views/Tracker/*, Habit Core Widget/Habit_Core_Widget.swift
Zmiana: Jedna implementacja okna dni, dziennego wskaźnika ukończenia, podsumowań i streaka (+ `CompletionIndex` z binary search). Appka i widget tylko ją wywołują. Widget dla pojedynczego nawyku pokazuje kafelki per okres, tak jak appka. Model liczony raz na body. Usunięte `Habit.longestStreak`.
Powód: W3 - duplikacja logiki statystyk między appką, widgetem i testami. W4 - błędny mianownik „Perfect” w widgecie. W8 - kosztowne przeliczenia w body.

## 2026-09-29
Plik/lokalizacja: Habit Core/Habit Core/Services/HabitActions.swift (nowy), Habit+Period.swift (completedEntry(in:)), widoki Today/Tracker/Settings/AddEdit
Zmiana: Wszystkie mutacje (toggle, archive, restore, reset, delete, commit) w jednym serwisie: zapis, Logger przy błędzie, odświeżenie przypomnienia. Usuwanie z sheetu edycji odroczone do `onDismiss` w TrackerView.
Powód: W5 - logika biznesowa i efekty uboczne rozrzucone po widokach. D2 - odczyt usuniętego modelu podczas zamykania sheetu. D5 - połykanie błędów zapisu.

## 2026-09-29
Plik/lokalizacja: Habit Core/Habit Core/Views/AddEdit/AddHabitView.swift (save), Extensions/Habit+Period.swift (canMarkToday)
Zmiana: Daty startu i końca normalizowane do `startOfDay`. `canMarkToday` porównuje dniami.
Powód: W6 - pora dnia z DatePicker blokowała odhaczanie w dniu startu i końca.

## 2026-09-29
Plik/lokalizacja: Habit Core/Habit Core/Shared/HeatmapGrid.swift, Shared/StatsRow.swift, Views/Components/HabitColorDot.swift, ColorSwatchPicker.swift, CardBackground.swift (nowe)
Zmiana: Wydzielone komponenty siatki, wiersza statystyk, kropki koloru, pickera kolorów (Button, etykiety VoiceOver, `.isSelected`) i tła karty (`.regularMaterial`).
Powód: W7 - element UI powtórzony ponad 2 razy. D13 - niespójne style kart.

## 2026-09-29
Plik/lokalizacja: Habit Core/Habit Core/Shared/SharedStore.swift (nowy), Habit_CoreApp.swift, Habit Core Widget/WidgetModelStore.swift
Zmiana: Jedna fabryka ModelContainer (schema, URL App Group, nazwa pliku) dla appki i widgetu.
Powód: W9 - zduplikowana konfiguracja store'u.

## 2026-09-29
Plik/lokalizacja: Habit Core/Habit CoreTests/HabitPeriodTests.swift, HabitStatsTests.swift, HabitActionsTests.swift, TestSupport.swift (nowe). Usunięte CombinedGridLogicTests.swift i Habit_CoreTests.swift
Zmiana: Testy kodu produkcyjnego (okresy, przypadki brzegowe monthly/custom, granice dat, statystyki, akcje) zamiast kopii logiki.
Powód: W10 - testy sprawdzały kopię logiki.

## 2026-09-29
Plik/lokalizacja: Habit Core/Habit Core.xcodeproj/project.pbxproj
Zmiana: Widget: IPHONEOS_DEPLOYMENT_TARGET 26.2, TARGETED_DEVICE_FAMILY 1. SWIFT_VERSION 6.0 we wszystkich targetach.
Powód: W11 - niespójne ustawienia targetów. D9 - strict concurrency.

## 2026-09-29
Plik/lokalizacja: Habit Core/Habit Core/Views/AddEdit/AddHabitView.swift (dangerSection), Views/Today/TodayView.swift (swipe)
Zmiana: Dodana akcja „Archiwizuj” w edycji nawyku i jako swipe na Today.
Powód: W12 - archiwizacja była nieosiągalna.

## 2026-09-29
Plik/lokalizacja: Habit+Period.swift (custom), Views/Today/HabitTodayRow.swift, Extensions/Color+Hex.swift (SharedDefaults), CloudSyncMonitor.swift, Persistence.swift (ReminderSettings), AppIntent.swift, Localizable.xcstrings, TabNavigationUITests.swift, CLAUDE.md, TODO.md
Zmiana: `max(1, customDays)`. `let habit` zamiast `@Bindable`. Wspólne stałe kluczy i koloru domyślnego. `.syncing` bez payloadu + `MainActor.assumeIsolated`. Ustawienia przypomnień wydzielone z AppTheme, widoki biorą NotificationManager z environment. Widget zlokalizowany (en/pl). UI test przypięty do en. Dokumentacja zaktualizowana.
Powód: D1, D4, D6, D7, D8, D10, D11.

## 2026-09-29
Plik/lokalizacja: Habit Core/Habit Core/Views/AddEdit/AddHabitView.swift (deleteHabit, doc-comment onDelete)
Zmiana: Gdy prezenter nie poda `onDelete`, sheet sam usuwa nawyk przez `HabitActions.delete` (po `dismiss()`), zamiast nic nie robić. Z callbackiem zachowanie bez zmian (usunięcie odroczone do `onDismiss` prezentera).
Powód: Nieblokująca sugestia z iteracji 2 - opcjonalne `onDelete` mogło zrobić z „Usuń” cichy no-op dla przyszłych prezenterów edycji.
