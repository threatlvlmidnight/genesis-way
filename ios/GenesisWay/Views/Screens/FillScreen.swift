import SwiftUI
import UserNotifications

struct FillScreen: View {
    @EnvironmentObject private var store: GenesisStore
    @State private var showCalendarSettings = false
    @State private var showAppSettings = false
    @State private var reminderStatus = ""

    private var doneCount: Int {
        store.big3.filter { $0.done }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header

                GlassCard {
                    VStack(alignment: .leading, spacing: 9) {
                        Text("How Fill Works")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(GWTheme.textGhost)
                            .textCase(.uppercase)

                        Text("Turn clarity into scheduled action")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(GWTheme.textPrimary)

                        Text("1. Choose your Daily Big 3\n2. Place work and personal tasks on today\n3. Schedule reminders so your plan survives the day")
                            .font(.system(size: 12))
                            .foregroundStyle(GWTheme.textMuted)
                            .lineSpacing(2)
                            .multilineTextAlignment(.leading)
                    }
                }

                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Calendar Sync")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(GWTheme.textGhost)
                            Text("Google direct sync + Apple ICS import")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(GWTheme.textPrimary)
                            Text("Provider abstraction planned for Android parity")
                                .font(.system(size: 11))
                                .foregroundStyle(GWTheme.textMuted)
                        }
                        Spacer()
                        Button {
                            showCalendarSettings = true
                        } label: {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(GWTheme.gold)
                        }
                        .buttonStyle(.plain)
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Reminders & Alerts")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(GWTheme.textGhost)
                            .textCase(.uppercase)

                        Toggle("Enable reminders", isOn: Binding(
                            get: { store.remindersEnabled },
                            set: { store.setRemindersEnabled($0) }
                        ))
                        .tint(GWTheme.gold)

                        Picker("Lead time", selection: Binding(
                            get: { store.reminderLeadMinutes },
                            set: { store.setReminderLeadMinutes($0) }
                        )) {
                            Text("At time").tag(0)
                            Text("10 min").tag(10)
                            Text("30 min").tag(30)
                            Text("60 min").tag(60)
                        }
                        .pickerStyle(.segmented)
                        .disabled(!store.remindersEnabled)

