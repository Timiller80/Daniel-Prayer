//
//  ContentView.swift
//  Pray Like Daniel
//
//  Created by Timothy Miller on 1/3/25.
//

import SwiftUI
import SwiftData
#if canImport(AlarmKit)
import AlarmKit
#endif

#if canImport(AlarmKit)
struct EmptyMetadata: AlarmMetadata {}
#else
struct EmptyMetadata {}
#endif

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    private static let defaultAlarm1Time = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    private static let defaultAlarm2Time = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
    private static let defaultAlarm3Time = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    private static let defaultAlarm1ID = UUID().uuidString
    private static let defaultAlarm2ID = UUID().uuidString
    private static let defaultAlarm3ID = UUID().uuidString

    // MARK: Alarm state
    @State private var authorized = false
    @State private var statusMessage: String?
    @State private var showingAlarmSettings = false
    @State private var showingBackupExporter = false
    @State private var showingBackupImporter = false
    @State private var backupDocument = PrayerListBackupDocument()
    @AppStorage("followsCurrentPrayerPeriod") private var followsCurrentPrayerPeriod = true
    @AppStorage("selectedPrayerPeriodRawValue") private var selectedPrayerPeriodRawValue = PrayerPeriod.current().rawValue
    private let alarmTestModeEnabled = false

    @State private var alarm1Enabled = true
    @State private var alarm2Enabled = true
    @State private var alarm3Enabled = true

    @AppStorage("alarm1TimeInterval") private var alarm1TimeInterval = Self.defaultAlarm1Time.timeIntervalSinceReferenceDate
    @AppStorage("alarm2TimeInterval") private var alarm2TimeInterval = Self.defaultAlarm2Time.timeIntervalSinceReferenceDate
    @AppStorage("alarm3TimeInterval") private var alarm3TimeInterval = Self.defaultAlarm3Time.timeIntervalSinceReferenceDate
    @AppStorage("alarm1ID") private var alarm1ID = Self.defaultAlarm1ID
    @AppStorage("alarm2ID") private var alarm2ID = Self.defaultAlarm2ID
    @AppStorage("alarm3ID") private var alarm3ID = Self.defaultAlarm3ID
    @AppStorage("lastMorningPrayerResetInterval") private var lastMorningPrayerResetInterval = 0.0
    @AppStorage("lastAfternoonPrayerResetInterval") private var lastAfternoonPrayerResetInterval = 0.0
    @AppStorage("lastEveningPrayerResetInterval") private var lastEveningPrayerResetInterval = 0.0

    @State private var alarm1Title: String = "Morning Prayer"
    @State private var alarm2Title: String = "Midday Prayer"
    @State private var alarm3Title: String = "Evening Prayer"
    @FocusState private var focusedItemCreatedAt: Date?

    private var selectedPrayerPeriod: PrayerPeriod {
        get { PrayerPeriod(rawValue: selectedPrayerPeriodRawValue) ?? .morning }
        set { selectedPrayerPeriodRawValue = newValue.rawValue }
    }

    private var visiblePrayerPeriod: PrayerPeriod {
        followsCurrentPrayerPeriod ? PrayerPeriod.current() : selectedPrayerPeriod
    }

    private var activeItems: [Item] {
        items
            .filter { $0.prayerPeriod == visiblePrayerPeriod && $0.status != .answered }
            .sorted { lhs, rhs in
                (lhs.createdAt ?? .distantPast) > (rhs.createdAt ?? .distantPast)
            }
    }

    private var answeredItems: [Item] {
        items
            .filter { $0.prayerPeriod == visiblePrayerPeriod && $0.status == .answered }
            .sorted { lhs, rhs in
                (lhs.answeredAt ?? lhs.createdAt ?? .distantPast) > (rhs.answeredAt ?? rhs.createdAt ?? .distantPast)
            }
    }

    private var periodAccent: Color {
        switch visiblePrayerPeriod {
        case .morning:
            Color.orange
        case .afternoon:
            Color.blue
        case .evening:
            Color.indigo
        }
    }

    private var periodGradient: LinearGradient {
        switch visiblePrayerPeriod {
        case .morning:
            LinearGradient(colors: [Color.orange.opacity(0.95), Color.yellow.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .afternoon:
            LinearGradient(colors: [Color.blue.opacity(0.9), Color.cyan.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .evening:
            LinearGradient(colors: [Color.indigo.opacity(0.95), Color.teal.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var periodSymbol: String {
        switch visiblePrayerPeriod {
        case .morning:
            "sunrise.fill"
        case .afternoon:
            "sun.max.fill"
        case .evening:
            "moon.stars.fill"
        }
    }

    private var periodDescription: String {
        switch visiblePrayerPeriod {
        case .morning:
            "Through the Lord's mercies we are not consumed, Because His compassions fail not. They are new every morning; Great is Your faithfulness. Lam 3:22-23 NKJV"
        case .afternoon:
            "Evening and morning and at noon I will pray, and cry aloud, And He shall hear my voice. Psalm 55:17 NKJV"
        case .evening:
            "Let my prayer be set before You as incense, The lifting up of my hands as the evening sacrifice. Psalm 141:2 NKJV"
        }
    }

    // MARK: - Helpers
    #if canImport(AlarmKit)
    private func makePresentation(for title: String) -> AlarmPresentation {
        let titleString: String = title.isEmpty ? "Prayer Reminder" : title
        if #available(iOS 26.1, *) {
            let titleRes = LocalizedStringResource(stringLiteral: titleString)
            let alert = AlarmPresentation.Alert(title: titleRes)
            return AlarmPresentation(alert: alert)
        } else {
            // On iOS 26.0, use the older alert initializer that is available on 26.0
            let titleRes = LocalizedStringResource(stringLiteral: titleString)
            let alert = AlarmPresentation.Alert(title: titleRes)
            return AlarmPresentation(alert: alert)
        }
    }
    #endif

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    currentPrayerHero

                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeading(title: "Prayer List", subtitle: activeItems.isEmpty ? "Add a prayer to begin." : "\(activeItems.count) prayer(s) for this time of day.")

                        if activeItems.isEmpty {
                            emptyPrayerCard(message: "No prayers in this list yet. Use the plus button to add one.")
                        } else {
                            ForEach(activeItems) { item in
                                ItemRow(
                                    item: item,
                                    answeredList: false,
                                    accent: periodAccent,
                                    focusedItemCreatedAt: $focusedItemCreatedAt
                                ) {
                                    withAnimation {
                                        modelContext.delete(item)
                                    }
                                }
                            }
                        }
                    }

                    if !answeredItems.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeading(title: "Answered Prayers", subtitle: "A gratitude archive for this time of day.")

                            ForEach(answeredItems) { item in
                                ItemRow(
                                    item: item,
                                    answeredList: true,
                                    accent: periodAccent,
                                    focusedItemCreatedAt: $focusedItemCreatedAt
                                ) {
                                    withAnimation {
                                        modelContext.delete(item)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(
                LinearGradient(
                    colors: [periodAccent.opacity(0.08), Color(.systemBackground), Color(.systemGroupedBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Pray Like Daniel")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { EditButton() }
                ToolbarItem { Button { addItem() } label: { Label("Add Item", systemImage: "plus") } }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedItemCreatedAt = nil
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingAlarmSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Menu {
                        Button {
                            exportPrayerList()
                        } label: {
                            Label("Export Prayer List", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            showingBackupImporter = true
                        } label: {
                            Label("Import Prayer List", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Label("Backup", systemImage: "externaldrive.badge.icloud")
                    }
                }
            }
        }
        .task {
            await requestAlarmAuthorization()
            resetPrayerStatusesIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            resetPrayerStatusesIfNeeded()
        }
        .fileExporter(
            isPresented: $showingBackupExporter,
            document: backupDocument,
            contentType: .json,
            defaultFilename: "Pray-Like-Daniel-List-Backup"
        ) { result in
            switch result {
            case .success:
                statusMessage = "Prayer list backup exported."
            case .failure(let error):
                statusMessage = "Backup export failed: \(error.localizedDescription)"
            }
        }
        .fileImporter(
            isPresented: $showingBackupImporter,
            allowedContentTypes: [.json]
        ) { result in
            importPrayerList(from: result)
        }
        .sheet(isPresented: $showingAlarmSettings) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Toggle("Follow Current Time of Day", isOn: $followsCurrentPrayerPeriod)

                        Picker("Prayer List", selection: $selectedPrayerPeriodRawValue) {
                            ForEach(PrayerPeriod.allCases, id: \.self) { period in
                                Text(period.title).tag(period.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .disabled(followsCurrentPrayerPeriod)
                        .opacity(followsCurrentPrayerPeriod ? 0.45 : 1)


                        alarmEditor(title: "Prayer Reminder 1", enabled: $alarm1Enabled, time: alarmTimeBinding(for: 1), name: $alarm1Title)
                        alarmEditor(title: "Prayer Reminder 2", enabled: $alarm2Enabled, time: alarmTimeBinding(for: 2), name: $alarm2Title)
                        alarmEditor(title: "Prayer Reminder 3", enabled: $alarm3Enabled, time: alarmTimeBinding(for: 3), name: $alarm3Title)

                        Button(role: .none) {
                            Task { await scheduleThreeDailyAlarms() }
                        } label: {
                            Label("Schedule Prayer Reminders", systemImage: "alarm")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        if let statusMessage {
                            Text(statusMessage)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }

                        Text("Scripture quotations marked NKJV are taken from the New King James Version®. Copyright © 1982 by Thomas Nelson. Used by permission. All rights reserved.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .navigationTitle("Prayer Reminders")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            showingAlarmSettings = false
                        }
                    }
                }
            }
        }
    }

    private var currentPrayerHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(visiblePrayerPeriod.title)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(periodDescription)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                }

                Spacer()

                Image(systemName: periodSymbol)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

        }
        .padding(20)
        .background(periodGradient, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: periodAccent.opacity(0.2), radius: 20, y: 10)
    }

    private func sectionHeading(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.semibold))
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func emptyPrayerCard(message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Alarm editor row
    @ViewBuilder
    private func alarmEditor(title: String, enabled: Binding<Bool>, time: Binding<Date>, name: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Toggle("Enabled", isOn: enabled).labelsHidden()
            }
            DatePicker("Time", selection: time, displayedComponents: [.hourAndMinute])
                .datePickerStyle(.compact)
            TextField("Title", text: name)
                .textFieldStyle(.roundedBorder)
            Text(nextTriggerDescription(for: time.wrappedValue))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial, in: .rect(cornerRadius: 12))
    }

    private func nextTriggerDescription(for time: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        let descriptionPrefix = "Next repeating reminder"
        guard let nextDate = nextTriggerDate(for: time) else {
            return "\(descriptionPrefix): unavailable"
        }

        return "\(descriptionPrefix): \(formatter.string(from: nextDate))"
    }

    private func nextTriggerDate(for time: Date) -> Date? {
        if alarmTestModeEnabled {
            return Date().addingTimeInterval(120)
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        guard let hour = components.hour, let minute = components.minute else { return nil }

        return calendar.nextDate(
            after: Date(),
            matching: DateComponents(hour: hour, minute: minute),
            matchingPolicy: .nextTime,
            repeatedTimePolicy: .first,
            direction: .forward
        )
    }

    private func alarmTimeBinding(for alarmNumber: Int) -> Binding<Date> {
        switch alarmNumber {
        case 1:
            Binding(
                get: { Date(timeIntervalSinceReferenceDate: alarm1TimeInterval) },
                set: { alarm1TimeInterval = $0.timeIntervalSinceReferenceDate }
            )
        case 2:
            Binding(
                get: { Date(timeIntervalSinceReferenceDate: alarm2TimeInterval) },
                set: { alarm2TimeInterval = $0.timeIntervalSinceReferenceDate }
            )
        default:
            Binding(
                get: { Date(timeIntervalSinceReferenceDate: alarm3TimeInterval) },
                set: { alarm3TimeInterval = $0.timeIntervalSinceReferenceDate }
            )
        }
    }

    // MARK: - AlarmKit Authorization
    private func requestAlarmAuthorization() async {
        #if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else {
            await MainActor.run {
                authorized = false
                statusMessage = "Prayer reminders require iOS 26 or newer."
            }
            return
        }
        do {
            let manager = AlarmManager.shared
            let state: AlarmManager.AuthorizationState
            if manager.authorizationState == .notDetermined {
                state = try await manager.requestAuthorization()
            } else {
                state = manager.authorizationState
            }
            await MainActor.run {
                authorized = (state == .authorized)
                statusMessage = authorized ? nil : "Prayer reminder authorization denied. Enable it in Settings."
            }
        } catch {
            await MainActor.run {
                authorized = false
                statusMessage = "Authorization error: \(error.localizedDescription)"
            }
        }
        #else
        await MainActor.run {
            authorized = false
            statusMessage = "Prayer reminders are not available in this build."
        }
        #endif
    }

    private func resetPrayerStatusesIfNeeded(referenceDate: Date = .now) {
        resetPrayerStatusesIfNeeded(for: .morning, enabled: alarm1Enabled, time: Date(timeIntervalSinceReferenceDate: alarm1TimeInterval), referenceDate: referenceDate)
        resetPrayerStatusesIfNeeded(for: .afternoon, enabled: alarm2Enabled, time: Date(timeIntervalSinceReferenceDate: alarm2TimeInterval), referenceDate: referenceDate)
        resetPrayerStatusesIfNeeded(for: .evening, enabled: alarm3Enabled, time: Date(timeIntervalSinceReferenceDate: alarm3TimeInterval), referenceDate: referenceDate)
    }

    private func resetPrayerStatusesIfNeeded(for period: PrayerPeriod, enabled: Bool, time: Date, referenceDate: Date) {
        guard enabled, let latestTrigger = mostRecentTriggerDate(for: time, referenceDate: referenceDate) else {
            return
        }

        let lastResetInterval: Double
        switch period {
        case .morning:
            lastResetInterval = lastMorningPrayerResetInterval
        case .afternoon:
            lastResetInterval = lastAfternoonPrayerResetInterval
        case .evening:
            lastResetInterval = lastEveningPrayerResetInterval
        }

        guard latestTrigger.timeIntervalSinceReferenceDate > lastResetInterval else {
            return
        }

        let itemsToReset = items.filter { $0.prayerPeriod == period && $0.status == .praying }
        for item in itemsToReset {
            item.status = .unchecked
        }

        switch period {
        case .morning:
            lastMorningPrayerResetInterval = latestTrigger.timeIntervalSinceReferenceDate
        case .afternoon:
            lastAfternoonPrayerResetInterval = latestTrigger.timeIntervalSinceReferenceDate
        case .evening:
            lastEveningPrayerResetInterval = latestTrigger.timeIntervalSinceReferenceDate
        }

        if !itemsToReset.isEmpty {
            try? modelContext.save()
        }
    }

    private func mostRecentTriggerDate(for time: Date, referenceDate: Date) -> Date? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        guard
            let hour = components.hour,
            let minute = components.minute
        else {
            return nil
        }

        var triggerComponents = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        triggerComponents.hour = hour
        triggerComponents.minute = minute
        triggerComponents.second = 0

        guard let todayTrigger = calendar.date(from: triggerComponents) else {
            return nil
        }

        if referenceDate >= todayTrigger {
            return todayTrigger
        }

        return calendar.date(byAdding: .day, value: -1, to: todayTrigger)
    }

    // MARK: - Schedule three daily alarms
    private func scheduleThreeDailyAlarms() async {
        #if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else {
            await MainActor.run { statusMessage = "Prayer reminders require iOS 26 or newer." }
            return
        }
        guard authorized else {
            await MainActor.run { statusMessage = "Cannot schedule without authorization." }
            return
        }

        func configuration(for title: String, at time: Date) -> AlarmManager.AlarmConfiguration<EmptyMetadata> {
            let cal = Calendar.current
            let hour = cal.component(.hour, from: time)
            let minute = cal.component(.minute, from: time)
            let schedule: Alarm.Schedule

            if alarmTestModeEnabled, let nextDate = nextTriggerDate(for: time) {
                schedule = .fixed(nextDate)
            } else {
                schedule = .relative(.init(
                    time: .init(hour: hour, minute: minute),
                    repeats: .weekly([.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday])
                ))
            }

            #if canImport(AlarmKit)
            if #available(iOS 26.0, *) {
                let presentation = makePresentation(for: title)
                let attributes = AlarmAttributes<EmptyMetadata>(
                    presentation: presentation,
                    metadata: EmptyMetadata(),
                    tintColor: .accentColor
                )
                return AlarmManager.AlarmConfiguration.alarm(schedule: schedule, attributes: attributes)
            } else {
                fatalError("Unsupported iOS version")
            }
            #else
            fatalError("AlarmKit not available")
            #endif
        }

        do {
            let manager = AlarmManager.shared
            let id1 = UUID(uuidString: alarm1ID) ?? UUID()
            let id2 = UUID(uuidString: alarm2ID) ?? UUID()
            let id3 = UUID(uuidString: alarm3ID) ?? UUID()

            if id1.uuidString != alarm1ID { alarm1ID = id1.uuidString }
            if id2.uuidString != alarm2ID { alarm2ID = id2.uuidString }
            if id3.uuidString != alarm3ID { alarm3ID = id3.uuidString }

            // Clear all existing alarms for this app so test-mode and enabled-state changes
            // don't leave stale weekly schedules behind.
            let existingAlarms = try manager.alarms
            for alarm in existingAlarms {
                try? manager.cancel(id: alarm.id)
            }

            var scheduledCount = 0

            if alarm1Enabled {
                _ = try await manager.schedule(id: id1, configuration: configuration(for: alarm1Title, at: Date(timeIntervalSinceReferenceDate: alarm1TimeInterval)))
                scheduledCount += 1
            }

            if alarm2Enabled {
                _ = try await manager.schedule(id: id2, configuration: configuration(for: alarm2Title, at: Date(timeIntervalSinceReferenceDate: alarm2TimeInterval)))
                scheduledCount += 1
            }

            if alarm3Enabled {
                _ = try await manager.schedule(id: id3, configuration: configuration(for: alarm3Title, at: Date(timeIntervalSinceReferenceDate: alarm3TimeInterval)))
                scheduledCount += 1
            }

            await MainActor.run {
                if scheduledCount == 0 {
                    statusMessage = "No prayer reminders are enabled."
                } else if alarmTestModeEnabled {
                    statusMessage = "\(scheduledCount) test prayer reminder(s) scheduled."
                } else {
                    statusMessage = "\(scheduledCount) repeating prayer reminder(s) scheduled."
                }
            }
        } catch {
            await MainActor.run { statusMessage = "Failed to schedule: \(error.localizedDescription)" }
        }
        #else
        await MainActor.run { statusMessage = "Prayer reminders are not available in this build." }
        #endif
    }

    // MARK: - Items
    private func exportPrayerList() {
        backupDocument = PrayerListBackupDocument(
            payload: PrayerListBackupPayload(
                version: 1,
                exportedAt: .now,
                items: items.map { item in
                    PrayerListBackupItem(
                        title: item.title,
                        statusRawValue: item.statusRawValue,
                        prayerPeriodRawValue: item.prayerPeriodRawValue,
                        createdAt: item.createdAt,
                        answeredAt: item.answeredAt
                    )
                }
            )
        )
        showingBackupExporter = true
    }

    private func importPrayerList(from result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let payload = try decoder.decode(PrayerListBackupPayload.self, from: data)

                withAnimation {
                    for item in items {
                        modelContext.delete(item)
                    }

                    for backupItem in payload.items {
                        let status = PrayerStatus(rawValue: backupItem.statusRawValue) ?? .unchecked
                        let prayerPeriod = PrayerPeriod(rawValue: backupItem.prayerPeriodRawValue) ?? visiblePrayerPeriod
                        modelContext.insert(Item(title: backupItem.title, status: status, prayerPeriod: prayerPeriod, createdAt: backupItem.createdAt ?? .now, answeredAt: backupItem.answeredAt))
                    }
                }

                try modelContext.save()
                statusMessage = "Prayer list restored from backup."
            } catch {
                statusMessage = "Backup import failed: \(error.localizedDescription)"
            }
        case .failure(let error):
            statusMessage = "Backup import failed: \(error.localizedDescription)"
        }
    }

    private func addItem() {
        let createdAt = Date()
        withAnimation {
            modelContext.insert(Item(prayerPeriod: visiblePrayerPeriod, createdAt: createdAt))
            focusedItemCreatedAt = createdAt
        }
        try? modelContext.save()
    }

    private func deleteActiveItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets { modelContext.delete(activeItems[index]) }
        }
    }

    private func deleteAnsweredItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets { modelContext.delete(answeredItems[index]) }
        }
    }
}

