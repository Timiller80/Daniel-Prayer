//
//  ContentView.swift
//  Pray Like Daniel Watch Watch App
//
//  Created by Timothy Miller on 5/3/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @AppStorage("watchSelectedPrayerPeriodRawValue") private var selectedPrayerPeriodRawValue = PrayerPeriod.current().rawValue

    private var selectedPrayerPeriod: PrayerPeriod {
        get { PrayerPeriod(rawValue: selectedPrayerPeriodRawValue) ?? .morning }
        set { selectedPrayerPeriodRawValue = newValue.rawValue }
    }

    private var activeItems: [Item] {
        items
            .filter { $0.prayerPeriod == selectedPrayerPeriod && $0.status != .answered }
            .sorted { lhs, rhs in
                (lhs.createdAt ?? .distantPast) > (rhs.createdAt ?? .distantPast)
            }
    }

    private var answeredItems: [Item] {
        items
            .filter { $0.prayerPeriod == selectedPrayerPeriod && $0.status == .answered }
            .sorted { lhs, rhs in
                (lhs.answeredAt ?? lhs.createdAt ?? .distantPast) > (rhs.answeredAt ?? rhs.createdAt ?? .distantPast)
            }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Prayer List", selection: $selectedPrayerPeriodRawValue) {
                        ForEach(PrayerPeriod.allCases, id: \.rawValue) { period in
                            Text(period.title).tag(period.rawValue)
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Label(selectedPrayerPeriod.title, systemImage: periodSymbol)
                            .font(.headline)
                        Text(periodScripture)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Prayer List") {
                    if activeItems.isEmpty {
                        Text("No prayers yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(activeItems) { item in
                            WatchPrayerRow(item: item, answeredList: false)
                        }
                    }
                }

                if !answeredItems.isEmpty {
                    Section("Answered") {
                        ForEach(answeredItems) { item in
                            WatchPrayerRow(item: item, answeredList: true)
                        }
                    }
                }

                Section {
                    Text("Scripture quotations marked NKJV are taken from the New King James Version®. Copyright © 1982 by Thomas Nelson. Used by permission. All rights reserved.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Pray Like Daniel")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        modelContext.insert(Item(prayerPeriod: selectedPrayerPeriod))
                        try? modelContext.save()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private var periodSymbol: String {
        switch selectedPrayerPeriod {
        case .morning:
            "sunrise.fill"
        case .afternoon:
            "sun.max.fill"
        case .evening:
            "moon.stars.fill"
        }
    }

    private var periodScripture: String {
        switch selectedPrayerPeriod {
        case .morning:
            "Through the Lord's mercies we are not consumed, Because His compassions fail not. They are new every morning; Great is Your faithfulness. Lam 3:22-23 NKJV"
        case .afternoon:
            "Evening and morning and at noon I will pray, and cry aloud, And He shall hear my voice. Psalm 55:17 NKJV"
        case .evening:
            "Let my prayer be set before You as incense, The lifting up of my hands as the evening sacrifice. Psalm 141:2 NKJV"
        }
    }
}

private struct WatchPrayerRow: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: Item
    let answeredList: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    if answeredList {
                        item.status = .unchecked
                    } else {
                        item.status = item.status.nextActive
                    }
                } label: {
                    statusIcon
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.status.accessibilityLabel)

                TextField("Prayer item", text: $item.title)
            }

            if answeredList {
                DatePicker(
                    "Started",
                    selection: createdAtBinding,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .font(.body)

                DatePicker(
                    "Answered",
                    selection: answeredAtBinding,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .font(.body)
            }

            HStack(spacing: 8) {
                if answeredList {
                    Button("Pray Again") {
                        item.status = .unchecked
                    }
                } else {
                    Button("Answered") {
                        item.status = .answered
                    }
                }

                Button("Delete", role: .destructive) {
                    modelContext.delete(item)
                }
            }
            .font(.caption2.weight(.semibold))
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch item.status {
        case .praying:
            Text(item.status.emoji)
        default:
            Image(systemName: item.status.systemImageName)
        }
    }

    private var createdAtBinding: Binding<Date> {
        Binding(
            get: { item.createdAt ?? .now },
            set: { item.createdAt = $0 }
        )
    }

    private var answeredAtBinding: Binding<Date> {
        Binding(
            get: { item.answeredAt ?? item.createdAt ?? .now },
            set: { item.answeredAt = $0 }
        )
    }
}


#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
