import CryptoKit
import Foundation
import Security
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

extension Notification.Name {
    static let genesisOpenFillFromReminder = Notification.Name("genesisOpenFillFromReminder")
}

struct AuthSession: Codable {
    var userId: String
    var provider: AuthProvider
    var accessToken: String?
    var refreshToken: String?
}

final class GenesisStore: ObservableObject {
    @Published private(set) var state: GenesisState {
        didSet { persist() }
    }
    @Published private(set) var guidedSetupLaunchToken = UUID()
    @Published private(set) var authLastStatusMessage = ""
    @Published private(set) var googleCalendarStatusMessage = ""
    private var reminderTapObserver: NSObjectProtocol?
    private var pendingGoogleCalendarAuthorization: PendingGoogleCalendarAuthorization?

    private let storageKey = "genesis-way-ios-v1"
    private let authSessionService = "com.genesisway.app.auth"
    private let authSessionAccount = "session.v1"
    private let authClient: AuthClient = SupabaseAuthClient()
    private static let legacySeededTasks: Set<String> = [
        "Review product roadmap",
        "Design data sync contracts",
        "Evening walk"
    ]
    private static let legacySeededBig3: [String] = [
        "Finalize iOS architecture",
        "Port Dump and Fill screens",
        "Set calendar integration strategy"
    ]
    private static let developerTestDumpItems: [String] = [
        "Read scripture for 10 minutes before checking phone",
        "Write one gratitude prayer in journal",
        "Attend weekend service with full focus",
        "Plan one device-free family dinner",
        "Schedule one-on-one time with spouse",
        "Call a parent or sibling for 20 minutes",
        "Block 60 minutes for highest-impact work",
        "Draft and send weekly progress update",
        "Finish one important deliverable before noon",
        "Walk 20 minutes after lunch",
        "Prepare healthy lunch for tomorrow",
        "Set bedtime and lights-out boundary",
        "Read 15 pages of a growth book",
        "Journal for 10 minutes before bed",
        "Take a 15-minute no-screen reset break",
        "Reach out to a friend to check in",
        "Plan one shared meal with community",
        "Send one encouragement message",
        "Review weekly spending for 20 minutes",
        "Categorize recent transactions",
        "Set one savings transfer for this week"
    ]
    private static let developerLightweightDumpItems: [String] = [
        "Plan today\'s top work outcome",
        "Schedule one personal admin task",
        "Capture one follow-up email",
        "Set 20-minute focus sprint",
        "Choose one family connection touchpoint",
        "Prepare quick end-of-day shutdown note"
    ]

    enum AuthError: Error {
        case missingCredentials
        case missingConfiguration
        case unsupported
        case invalidURL
        case invalidResponse
        case serverError
    }

    protocol AuthClient {
        func signInWithApple(userId: String, identityToken: String, authorizationCode: String) async throws -> AuthSession
        func signOut(session: AuthSession?) async -> Bool
    }

    struct SupabaseAuthConfiguration {
        let projectURL: URL
        let anonKey: String

        static func fromBundle() -> SupabaseAuthConfiguration? {
            let env = ProcessInfo.processInfo.environment
            let plistURL = Bundle.main.object(forInfoDictionaryKey: "GW_SUPABASE_URL") as? String
            let plistKey = Bundle.main.object(forInfoDictionaryKey: "GW_SUPABASE_ANON_KEY") as? String
            let envURL = env["GW_SUPABASE_URL"]
            let envKey = env["GW_SUPABASE_ANON_KEY"]
            print("[GWConfig] Supabase plistURL=\(plistURL ?? "nil") envURL=\(envURL ?? "nil")")
            print("[GWConfig] Supabase plistKey=\(plistKey.map { $0.prefix(8) + "…" } ?? "nil") envKey=\(envKey.map { $0.prefix(8) + "…" } ?? "nil")")
            let hardcodedURL = "https://bolxsqpvabvpjbtbhmpf.supabase.co"
            let hardcodedKey = "sb_publishable_LbTmRHJIRpnaRXOHXC66ag_9VViLL32"
            let rawURL = plistURL ?? envURL ?? hardcodedURL
            let rawKey = plistKey ?? envKey ?? hardcodedKey
            print("[GWConfig] Supabase resolved rawURL=\(rawURL) rawKey=\(rawKey.prefix(8))…")

            let cleanedURL = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanedKey = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !cleanedURL.isEmpty,
                  !cleanedKey.isEmpty,
                  let projectURL = URL(string: cleanedURL) else {
                return nil
            }

            return SupabaseAuthConfiguration(projectURL: projectURL, anonKey: cleanedKey)
        }

        static func missingKeyDiagnostics() -> String? {
            let env = ProcessInfo.processInfo.environment
            let rawURL = ((Bundle.main.object(forInfoDictionaryKey: "GW_SUPABASE_URL") as? String)
                ?? env["GW_SUPABASE_URL"] ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let rawKey = ((Bundle.main.object(forInfoDictionaryKey: "GW_SUPABASE_ANON_KEY") as? String)
                ?? env["GW_SUPABASE_ANON_KEY"] ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            var missing: [String] = []
            if rawURL.isEmpty { missing.append("GW_SUPABASE_URL") }
            if rawKey.isEmpty { missing.append("GW_SUPABASE_ANON_KEY") }

            guard !missing.isEmpty else {
                return "Values are present but invalid. Verify GW_SUPABASE_URL is a valid https URL."
            }
            return "Missing runtime key(s): \(missing.joined(separator: ", "))."
        }
    }

    struct SupabaseAuthClient: AuthClient {
        private let configuration: SupabaseAuthConfiguration?
        private let session: URLSession

        init(configuration: SupabaseAuthConfiguration? = .fromBundle(), session: URLSession = .shared) {
            self.configuration = configuration
            self.session = session
        }

        func signInWithApple(userId: String, identityToken: String, authorizationCode: String) async throws -> AuthSession {
            guard !userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !identityToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw AuthError.missingCredentials
            }

            guard let configuration else {
                throw AuthError.missingConfiguration
            }

            guard var components = URLComponents(url: configuration.projectURL, resolvingAgainstBaseURL: false) else {
                throw AuthError.invalidURL
            }
            components.path = "/auth/v1/token"
            components.queryItems = [URLQueryItem(name: "grant_type", value: "id_token")]
            guard let endpoint = components.url else {
                throw AuthError.invalidURL
            }

            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue(configuration.anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(configuration.anonKey)", forHTTPHeaderField: "Authorization")

            let payload = SupabaseAppleSignInRequest(
                provider: "apple",
                idToken: identityToken,
                nonce: nil,
                code: authorizationCode
            )
            request.httpBody = try JSONEncoder().encode(payload)

            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            guard (200 ..< 300).contains(httpResponse.statusCode) else {
                throw AuthError.serverError
            }

            let decoded = try JSONDecoder().decode(SupabaseAppleSignInResponse.self, from: data)
            return AuthSession(
                userId: decoded.user.id,
                provider: .apple,
                accessToken: decoded.accessToken,
                refreshToken: decoded.refreshToken
            )
        }

        func signOut(session: AuthSession?) async -> Bool {
            guard let configuration,
                  let accessToken = session?.accessToken,
                  !accessToken.isEmpty,
                  var components = URLComponents(url: configuration.projectURL, resolvingAgainstBaseURL: false) else {
                return false
            }

            components.path = "/auth/v1/logout"
            guard let endpoint = components.url else { return false }

            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue(configuration.anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            do {
                let (_, response) = try await self.session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else { return false }
                return (200 ..< 300).contains(httpResponse.statusCode)
            } catch {
                return false
            }
        }
    }

    struct GoogleCalendarConfiguration {
        let clientId: String
        let callbackScheme: String
        let apiBaseURL: URL

        static func fromBundle() -> GoogleCalendarConfiguration? {
            let env = ProcessInfo.processInfo.environment
            let plistClientId = Bundle.main.object(forInfoDictionaryKey: "GW_GOOGLE_OAUTH_CLIENT_ID") as? String
            let plistBaseURL = Bundle.main.object(forInfoDictionaryKey: "GW_CALENDAR_API_BASE_URL") as? String
            let envClientId = env["GW_GOOGLE_OAUTH_CLIENT_ID"]
            let envBaseURL = env["GW_CALENDAR_API_BASE_URL"]
            print("[GWConfig] GoogleCal plistClientId=\(plistClientId.map { $0.prefix(12) + "…" } ?? "nil") envClientId=\(envClientId.map { $0.prefix(12) + "…" } ?? "nil")")
            print("[GWConfig] GoogleCal plistBaseURL=\(plistBaseURL ?? "nil") envBaseURL=\(envBaseURL ?? "nil")")
            let hardcodedClientId = "609243271731-nkcl43ltitd9itdeaduf24alr5timo8e.apps.googleusercontent.com"
            let hardcodedBaseURL = "https://genesis-way.vercel.app"
            let rawClientId = plistClientId ?? envClientId ?? hardcodedClientId
            let rawAPIBaseURL = plistBaseURL ?? envBaseURL ?? hardcodedBaseURL
            print("[GWConfig] GoogleCal resolved clientId=\(rawClientId.prefix(12))… baseURL=\(rawAPIBaseURL)")
            guard !rawClientId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !rawAPIBaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }

            let clientId = rawClientId.trimmingCharacters(in: .whitespacesAndNewlines)
            let callbackScheme = ((Bundle.main.object(forInfoDictionaryKey: "GW_GOOGLE_CALLBACK_SCHEME") as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? "genesisway"
            let apiBaseURLString = rawAPIBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !clientId.isEmpty,
                  !callbackScheme.isEmpty,
                  !apiBaseURLString.isEmpty,
                  let apiBaseURL = URL(string: apiBaseURLString) else {
                return nil
            }

            return GoogleCalendarConfiguration(
                clientId: clientId,
                callbackScheme: callbackScheme,
                apiBaseURL: apiBaseURL
            )
        }
    }

    struct GoogleCalendarAuthorizationRequest {
        let authorizationURL: URL
        let callbackScheme: String
    }

    private struct PendingGoogleCalendarAuthorization {
        let state: String
        let codeVerifier: String
        let redirectURI: String
    }

    private struct GoogleCalendarCallbackResponse: Codable {
        let accessToken: String
        let expiresIn: Int?
        let refreshToken: String?

        enum CodingKeys: String, CodingKey {
            case accessToken
            case expiresIn
            case refreshToken
        }
    }

    private struct GoogleCalendarRefreshResponse: Codable {
        let accessToken: String
        let expiresIn: Int?
        let refreshToken: String?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case expiresIn = "expires_in"
            case refreshToken = "refresh_token"
        }
    }

    private struct GoogleCalendarSyncPullRequest: Encodable {
        let accessToken: String
        let selectedCalendarIds: [String]
        let windowDays: Int
    }

    private struct GoogleCalendarSyncPullResponse: Decodable {
        struct EventPayload: Decodable {
            let provider: String
            let calendarId: String
            let providerEventId: String
            let title: String
            let startAtISO: String?
            let endAtISO: String?
            let allDay: Bool
        }

        let count: Int
        let events: [EventPayload]?

        enum CodingKeys: String, CodingKey {
            case count
            case events
        }
    }

    private struct GoogleCalendarListResponse: Codable {
        struct CalendarItem: Codable {
            let id: String
            let summary: String?
            let description: String?
            let accessRole: String?
            let primary: Bool?

            enum CodingKeys: String, CodingKey {
                case id
                case summary
                case description
                case accessRole
                case primary
            }
        }

        let items: [CalendarItem]?
    }

    struct LocalAuthClient: AuthClient {
        func signInWithApple(userId: String, identityToken: String, authorizationCode: String) async throws -> AuthSession {
            guard !userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw AuthError.missingCredentials
            }
            return AuthSession(userId: userId, provider: .apple)
        }

        func signOut(session: AuthSession?) async -> Bool { false }
    }

    private struct SupabaseAppleSignInRequest: Codable {
        let provider: String
        let idToken: String
        let nonce: String?
        let code: String?

        enum CodingKeys: String, CodingKey {
            case provider
            case idToken = "id_token"
            case nonce
            case code
        }
    }

    private struct SupabaseAppleSignInResponse: Codable {
        struct SupabaseUser: Codable {
            let id: String
        }

        let accessToken: String?
        let refreshToken: String?
        let user: SupabaseUser

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case user
        }
    }

