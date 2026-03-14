import SwiftUI

struct CalendarSettingsScreen: View {
    @EnvironmentObject private var store: GenesisStore
    @Environment(\.dismiss) private var dismiss

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
                    Toggle("Connected", isOn: Binding(
                        get: { store.googleCalendarConnected },
                        set: { store.setGoogleCalendarConnected($0) }
                    ))
                    Text("Happy path for direct calendar sync.")
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

                    Button("Mark Sync Now") {
                        store.markCalendarSyncedNow()
                    }
                    .foregroundStyle(GWTheme.gold)
                }
            }
            .scrollContentBackground(.hidden)
            .background(GWTheme.background.ignoresSafeArea())
            .navigationTitle("Calendar Settings")
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
