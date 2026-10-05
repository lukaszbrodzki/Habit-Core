# iOS review - ustalenia i wyjątki (Habit Core)

## 2026-09-29 - SwiftData: podwójne ustawienie relacji przy odhaczaniu
Ustalenie: W `HabitActions.toggleCompletion` zostaje zarówno `HabitEntry(..., habit: habit)`, jak i `habit.entries?.append(entry)`. Nie zgłaszać ponownie.
Kontekst: Recenzent (D3) nie był pewien, czy SwiftData nie zdubluje wpisu w tablicy. Test `HabitActionsTests.testToggleCompletionMarksAndUnmarksCurrentPeriod` potwierdza `entries.count == 1`, a usunięcie `append` mogłoby opóźnić odświeżenie `habit.entries` w UI przed zapisem.

## 2026-09-29 - Widget: `cloudKitDatabase: .automatic` zamiast `.none`
Ustalenie: `SharedStore.makeContainer()` używa `.automatic` w obu targetach (appka i widget) i jest to akceptowane. Nie zgłaszać ponownie, dopóki nie pojawi się źródło potwierdzające, że `.none` jest bezpieczne.
Kontekst: Recenzent (W9) sugerował jawne `.none` w widgecie. Kontrargument: widget nie ma entitlementu iCloud, więc i tak nie mirroruje, a otwarcie tego samego pliku store'u z inną konfiguracją (bez persistent history tracking, którego używa mirroring CloudKit) może skutkować otwarciem w trybie read-only lub ostrzeżeniami Core Data. Bez testu na urządzeniu nie da się tego rozstrzygnąć, a obecna konfiguracja działa. Do ponownej weryfikacji na fizycznym urządzeniu przy okazji testów widgetu.

## 2026-09-29 - Linki prawne (Terms / Privacy Policy) jako placeholdery
Ustalenie: Placeholdery `https://example.com/terms` i `/privacy` w `SettingsView` są znanym blockerem przed wysyłką do App Store (Guideline 5.1.1(i)), śledzonym w TODO.md. Nie zgłaszać jako uwagi w rundach review, ale przed wysyłką MUSZĄ zostać podmienione na prawdziwe strony Habit Core.
Kontekst: Strony prawne są po stronie użytkownika (strona www w przygotowaniu). Nie wolno ponownie używać stron Wallet Log.

## 2026-09-29 - Brak migracji store'u po przeniesieniu do App Group
Ustalenie: Brak jednorazowej migracji danych ze starej lokalizacji store'u do kontenera App Group jest akceptowany. Uwaga wyłącznie informacyjna.
Kontekst: Aplikacja nie jest jeszcze wydana, więc zmiana lokalizacji dotyczy tylko urządzeń deweloperskich, a CloudKit odtwarza dane z prywatnej bazy. Wrócić do tematu, jeśli lokalizacja store'u zmieni się po wydaniu.

## 2026-10-05 - Linki prawne — rozwiązane
Ustalenie: Wpis o placeholderach linków prawnych jest nieaktualny. Ustawienia linkują do polityki prywatności `https://lukbro.com/habitcore/privacy-policy/`; wiersz „Warunki korzystania” usunięty.
Kontekst: Decyzja użytkownika — appka jest darmowa, bez konta i zakupów, więc obowiązuje standardowa EULA Apple i własny regulamin nie jest wymagany (App Review Guidelines wymagają linku do polityki prywatności w appce i w App Store Connect, 5.1.1(i)).