    init() {
        if let saved = Self.load(storageKey: storageKey) {
            state = saved
            if state.showIntroOnLaunch {
                state.screen = .onboarding
            }
        } else {
            state = .initial
        }

        removeLegacySeededTasksIfPresent()
        removeLegacySeededBig3IfPresent()
        migrateLegacySpokesToArchiveIfPresent()
        normalizeDailyPileMetadata()
        runDailyRolloverIfNeeded()
        if state.loopRules == nil {
            state.loopRules = []
        }
        materializeRepeatingTasksIfNeeded()
        materializeLoopTasksIfNeeded()
        hydrateAuthSessionFromKeychainIfNeeded()
        autoRetryAuthMigrationIfNeeded()
        GWTheme.setThemeStyle(state.themeStyle ?? .brown)

        reminderTapObserver = NotificationCenter.default.addObserver(
            forName: .genesisOpenFillFromReminder,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.navigate(.fill)
        }

        persist()
    }

    deinit {
        if let reminderTapObserver {
            NotificationCenter.default.removeObserver(reminderTapObserver)
        }
    }

    var screen: AppScreen {
        get { state.screen }
        set { state.screen = newValue }
    }

    var dumpItems: [DumpItem] { state.dumpItems }
    var showIntroOnLaunch: Bool { state.showIntroOnLaunch }
    var showFeedbackIdentifiers: Bool { state.showFeedbackIdentifiers ?? true }
    var remindersEnabled: Bool { state.remindersEnabled }
    var reminderLeadMinutes: Int { state.reminderLeadMinutes }
    var big3: [Big3Item] { state.big3 }
    var activePlanningDay: Date {
        guard let iso = state.activePlanningDayISO,
              let date = Self.dateFromDayISO(iso) else {
            return Calendar.current.startOfDay(for: Date())
        }
        return date
    }
    var activePlanningDayISO: String {
        state.activePlanningDayISO ?? Self.todayDayISO()
    }
    var shapedDumpItems: [DumpItem] {
        pendingPileItems
    }
    var pendingPileItems: [DumpItem] {
        pendingPileItems(for: activePlanningDay)
    }
    var workTasks: [TaskItem] { state.tasks.filter { $0.lane == .work } }
    var personalTasks: [TaskItem] { state.tasks.filter { $0.lane == .personal } }
    var todayTaskPool: [TaskItem] {
        let today = Self.todayDayISO()
        return state.tasks.filter { task in
            (task.plannedDayISO == nil || task.plannedDayISO == today) && task.time == nil
        }
    }
    var todayAppointments: [ScheduledAppointment] {
        let today = Self.todayDayISO()
        return state.appointments
            .filter { Self.dayISO(fromISODateTime: $0.scheduledAtISO) == today }
            .sorted { $0.scheduledAtISO < $1.scheduledAtISO }
    }
    var parked: [ParkItem] { state.parked }
    var googleCalendarConnected: Bool { state.googleCalendarConnected }
    var googleCalendarConnectionStatus: CalendarConnectionStatus {
        state.googleCalendarConnectionStatus ?? (state.googleCalendarConnected ? .connected : .disconnected)
    }
    var googleCalendarAccountLabel: String? { state.googleCalendarAccountLabel }
    var googleCalendarAvailableCalendars: [CalendarSourceSummary] { state.googleCalendarAvailableCalendars ?? [] }
    var googleCalendarSelectedCalendarIDs: [String] { state.googleCalendarSelectedCalendarIDs ?? [] }
    var googleCalendarSelectedCalendars: [CalendarSourceSummary] {
        let selectedIDs = Set(googleCalendarSelectedCalendarIDs)
        return googleCalendarAvailableCalendars.filter { selectedIDs.contains($0.id) }
    }
    var googleCalendarLastError: String? { state.googleCalendarLastError }
    var isGoogleCalendarConfigured: Bool { GoogleCalendarConfiguration.fromBundle() != nil }
    var googleCalendarLastPulledEventCount: Int { state.googleCalendarLastPulledEventCount ?? 0 }
    var syncedCalendarEvents: [SyncedCalendarEvent] { state.syncedCalendarEvents ?? [] }
    var hasGoogleCalendarAccessToken: Bool {
        guard let token = state.googleCalendarAccessToken else { return false }
        return !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    var appleIcsEnabled: Bool { state.appleIcsEnabled }
    var lastCalendarSyncISO: String? { state.lastCalendarSyncISO }
    var delegatedFollowUps: [DelegateFollowUpItem] { state.delegatedFollowUps }
    var morningPlanningReminderEnabled: Bool { state.morningPlanningReminderEnabled ?? false }
    var morningPlanningReminderTime: String { state.morningPlanningReminderTime ?? "" }
    var eveningPlanningReminderEnabled: Bool { state.eveningPlanningReminderEnabled }
    var eveningPlanningReminderTime: String { state.eveningPlanningReminderTime }
    var hasConfiguredDailyFlowReminders: Bool { state.hasConfiguredDailyFlowReminders ?? false }
    var appThemeStyle: AppThemeStyle { state.themeStyle ?? .brown }
    var appIconStyle: AppIconStyle { state.appIconStyle ?? .chrome }
    var shouldShowGuidedSetup: Bool { !(state.hasCompletedGuidedSetup ?? false) }
    var repeatingTaskRules: [RepeatingTaskRule] { state.repeatingTaskRules }
    var loopRules: [LoopRule] { state.loopRules ?? [] }
    var weeklyTopGoals: [String] { state.weeklyTopGoals }
    var weeklyMacroDump: String { state.weeklyMacroDump }
    var plannerStartHour: Int { state.plannerStartHour ?? 8 }
    var plannerEndHour: Int { state.plannerEndHour ?? 18 }
    var parkingLotReviewReminderEnabled: Bool { state.parkingLotReviewReminderEnabled ?? false }
    var parkingLotReviewReminderFrequency: String { state.parkingLotReviewReminderFrequency ?? "weekly" }
    var parkingLotReviewReminderTime: String { state.parkingLotReviewReminderTime ?? "" }
    var lastParkingLotReviewISO: String? { state.lastParkingLotReviewISO }
    var isParkingLotReviewOverdue: Bool {
        guard parkingLotReviewReminderEnabled,
              let lastISO = state.lastParkingLotReviewISO,
              let last = ISO8601DateFormatter().date(from: lastISO) else {
            return parkingLotReviewReminderEnabled
        }
        let days: Int
        switch parkingLotReviewReminderFrequency {
        case "monthly": days = 30
        case "quarterly": days = 90
        default: days = 7
        }
        return Date().timeIntervalSince(last) > Double(days * 86400)
    }
    var hasUnreadyShapeItems: Bool {
        let selectedDayISO = activePlanningDayISO
        return state.dumpItems.contains { item in
            let outcome = item.filterOutcome ?? .pending
            let dayISO = item.planningDayISO ?? selectedDayISO
            return outcome == .pending && dayISO == selectedDayISO && item.lane == nil
        }
    }

    var authAccountState: AuthAccountState { state.authAccountState ?? .guest }
    var authProvider: AuthProvider { state.authProvider ?? .guest }
    var authUserId: String? { state.authUserId }
    var isSignedIn: Bool { authAccountState == .signedIn }
    var isSupabaseConfigured: Bool { SupabaseAuthConfiguration.fromBundle() != nil }
    var authMigrationStatus: AuthMigrationStatus { state.authMigrationStatus ?? .notStarted }
    var authMigrationEvents: [AuthMigrationEvent] {
        Array((state.authMigrationEvents ?? []).reversed())
    }
    var canRetryAuthMigration: Bool {
        isSignedIn && (state.authMigrationStatus ?? .notStarted) == .failed
    }

    func beginJourney() {
        state.showIntroOnLaunch = false
        state.screen = .dump
    }
    func skipToPlanner() {
        state.showIntroOnLaunch = false
        state.screen = .fill
    }

    func setActivePlanningDay(_ day: Date) {
        state.activePlanningDayISO = Self.dayISO(from: day)
    }

    func setActivePlanningDayToToday() {
        state.activePlanningDayISO = Self.todayDayISO()
    }

    func signInWithAppleScaffold() {
        // Sprint 2 scaffold: local signed-in state until full Apple Sign In flow lands.
        let userId = "apple-user-\(UUID().uuidString)"
        state.authAccountState = .signedIn
        state.authProvider = .apple
        state.authUserId = userId
        persistAuthSessionToKeychain(AuthSession(userId: userId, provider: .apple, accessToken: nil, refreshToken: nil))
    }

    func signOutAccount() {
        let existingSession = loadAuthSessionFromKeychain()
        let client = authClient
        state.authAccountState = .guest
        state.authProvider = .guest
        state.authUserId = nil
        clearAuthSessionFromKeychain()
        authLastStatusMessage = "Signed out locally."

        Task {
            let didRevokeRemote = await client.signOut(session: existingSession)
            await MainActor.run { [weak self] in
                guard let self else { return }
                if didRevokeRemote {
                    self.authLastStatusMessage = "Signed out locally and Supabase session cleared."
                } else if existingSession?.accessToken != nil {
                    self.authLastStatusMessage = "Signed out locally. Supabase logout could not be confirmed."
                }
            }
        }
    }

    func completeAppleSignIn(userId: String, identityToken: String?, authorizationCode: String?) async -> Bool {
        let trimmedUserId = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUserId.isEmpty else {
            authLastStatusMessage = "Apple Sign In missing user id."
            return false
        }

        let token = identityToken?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let code = authorizationCode?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !token.isEmpty && !code.isEmpty {
            do {
                let session = try await authClient.signInWithApple(userId: trimmedUserId, identityToken: token, authorizationCode: code)
                applySignedInSession(session)
                let didMigrate = runAuthMigrationIfNeeded(for: session.userId)
                authLastStatusMessage = didMigrate
                    ? "Signed in with Apple via Supabase. Migration linked local data to this account."
                    : "Signed in with Apple via Supabase. Migration check needs retry."
                return true
            } catch {
                // Keep Sprint 2 resilient even when backend config/provider is incomplete.
                authLastStatusMessage = "Supabase Apple exchange failed. Local fallback session used."
            }
        } else {
            authLastStatusMessage = "Apple token/code unavailable. Local fallback session used."
        }

        applySignedInSession(AuthSession(userId: trimmedUserId, provider: .apple, accessToken: nil, refreshToken: nil))
        _ = runAuthMigrationIfNeeded(for: trimmedUserId)
        return true
    }

    @discardableResult
    func retryAuthMigration() -> Bool {
        guard let userId = state.authUserId, !userId.isEmpty else { return false }
        let succeeded = runAuthMigrationIfNeeded(for: userId)
        authLastStatusMessage = succeeded
            ? "Migration retry succeeded."
            : "Migration retry failed."
        return succeeded
    }

    @discardableResult
    func runAuthMigrationRegressionProbe() -> Bool {
        guard let userId = state.authUserId, !userId.isEmpty else {
            authLastStatusMessage = "Migration regression probe skipped: no signed-in user."
            return false
        }

        let firstSucceeded = runAuthMigrationIfNeeded(for: userId)
        let snapshotAfterFirst = migrationCoreSnapshot()
        let secondSucceeded = runAuthMigrationIfNeeded(for: userId)
        let snapshotAfterSecond = migrationCoreSnapshot()

        let idempotentCore = snapshotAfterFirst == snapshotAfterSecond
        let expectedCore = snapshotAfterSecond.linkedUserId == userId &&
            snapshotAfterSecond.version == 1 &&
            snapshotAfterSecond.status == .succeeded &&
            snapshotAfterSecond.retryCount == 0

        let passed = firstSucceeded && secondSucceeded && idempotentCore && expectedCore
        authLastStatusMessage = passed
            ? "Migration regression probe passed."
            : "Migration regression probe failed."
        return passed
    }

    func authMigrationDiagnosticsReport() -> String {
        let status = (state.authMigrationStatus ?? .notStarted).rawValue
        let linked = state.authLinkedUserId ?? "none"
        let retries = state.authMigrationRetryCount ?? 0
        let relinks = state.authMigrationRelinkCount ?? 0
        let version = state.authMigrationVersion ?? 0
        let lastAttempt = state.authMigrationLastAttemptISO ?? "none"
        let lastError = state.authMigrationLastError ?? "none"
        let events = (state.authMigrationEvents ?? [])
            .suffix(10)
            .map { event in
                "- [\(event.occurredAtISO)] \(event.status.rawValue) retries=\(event.retryCount) user=\(event.userId ?? "none") :: \(event.details)"
            }
            .joined(separator: "\n")

        return """
        Auth migration diagnostics
        status: \(status)
        linked_user: \(linked)
        version: \(version)
        retries: \(retries)
        relinks: \(relinks)
        last_attempt: \(lastAttempt)
        last_error: \(lastError)
        recent_events:
        \(events.isEmpty ? "- none" : events)
        """
    }

    func setShowIntroOnLaunch(_ enabled: Bool) {
        state.showIntroOnLaunch = enabled
    }

    func setShowFeedbackIdentifiers(_ enabled: Bool) {
        state.showFeedbackIdentifiers = enabled
    }

    func setRemindersEnabled(_ enabled: Bool) {
        state.remindersEnabled = enabled
    }

    func setReminderLeadMinutes(_ minutes: Int) {
        state.reminderLeadMinutes = minutes
    }

    func setMorningPlanningReminderEnabled(_ enabled: Bool) {
        state.morningPlanningReminderEnabled = enabled
        if enabled == false {
            state.morningPlanningReminderTime = ""
        }
        state.hasConfiguredDailyFlowReminders = false
        Task { await scheduleDailyFlowRemindersIfNeeded() }
    }

    func setMorningPlanningReminderTime(_ time: String) {
        state.morningPlanningReminderTime = time
        state.hasConfiguredDailyFlowReminders = false
        Task { await scheduleDailyFlowRemindersIfNeeded() }
    }

    func setEveningPlanningReminderEnabled(_ enabled: Bool) {
        state.eveningPlanningReminderEnabled = enabled
        if enabled == false {
            state.eveningPlanningReminderTime = ""
        }
        state.hasConfiguredDailyFlowReminders = false
        Task { await scheduleDailyFlowRemindersIfNeeded() }
    }

    func setEveningPlanningReminderTime(_ time: String) {
        state.eveningPlanningReminderTime = time
        state.hasConfiguredDailyFlowReminders = false
        Task { await scheduleDailyFlowRemindersIfNeeded() }
    }

    func setParkingLotReviewReminderEnabled(_ enabled: Bool) {
        state.parkingLotReviewReminderEnabled = enabled
        Task { await scheduleParkingLotReviewReminderIfNeeded() }
    }

    func setParkingLotReviewReminderFrequency(_ frequency: String) {
        state.parkingLotReviewReminderFrequency = frequency
        Task { await scheduleParkingLotReviewReminderIfNeeded() }
    }

    func setParkingLotReviewReminderTime(_ time: String) {
        state.parkingLotReviewReminderTime = time
        Task { await scheduleParkingLotReviewReminderIfNeeded() }
    }

    func markParkingLotReviewed() {
        state.lastParkingLotReviewISO = ISO8601DateFormatter().string(from: Date())
    }

    private func scheduleParkingLotReviewReminderIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["gw.parkingLotReview"])

