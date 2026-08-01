//
//  Item.swift
//  Pray Like Daniel
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
