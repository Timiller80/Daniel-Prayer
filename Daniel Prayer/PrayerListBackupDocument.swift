//
//  PrayerListBackupDocument.swift
//  Daniel Prayer
//
//  Created by OpenAI on 4/15/26.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct PrayerListBackupPayload: Codable {
    var version: Int
    var exportedAt: Date
    var items: [PrayerListBackupItem]

    static let empty = PrayerListBackupPayload(version: 1, exportedAt: .now, items: [])
}

struct PrayerListBackupItem: Codable {
    var title: String
    var statusRawValue: Int
    var prayerPeriodRawValue: Int

    init(title: String, statusRawValue: Int, prayerPeriodRawValue: Int) {
        self.title = title
        self.statusRawValue = statusRawValue
        self.prayerPeriodRawValue = prayerPeriodRawValue
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)

        if let statusRawValue = try container.decodeIfPresent(Int.self, forKey: .statusRawValue) {
            self.statusRawValue = statusRawValue
        } else if let isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) {
            statusRawValue = isCompleted ? PrayerStatus.answered.rawValue : PrayerStatus.unchecked.rawValue
        } else {
            statusRawValue = PrayerStatus.unchecked.rawValue
        }

        prayerPeriodRawValue = try container.decodeIfPresent(Int.self, forKey: .prayerPeriodRawValue) ?? PrayerPeriod.current().rawValue
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(statusRawValue, forKey: .statusRawValue)
        try container.encode(prayerPeriodRawValue, forKey: .prayerPeriodRawValue)
    }

    enum CodingKeys: String, CodingKey {
        case title
        case statusRawValue
        case prayerPeriodRawValue
        case isCompleted
    }
}

struct PrayerListBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var payload: PrayerListBackupPayload

    init(payload: PrayerListBackupPayload = .empty) {
        self.payload = payload
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        payload = try JSONDecoder().decode(PrayerListBackupPayload.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(payload)
        return FileWrapper(regularFileWithContents: data)
    }
}
