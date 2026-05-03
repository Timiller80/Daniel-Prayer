//
//  Item.swift
//  Daniel Prayer
//
//  Created by Timothy Miller on 1/3/25.
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
            "⬜"
        case .praying:
            "🙏"
        case .answered:
            "✨"
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
    var title: String
    var statusRawValue: Int
    var prayerPeriodRawValue: Int

    var status: PrayerStatus {
        get { PrayerStatus(rawValue: statusRawValue) ?? .unchecked }
        set { statusRawValue = newValue.rawValue }
    }

    var prayerPeriod: PrayerPeriod {
        get { PrayerPeriod(rawValue: prayerPeriodRawValue) ?? .morning }
        set { prayerPeriodRawValue = newValue.rawValue }
    }

    init(title: String = "", status: PrayerStatus = .unchecked, prayerPeriod: PrayerPeriod = .morning) {
        self.title = title
        self.statusRawValue = status.rawValue
        self.prayerPeriodRawValue = prayerPeriod.rawValue
    }
}