private struct ItemRow: View {
    @Bindable var item: Item
    let answeredList: Bool
    let accent: Color
    var focusedItemCreatedAt: FocusState<Date?>.Binding
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button {
                withAnimation(.snappy) {
                    if answeredList {
                        item.status = .unchecked
                    } else {
                        item.status = item.status.nextActive
                    }
                }
            } label: {
                statusIcon
                    .font(.title2)
                    .frame(width: 42, height: 42)
                    .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.status.accessibilityLabel)

            VStack(alignment: .leading, spacing: 10) {
                TextField("Prayer item", text: $item.title, axis: .vertical)
                    .font(.body)
                    .focused(focusedItemCreatedAt, equals: item.createdAt)

                if answeredList {
                    DatePicker(
                        "Started",
                        selection: createdAtBinding,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .datePickerStyle(.compact)

                    DatePicker(
                        "Answered",
                        selection: answeredAtBinding,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .datePickerStyle(.compact)
                }

                HStack(spacing: 8) {
                    if answeredList {
                        actionChip(title: "Pray Again", tint: accent) {
                            item.status = .unchecked
                        }
                    } else {
                        actionChip(title: "Answered", tint: accent) {
                            item.status = .answered
                        }
                    }

                    actionChip(title: "Delete", tint: .secondary, action: onDelete)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
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

    private func actionChip(title: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: Capsule())
            .foregroundStyle(tint)
            .buttonStyle(.plain)
    }
}


#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
