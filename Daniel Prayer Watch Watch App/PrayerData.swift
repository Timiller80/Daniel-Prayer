//
//  PrayerData.swift
//  Pray Like Daniel Watch Watch App
//
//  Created by Codex on 5/31/26.
//

import Foundation
import SwiftData

enum PrayerStatus: Int, Codable, CaseIterable {
    case unchecked
    case praying
    case answered

    var emoji: String {
        switch self {
        case .unchecked:
            "□"
        case .praying:
            "🙏"
        case .answered:
            "Answered"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .unchecked:
            "Not started"
        case .praying:
            "Praying"
        case .answered:
            "Answered"
        }
    }

    var systemImageName: String {
        switch self {
        case .unchecked:
            "square"
        case .praying:
            "hand.raised.fill"
        case .answered:
            "sparkles"
        }
    }

    var nextActive: PrayerStatus {
        switch self {
        case .unchecked:
            .praying
        case .praying:
            .unchecked
        case .answered:
            .unchecked
        }
    }
}

enum PrayerPeriod: Int, Codable, CaseIterable {
    case morning
    case afternoon
    case evening

    var title: String {
        switch self {
        case .morning:
            "Morning"
        case .afternoon:
            "Afternoon"
        case .evening:
            "Evening"
        }
    }

    static func current(for date: Date = .now) -> PrayerPeriod {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case ..<12:
            return PrayerPeriod.morning
        case 12..<17:
            return PrayerPeriod.afternoon
        default:
            return PrayerPeriod.evening
        }
    }
}

@Model
final class Item {
    var title: String = ""
    var statusRawValue: Int = PrayerStatus.unchecked.rawValue
    var prayerPeriodRawValue: Int = PrayerPeriod.morning.rawValue
    var createdAt: Date?
    var answeredAt: Date?

    var status: PrayerStatus {
        get { PrayerStatus(rawValue: statusRawValue) ?? .unchecked }
        set {
            statusRawValue = newValue.rawValue
            if newValue == .answered {
                answeredAt = answeredAt ?? .now
            } else {
                answeredAt = nil
            }
        }
    }

    var prayerPeriod: PrayerPeriod {
        get { PrayerPeriod(rawValue: prayerPeriodRawValue) ?? .morning }
        set { prayerPeriodRawValue = newValue.rawValue }
    }

    init(title: String = "", status: PrayerStatus = .unchecked, prayerPeriod: PrayerPeriod = .morning, createdAt: Date = .now, answeredAt: Date? = nil) {
        self.title = title
        self.statusRawValue = status.rawValue
        self.prayerPeriodRawValue = prayerPeriod.rawValue
        self.createdAt = createdAt
        self.answeredAt = status == .answered ? (answeredAt ?? .now) : nil
    }
}

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