        guard state.parkingLotReviewReminderEnabled == true else { return }

        let frequency = state.parkingLotReviewReminderFrequency ?? "weekly"
        let timeStr = state.parkingLotReviewReminderTime ?? ""

        guard let fireDate = reminderDate(from: timeStr) else { return }

        var authorized = false
        do {
            authorized = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch { return }
        guard authorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Parking Lot Review"
        content.body = "Time to review your Parking Lot. Promote anything that's now due, delete what no longer matters."
        content.sound = .default

        var components = Calendar.current.dateComponents([.hour, .minute], from: fireDate)
        let trigger: UNCalendarNotificationTrigger

        switch frequency {
        case "monthly":
            components.day = 1
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        case "quarterly":
            // Use monthly trigger for first of each quarter month (Jan/Apr/Jul/Oct)
            // Simplest approach: schedule as monthly, app badge logic handles "overdue" UX
            components.day = 1
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        default: // weekly — fire on Sunday
            components.weekday = 1
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        }

        let request = UNNotificationRequest(identifier: "gw.parkingLotReview", content: content, trigger: trigger)
        try? await center.add(request)
    }

    @discardableResult
    func markDailyFlowRemindersConfigured() -> Bool {
        if !canMarkDailyFlowRemindersConfigured() {
            return false
        }
        state.hasConfiguredDailyFlowReminders = true
        Task { await scheduleDailyFlowRemindersIfNeeded() }
        return true
    }

    func canMarkDailyFlowRemindersConfigured() -> Bool {
        let morningEnabled = state.morningPlanningReminderEnabled ?? false
        let eveningEnabled = state.eveningPlanningReminderEnabled
        let morningHasTime = !(state.morningPlanningReminderTime ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let eveningHasTime = !state.eveningPlanningReminderTime.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if morningEnabled && !morningHasTime { return false }
        if eveningEnabled && !eveningHasTime { return false }
        return true
    }

    func setAppThemeStyle(_ style: AppThemeStyle) {
        state.themeStyle = style
        GWTheme.setThemeStyle(style)
    }

    func setAppIconStyle(_ style: AppIconStyle) {
        #if canImport(UIKit)
        guard UIApplication.shared.supportsAlternateIcons else {
            state.appIconStyle = style
            return
        }

        UIApplication.shared.setAlternateIconName(style.alternateIconName) { [weak self] error in
            guard error == nil else { return }
            DispatchQueue.main.async {
                self?.state.appIconStyle = style
            }
        }
        #else
        state.appIconStyle = style
        #endif
    }

    func completeGuidedSetup() {
        state.hasCompletedGuidedSetup = true
    }

    func resetGuidedSetup() {
        state.hasCompletedGuidedSetup = false
    }

    func launchGuidedSetup() {
        state.hasCompletedGuidedSetup = false
        state.screen = .dump
        guidedSetupLaunchToken = UUID()
    }

    func addRepeatingTaskRule(text: String, everyDays: Int, lane: TaskLane) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        state.repeatingTaskRules.append(
            RepeatingTaskRule(text: trimmed, everyDays: everyDays, lane: lane)
        )
        materializeRepeatingTasksIfNeeded()
    }

    func removeRepeatingTaskRule(_ id: UUID) {
        state.repeatingTaskRules.removeAll { $0.id == id }
    }

    func addLoopRule(
        text: String,
        lane: TaskLane?,
        recurrenceType: LoopRecurrenceType,
        weekdayNumbers: [Int],
        durationType: LoopDurationType,
        fixedCount: Int?
    ) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var normalizedWeekdays = weekdayNumbers
            .map { min(max($0, 1), 7) }
            .reduce(into: [Int]()) { partialResult, value in
                if !partialResult.contains(value) {
                    partialResult.append(value)
                }
            }

        if recurrenceType != .weekdays {
            normalizedWeekdays = []
        } else if normalizedWeekdays.isEmpty {
            let weekday = Calendar.current.component(.weekday, from: Date())
            normalizedWeekdays = [weekday]
        }

        let resolvedFixedCount = durationType == .fixedCount ? max(1, fixedCount ?? 1) : nil

        let rule = LoopRule(
            text: trimmed,
            lane: lane,
            recurrenceType: recurrenceType,
            weekdayNumbers: normalizedWeekdays,
            durationType: durationType,
            remainingOccurrences: resolvedFixedCount,
            anchorDayISO: Self.todayDayISO()
        )

        var rules = state.loopRules ?? []
        rules.append(rule)
        state.loopRules = rules
        materializeLoopTasksIfNeeded()
    }

    func removeLoopRule(_ id: UUID) {
        guard var rules = state.loopRules else { return }
        rules.removeAll { $0.id == id }
        state.loopRules = rules
    }

