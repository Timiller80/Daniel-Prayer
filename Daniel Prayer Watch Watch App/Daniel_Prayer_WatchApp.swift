//
//  Daniel_Prayer_WatchApp.swift
//  Pray Like Daniel Watch Watch App
//
//  Created by Timothy Miller on 5/3/26.
//

import SwiftUI
import SwiftData

@main
struct Daniel_Prayer_Watch_Watch_AppApp: App {
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
