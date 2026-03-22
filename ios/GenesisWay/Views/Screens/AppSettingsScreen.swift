import SwiftUI

struct AppSettingsScreen: View {
    @EnvironmentObject private var store: GenesisStore
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirmation = false
    @State private var importStatus = ""
    @State private var showDiagnostics = false
    @State private var showCalendarSettings = false
    @State private var showFindOutMore = false

    private var buildLabel: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "v\(version) (\(build))"
    }

    private var plannerStartOptions: [Int] {
        Array(5...21)
    }

    private var plannerEndOptions: [Int] {
        Array(max(store.plannerStartHour + 1, 6)...22)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Launch") {
                    Toggle("Start at Intro screen", isOn: Binding(
                        get: { store.showIntroOnLaunch },
                        set: { store.setShowIntroOnLaunch($0) }
                    ))

                    Text("When enabled, the app opens on the intro screen on launch.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button("Open Intro Now") {
                        store.navigate(.onboarding)
                        dismiss()
                    }
                    .foregroundStyle(GWTheme.gold)

                    Button("Start Guided Setup") {
                        store.launchGuidedSetup()
                        dismiss()
                    }
                    .foregroundStyle(GWTheme.gold)
                }

                Section("Navigation") {
                    Button("Go to Fill screen") {
                        store.navigate(.fill)
                        dismiss()
                    }
                    .foregroundStyle(GWTheme.gold)

                    Button("Open Calendar Settings") {
                        showCalendarSettings = true
                    }
                    .foregroundStyle(GWTheme.gold)

                    Button("Find Out More") {
                        showFindOutMore = true
                    }
                    .foregroundStyle(GWTheme.gold)
                }

                Section("Appearance") {
                    Picker("Theme", selection: Binding(
                        get: { store.appThemeStyle },
                        set: { store.setAppThemeStyle($0) }
                    )) {
                        ForEach(AppThemeStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }

                    Text("Glass look stays the same, while colors and gradients shift by theme. Brown Glass is the default.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("App Icon") {
                    Picker("Icon Style", selection: Binding(
                        get: { store.appIconStyle },
                        set: { store.setAppIconStyle($0) }
                    )) {
                        ForEach(AppIconStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }

                    Text("Choose from 6 icon styles. Chrome is the default.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Loop Rules") {
                    Text("Create loops from Dump's Automate menu. This screen is for review and cleanup.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if store.loopRules.isEmpty {
                        Text("No loops configured yet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.loopRules) { rule in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(rule.text)
                                    Text(loopSummary(for: rule))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    store.removeLoopRule(rule.id)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    }
                }

                Section("Reminders") {
                    Toggle("Enable reminders and alerts", isOn: Binding(
                        get: { store.remindersEnabled },
                        set: { store.setRemindersEnabled($0) }
                    ))

                    Picker("Alert lead time", selection: Binding(
                        get: { store.reminderLeadMinutes },
                        set: { store.setReminderLeadMinutes($0) }
                    )) {
                        Text("At time of task").tag(0)
                        Text("10 minutes before").tag(10)
                        Text("30 minutes before").tag(30)
                        Text("60 minutes before").tag(60)
                    }
                    .disabled(!store.remindersEnabled)

                    Text("These options control how Fill screen reminders are scheduled.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Toggle("Morning daily-flow reminder", isOn: Binding(
                        get: { store.morningPlanningReminderEnabled },
                        set: { store.setMorningPlanningReminderEnabled($0) }
                    ))

                    Picker("Morning reminder time", selection: Binding(
                        get: { store.morningPlanningReminderTime },
                        set: { store.setMorningPlanningReminderTime($0) }
                    )) {
                        Text("Choose in onboarding/settings").tag("")
                        Text("6:30 AM").tag("6:30 AM")
                        Text("7:00 AM").tag("7:00 AM")
                        Text("7:30 AM").tag("7:30 AM")
                        Text("8:00 AM").tag("8:00 AM")
                        Text("8:30 AM").tag("8:30 AM")
                        Text("9:00 AM").tag("9:00 AM")
                    }
                    .disabled(!store.morningPlanningReminderEnabled)

                    Toggle("Evening 5-minute planning reminder", isOn: Binding(
                        get: { store.eveningPlanningReminderEnabled },
                        set: { store.setEveningPlanningReminderEnabled($0) }
                    ))

                    Picker("Evening reminder time", selection: Binding(
                        get: { store.eveningPlanningReminderTime },
                        set: { store.setEveningPlanningReminderTime($0) }
                    )) {
                        Text("Choose in onboarding/settings").tag("")
                        Text("7:00 PM").tag("7:00 PM")
                        Text("7:30 PM").tag("7:30 PM")
                        Text("8:00 PM").tag("8:00 PM")
                        Text("8:30 PM").tag("8:30 PM")
                        Text("9:00 PM").tag("9:00 PM")
                    }
                    .disabled(!store.eveningPlanningReminderEnabled)

                    Text("No reminder times are auto-defaulted. Configure your morning/evening flow reminders explicitly.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Daily Planner") {
                    Picker("Start hour", selection: Binding(
                        get: { store.plannerStartHour },
                        set: { store.setPlannerStartHour($0) }
                    )) {
                        ForEach(plannerStartOptions, id: \.self) { hour in
                            Text(hourLabel(hour)).tag(hour)
                        }
                    }

                    Picker("End hour", selection: Binding(
                        get: { store.plannerEndHour },
                        set: { store.setPlannerEndHour($0) }
                    )) {
                        ForEach(plannerEndOptions, id: \.self) { hour in
                            Text(hourLabel(hour)).tag(hour)
                        }
                    }

                    Text("Choose the visible hour range for Fill's Daily Planner timeline.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Developer") {
                    Button("Import lightweight test day") {
                        let added = store.importDeveloperLightweightTestDumpData()
                        if added == 0 {
                            importStatus = "Lightweight test day already imported."
                        } else {
                            importStatus = "Imported \(added) lightweight test item\(added == 1 ? "" : "s")."
                        }
                    }
                    .foregroundStyle(GWTheme.gold)

                    Button("Import test data into Dump") {
                        let added = store.importDeveloperTestDumpData()
                        if added == 0 {
                            importStatus = "Test data already imported."
                        } else {
                            importStatus = "Imported \(added) test dump item\(added == 1 ? "" : "s")."
                        }
                    }
                    .foregroundStyle(GWTheme.gold)

                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Text("Clear all user data and start over")
                    }

                    if !importStatus.isEmpty {
                        Text(importStatus)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Button("Show diagnostics") {
                        showDiagnostics = true
                    }
                    .foregroundStyle(GWTheme.gold)

                    Text("Temporary pre-release option. Remove before final build.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    HStack {
                        Spacer()
                        Text(buildLabel)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .background(GWTheme.background.ignoresSafeArea())
            .navigationTitle("App Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Clear all data?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    store.resetAllUserData()
                    dismiss()
                }
            } message: {
                Text("This removes your dump items, shaped assignments, Fill plan, reminders preferences, and parked items.")
            }
            .sheet(isPresented: $showDiagnostics) {
                NavigationStack {
                    List {
                        ForEach(store.diagnosticsSummary(), id: \.0) { item in
                            HStack {
                                Text(item.0)
                                Spacer()
                                Text(item.1)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .navigationTitle("Diagnostics")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showDiagnostics = false }
                        }
                    }
                }
            }
            .sheet(isPresented: $showCalendarSettings) {
                CalendarSettingsScreen()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showFindOutMore) {
                FindOutMoreScreen()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(GWTheme.gold)
                }
            }
        }
    }
}

private func hourLabel(_ hour: Int) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "h:00 a"

    var components = DateComponents()
    components.hour = hour
    components.minute = 0
    let date = Calendar.current.date(from: components) ?? Date()
    return formatter.string(from: date)
}

private func loopSummary(for rule: LoopRule) -> String {
    let laneText: String
    if let lane = rule.lane {
        laneText = lane == .work ? "Work" : "Personal"
    } else {
        laneText = "Unassigned"
    }

    let recurrenceText: String
    switch rule.recurrenceType {
    case .daily:
        recurrenceText = "Daily"
    case .weekly:
        recurrenceText = "Weekly"
    case .weekdays:
        let dayNames = rule.weekdayNumbers.map { weekdayNumberToShortName($0) }.joined(separator: ", ")
        recurrenceText = dayNames.isEmpty ? "Specific weekdays" : dayNames
    }

    let durationText: String
    switch rule.durationType {
    case .forever:
        durationText = "Forever"
    case .fixedCount:
        durationText = "\(rule.remainingOccurrences ?? 0) left"
    }

    return "\(recurrenceText) • \(durationText) • \(laneText)"
}

private func weekdayNumberToShortName(_ weekday: Int) -> String {
    switch weekday {
    case 1: return "Sun"
    case 2: return "Mon"
    case 3: return "Tue"
    case 4: return "Wed"
    case 5: return "Thu"
    case 6: return "Fri"
    case 7: return "Sat"
    default: return "?"
    }
}

private struct FindOutMoreScreen: View {
    @Environment(\.dismiss) private var dismiss

    private let danWebsite = URL(string: "https://www.genesisway.co")!
    private let brandingPage = URL(string: "https://www.genesisway.co/about")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Coach")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(GWTheme.textPrimary)

                            Text("Learn more about Dan's work and the Genesis Way brand story.")
                                .font(.system(size: 12))
                                .foregroundStyle(GWTheme.textMuted)

                            Link(destination: danWebsite) {
                                Label("Dan's Website", systemImage: "safari")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color(hex: "1a1208"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(GWTheme.gold)
                                    .clipShape(Capsule())
                            }

                            Link(destination: brandingPage) {
                                Label("Branding / About", systemImage: "sparkles")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(GWTheme.gold)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(GWTheme.background.ignoresSafeArea())
            .navigationTitle("Find Out More")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(GWTheme.gold)
                }
            }
        }
    }
}
