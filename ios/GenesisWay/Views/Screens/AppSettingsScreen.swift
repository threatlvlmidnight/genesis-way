import SwiftUI

struct AppSettingsScreen: View {
    @EnvironmentObject private var store: GenesisStore
    @Environment(\.dismiss) private var dismiss

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
                }

                Section("Navigation") {
                    Button("Go to Fill screen") {
                        store.navigate(.fill)
                        dismiss()
                    }
                    .foregroundStyle(GWTheme.gold)
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
                }
            }
            .scrollContentBackground(.hidden)
            .background(GWTheme.background.ignoresSafeArea())
            .navigationTitle("App Settings")
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
