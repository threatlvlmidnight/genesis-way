import AuthenticationServices
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct CalendarSettingsScreen: View {
    @EnvironmentObject private var store: GenesisStore
    @Environment(\.dismiss) private var dismiss
    @State private var googleAuthSession: ASWebAuthenticationSession?
    @State private var isConnectingGoogleCalendar = false
    @State private var isSyncingGoogleCalendar = false

    private var statusLabel: String {
        switch store.googleCalendarConnectionStatus {
        case .disconnected:
            return "Disconnected"
        case .readyToConnect:
            return "Ready to connect"
        case .connected:
            return "Connected"
        case .needsAttention:
            return "Needs attention"
        }
    }

    private var statusColor: Color {
        switch store.googleCalendarConnectionStatus {
        case .connected:
            return Color(hex: "5ca06d")
        case .readyToConnect:
            return GWTheme.gold
        case .needsAttention:
            return Color(hex: "c07060")
        case .disconnected:
            return .secondary
        }
    }

    private var calendarConfigRows: [(String, Bool)] {
        [
            ("Signed in account", store.isSignedIn),
            ("Supabase auth config", store.isSupabaseConfigured),
            ("Google OAuth app config", store.isGoogleCalendarConfigured)
        ]
    }

    private var lastSyncLabel: String {
        guard let iso = store.lastCalendarSyncISO,
              let date = ISO8601DateFormatter().date(from: iso) else {
            return "Not synced yet"
        }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Google") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(statusLabel)
                            .foregroundStyle(statusColor)
                    }

                    if let accountLabel = store.googleCalendarAccountLabel,
                       store.googleCalendarConnected {
                        HStack {
                            Text("Account")
                            Spacer()
                            Text(accountLabel)
                                .foregroundStyle(.secondary)
                        }
                    }

                    ForEach(calendarConfigRows, id: \.0) { row in
                        HStack {
                            Text(row.0)
                            Spacer()
                            Image(systemName: row.1 ? "checkmark.circle.fill" : "exclamationmark.circle")
                                .foregroundStyle(row.1 ? Color(hex: "5ca06d") : Color(hex: "c07060"))
                        }
                    }

                    if store.googleCalendarConnected {
                        Button("Disconnect Google Calendar") {
                            store.disconnectGoogleCalendar()
                        }
                        .foregroundStyle(Color.red)
                    } else {
                        Button(isConnectingGoogleCalendar ? "Connecting Google Calendar..." : "Connect Google Calendar") {
                            startGoogleCalendarConnection()
                        }
                        .foregroundStyle(GWTheme.gold)
                        .disabled(isConnectingGoogleCalendar)
                    }

                    if let error = store.googleCalendarLastError,
                       !error.isEmpty {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(statusColor)
                    } else {
                        Text(store.googleCalendarStatusMessage.isEmpty ? "Connect Google Calendar to sync events into the Fill timeline." : store.googleCalendarStatusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if !store.googleCalendarAvailableCalendars.isEmpty {
                    Section("Selected Calendars") {
                        ForEach(store.googleCalendarAvailableCalendars) { calendar in
                            Button {
                                store.toggleGoogleCalendarSelection(id: calendar.id)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(calendar.title)
                                            .foregroundStyle(GWTheme.textPrimary)
                                        if let detail = calendar.detail, !detail.isEmpty {
                                            Text(detail)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: store.googleCalendarSelectedCalendarIDs.contains(calendar.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(store.googleCalendarSelectedCalendarIDs.contains(calendar.id) ? GWTheme.gold : .secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else if store.googleCalendarConnectionStatus == .connected || store.googleCalendarConnectionStatus == .readyToConnect {
                    Section("Selected Calendars") {
                        Text("Calendar discovery will populate here after Google sign-in completes.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Google Sync") {
                    HStack {
                        Text("Selected count")
                        Spacer()
                        Text("\(store.googleCalendarSelectedCalendarIDs.count)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Last pulled")
                        Spacer()
                        Text("\(store.googleCalendarLastPulledEventCount) events")
                            .foregroundStyle(.secondary)
                    }

                    Button(isSyncingGoogleCalendar ? "Syncing..." : "Sync Now") {
                        isSyncingGoogleCalendar = true
                        Task {
                            _ = await store.syncGoogleCalendarNow()
                            await MainActor.run {
                                isSyncingGoogleCalendar = false
                            }
                        }
                    }
                    .foregroundStyle(GWTheme.gold)
                    .disabled(!store.googleCalendarConnected)

                    Text("Sync Now pulls selected Google calendars for a ±7 day window.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Apple Calendar") {
                    Toggle("Enable ICS import", isOn: Binding(
                        get: { store.appleIcsEnabled },
                        set: { store.setAppleIcsEnabled($0) }
                    ))
                    Text("Practical compatibility path in early versions.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Sync") {
                    HStack {
                        Text("Last sync")
                        Spacer()
                        Text(lastSyncLabel)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(GWTheme.background.ignoresSafeArea())
            .navigationTitle("Calendar Settings")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .top) {
                if store.showFeedbackIdentifiers {
                    FeedbackIdentifierBadge(text: "GW-S02 · Calendar Settings")
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

private extension CalendarSettingsScreen {
    func startGoogleCalendarConnection() {
        guard let request = store.makeGoogleCalendarAuthorizationRequest() else { return }

        let session = ASWebAuthenticationSession(
            url: request.authorizationURL,
            callbackURLScheme: request.callbackScheme
        ) { callbackURL, error in
            if let error {
                Task { @MainActor in
                    isConnectingGoogleCalendar = false
                    let authError = error as NSError
                    if authError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        store.cancelGoogleCalendarAuthorization()
                    } else {
                        store.setGoogleCalendarError(error.localizedDescription)
                    }
                }
                return
            }

            guard let callbackURL else {
                Task { @MainActor in
                    isConnectingGoogleCalendar = false
                    store.setGoogleCalendarError("Google Calendar did not return a callback URL.")
                }
                return
            }

            Task { @MainActor in
                _ = await store.finishGoogleCalendarAuthorization(callbackURL: callbackURL)
                isConnectingGoogleCalendar = false
            }
        }

        session.presentationContextProvider = GoogleCalendarPresentationContextProvider.shared
        session.prefersEphemeralWebBrowserSession = false
        googleAuthSession = session
        isConnectingGoogleCalendar = session.start()

        if !isConnectingGoogleCalendar {
            store.setGoogleCalendarError("Unable to start Google Calendar sign-in.")
        }
    }
}

private final class GoogleCalendarPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = GoogleCalendarPresentationContextProvider()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windows = scenes.flatMap { $0.windows }
        return windows.first(where: { $0.isKeyWindow }) ?? ASPresentationAnchor()
    }
}
