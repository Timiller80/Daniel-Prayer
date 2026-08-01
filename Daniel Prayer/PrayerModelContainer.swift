//
//  PrayerModelContainer.swift
//  Pray Like Daniel
//
//  Created by Codex on 9/10/25.
//

import SwiftData

enum PrayerModelContainer {
    static func makeShared() throws -> ModelContainer {
        try makeContainer(isStoredInMemoryOnly: false, cloudKitDatabase: .private("iCloud.StarShine.Daniel-Prayer"))
    }

    static func makeLocal() throws -> ModelContainer {
        try makeContainer(isStoredInMemoryOnly: false, cloudKitDatabase: .none)
    }

    static func makeInMemory() throws -> ModelContainer {
        try makeContainer(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
    }

    private static func makeContainer(isStoredInMemoryOnly: Bool, cloudKitDatabase: ModelConfiguration.CloudKitDatabase) throws -> ModelContainer {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            cloudKitDatabase: cloudKitDatabase
        )

        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    }
}
