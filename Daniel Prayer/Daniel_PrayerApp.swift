//
//  Daniel_PrayerApp.swift
//  Pray Like Daniel
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
            print("Could not create CloudKit ModelContainer: \(error)")
            do {
                return try PrayerModelContainer.makeLocal()
            } catch {
                print("Could not create local ModelContainer: \(error)")
                do {
                    return try PrayerModelContainer.makeInMemory()
                } catch {
                    preconditionFailure("Could not create in-memory ModelContainer: \(error)")
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
