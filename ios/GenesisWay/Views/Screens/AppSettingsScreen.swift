import AuthenticationServices
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AppSettingsScreen: View {
    @EnvironmentObject private var store: GenesisStore
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirmation = false
    @State private var importStatus = ""
    @State private var showDiagnostics = false
    @State private var showCalendarSettings = false
    @State private var showFindOutMore = false
    @State private var authStatusMessage = ""
    @State private var isSigningIn = false
    @State private var devDateOverride: Date = Date()

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

    private var accountStatusLabel: String {
        if store.isSignedIn {
            return "Signed in (\(store.authProvider.rawValue.capitalized))"
        }
        return "Guest"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Launch") {
                    Toggle("Start at Intro screen", isOn: Binding(
                        get: { store.showIntroOnLaunch },
                        set: { store.setShowIntroOnLaunch($0) }
                    ))

                    Toggle("Show feedback identifiers", isOn: Binding(
                        get: { store.showFeedbackIdentifiers },
                        set: { store.setShowFeedbackIdentifiers($0) }
                    ))

                    Text("When enabled, the app opens on the intro screen on launch.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text("Identifiers like GW-P04 remain visible on screens for quick feedback collection.")
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

                Section("Account") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(accountStatusLabel)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Backend")
                        Spacer()
                        Text(store.isSupabaseConfigured ? "Supabase configured" : "Supabase not configured")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Migration")
                        Spacer()
                        Text(store.authMigrationStatus.rawValue)
                            .foregroundStyle(.secondary)
                    }

                    if let userId = store.authUserId, store.isSignedIn {
                        HStack {
                            Text("User")
                            Spacer()
                            Text(shortUserId(userId))
                                .foregroundStyle(.secondary)
                        }
                    }

                    if store.isSignedIn {
                        Button("Sign out") {
                            store.signOutAccount()
                            authStatusMessage = "Signed out. Guest mode is active."
                        }
                        .foregroundStyle(Color.red)

                        if store.canRetryAuthMigration {
                            Button("Retry account migration") {
                                let succeeded = store.retryAuthMigration()
                                authStatusMessage = succeeded
                                    ? "Migration retry succeeded."
                                    : "Migration retry failed."
                            }
                            .foregroundStyle(GWTheme.gold)
                        }

                        Button("Run migration regression probe") {
                            let passed = store.runAuthMigrationRegressionProbe()
                            authStatusMessage = passed
                                ? "Migration regression probe passed."
                                : "Migration regression probe failed."
                        }
                        .foregroundStyle(GWTheme.gold)

                        Button("Copy migration diagnostics") {
                            let report = store.authMigrationDiagnosticsReport()
                            #if canImport(UIKit)
                            UIPasteboard.general.string = report
                            authStatusMessage = "Migration diagnostics copied to clipboard."
                            #else
                            authStatusMessage = report
                            #endif
                        }
                        .foregroundStyle(GWTheme.gold)
                    } else {
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            handleAppleSignInCompletion(result)
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 44)
                        .disabled(isSigningIn)
                    }

                    Text("Guest-first mode remains fully available. Account controls are enabled as Sprint 2 scaffolding.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if !store.authLastStatusMessage.isEmpty {
                        Text(store.authLastStatusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if !authStatusMessage.isEmpty {
                        Text(authStatusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if !store.authMigrationEvents.isEmpty {
                        Text("Recent migration events")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ForEach(Array(store.authMigrationEvents.prefix(5).enumerated()), id: \.offset) { _, event in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.details)
                                    .font(.caption)
                                    .foregroundStyle(GWTheme.textPrimary)
                                Text("\(event.status.rawValue) • retries: \(event.retryCount) • \(shortEventTime(event.occurredAtISO))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
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

                    if store.morningPlanningReminderEnabled {
                        reminderWeekdayChips(
                            selected: Set(store.morningReminderWeekdays),
                            onToggle: { weekday in
                                var days = Set(store.morningReminderWeekdays)
                                if days.contains(weekday) { days.remove(weekday) } else { days.insert(weekday) }
                                store.setMorningReminderWeekdays(Array(days))
                            }
                        )
                    }

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

                    if store.eveningPlanningReminderEnabled {
                        reminderWeekdayChips(
                            selected: Set(store.eveningReminderWeekdays),
                            onToggle: { weekday in
                                var days = Set(store.eveningReminderWeekdays)
                                if days.contains(weekday) { days.remove(weekday) } else { days.insert(weekday) }
                                store.setEveningReminderWeekdays(Array(days))
                            }
                        )
                    }

                    Text("No reminder times are auto-defaulted. Configure your morning/evening flow reminders explicitly.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Toggle("Parking Lot recurring review", isOn: Binding(
                        get: { store.parkingLotReviewReminderEnabled },
                        set: { store.setParkingLotReviewReminderEnabled($0) }
                    ))

                    Picker("Review frequency", selection: Binding(
                        get: { store.parkingLotReviewReminderFrequency },
                        set: { store.setParkingLotReviewReminderFrequency($0) }
                    )) {
                        Text("Weekly (Sunday)").tag("weekly")
                        Text("Monthly (1st)").tag("monthly")
                        Text("Quarterly (1st of quarter)").tag("quarterly")
                    }
                    .disabled(!store.parkingLotReviewReminderEnabled)

                    Picker("Review reminder time", selection: Binding(
                        get: { store.parkingLotReviewReminderTime },
                        set: { store.setParkingLotReviewReminderTime($0) }
                    )) {
                        Text("No time set").tag("")
                        Text("8:00 AM").tag("8:00 AM")
                        Text("9:00 AM").tag("9:00 AM")
                        Text("10:00 AM").tag("10:00 AM")
                        Text("12:00 PM").tag("12:00 PM")
                        Text("5:00 PM").tag("5:00 PM")
                        Text("7:00 PM").tag("7:00 PM")
                    }
                    .disabled(!store.parkingLotReviewReminderEnabled)

                    Text("A repeating notification prompts you to review the Parking Lot and promote or delete items.")
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

                Section("Developer Testing") {
                    DatePicker(
                        "Active day",
                        selection: $devDateOverride,
                        displayedComponents: [.date]
                    )

                    Button("Jump to selected day") {
                        store.setActivePlanningDay(devDateOverride)
                    }
                    .foregroundStyle(GWTheme.gold)

                    Button("Reset to today") {
                        store.setActivePlanningDayToToday()
                        devDateOverride = Date()
                    }
                    .foregroundStyle(.secondary)

                    Text("Change the active planning day throughout the app to test Loop carryover, carried badges, and cross-day state without waiting for real dates.")
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
                    .safeAreaInset(edge: .top) {
                        if store.showFeedbackIdentifiers {
                            FeedbackIdentifierBadge(text: "GW-S04 · Diagnostics")
                                .padding(.top, 4)
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
                    .environmentObject(store)
            }
            .safeAreaInset(edge: .top) {
                if store.showFeedbackIdentifiers {
                    FeedbackIdentifierBadge(text: "GW-S01 · App Settings")
                        .padding(.top, 4)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(GWTheme.gold)
                }
            }
        }
    }

    private func shortUserId(_ userId: String) -> String {
        String(userId.prefix(10)) + "..."
    }

    private func shortEventTime(_ iso: String) -> String {
        String(iso.prefix(19)).replacingOccurrences(of: "T", with: " ")
    }

    private func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let error):
            authStatusMessage = "Apple Sign In failed: \(error.localizedDescription)"
            isSigningIn = false
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                authStatusMessage = "Apple Sign In did not return expected credentials."
                isSigningIn = false
                return
            }

            let identityToken = credential.identityToken.flatMap { String(data: $0, encoding: .utf8) }
            let authorizationCode = credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
            isSigningIn = true

            Task {
                let didSignIn = await store.completeAppleSignIn(
                    userId: credential.user,
                    identityToken: identityToken,
                    authorizationCode: authorizationCode
                )

                await MainActor.run {
                    authStatusMessage = didSignIn
                        ? store.authLastStatusMessage
                        : "Apple Sign In was canceled or incomplete."
                    isSigningIn = false
                }
            }
        }
    }

    @ViewBuilder
    private func reminderWeekdayChips(selected: Set<Int>, onToggle: @escaping (Int) -> Void) -> some View {
        let days: [(Int, String)] = [(2,"Mon"),(3,"Tue"),(4,"Wed"),(5,"Thu"),(6,"Fri"),(7,"Sat"),(1,"Sun")]
        VStack(alignment: .leading, spacing: 4) {
            Text("Days active (empty = all days)")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                ForEach(days, id: \.0) { weekday, label in
                    let isOn = selected.contains(weekday)
                    Button(label) { onToggle(weekday) }
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(isOn ? Color(hex: "1a1208") : .secondary)
                        .lineLimit(1)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 5)
                        .background(isOn ? GWTheme.gold : Color.secondary.opacity(0.15))
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
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
    @EnvironmentObject private var store: GenesisStore
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
            .safeAreaInset(edge: .top) {
                if store.showFeedbackIdentifiers {
                    FeedbackIdentifierBadge(text: "GW-S03 · Find Out More")
                        .padding(.top, 4)
                }
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
