//
//  Habit_CoreApp.swift
//  Habit Core
//
//  Created by Łukasz Brodzki on 19/03/2026.
//

import SwiftUI
import CoreData

@main
struct Habit_CoreApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