    func setWeeklyTopGoal(index: Int, text: String) {
        guard state.weeklyTopGoals.indices.contains(index) else { return }
        state.weeklyTopGoals[index] = text
    }

    func setWeeklyMacroDump(_ text: String) {
        state.weeklyMacroDump = text
    }

    func setPlannerStartHour(_ hour: Int) {
        let clamped = min(max(hour, 5), 21)
        state.plannerStartHour = clamped
        if plannerEndHour <= clamped {
            state.plannerEndHour = min(clamped + 1, 22)
        }
    }

    func setPlannerEndHour(_ hour: Int) {
        let minimumEnd = max(plannerStartHour + 1, 6)
        let clamped = min(max(hour, minimumEnd), 22)
        state.plannerEndHour = clamped
    }

    func addDumpItem(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        state.dumpItems.append(
            DumpItem(
                text: trimmed,
                filterOutcome: .pending,
                planningDayISO: Self.todayDayISO(),
                carriedOver: false
            )
        )
    }

    func addDumpItem(_ text: String, for day: Date) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        state.dumpItems.append(
            DumpItem(
                text: trimmed,
                filterOutcome: .pending,
                planningDayISO: Self.dayISO(from: day),
                carriedOver: false
            )
        )
    }

    func dumpItems(for day: Date) -> [DumpItem] {
        let dayISO = Self.dayISO(from: day)
        return state.dumpItems.filter { item in
            (item.planningDayISO ?? dayISO) == dayISO
        }
    }

    func removeDumpItem(id: UUID) {
        state.dumpItems.removeAll { $0.id == id }
    }

    func updateDumpItemText(id: UUID, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let idx = state.dumpItems.firstIndex(where: { $0.id == id }) else { return }
        state.dumpItems[idx].text = trimmed
    }

    func assignDumpItem(_ id: UUID, to spoke: Spoke?) {
        guard let idx = state.dumpItems.firstIndex(where: { $0.id == id }) else { return }
        state.dumpItems[idx].spoke = spoke
    }

    func pendingPileItems(for day: Date) -> [DumpItem] {
        let dayISO = Self.dayISO(from: day)
        return state.dumpItems.filter {
            ($0.filterOutcome ?? .pending) == .pending &&
                (($0.planningDayISO ?? dayISO) == dayISO)
        }
    }

    func assignDumpItemLane(_ id: UUID, lane: TaskLane) {
        guard let idx = state.dumpItems.firstIndex(where: { $0.id == id }) else { return }
        state.dumpItems[idx].lane = lane
    }

    func clearDumpItemLane(_ id: UUID) {
        guard let idx = state.dumpItems.firstIndex(where: { $0.id == id }) else { return }
        state.dumpItems[idx].lane = nil
    }

    func setAutomationNote(_ id: UUID, note: String) {
        guard let idx = state.dumpItems.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        state.dumpItems[idx].automationNote = trimmed.isEmpty ? nil : trimmed
        persist()
    }

    func count(for spoke: Spoke) -> Int {
        state.dumpItems.filter { $0.spoke == spoke }.count
    }

    func rhythmAnchor(for spoke: Spoke) -> String {
        state.rhythmAnchors[spoke.rawValue] ?? ""
    }

    func setRhythmAnchor(for spoke: Spoke, value: String) {
        state.rhythmAnchors[spoke.rawValue] = value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func toggleBig3(id: UUID) {
        guard let idx = state.big3.firstIndex(where: { $0.id == id }) else { return }
        state.big3[idx].done.toggle()
    }

    func setBig3Text(id: UUID, text: String) {
        guard let idx = state.big3.firstIndex(where: { $0.id == id }) else { return }
        state.big3[idx].text = text
    }

    func setBig3FromTask(id: UUID, taskId: UUID) {
        guard let big3Index = state.big3.firstIndex(where: { $0.id == id }) else { return }
        guard let task = state.tasks.first(where: { $0.id == taskId }) else { return }
        state.big3[big3Index].text = task.text
        state.big3[big3Index].done = false
    }

    func isDumpItemPromotedToTasks(_ dumpItemId: UUID) -> Bool {
        state.tasks.contains { $0.sourceDumpItemId == dumpItemId }
    }

    func applyFilterOutcome(_ dumpItemId: UUID, outcome: PileFilterOutcome) {
        guard let idx = state.dumpItems.firstIndex(where: { $0.id == dumpItemId }) else { return }
        state.dumpItems[idx].filterOutcome = outcome

        if outcome == .parked {
            addParkItem(state.dumpItems[idx].text)
        }
    }

    func scheduleDumpItem(_ dumpItemId: UUID, lane: TaskLane) {
        assignDumpItemLane(dumpItemId, lane: lane)
        setDumpItemPlanningDay(dumpItemId, dayISO: Self.todayDayISO())
    }

    func scheduleDumpItem(_ dumpItemId: UUID, on date: Date, lane: TaskLane) {
        assignDumpItemLane(dumpItemId, lane: lane)
        setDumpItemPlanningDay(dumpItemId, dayISO: Self.dayISO(from: date))
    }

    func scheduleDumpItemAsAppointment(_ dumpItemId: UUID, at dateTime: Date, lane: TaskLane) {
        guard let item = state.dumpItems.first(where: { $0.id == dumpItemId }) else { return }

        let prefix = lane == .work ? "W" : "P"
        let next = nextCodeNumber(for: lane)
        let iso = Self.isoDateTime(from: dateTime)

        state.appointments.append(
            ScheduledAppointment(
                text: item.text,
                code: "\(prefix)\(next)",
                lane: lane,
                sourceDumpItemId: dumpItemId,
                scheduledAtISO: iso
            )
        )

        if let idx = state.dumpItems.firstIndex(where: { $0.id == dumpItemId }) {
            state.dumpItems[idx].lane = lane
            state.dumpItems[idx].filterOutcome = .scheduled
            state.dumpItems[idx].planningDayISO = Self.dayISO(from: dateTime)
        }
    }

    func moveDumpItemToNextDay(_ dumpItemId: UUID) {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        moveDumpItemToDay(dumpItemId, day: tomorrow)
    }

    func moveDumpItemToDay(_ dumpItemId: UUID, day: Date) {
        setDumpItemPlanningDay(dumpItemId, dayISO: Self.dayISO(from: day))
        if let idx = state.dumpItems.firstIndex(where: { $0.id == dumpItemId }) {
            state.dumpItems[idx].filterOutcome = .pending
        }
    }

    func isLikelyOversizedDumpItem(_ dumpItemId: UUID) -> Bool {
        guard let item = state.dumpItems.first(where: { $0.id == dumpItemId }) else { return false }
        return Self.isLikelyOversizedText(item.text)
    }

    func createJamSessionForDumpItem(_ dumpItemId: UUID) {
        guard let idx = state.dumpItems.firstIndex(where: { $0.id == dumpItemId }) else { return }

        let original = state.dumpItems[idx]
        let lane = original.lane ?? .work
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

        let jamText = "Jam Session: break into 15-30 min slices - \(original.text)"
        let jam = DumpItem(
            text: jamText,
            lane: lane,
            filterOutcome: .pending,
            planningDayISO: Self.dayISO(from: tomorrow),
            carriedOver: true
        )

        state.dumpItems.append(jam)
        state.dumpItems[idx].filterOutcome = .movedForward
    }

    func promoteShapedDumpItemToTask(_ dumpItemId: UUID, lane: TaskLane) {
        promoteDumpItemToTask(dumpItemId, lane: lane)
    }

    func promoteDumpItemToTask(_ dumpItemId: UUID, lane: TaskLane? = nil) {
        guard let item = state.dumpItems.first(where: { $0.id == dumpItemId }) else { return }
        guard !isDumpItemPromotedToTasks(dumpItemId) else { return }

        let resolvedLane = lane ?? item.lane ?? .work
        let prefix = resolvedLane == .work ? "W" : "P"
        let next = nextTaskNumber(for: resolvedLane)
        state.tasks.append(TaskItem(text: item.text, code: "\(prefix)\(next)", lane: resolvedLane, sourceDumpItemId: dumpItemId))

        if let idx = state.dumpItems.firstIndex(where: { $0.id == dumpItemId }) {
            state.dumpItems[idx].lane = resolvedLane
            state.dumpItems[idx].filterOutcome = .scheduled
        }
    }

    func moveTask(_ taskId: UUID, direction: Int) {
        guard let taskIndex = state.tasks.firstIndex(where: { $0.id == taskId }) else { return }
        let lane = state.tasks[taskIndex].lane
        let laneIndices = state.tasks.indices.filter { state.tasks[$0].lane == lane }
        guard let lanePosition = laneIndices.firstIndex(of: taskIndex) else { return }

        let targetPosition = lanePosition + direction
        guard targetPosition >= 0 && targetPosition < laneIndices.count else { return }

        let sourceIndex = laneIndices[lanePosition]
        let destinationIndex = laneIndices[targetPosition]
        state.tasks.swapAt(sourceIndex, destinationIndex)
    }

    func moveTaskToLane(_ taskId: UUID, lane: TaskLane) {
        guard let idx = state.tasks.firstIndex(where: { $0.id == taskId }) else { return }
        guard state.tasks[idx].lane != lane else { return }

        state.tasks[idx].lane = lane
        let prefix = lane == .work ? "W" : "P"
        let next = nextTaskNumber(for: lane)
        state.tasks[idx].code = "\(prefix)\(next)"
    }

    func scheduleTaskOnTimeline(_ taskId: UUID, day: Date, time: String) {
        guard let idx = state.tasks.firstIndex(where: { $0.id == taskId }) else { return }
        state.tasks[idx].plannedDayISO = Self.dayISO(from: day)
        state.tasks[idx].time = time
        state.tasks[idx].completed = false
    }

    func scheduleDumpItemOnTimeline(_ dumpItemId: UUID, day: Date, time: String) {
        if !isDumpItemPromotedToTasks(dumpItemId) {
            promoteDumpItemToTask(dumpItemId)
        }

        guard let idx = state.tasks.firstIndex(where: { $0.sourceDumpItemId == dumpItemId }) else { return }
        state.tasks[idx].plannedDayISO = Self.dayISO(from: day)
        state.tasks[idx].time = time
        state.tasks[idx].completed = false
    }

    func moveTaskToDay(_ taskId: UUID, day: Date) {
        guard let idx = state.tasks.firstIndex(where: { $0.id == taskId }) else { return }
        state.tasks[idx].plannedDayISO = Self.dayISO(from: day)
        state.tasks[idx].time = nil
    }

    func unscheduleTask(_ taskId: UUID) {
        guard let idx = state.tasks.firstIndex(where: { $0.id == taskId }) else { return }
        state.tasks[idx].time = nil
    }

    func moveScheduledTaskWithinSlot(_ taskId: UUID, day: Date, time: String, direction: Int) {
        let dayISO = Self.dayISO(from: day)
        let slotIndices = state.tasks.indices.filter {
            state.tasks[$0].plannedDayISO == dayISO && state.tasks[$0].time == time
        }

        guard let currentPosition = slotIndices.firstIndex(where: { state.tasks[$0].id == taskId }) else { return }
        let targetPosition = currentPosition + direction
        guard targetPosition >= 0 && targetPosition < slotIndices.count else { return }

        state.tasks.swapAt(slotIndices[currentPosition], slotIndices[targetPosition])
    }

    func toggleTaskCompleted(_ taskId: UUID) {
        guard let idx = state.tasks.firstIndex(where: { $0.id == taskId }) else { return }
        state.tasks[idx].completed.toggle()
    }

    func addDelegateFollowUp(taskText: String, assignee: String, followUpDate: Date) {
        let trimmedTask = taskText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAssignee = assignee.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTask.isEmpty, !trimmedAssignee.isEmpty else { return }

        state.delegatedFollowUps.append(
            DelegateFollowUpItem(
                taskText: trimmedTask,
                assignee: trimmedAssignee,
                followUpISODate: Self.dayISO(from: followUpDate)
            )
        )
    }

    func toggleDelegateFollowUpCompleted(_ id: UUID) {
        guard let idx = state.delegatedFollowUps.firstIndex(where: { $0.id == id }) else { return }
        state.delegatedFollowUps[idx].completed.toggle()
    }

    func scheduleDelegateReminder(taskText: String, assignee: String, on date: Date) async -> Bool {
        let center = UNUserNotificationCenter.current()

        let authorized: Bool
        do {
            authorized = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
        guard authorized else { return false }

        let content = UNMutableNotificationContent()
        content.title = "Delegate follow-up"
        content.body = "Check in with \(assignee): \(taskText)"
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = "genesis.delegate.followup.\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
            return true
        } catch {
            return false
        }
    }

    func diagnosticsSummary() -> [(String, String)] {
        let pendingCount = state.dumpItems.filter { ($0.filterOutcome ?? .pending) == .pending }.count
        let scheduledCount = state.dumpItems.filter { ($0.filterOutcome ?? .pending) == .scheduled }.count
        let movedCount = state.dumpItems.filter { ($0.filterOutcome ?? .pending) == .movedForward }.count
        let delegatedCount = state.dumpItems.filter { ($0.filterOutcome ?? .pending) == .delegated }.count
        let parkedCount = state.dumpItems.filter { ($0.filterOutcome ?? .pending) == .parked }.count
        let eliminatedCount = state.dumpItems.filter { ($0.filterOutcome ?? .pending) == .eliminated }.count

        let migrationCheck = migrationSelfCheckPassed() ? "pass" : "check"

        return [
            ("Pending dump", "\(pendingCount)"),
            ("Scheduled", "\(scheduledCount)"),
            ("Moved forward", "\(movedCount)"),
            ("Delegated", "\(delegatedCount)"),
            ("Parked", "\(parkedCount)"),
            ("Eliminated", "\(eliminatedCount)"),
            ("Tasks", "\(state.tasks.count)"),
            ("Appointments", "\(state.appointments.count)"),
            ("Delegate follow-ups", "\(state.delegatedFollowUps.count)"),
            ("Auth linked user", state.authLinkedUserId ?? "none"),
            ("Auth migration", (state.authMigrationStatus ?? .notStarted).rawValue),
            ("Auth migration retries", "\(state.authMigrationRetryCount ?? 0)"),
            ("Auth migration relinks", "\(state.authMigrationRelinkCount ?? 0)"),
            ("Auth migration last error", state.authMigrationLastError ?? "none"),
            ("Auth migration last event", state.authMigrationEvents?.last?.details ?? "none"),
            ("Auth migration regression", authMigrationRegressionSelfCheckPassed() ? "pass" : "check"),
            ("Migration self-check", migrationCheck),
            ("Last rollover", state.lastRolloverDayISO ?? "never")
        ]
    }

    func taskPool(for day: Date) -> [TaskItem] {
        let dayISO = Self.dayISO(from: day)
        return state.tasks.filter { task in
            (task.plannedDayISO == nil || task.plannedDayISO == dayISO) && task.time == nil
        }
    }

    func appointments(for day: Date) -> [ScheduledAppointment] {
        let dayISO = Self.dayISO(from: day)
        return state.appointments
            .filter { Self.dayISO(fromISODateTime: $0.scheduledAtISO) == dayISO }
            .sorted { $0.scheduledAtISO < $1.scheduledAtISO }
    }

    func scheduledTasks(for day: Date) -> [TaskItem] {
        let dayISO = Self.dayISO(from: day)
        return state.tasks.filter { task in
            task.plannedDayISO == dayISO && task.time != nil
        }
    }

    func tasksScheduled(for day: Date, at time: String) -> [TaskItem] {
        let dayISO = Self.dayISO(from: day)
        return state.tasks.filter { task in
            task.plannedDayISO == dayISO && task.time == time
        }
    }

    func addParkItem(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        state.parked.append(ParkItem(text: trimmed))
    }

    func removeParkItem(id: UUID) {
        state.parked.removeAll { $0.id == id }
    }

    func navigate(_ screen: AppScreen) {
        if screen == .fill, hasUnreadyShapeItems {
            state.screen = .shape
            return
        }
        state.screen = screen
    }

    func setGoogleCalendarConnected(_ connected: Bool) {
        state.googleCalendarConnected = connected
        state.googleCalendarConnectionStatus = connected ? .connected : .disconnected
        if !connected {
            state.googleCalendarAccountLabel = nil
            state.googleCalendarAvailableCalendars = []
            state.googleCalendarSelectedCalendarIDs = []
            state.googleCalendarLastError = nil
        }
    }

    func prepareGoogleCalendarConnection() {
        state.googleCalendarLastError = nil
        googleCalendarStatusMessage = ""

        guard isSignedIn else {
            state.googleCalendarConnectionStatus = .needsAttention
            state.googleCalendarLastError = "Sign in before connecting Google Calendar."
            return
        }

        guard isSupabaseConfigured else {
            state.googleCalendarConnectionStatus = .needsAttention
            state.googleCalendarLastError = "Supabase configuration is missing. Calendar connect depends on the signed-in account backend."
            return
        }

        guard GoogleCalendarConfiguration.fromBundle() != nil else {
            state.googleCalendarConnectionStatus = .needsAttention
            let env = ProcessInfo.processInfo.environment
            let clientIdBundle = (Bundle.main.object(forInfoDictionaryKey: "GW_GOOGLE_OAUTH_CLIENT_ID") as? String) ?? ""
            let clientIdEnv = env["GW_GOOGLE_OAUTH_CLIENT_ID"] ?? ""
            let baseURLBundle = (Bundle.main.object(forInfoDictionaryKey: "GW_CALENDAR_API_BASE_URL") as? String) ?? ""
            let baseURLEnv = env["GW_CALENDAR_API_BASE_URL"] ?? ""
            let clientIdSrc = !clientIdBundle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "plist:\(clientIdBundle.prefix(12))…" : (!clientIdEnv.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "env:\(clientIdEnv.prefix(12))…" : "MISSING")
            let baseURLSrc = !baseURLBundle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "plist:✓" : (!baseURLEnv.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "env:✓" : "MISSING")
            state.googleCalendarLastError = "Calendar config not ready. CLIENT_ID=\(clientIdSrc) BASE_URL=\(baseURLSrc). Set GW_GOOGLE_OAUTH_CLIENT_ID and GW_CALENDAR_API_BASE_URL in scheme env vars."
            return
        }

        state.googleCalendarConnectionStatus = .readyToConnect
        googleCalendarStatusMessage = "Google Calendar is ready to connect."
    }

    func makeGoogleCalendarAuthorizationRequest() -> GoogleCalendarAuthorizationRequest? {
        prepareGoogleCalendarConnection()

        guard state.googleCalendarConnectionStatus == .readyToConnect,
              let configuration = GoogleCalendarConfiguration.fromBundle() else {
            return nil
        }

        let stateValue = Self.randomOAuthToken(length: 32)
        let codeVerifier = Self.randomOAuthToken(length: 64)
        let redirectURI = configuration.apiBaseURL.appendingPathComponent("api/calendar/oauth/callback").absoluteString
        let codeChallenge = Self.pkceCodeChallenge(for: codeVerifier)

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: configuration.clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "https://www.googleapis.com/auth/calendar.readonly"),
            URLQueryItem(name: "include_granted_scopes", value: "true"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent"),
            URLQueryItem(name: "state", value: stateValue),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        guard let authorizationURL = components?.url else {
            state.googleCalendarConnectionStatus = .needsAttention
            state.googleCalendarLastError = "Unable to build Google authorization URL."
            return nil
        }

        pendingGoogleCalendarAuthorization = PendingGoogleCalendarAuthorization(
            state: stateValue,
            codeVerifier: codeVerifier,
            redirectURI: redirectURI
        )
        googleCalendarStatusMessage = "Opening Google sign-in."

        return GoogleCalendarAuthorizationRequest(
            authorizationURL: authorizationURL,
            callbackScheme: configuration.callbackScheme
        )
    }

    @discardableResult
    func finishGoogleCalendarAuthorization(callbackURL: URL) async -> Bool {
        guard let pendingAuthorization = pendingGoogleCalendarAuthorization else {
            state.googleCalendarConnectionStatus = .needsAttention
            state.googleCalendarLastError = "Google authorization session was lost. Start the connect flow again."
            return false
        }

        defer { pendingGoogleCalendarAuthorization = nil }

        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
            state.googleCalendarConnectionStatus = .needsAttention
            state.googleCalendarLastError = "Google callback URL was invalid."
            return false
        }

        let queryItems = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        if let errorDescription = queryItems["error_description"], !errorDescription.isEmpty {
            state.googleCalendarConnectionStatus = .needsAttention
            state.googleCalendarLastError = errorDescription
            return false
        }

        if let error = queryItems["error"], !error.isEmpty {
            state.googleCalendarConnectionStatus = .needsAttention
            state.googleCalendarLastError = error
            return false
        }

        guard queryItems["state"] == pendingAuthorization.state else {
            state.googleCalendarConnectionStatus = .needsAttention
            state.googleCalendarLastError = "Google OAuth state validation failed."
            return false
        }

        guard let code = queryItems["code"], !code.isEmpty else {
            state.googleCalendarConnectionStatus = .needsAttention
                let diagnostics = SupabaseAuthConfiguration.missingKeyDiagnostics() ?? ""
                state.googleCalendarLastError = "Supabase configuration is missing. Calendar connect depends on the signed-in account backend. \(diagnostics)"
            return false
        }

        do {
            let tokenPayload = try await exchangeGoogleAuthorizationCode(
                code: code,
                codeVerifier: pendingAuthorization.codeVerifier,
                redirectURI: pendingAuthorization.redirectURI
            )
            let accessToken = tokenPayload.accessToken
            let calendars = try await fetchGoogleCalendars(accessToken: accessToken)
            await MainActor.run {
                setGoogleCalendarAvailableCalendars(calendars)
                applyGoogleCalendarTokens(
                    accessToken: accessToken,
                    refreshToken: tokenPayload.refreshToken,
                    expiresIn: tokenPayload.expiresIn
                )
                if googleCalendarSelectedCalendarIDs.isEmpty {
                    let preferredCalendarID = calendars.first(where: { $0.detail?.contains("Primary") == true })?.id ?? calendars.first?.id
                    if let preferredCalendarID {
                        replaceGoogleCalendarSelections(ids: [preferredCalendarID])
                    }
                }
                connectGoogleCalendarScaffold(accountLabel: calendars.first(where: { $0.detail?.contains("Primary") == true })?.title)
                googleCalendarStatusMessage = "Google Calendar connected. Select which calendars to pull into Fill."
            }
            return true
        } catch {
            await MainActor.run {
                state.googleCalendarConnectionStatus = .needsAttention
                state.googleCalendarLastError = error.localizedDescription
            }
            return false
        }
    }

    func cancelGoogleCalendarAuthorization() {
        pendingGoogleCalendarAuthorization = nil
        if !googleCalendarConnected {
            state.googleCalendarConnectionStatus = .disconnected
        }
        googleCalendarStatusMessage = "Google Calendar connect was canceled."
    }

    func connectGoogleCalendarScaffold(accountLabel: String? = nil) {
        state.googleCalendarConnected = true
        state.googleCalendarConnectionStatus = .connected
        state.googleCalendarAccountLabel = accountLabel ?? authUserId ?? "Connected account"
        state.googleCalendarAvailableCalendars = state.googleCalendarAvailableCalendars ?? []
        state.googleCalendarSelectedCalendarIDs = state.googleCalendarSelectedCalendarIDs ?? []
        state.googleCalendarLastError = nil
        state.googleCalendarLastPulledEventCount = state.googleCalendarLastPulledEventCount ?? 0
    }

    func disconnectGoogleCalendar() {
        state.googleCalendarConnected = false
        state.googleCalendarConnectionStatus = .disconnected
        state.googleCalendarAccountLabel = nil
        state.googleCalendarAvailableCalendars = []
        state.googleCalendarSelectedCalendarIDs = []
        state.googleCalendarLastError = nil
        state.googleCalendarAccessToken = nil
        state.googleCalendarRefreshToken = nil
        state.googleCalendarAccessTokenExpiresAtISO = nil
        state.googleCalendarLastPulledEventCount = 0
        state.syncedCalendarEvents = []
        googleCalendarStatusMessage = "Google Calendar disconnected."
    }

    @discardableResult
    func syncGoogleCalendarNow() async -> Int {
        state.googleCalendarLastError = nil

        guard googleCalendarConnected else {
            state.googleCalendarLastError = "Connect Google Calendar before syncing."
            return 0
        }

        guard let configuration = GoogleCalendarConfiguration.fromBundle() else {
            state.googleCalendarLastError = "Calendar API base URL is not configured."
            return 0
        }

        let accessToken: String
        do {
            accessToken = try await validGoogleCalendarAccessToken(configuration: configuration)
        } catch {
            state.googleCalendarLastError = error.localizedDescription
            return 0
        }

        let selectedCalendarIDs = googleCalendarSelectedCalendarIDs
        let calendarIDs = selectedCalendarIDs.isEmpty ? ["primary"] : selectedCalendarIDs

        do {
            let response: GoogleCalendarSyncPullResponse
            do {
                response = try await performGoogleCalendarPull(
                    endpointBaseURL: configuration.apiBaseURL,
                    accessToken: accessToken,
                    selectedCalendarIDs: calendarIDs
                )
            } catch {
                if let nsError = error as NSError?, nsError.code == 401 {
                    let refreshedToken = try await validGoogleCalendarAccessToken(configuration: configuration, forceRefresh: true)
                    response = try await performGoogleCalendarPull(
                        endpointBaseURL: configuration.apiBaseURL,
                        accessToken: refreshedToken,
                        selectedCalendarIDs: calendarIDs
                    )
                } else {
                    throw error
                }
            }
            let syncedEvents = (response.events ?? []).map { payload in
                SyncedCalendarEvent(
                    id: "\(payload.provider):\(payload.calendarId):\(payload.providerEventId)",
                    provider: payload.provider,
                    calendarId: payload.calendarId,
                    providerEventId: payload.providerEventId,
                    title: payload.title,
                    startAtISO: payload.startAtISO,
                    endAtISO: payload.endAtISO,
                    allDay: payload.allDay
                )
            }
            let count = response.count
            await MainActor.run {
                state.syncedCalendarEvents = syncedEvents
                state.googleCalendarLastPulledEventCount = count
                markCalendarSyncedNow()
                googleCalendarStatusMessage = "Sync complete: \(count) events in window."
            }
            return count
        } catch {
            let message = error.localizedDescription
            await MainActor.run {
                state.googleCalendarLastError = message
                googleCalendarStatusMessage = "Calendar sync failed."
            }
            return 0
        }
    }

    func setGoogleCalendarAvailableCalendars(_ calendars: [CalendarSourceSummary]) {
        state.googleCalendarAvailableCalendars = calendars
        let availableIDs = Set(calendars.map(\.id))
        let filteredSelectedIDs = googleCalendarSelectedCalendarIDs.filter { availableIDs.contains($0) }
        state.googleCalendarSelectedCalendarIDs = filteredSelectedIDs
    }

    func toggleGoogleCalendarSelection(id: String) {
        var selectedIDs = googleCalendarSelectedCalendarIDs
        if let existingIndex = selectedIDs.firstIndex(of: id) {
            selectedIDs.remove(at: existingIndex)
        } else {
            selectedIDs.append(id)
        }
        state.googleCalendarSelectedCalendarIDs = selectedIDs
    }

    func replaceGoogleCalendarSelections(ids: [String]) {
        let allowedIDs = Set(googleCalendarAvailableCalendars.map(\.id))
        state.googleCalendarSelectedCalendarIDs = ids.filter { allowedIDs.contains($0) }
    }

    func setGoogleCalendarError(_ message: String?) {
        state.googleCalendarLastError = message?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func setAppleIcsEnabled(_ enabled: Bool) {
        state.appleIcsEnabled = enabled
    }

    func markCalendarSyncedNow() {
        state.lastCalendarSyncISO = ISO8601DateFormatter().string(from: Date())
    }

    func resetAllUserData() {
        state = .initial
        clearAuthSessionFromKeychain()
        UserDefaults.standard.removeObject(forKey: storageKey)
        persist()
    }

    func importDeveloperTestDumpData() -> Int {
        var existing = Set(state.dumpItems.map { Self.normalizedDumpText($0.text) })
        var added = 0

        for text in Self.developerTestDumpItems {
            let normalized = Self.normalizedDumpText(text)
            guard !existing.contains(normalized) else { continue }

            state.dumpItems.append(
                DumpItem(
                    text: text,
                    filterOutcome: .pending,
                    planningDayISO: Self.todayDayISO(),
                    carriedOver: false
                )
            )
            existing.insert(normalized)
            added += 1
        }

        return added
    }

    func importDeveloperLightweightTestDumpData() -> Int {
        var existing = Set(state.dumpItems.map { Self.normalizedDumpText($0.text) })
        var added = 0

        for text in Self.developerLightweightDumpItems {
            let normalized = Self.normalizedDumpText(text)
            guard !existing.contains(normalized) else { continue }

            state.dumpItems.append(
                DumpItem(
                    text: text,
                    filterOutcome: .pending,
                    planningDayISO: Self.todayDayISO(),
                    carriedOver: false
                )
            )
            existing.insert(normalized)
            added += 1
        }

        return added
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func removeLegacySeededTasksIfPresent() {
        state.tasks.removeAll { task in
            task.sourceDumpItemId == nil && Self.legacySeededTasks.contains(task.text)
        }
    }

    private func removeLegacySeededBig3IfPresent() {
        guard state.big3.count == 3 else { return }

        let current = state.big3.map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard current == Self.legacySeededBig3 else { return }

        state.big3 = [Big3Item(text: ""), Big3Item(text: ""), Big3Item(text: "")]
    }

    private func migrateLegacySpokesToArchiveIfPresent() {
        if state.archivedSpokeAssignments == nil {
            let assignments = Dictionary(uniqueKeysWithValues: state.dumpItems.compactMap { item -> (String, String)? in
                guard let spoke = item.spoke else { return nil }
                return (item.id.uuidString, spoke.rawValue)
            })

            if !assignments.isEmpty {
                state.archivedSpokeAssignments = assignments
            }
        }

        for idx in state.dumpItems.indices {
            state.dumpItems[idx].spoke = nil
        }

        if state.archivedRhythmAnchors == nil && !state.rhythmAnchors.isEmpty {
            state.archivedRhythmAnchors = state.rhythmAnchors
        }
        state.rhythmAnchors = [:]
    }

    private func normalizeDailyPileMetadata() {
        let today = Self.todayDayISO()
        for idx in state.dumpItems.indices {
            if state.dumpItems[idx].filterOutcome == nil {
                state.dumpItems[idx].filterOutcome = .pending
            }
            if state.dumpItems[idx].planningDayISO == nil {
                state.dumpItems[idx].planningDayISO = today
            }
            if state.dumpItems[idx].carriedOver == nil {
                state.dumpItems[idx].carriedOver = false
            }
        }

        for idx in state.tasks.indices {
            if state.tasks[idx].plannedDayISO == nil {
                state.tasks[idx].plannedDayISO = today
            }
        }
    }

    private func runDailyRolloverIfNeeded() {
        let today = Self.todayDayISO()
        guard state.lastRolloverDayISO != today else { return }

        let overdueTasks = state.tasks.filter {
            !$0.completed &&
                ($0.plannedDayISO ?? today) < today
        }

        for task in overdueTasks {
            state.dumpItems.append(
                DumpItem(
                    text: task.text,
                    lane: task.lane,
                    filterOutcome: .pending,
                    planningDayISO: today,
                    carriedOver: true
                )
            )
        }

        state.tasks.removeAll {
            !$0.completed &&
                ($0.plannedDayISO ?? today) < today
        }

        state.appointments.removeAll {
            Self.dayISO(fromISODateTime: $0.scheduledAtISO) < today
        }

        state.lastRolloverDayISO = today
    }

    private func materializeRepeatingTasksIfNeeded() {
        let todayISO = Self.todayDayISO()

        for idx in state.repeatingTaskRules.indices {
            var rule = state.repeatingTaskRules[idx]
            guard shouldGenerateRepeatingRule(rule, todayISO: todayISO) else { continue }

            let normalized = Self.normalizedDumpText(rule.text)
            let alreadyExistsToday = state.dumpItems.contains {
                ($0.planningDayISO ?? todayISO) == todayISO &&
                    Self.normalizedDumpText($0.text) == normalized
            }

            if !alreadyExistsToday {
                state.dumpItems.append(
                    DumpItem(
                        text: rule.text,
                        lane: rule.lane,
                        filterOutcome: .pending,
                        planningDayISO: todayISO,
                        carriedOver: false
                    )
                )
            }

            rule.lastGeneratedDayISO = todayISO
            state.repeatingTaskRules[idx] = rule
        }
    }

    private func shouldGenerateRepeatingRule(_ rule: RepeatingTaskRule, todayISO: String) -> Bool {
        guard let lastISO = rule.lastGeneratedDayISO,
              let lastDate = Self.dateFromDayISO(lastISO),
              let todayDate = Self.dateFromDayISO(todayISO) else {
            return true
        }

        let elapsed = Calendar.current.dateComponents([.day], from: lastDate, to: todayDate).day ?? 0
        return elapsed >= max(1, rule.everyDays)
    }

    private func materializeLoopTasksIfNeeded() {
        let todayISO = Self.todayDayISO()
        guard var rules = state.loopRules else { return }

        for idx in rules.indices {
            var rule = rules[idx]
            guard shouldEvaluateLoopRule(rule, todayISO: todayISO) else { continue }

            var remaining = rule.durationType == .fixedCount ? max(0, rule.remainingOccurrences ?? 0) : Int.max
            guard remaining > 0 else {
                rule.lastEvaluatedDayISO = todayISO
                rules[idx] = rule
                continue
            }

            let startISO = nextEvaluationStartISO(for: rule, todayISO: todayISO)
            guard let startDate = Self.dateFromDayISO(startISO),
                  let todayDate = Self.dateFromDayISO(todayISO) else {
                continue
            }

            var cursor = startDate
            var shouldCreateToday = false
            var carriesMissed = false

            while cursor <= todayDate {
                let cursorISO = Self.dayISO(from: cursor)
                let scheduled = loopRule(rule, isScheduledOn: cursor)
                if scheduled {
                    if rule.durationType == .fixedCount {
                        if remaining <= 0 {
                            break
                        }
                        remaining -= 1
                    }

                    if cursorISO == todayISO {
                        shouldCreateToday = true
                    } else {
                        carriesMissed = true
                    }
                }

                guard let next = Calendar.current.date(byAdding: .day, value: 1, to: cursor) else { break }
                cursor = next
            }

            if rule.durationType == .fixedCount {
                rule.remainingOccurrences = max(0, remaining)
            }

            if (shouldCreateToday || carriesMissed), !hasDumpItemToday(matching: rule.text, dayISO: todayISO) {
                state.dumpItems.append(
                    DumpItem(
                        text: rule.text,
                        lane: rule.lane,
                        filterOutcome: .pending,
                        planningDayISO: todayISO,
                        carriedOver: !shouldCreateToday && carriesMissed
                    )
                )
            }

            rule.lastEvaluatedDayISO = todayISO
            rules[idx] = rule
        }

        state.loopRules = rules.filter { rule in
            rule.durationType == .forever || (rule.remainingOccurrences ?? 0) > 0
        }
    }

    private func shouldEvaluateLoopRule(_ rule: LoopRule, todayISO: String) -> Bool {
        guard let last = rule.lastEvaluatedDayISO else { return true }
        return last != todayISO
    }

    private func nextEvaluationStartISO(for rule: LoopRule, todayISO: String) -> String {
        guard let last = rule.lastEvaluatedDayISO,
              let lastDate = Self.dateFromDayISO(last),
              let next = Calendar.current.date(byAdding: .day, value: 1, to: lastDate) else {
            return rule.anchorDayISO
        }

        let nextISO = Self.dayISO(from: next)
        return nextISO > todayISO ? todayISO : nextISO
    }

    private func loopRule(_ rule: LoopRule, isScheduledOn date: Date) -> Bool {
        switch rule.recurrenceType {
        case .daily:
            return true
        case .weekly:
            guard let anchorDate = Self.dateFromDayISO(rule.anchorDayISO) else { return false }
            let anchorWeekday = Calendar.current.component(.weekday, from: anchorDate)
            let targetWeekday = Calendar.current.component(.weekday, from: date)
            return anchorWeekday == targetWeekday
        case .weekdays:
            let targetWeekday = Calendar.current.component(.weekday, from: date)
            return rule.weekdayNumbers.contains(targetWeekday)
        }
    }

    private func hasDumpItemToday(matching text: String, dayISO: String) -> Bool {
        let normalized = Self.normalizedDumpText(text)
        return state.dumpItems.contains {
            ($0.planningDayISO ?? dayISO) == dayISO &&
                Self.normalizedDumpText($0.text) == normalized
        }
    }

    private func reminderDate(from timeString: String) -> Date? {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "h:mm a"
        guard let parsedTime = parser.date(from: timeString) else { return nil }

        let calendar = Calendar.current
        let today = Date()
        let timeParts = calendar.dateComponents([.hour, .minute], from: parsedTime)
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.hour = timeParts.hour
        components.minute = timeParts.minute
        components.second = 0
        return calendar.date(from: components)
    }

    private func scheduleDailyFlowRemindersIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["genesis.morning.plan", "genesis.evening.plan"])

        let morningEnabled = state.morningPlanningReminderEnabled ?? false
        let eveningEnabled = state.eveningPlanningReminderEnabled
        guard morningEnabled || eveningEnabled else { return }

        let authorized: Bool
        do {
            authorized = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return
        }
        guard authorized else { return }

        if morningEnabled,
           let fireDate = reminderDate(from: state.morningPlanningReminderTime ?? "") {
            let content = UNMutableNotificationContent()
            content.title = "Start your day with Genesis"
            content.body = "Run Dump -> Shape -> Fill to plan your day with intention."
            content.sound = .default

            let components = Calendar.current.dateComponents([.hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: "genesis.morning.plan", content: content, trigger: trigger)

            do {
                try await center.add(request)
            } catch {
                // Ignore scheduling failures in the store layer.
            }
        }

        if eveningEnabled,
           let fireDate = reminderDate(from: state.eveningPlanningReminderTime) {
            let content = UNMutableNotificationContent()
            content.title = "Plan tomorrow in 5 minutes"
            content.body = "Open Fill and prep tomorrow before your day starts."
            content.sound = .default
            content.userInfo = ["targetScreen": "fill"]

            let components = Calendar.current.dateComponents([.hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: "genesis.evening.plan", content: content, trigger: trigger)

            do {
                try await center.add(request)
            } catch {
                // Ignore scheduling failures in the store layer.
            }
        }
    }

    private func nextTaskNumber(for lane: TaskLane) -> Int {
        nextCodeNumber(for: lane)
    }

    private func applySignedInSession(_ session: AuthSession) {
        state.authAccountState = .signedIn
        state.authProvider = session.provider
        state.authUserId = session.userId
        persistAuthSessionToKeychain(session)
    }

    @discardableResult
    private func runAuthMigrationIfNeeded(for userId: String) -> Bool {
        state.authMigrationLastAttemptISO = Self.isoDateTime(from: Date())

        guard !userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return failAuthMigration(details: "Migration failed: missing auth user id.", userId: nil)
        }

        guard migrationSelfCheckPassed() else {
            return failAuthMigration(details: "Migration failed: migration self-check did not pass.", userId: userId)
        }

        // Already migrated for this user and version.
        if state.authLinkedUserId == userId,
           state.authMigrationVersion == 1,
           state.authMigrationStatus == .succeeded {
            appendAuthMigrationEvent(status: .succeeded, details: "Migration skipped: already linked for current user.", userId: userId)
            return true
        }

        if let previousLinkedUser = state.authLinkedUserId,
           !previousLinkedUser.isEmpty,
           previousLinkedUser != userId {
            state.authMigrationRelinkCount = (state.authMigrationRelinkCount ?? 0) + 1
            appendAuthMigrationEvent(
                status: .succeeded,
                details: "Account relink detected from \(previousLinkedUser) to \(userId).",
                userId: userId
            )
        }

        // v1 migration model: the full local state is treated as one user-owned graph.
        // Linking is represented by the owning auth user id plus migration version marker.
        state.authLinkedUserId = userId
        state.authMigrationVersion = 1
        state.authMigrationStatus = .succeeded
        state.authMigrationRetryCount = 0
        state.authMigrationRelinkCount = state.authMigrationRelinkCount ?? 0
        state.authMigrationLastError = nil
        appendAuthMigrationEvent(status: .succeeded, details: "Migration linked local graph to signed-in account.", userId: userId)
        return true
    }

    private func failAuthMigration(details: String, userId: String?) -> Bool {
        state.authMigrationStatus = .failed
        state.authMigrationRetryCount = (state.authMigrationRetryCount ?? 0) + 1
        state.authMigrationLastError = details
        appendAuthMigrationEvent(status: .failed, details: details, userId: userId)
        return false
    }

    private func appendAuthMigrationEvent(status: AuthMigrationStatus, details: String, userId: String?) {
        var events = state.authMigrationEvents ?? []
        events.append(
            AuthMigrationEvent(
                occurredAtISO: Self.isoDateTime(from: Date()),
                status: status,
                details: details,
                retryCount: state.authMigrationRetryCount ?? 0,
                userId: userId
            )
        )

        if events.count > 25 {
            events = Array(events.suffix(25))
        }

        state.authMigrationEvents = events
    }

    private func autoRetryAuthMigrationIfNeeded() {
        guard state.authAccountState == .signedIn,
              let userId = state.authUserId,
              !userId.isEmpty else { return }

        let status = state.authMigrationStatus ?? .notStarted
        if status == .failed || status == .notStarted || state.authLinkedUserId == nil {
            let succeeded = runAuthMigrationIfNeeded(for: userId)
            if !succeeded {
                authLastStatusMessage = "Signed in, but migration needs retry."
            }
        }
    }

    private struct MigrationCoreSnapshot: Equatable {
        var linkedUserId: String?
        var version: Int?
        var status: AuthMigrationStatus?
        var retryCount: Int?
    }

    private func migrationCoreSnapshot() -> MigrationCoreSnapshot {
        MigrationCoreSnapshot(
            linkedUserId: state.authLinkedUserId,
            version: state.authMigrationVersion,
            status: state.authMigrationStatus,
            retryCount: state.authMigrationRetryCount
        )
    }

    private func authMigrationRegressionSelfCheckPassed() -> Bool {
        let eventCount = state.authMigrationEvents?.count ?? 0
        if eventCount > 25 { return false }

        if (state.authMigrationStatus ?? .notStarted) == .succeeded {
            guard let linked = state.authLinkedUserId, !linked.isEmpty else { return false }
            guard state.authMigrationVersion == 1 else { return false }
            guard (state.authMigrationRetryCount ?? 0) == 0 else { return false }
            guard (state.authMigrationRelinkCount ?? 0) >= 0 else { return false }
        }

        return true
    }

    private func hydrateAuthSessionFromKeychainIfNeeded() {
        guard state.authAccountState == nil else { return }
        guard let session = loadAuthSessionFromKeychain() else {
            state.authAccountState = .guest
            state.authProvider = .guest
            state.authUserId = nil
            return
        }

        state.authAccountState = .signedIn
        state.authProvider = session.provider
        state.authUserId = session.userId
    }

    private func persistAuthSessionToKeychain(_ session: AuthSession) {
        guard let payload = try? JSONEncoder().encode(session) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: authSessionService,
            kSecAttrAccount as String: authSessionAccount,
        ]

        SecItemDelete(query as CFDictionary)

        var createQuery = query
        createQuery[kSecValueData as String] = payload
        SecItemAdd(createQuery as CFDictionary, nil)
    }

    private func loadAuthSessionFromKeychain() -> AuthSession? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: authSessionService,
            kSecAttrAccount as String: authSessionAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let session = try? JSONDecoder().decode(AuthSession.self, from: data) else {
            return nil
        }

        return session
    }

    private func clearAuthSessionFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: authSessionService,
            kSecAttrAccount as String: authSessionAccount,
        ]
        SecItemDelete(query as CFDictionary)
    }

    private func exchangeGoogleAuthorizationCode(code: String, codeVerifier: String, redirectURI: String) async throws -> GoogleCalendarCallbackResponse {
        guard let configuration = GoogleCalendarConfiguration.fromBundle() else {
            throw NSError(domain: "GenesisWay", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Google Calendar configuration is missing."])
        }

        let endpoint = configuration.apiBaseURL.appending(path: "api/calendar/oauth/callback")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "code": code,
            "codeVerifier": codeVerifier,
            "redirectUri": redirectURI,
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "GenesisWay", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Google token exchange returned an invalid response."])
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            let message = (try? JSONSerialization.jsonObject(with: data))
                .flatMap { $0 as? [String: Any] }?["error"] as? String
            throw NSError(domain: "GenesisWay", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message ?? "Google token exchange failed."])
        }

        let payload = try JSONDecoder().decode(GoogleCalendarCallbackResponse.self, from: data)
        return payload
    }

    private func refreshGoogleCalendarAccessToken(
        configuration: GoogleCalendarConfiguration,
        refreshToken: String
    ) async throws -> GoogleCalendarRefreshResponse {
        guard let endpoint = URL(string: "https://oauth2.googleapis.com/token") else {
            throw NSError(domain: "GenesisWay", code: 1005, userInfo: [NSLocalizedDescriptionKey: "Google token refresh URL is invalid."])
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "client_id", value: configuration.clientId),
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken),
        ]
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "GenesisWay", code: 1006, userInfo: [NSLocalizedDescriptionKey: "Google token refresh returned an invalid response."])
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            let message = (try? JSONSerialization.jsonObject(with: data))
                .flatMap { $0 as? [String: Any] }?["error_description"] as? String
            throw NSError(domain: "GenesisWay", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message ?? "Google token refresh failed. Reconnect your calendar account."])
        }

        return try JSONDecoder().decode(GoogleCalendarRefreshResponse.self, from: data)
    }

    private func validGoogleCalendarAccessToken(
        configuration: GoogleCalendarConfiguration,
        forceRefresh: Bool = false
    ) async throws -> String {
        let currentAccessToken = state.googleCalendarAccessToken?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let refreshToken = state.googleCalendarRefreshToken?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let shouldRefresh = forceRefresh || googleCalendarAccessTokenNeedsRefresh

        if !shouldRefresh, !currentAccessToken.isEmpty {
            return currentAccessToken
        }

        guard !refreshToken.isEmpty else {
            if !currentAccessToken.isEmpty {
                return currentAccessToken
            }
            throw NSError(domain: "GenesisWay", code: 1007, userInfo: [NSLocalizedDescriptionKey: "Google access token is missing and no refresh token is available. Reconnect your calendar account."])
        }

        let refreshed = try await refreshGoogleCalendarAccessToken(configuration: configuration, refreshToken: refreshToken)
        await MainActor.run {
            applyGoogleCalendarTokens(
                accessToken: refreshed.accessToken,
                refreshToken: refreshed.refreshToken,
                expiresIn: refreshed.expiresIn
            )
            googleCalendarStatusMessage = forceRefresh ? "Calendar session renewed. Retrying sync." : "Calendar session renewed."
        }

        return refreshed.accessToken
    }

    private func performGoogleCalendarPull(
        endpointBaseURL: URL,
        accessToken: String,
        selectedCalendarIDs: [String]
    ) async throws -> GoogleCalendarSyncPullResponse {
        let endpoint = endpointBaseURL.appending(path: "api/calendar/sync/pull")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let payload = GoogleCalendarSyncPullRequest(
            accessToken: accessToken,
            selectedCalendarIds: selectedCalendarIDs,
            windowDays: 7
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "GenesisWay", code: 1101, userInfo: [NSLocalizedDescriptionKey: "Calendar pull returned an invalid response."])
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            let message = (try? JSONSerialization.jsonObject(with: data))
                .flatMap { $0 as? [String: Any] }?["error"] as? String
            throw NSError(domain: "GenesisWay", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message ?? "Calendar pull failed."])
        }

        let decoded = try JSONDecoder().decode(GoogleCalendarSyncPullResponse.self, from: data)
        return decoded
    }

    private func fetchGoogleCalendars(accessToken: String) async throws -> [CalendarSourceSummary] {
        guard let endpoint = URL(string: "https://www.googleapis.com/calendar/v3/users/me/calendarList") else {
            throw NSError(domain: "GenesisWay", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Google calendar list URL is invalid."])
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "GenesisWay", code: 1004, userInfo: [NSLocalizedDescriptionKey: "Google calendar list returned an invalid response."])
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            throw NSError(domain: "GenesisWay", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch Google calendars."])
        }

        let payload = try JSONDecoder().decode(GoogleCalendarListResponse.self, from: data)
        let items: [GoogleCalendarListResponse.CalendarItem] = payload.items ?? []
        let calendars = items.map { item in
            let role = item.accessRole?.capitalized
            let isPrimary = item.primary == true
            let trimmedSummary = item.summary?.trimmingCharacters(in: .whitespacesAndNewlines)
            let title = (trimmedSummary?.isEmpty == false ? trimmedSummary : nil) ?? item.id
            let detailParts: [String] = [
                isPrimary ? "Primary" : nil,
                role,
                item.description
            ].compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }

            return CalendarSourceSummary(
                id: item.id,
                title: title,
                detail: detailParts.isEmpty ? nil : detailParts.joined(separator: " • ")
            )
        }

        return calendars.sorted { lhs, rhs in
            let lhsPrimary = lhs.detail?.contains("Primary") == true
            let rhsPrimary = rhs.detail?.contains("Primary") == true
            if lhsPrimary != rhsPrimary {
                return lhsPrimary
            }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    private var googleCalendarAccessTokenNeedsRefresh: Bool {
        guard let expiresAtISO = state.googleCalendarAccessTokenExpiresAtISO,
              let expiresAt = ISO8601DateFormatter().date(from: expiresAtISO) else {
            return false
        }

        return expiresAt.timeIntervalSinceNow <= 300
    }

    private func applyGoogleCalendarTokens(accessToken: String, refreshToken: String?, expiresIn: Int?) {
        state.googleCalendarAccessToken = accessToken
        if let refreshToken, !refreshToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            state.googleCalendarRefreshToken = refreshToken
        }
        if let expiresIn {
            let expiresAt = Date().addingTimeInterval(TimeInterval(max(60, expiresIn)))
            state.googleCalendarAccessTokenExpiresAtISO = Self.isoDateTime(from: expiresAt)
        } else {
            state.googleCalendarAccessTokenExpiresAtISO = nil
        }
    }

    private static func randomOAuthToken(length: Int) -> String {
        let characters = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if status != errSecSuccess {
            return UUID().uuidString.replacingOccurrences(of: "-", with: "")
        }
        return String(bytes.map { characters[Int($0) % characters.count] })
    }

    private static func pkceCodeChallenge(for verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func nextCodeNumber(for lane: TaskLane) -> Int {
        let numbers = state.tasks
            .filter { $0.lane == lane }
            .compactMap { task -> Int? in
                let digits = task.code.filter(\.isNumber)
                return Int(digits)
            }

        let appointmentNumbers = state.appointments
            .filter { $0.lane == lane }
            .compactMap { appointment -> Int? in
                let digits = appointment.code.filter(\.isNumber)
                return Int(digits)
            }

        return (numbers + appointmentNumbers).max().map { $0 + 1 } ?? 1
    }

    private static func normalizedDumpText(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func migrationSelfCheckPassed() -> Bool {
        let hasNilFilter = state.dumpItems.contains { $0.filterOutcome == nil }
        let hasNilDay = state.dumpItems.contains { $0.planningDayISO == nil }
        let hasLegacySpokes = state.dumpItems.contains { $0.spoke != nil }
        return !hasNilFilter && !hasNilDay && !hasLegacySpokes
    }

    private static func isLikelyOversizedText(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = trimmed.split { $0 == " " || $0 == "\n" || $0 == "\t" }

        if words.count >= 10 { return true }

        let lowered = trimmed.lowercased()
        let hasWorkflowPhrases = lowered.contains(" and ") ||
            lowered.contains(" then ") ||
            lowered.contains(" after ") ||
            lowered.contains(" before ")

        return hasWorkflowPhrases && words.count >= 7
    }

    private static func todayDayISO() -> String {
        dayISO(from: Date())
    }

    private static func dayISO(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func isoDateTime(from date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private static func dayISO(fromISODateTime iso: String) -> String {
        guard let parsed = ISO8601DateFormatter().date(from: iso) else {
            return String(iso.prefix(10))
        }
        return dayISO(from: parsed)
    }

    private static func dateFromDayISO(_ iso: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: iso)
    }

    private func setDumpItemPlanningDay(_ dumpItemId: UUID, dayISO: String) {
        guard let idx = state.dumpItems.firstIndex(where: { $0.id == dumpItemId }) else { return }
        state.dumpItems[idx].planningDayISO = dayISO
        state.dumpItems[idx].filterOutcome = .pending
    }

    private static func load(storageKey: String) -> GenesisState? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(GenesisState.self, from: data)
    }
}
