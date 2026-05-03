//
//  PrayerModelContainer.swift
//  Daniel Prayer
//
//  Created by Codex on 9/10/25.
//

import SwiftData

enum PrayerModelContainer {
    static func makeShared() throws -> ModelContainer {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    }
}
