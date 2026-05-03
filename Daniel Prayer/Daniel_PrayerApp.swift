//
//  Daniel_PrayerApp.swift
//  Daniel Prayer
//
//  Created by Timothy Miller on 1/3/25.
//

import SwiftUI
import SwiftData

@main
struct Daniel_PrayerApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            return try PrayerModelContainer.makeShared()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
