//
//  WatchPrayerHomeView.swift
//  Daniel Prayer
//
//  Created by Codex on 9/10/25.
//

import SwiftUI
import SwiftData

struct WatchPrayerHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @AppStorage("watchSelectedPrayerPeriodRawValue") private var selectedPrayerPeriodRawValue = PrayerPeriod.current().rawValue

    private var selectedPrayerPeriod: PrayerPeriod {
        get { PrayerPeriod(rawValue: selectedPrayerPeriodRawValue) ?? .morning }
        set { selectedPrayerPeriodRawValue = newValue.rawValue }
    }

    private var activeItems: [Item] {
        items.filter { $0.prayerPeriod == selectedPrayerPeriod && $0.status != .answered }
    }

    private var answeredItems: [Item] {
        items.filter { $0.prayerPeriod == selectedPrayerPeriod && $0.status == .answered }
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
                    .pickerStyle(.navigationLink)
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
            }
            .navigationTitle("Daniel Prayer")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        modelContext.insert(Item(prayerPeriod: selectedPrayerPeriod))
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
                    Text(item.status.emoji)
                        .font(.title3)
                }
                .buttonStyle(.plain)

                TextField("Prayer item", text: $item.title)
            }

            HStack(spacing: 8) {
                if answeredList {
                    Button("Restore") {
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
}

#Preview("Watch Prayer Home") {
    WatchPrayerHomeView()
        .modelContainer(for: Item.self, inMemory: true)
}