                        HStack(spacing: 12) {
                            Button("Schedule Alerts") {
                                Task { await scheduleTaskReminders() }
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(hex: "1a1208"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(GWTheme.gold)
                            .clipShape(Capsule())
                            .buttonStyle(.plain)

                            Button("Clear") {
                                Task { await clearTaskReminders() }
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(GWTheme.textGhost)
                            .buttonStyle(.plain)
                        }

                        if !reminderStatus.isEmpty {
                            Text(reminderStatus)
                                .font(.system(size: 11))
                                .foregroundStyle(GWTheme.textMuted)
                        }
                    }
                }

                rowHeader(title: "Daily Big 3", trailing: "\(doneCount)/3")
                Text("These are your non-negotiables for today. Check them off as completed.")
                    .font(.system(size: 11))
                    .foregroundStyle(GWTheme.textGhost)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(store.big3) { item in
                    HStack(spacing: 12) {
                        Button {
                            store.toggleBig3(id: item.id)
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(GWTheme.gold.opacity(item.done ? 1 : 0.35), lineWidth: 1.5)
                                    .frame(width: 22, height: 22)
                                if item.done {
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(GWTheme.gold)
                                        .frame(width: 22, height: 22)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color(hex: "1a1208"))
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        Text(item.text)
                            .font(.system(size: 13))
                            .foregroundStyle(item.done ? GWTheme.textGhost : GWTheme.textMuted)
                            .strikethrough(item.done)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                rowHeader(title: "Work", trailing: "↓")
                Text("Tasks tied to output, clients, and deadlines.")
                    .font(.system(size: 11))
                    .foregroundStyle(GWTheme.textGhost)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(store.workTasks) { task in
                    taskRow(task: task, codeColor: GWTheme.gold)
                }

                rowHeader(title: "Personal", trailing: "↑")
                Text("Tasks that protect relationships, health, and life rhythms.")
                    .font(.system(size: 11))
                    .foregroundStyle(GWTheme.textGhost)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(store.personalTasks) { task in
                    taskRow(task: task, codeColor: Color(hex: "907050"))
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("What success looks like")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(GWTheme.textGhost)
                            .textCase(.uppercase)

                        Text("By end of day: Big 3 completed, key tasks scheduled, reminders set.")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(GWTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Fill is not about adding more. It is about protecting what matters most.")
                            .font(.system(size: 11))
                            .foregroundStyle(GWTheme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(24)
        }
        .background(GWTheme.background.ignoresSafeArea())
        .sheet(isPresented: $showAppSettings) {
            AppSettingsScreen()
                .environmentObject(store)
        }
        .sheet(isPresented: $showCalendarSettings) {
            CalendarSettingsScreen()
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(GWTheme.textGhost)
                Text("Fill It")
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(GWTheme.textPrimary)
                Text("Assign intentional actions to the right time, then protect them.")
                    .font(.system(size: 13))
                    .foregroundStyle(GWTheme.textMuted)
            }

            Spacer()

            Button {
                showAppSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(GWTheme.gold)
                    .frame(width: 34, height: 34)
                    .background(GWTheme.gold.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
    }

    private func rowHeader(title: String, trailing: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(GWTheme.textGhost)
                .textCase(.uppercase)
            Spacer()
            Text(trailing)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(GWTheme.gold)
        }
        .padding(.top, 4)
    }

    private func taskRow(task: TaskItem, codeColor: Color) -> some View {
        HStack(spacing: 10) {
            Text(task.code)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(codeColor)
                .frame(width: 28, alignment: .leading)
            Text(task.text)
                .font(.system(size: 13))
                .foregroundStyle(GWTheme.textMuted)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            if let time = task.time {
                Text(time)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(GWTheme.gold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(GWTheme.gold.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 6)
    }

    private func scheduleTaskReminders() async {
        guard store.remindersEnabled else {
            await MainActor.run {
                reminderStatus = "Reminders are disabled in settings."
            }
            return
        }

        let center = UNUserNotificationCenter.current()
        let authorized = await requestReminderAuthorization(center: center)
        guard authorized else {
            await MainActor.run {
                reminderStatus = "Enable notifications for Genesis Way in iOS Settings."
            }
            return
        }

        let tasks = store.workTasks + store.personalTasks
        let lead = TimeInterval(store.reminderLeadMinutes * 60)
        let now = Date()

        var scheduledCount = 0

        for task in tasks {
            guard let time = task.time,
                  let taskTime = dateForToday(timeString: time) else { continue }

            var fireDate = taskTime.addingTimeInterval(-lead)
            if fireDate <= now {
                fireDate = now.addingTimeInterval(8)
            }

            let content = UNMutableNotificationContent()
            content.title = "Upcoming: \(task.text)"
            content.body = "\(task.code) • \(time)"
            content.sound = .default

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "genesis.task.\(task.id.uuidString)", content: content, trigger: trigger)

            do {
                try await center.add(request)
                scheduledCount += 1
            } catch {
                await MainActor.run {
                    reminderStatus = "Failed to schedule alerts: \(error.localizedDescription)"
                }
                return
            }
        }

        await MainActor.run {
            reminderStatus = "Scheduled \(scheduledCount) reminder\(scheduledCount == 1 ? "" : "s")."
        }
    }

    private func clearTaskReminders() async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: reminderIdentifiers())
        await MainActor.run {
            reminderStatus = "Cleared scheduled task reminders."
        }
    }

    private func reminderIdentifiers() -> [String] {
        (store.workTasks + store.personalTasks).map { "genesis.task.\($0.id.uuidString)" }
    }

    private func requestReminderAuthorization(center: UNUserNotificationCenter) async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    private func dateForToday(timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"

        guard let parsed = formatter.date(from: timeString) else { return nil }

        let calendar = Calendar.current
        let timeParts = calendar.dateComponents([.hour, .minute], from: parsed)
        let today = calendar.dateComponents([.year, .month, .day], from: Date())

        var components = DateComponents()
        components.year = today.year
        components.month = today.month
        components.day = today.day
        components.hour = timeParts.hour
        components.minute = timeParts.minute

        return calendar.date(from: components)
    }
}
