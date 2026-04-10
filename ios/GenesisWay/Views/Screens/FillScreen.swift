import SwiftUI
import UniformTypeIdentifiers
import UserNotifications
import UIKit

struct FillScreen: View {
    @EnvironmentObject private var store: GenesisStore
    @State private var reminderStatus = ""
    @State private var showBig3Help = false
    @State private var showRatingHelp = false
    @State private var targetedDropSlot: String?
    @State private var isAutoSyncingCalendar = false
    @State private var isRetryingCalendarSync = false
    @State private var hideCalendarErrorBannerForSession = false
    @FocusState private var focusedField: FillInputField?

    private enum FillInputField: Hashable {
        case big3(UUID)
        case weeklyGoal(Int)
        case weeklyMacro
    }

    private var planningDay: Date {
        store.activePlanningDay
    }

    private var planningDayBinding: Binding<Date> {
        Binding(
            get: { store.activePlanningDay },
            set: { store.setActivePlanningDay($0) }
        )
    }

    private var timelineSlots: [String] {
        ["All Day"] + (store.plannerStartHour...store.plannerEndHour).map { hourLabel($0) }
    }

    private var doneCount: Int {
        store.big3.filter { $0.done }.count
    }

    private var completedTaskCount: Int {
        dayTaskPool.filter { $0.completed }.count
    }

    private var big3CompletionRatio: Double {
        let total = max(store.big3.count, 1)
        return Double(doneCount) / Double(total)
    }

    private var scheduledTaskCompletionRatio: Double {
        guard !dayTaskPool.isEmpty else { return 0 }
        return Double(completedTaskCount) / Double(dayTaskPool.count)
    }

    private struct Big3PoolChoice: Identifiable {
        let id: String
        let label: String
        let taskId: UUID?
        let dumpItemId: UUID?
    }

    private var big3PoolChoices: [Big3PoolChoice] {
        let taskChoices = unscheduledTaskPool.map { task in
            Big3PoolChoice(
                id: "task-\(task.id.uuidString)",
                label: "\(task.code) • \(task.text)",
                taskId: task.id,
                dumpItemId: nil
            )
        }

        let dumpChoices = unfilteredPileItems.map { item in
            Big3PoolChoice(
                id: "dump-\(item.id.uuidString)",
                label: "DUMP • \(item.text)",
                taskId: nil,
                dumpItemId: item.id
            )
        }

        return taskChoices + dumpChoices
    }

    private var allTasks: [TaskItem] {
        store.workTasks + store.personalTasks
    }

    private var unscheduledTaskPool: [TaskItem] {
        store.taskPool(for: planningDay)
    }

    private var unfilteredPileItems: [DumpItem] {
        store.pendingPileItems(for: planningDay)
    }

    private var unfilteredWorkItems: [DumpItem] {
        unfilteredPileItems.filter { ($0.lane ?? .work) == .work }
    }

    private var unfilteredPersonalItems: [DumpItem] {
        unfilteredPileItems.filter { ($0.lane ?? .work) == .personal }
    }

    private var unscheduledWorkTasks: [TaskItem] {
        unscheduledTaskPool.filter { $0.lane == .work }
    }

    private var unscheduledPersonalTasks: [TaskItem] {
        unscheduledTaskPool.filter { $0.lane == .personal }
    }

    private var delegatedDumpItems: [DumpItem] {
        store.dumpItems(for: planningDay).filter { $0.filterOutcome == .delegated }
    }

    private var planningDayISO: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: planningDay)
    }

    private var dayTaskPool: [TaskItem] {
        allTasks.filter { task in
            (task.plannedDayISO ?? planningDayISO) == planningDayISO
        }
    }

    private var dayWorkTasks: [TaskItem] {
        dayTaskPool.filter { $0.lane == .work }
    }

    private var dayPersonalTasks: [TaskItem] {
        dayTaskPool.filter { $0.lane == .personal }
    }

    private var planningDayAppointments: [ScheduledAppointment] {
        store.appointments(for: planningDay)
    }

    private var unresolvedPlanningCount: Int {
        unscheduledTaskPool.count + unfilteredPileItems.count
    }

    private var scheduledOutsideVisibleHours: [TaskItem] {
        let visibleSlots = Set(timelineSlots)
        return store.scheduledTasks(for: planningDay).filter { task in
            guard let time = task.time else { return false }
            return !visibleSlots.contains(time)
        }
    }

    private var carryoverHistory: [(String, [DumpItem])] {
        let carried = store.dumpItems.filter { $0.carriedOver == true }
        let grouped = Dictionary(grouping: carried) { $0.planningDayISO ?? "Unknown" }
        return grouped
            .map { ($0.key, $0.value) }
            .sorted { $0.0 > $1.0 }
    }

    private var isWeeklyPlanningWindow: Bool {
        let weekday = Calendar.current.component(.weekday, from: planningDay)
        return weekday == 6 || weekday == 1
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header

                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        rowHeader(
                            title: "Execution Progress",
                            trailing: "B3 \(Int((big3CompletionRatio * 100).rounded()))% · Tasks \(Int((scheduledTaskCompletionRatio * 100).rounded()))%"
                        )

                        dualExecutionProgressBar

                        Text("Big 3 complete: \(doneCount)/3 • Planned tasks complete: \(completedTaskCount)/\(dayTaskPool.count)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(GWTheme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How Fill It Works")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(GWTheme.textGhost)
                            .textCase(.uppercase)

                        Text("Turn clarity into scheduled action")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(GWTheme.textPrimary)

                        Text("Fill It is placing each task into its proper place in your calendar based on priority, timing, and context so your plan becomes actionable.")
                            .font(.system(size: 13))
                            .foregroundStyle(GWTheme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)

                        ForEach([
                            ("1", "Sync your calendar", "Connect Google Calendar in Settings so your existing commitments are visible on the timeline."),
                            ("2", "Assign each task to a time", "Drag tasks from the Task Pool onto a time block. Use Move Day to shift tasks without assigning a time."),
                            ("3", "Finish your day on paper first", "Your plan is useless if it stays in your head. Lock it in here before the day begins."),
                            ("4", "Start your day", "Tap Start Day when everything is placed. Your Big 3 sets the daily north star.")
                        ], id: \.0) { num, title, detail in
                            HStack(alignment: .top, spacing: 10) {
                                Text(num)
                                    .font(.system(size: 11, weight: .heavy))
                                    .foregroundStyle(GWTheme.gold)
                                    .frame(width: 18, alignment: .center)
                                    .padding(.top, 1)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(title)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(GWTheme.textPrimary)
                                    Text(detail)
                                        .font(.system(size: 12))
                                        .foregroundStyle(GWTheme.textMuted)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        rowHeader(title: "Weekly Planning", trailing: isWeeklyPlanningWindow ? "Fri/Sun" : "Preview")

                        Text(isWeeklyPlanningWindow
                             ? "Weekly mode is active: align appointments, top 3 goals, and macro dump."
                             : "Weekly mode is designed for Friday/Sunday resets. You can still draft it now.")
                            .font(.system(size: 12))
                            .foregroundStyle(GWTheme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)

                        ForEach(Array(store.weeklyTopGoals.enumerated()), id: \.offset) { index, goal in
                            TextField(
                                "Weekly top goal #\(index + 1)",
                                text: Binding(
                                    get: { goal },
                                    set: { store.setWeeklyTopGoal(index: index, text: $0) }
                                )
                            )
                            .focused($focusedField, equals: .weeklyGoal(index))
                            .submitLabel(.done)
                            .onSubmit { dismissKeyboard() }
                            .font(.system(size: 12))
                            .foregroundStyle(GWTheme.textMuted)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        Text("Macro dump")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(GWTheme.textGhost)
                            .textCase(.uppercase)

                        TextField("Brain dump anything relevant to the week...", text: Binding(
                            get: { store.weeklyMacroDump },
                            set: { store.setWeeklyMacroDump($0) }
                        ), axis: .vertical)
                        .focused($focusedField, equals: .weeklyMacro)
                        .submitLabel(.done)
                        .onSubmit { dismissKeyboard() }
                        .font(.system(size: 12))
                        .foregroundStyle(GWTheme.textMuted)
                        .lineLimit(4...)
                        .textFieldStyle(.plain)
                        .frame(minHeight: 88, alignment: .topLeading)
                        .padding(10)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        rowHeader(title: "Today's Appointments", trailing: "\(planningDayAppointments.count)")

                        if planningDayAppointments.isEmpty {
                            Text("No scheduled appointments yet. Use Schedule in Shape to place an item on your timeline.")
                                .font(.system(size: 11))
                                .foregroundStyle(GWTheme.textGhost)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            ForEach(planningDayAppointments) { appointment in
                                HStack(spacing: 10) {
                                    Text(appointment.code)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(GWTheme.gold)
                                        .frame(width: 28, alignment: .leading)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(appointment.text)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(GWTheme.textMuted)
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)

                                        Text(formatAppointmentTime(appointment.scheduledAtISO))
                                            .font(.system(size: 10))
                                            .foregroundStyle(GWTheme.textGhost)
                                    }

                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        rowHeader(title: "Daily Planner", trailing: formattedPlanningDay())

                        DatePicker("Daily Planner", selection: planningDayBinding, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                            .tint(GWTheme.gold)

                        Text("Drag tasks from Task Pool onto a time block. Use Move Day to reschedule without assigning a time.")
                            .font(.system(size: 11))
                            .foregroundStyle(GWTheme.textGhost)

                        if store.googleCalendarConnected {
                            if isAutoSyncingCalendar {
                                Text("Syncing linked calendars...")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(GWTheme.textGhost)
                            }

                            if shouldShowCalendarErrorBanner {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(Color(hex: "c07060"))

                                        Text(calendarBannerMessage)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(Color(hex: "c07060"))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    HStack(spacing: 10) {
                                        Button(isRetryingCalendarSync ? "Retrying..." : "Retry Sync") {
                                            Task { await retryCalendarSyncFromBanner() }
                                        }
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Color(hex: "1a1208"))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(GWTheme.gold)
                                        .clipShape(Capsule())
                                        .buttonStyle(.plain)
                                        .disabled(isRetryingCalendarSync)

                                        Button("Dismiss") {
                                            hideCalendarErrorBannerForSession = true
                                        }
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(GWTheme.textMuted)
                                        .buttonStyle(.plain)

                                        Spacer()
                                    }
                                }
                                .padding(10)
                                .background(Color(hex: "c07060").opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            if let lastSync = formattedLastCalendarSync {
                                Text("Last synced \(lastSync)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(GWTheme.textGhost)
                            }

                            if store.googleCalendarLastPulledEventCount > 0 {
                                Text("Linked calendar events loaded: \(store.googleCalendarLastPulledEventCount)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color(hex: "5ca06d"))
                            }
                        }

                        if !scheduledOutsideVisibleHours.isEmpty {
                            Text("\(scheduledOutsideVisibleHours.count) scheduled task\(scheduledOutsideVisibleHours.count == 1 ? " is" : "s are") outside your visible planner hours. Adjust Daily Planner hour range in Settings to view them.")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(GWTheme.gold)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        ForEach(timelineSlots, id: \.self) { slot in
                            timelineSlotRow(slot: slot)
                        }

                        HStack(spacing: 10) {
                            Image(systemName: unresolvedPlanningCount == 0 ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(unresolvedPlanningCount == 0 ? GWTheme.gold : Color(hex: "c07060"))

                            Text(unresolvedPlanningCount == 0
                                 ? "All items are assigned. You can start your day."
                                 : "\(unresolvedPlanningCount) item\(unresolvedPlanningCount == 1 ? "" : "s") still need disposition before start.")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(unresolvedPlanningCount == 0 ? GWTheme.textMuted : Color(hex: "c07060"))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Button("Start Day") {
                            reminderStatus = "Day started. Stay in flow."
                            GWHaptics.success()
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "1a1208"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(unresolvedPlanningCount == 0 ? GWTheme.gold : Color.gray.opacity(0.35))
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                        .disabled(unresolvedPlanningCount != 0)
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        rowHeader(title: "Task Pool", trailing: "\(unscheduledTaskPool.count + unfilteredPileItems.count)")

                        if unscheduledTaskPool.isEmpty && unfilteredPileItems.isEmpty {
                            Text("No unscheduled tasks for this day.")
                                .font(.system(size: 11))
                                .foregroundStyle(GWTheme.textGhost)
                        } else {
                            Text("Work")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(GWTheme.textGhost)
                                .textCase(.uppercase)

                            ForEach(unfilteredWorkItems) { item in
                                HStack(spacing: 10) {
                                    dragHandle

                                    if item.carriedOver == true {
                                        Text("Carried")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(Color(hex: "1a1208"))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(GWTheme.gold.opacity(0.85))
                                            .clipShape(Capsule())
                                    }

                                    Text(item.text)
                                        .font(.system(size: 12))
                                        .foregroundStyle(GWTheme.textMuted)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)

                                    Spacer()
                                }
                                .padding(.vertical, 2)
                                .draggable("dump:\(item.id.uuidString)")
                            }

                            ForEach(unscheduledWorkTasks) { task in
                                HStack(spacing: 10) {
                                    dragHandle

                                    Text(task.code)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(GWTheme.gold)
                                        .frame(width: 28, alignment: .leading)

                                    Text(task.text)
                                        .font(.system(size: 12))
                                        .foregroundStyle(task.time == nil ? GWTheme.textMuted : GWTheme.textGhost)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)

                                    if task.carriedOver {
                                        Text("Carried")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(Color(hex: "1a1208"))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(GWTheme.gold.opacity(0.85))
                                            .clipShape(Capsule())
                                    }

                                    Spacer()

                                    Menu {
                                        DatePicker("Move to Day", selection: Binding(
                                            get: { planningDay },
                                            set: { store.moveTaskToDay(task.id, day: $0) }
                                        ), displayedComponents: [.date])
                                    } label: {
                                        Text("Move Day")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundStyle(GWTheme.textGhost)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 4)
                                .draggable("task:\(task.id.uuidString)")
                                .contextMenu {
                                    Button("Add to Big 3 #1") { assignTask(task, toBig3Slot: 0) }
                                    Button("Add to Big 3 #2") { assignTask(task, toBig3Slot: 1) }
                                    Button("Add to Big 3 #3") { assignTask(task, toBig3Slot: 2) }
                                }
                            }

                            Text("Personal")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(GWTheme.textGhost)
                                .textCase(.uppercase)

                            ForEach(unfilteredPersonalItems) { item in
                                HStack(spacing: 10) {
                                    dragHandle

                                    if item.carriedOver == true {
                                        Text("Carried")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(Color(hex: "1a1208"))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(GWTheme.gold.opacity(0.85))
                                            .clipShape(Capsule())
                                    }

                                    Text(item.text)
                                        .font(.system(size: 12))
                                        .foregroundStyle(GWTheme.textMuted)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)

                                    Spacer()
                                }
                                .padding(.vertical, 2)
                                .draggable("dump:\(item.id.uuidString)")
                            }

                            ForEach(unscheduledPersonalTasks) { task in
                                HStack(spacing: 10) {
                                    dragHandle

                                    Text(task.code)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(GWTheme.gold)
                                        .frame(width: 28, alignment: .leading)

                                    Text(task.text)
                                        .font(.system(size: 12))
                                        .foregroundStyle(task.time == nil ? GWTheme.textMuted : GWTheme.textGhost)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)

                                    if task.carriedOver {
                                        Text("Carried")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(Color(hex: "1a1208"))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(GWTheme.gold.opacity(0.85))
                                            .clipShape(Capsule())
                                    }

                                    Spacer()

                                    Menu {
                                        DatePicker("Move to Day", selection: Binding(
                                            get: { planningDay },
                                            set: { store.moveTaskToDay(task.id, day: $0) }
                                        ), displayedComponents: [.date])
                                    } label: {
                                        Text("Move Day")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundStyle(GWTheme.textGhost)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 4)
                                .draggable("task:\(task.id.uuidString)")
                                .contextMenu {
                                    Button("Add to Big 3 #1") { assignTask(task, toBig3Slot: 0) }
                                    Button("Add to Big 3 #2") { assignTask(task, toBig3Slot: 1) }
                                    Button("Add to Big 3 #3") { assignTask(task, toBig3Slot: 2) }
                                }
                            }

                            if !delegatedDumpItems.isEmpty {
                                Text("Delegated")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(GWTheme.textGhost)
                                    .textCase(.uppercase)
                                    .padding(.top, 4)

                                ForEach(delegatedDumpItems) { item in
                                    let followUp = store.delegatedFollowUps.first(where: { $0.taskText == item.text })
                                    HStack(spacing: 10) {
                                        Image(systemName: "arrow.forward.circle")
                                            .font(.system(size: 12))
                                            .foregroundStyle(GWTheme.gold.opacity(0.7))

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.text)
                                                .font(.system(size: 12))
                                                .foregroundStyle(GWTheme.textMuted)
                                                .lineLimit(nil)
                                                .fixedSize(horizontal: false, vertical: true)

                                            if let fu = followUp, !fu.assignee.isEmpty {
                                                Text("→ \(fu.assignee)")
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundStyle(GWTheme.gold.opacity(0.75))
                                            }
                                        }

                                        Spacer()

                                        Text("Delegated")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(GWTheme.gold.opacity(0.8))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(GWTheme.gold.opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Alerts")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(GWTheme.textGhost)
                            .textCase(.uppercase)

                        Text("Enable reminders and choose lead time from App Settings.")
                            .font(.system(size: 11))
                            .foregroundStyle(GWTheme.textGhost)

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

                rowHeader(title: "Daily Big 3", trailing: "\(doneCount)/3") {
                    showBig3Help = true
                }
                Text("These are your non-negotiables for today. Check them off as completed.")
                    .font(.system(size: 12))
                    .foregroundStyle(GWTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)

                if big3PoolChoices.isEmpty {
                    Text("No tasks available for Daily Big 3 yet. Add items from the Task Pool first.")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(GWTheme.gold)
                        .fixedSize(horizontal: false, vertical: true)
                }

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

                        VStack(alignment: .leading, spacing: 8) {
                            Menu {
                                if big3PoolChoices.isEmpty {
                                    Text("No pool items available")
                                } else {
                                    ForEach(big3PoolChoices) { choice in
                                        Button(choice.label) {
                                            applyBig3PoolChoice(choice, big3Id: item.id)
                                        }
                                    }
                                }
                            } label: {
                                Label("Pick from Task Pool", systemImage: "list.bullet.clipboard")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(GWTheme.gold)
                            }
                            .buttonStyle(.plain)
                            .disabled(big3PoolChoices.isEmpty)

                            TextField(
                                "Big 3 focus (or type custom)",
                                text: Binding(
                                    get: { item.text },
                                    set: { store.setBig3Text(id: item.id, text: $0) }
                                )
                            )
                            .focused($focusedField, equals: .big3(item.id))
                            .submitLabel(.done)
                            .onSubmit {
                                dismissKeyboard()
                            }
                            .font(.system(size: 13))
                            .foregroundStyle(item.done ? GWTheme.textGhost : GWTheme.textMuted)
                            .strikethrough(item.done)

                            if item.done {
                                Text("Completed")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color(hex: "1a1208"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(GWTheme.gold.opacity(0.75))
                                    .clipShape(Capsule())
                            }
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(item.done ? GWTheme.gold.opacity(0.55) : Color.white.opacity(0.07), lineWidth: item.done ? 1.4 : 1)
                    }
                }

                rowHeader(title: "Work", trailing: "↓") {
                    showRatingHelp = true
                }
                Text("Tasks tied to output, clients, and deadlines.")
                    .font(.system(size: 12))
                    .foregroundStyle(GWTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(store.workTasks) { task in
                    taskRow(task: task, codeColor: GWTheme.gold)
                }

                rowHeader(title: "Personal", trailing: "↑") {
                    showRatingHelp = true
                }
                Text("Tasks that protect relationships, health, and life rhythms.")
                    .font(.system(size: 12))
                    .foregroundStyle(GWTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(store.personalTasks) { task in
                    taskRow(task: task, codeColor: Color(hex: "907050"))
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        rowHeader(title: "Carryover History", trailing: "\(carryoverHistory.count)")

                        if carryoverHistory.isEmpty {
                            Text("No carryover history yet.")
                                .font(.system(size: 11))
                                .foregroundStyle(GWTheme.textGhost)
                        } else {
                            ForEach(carryoverHistory.prefix(5), id: \.0) { day, items in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(day) • \(items.count) item\(items.count == 1 ? "" : "s")")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(GWTheme.gold)

                                    ForEach(items.prefix(2)) { item in
                                        Text("• \(item.text)")
                                            .font(.system(size: 11))
                                            .foregroundStyle(GWTheme.textMuted)
                                            .lineLimit(2)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("What success looks like")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(GWTheme.textGhost)
                            .textCase(.uppercase)

                        Text("By end of day: Big 3 completed, key tasks scheduled, reminders set, carryovers reviewed.")
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
        .alert("Daily Big 3", isPresented: $showBig3Help) {
            Button("Got it", role: .cancel) {}
        } message: {
            Text("Pick from Task Pool or type your own custom Big 3 focus manually in each field.")
        }
        .alert("Task Codes", isPresented: $showRatingHelp) {
            Button("Got it", role: .cancel) {}
        } message: {
            Text("W and P codes are auto-generated task IDs. They help index tasks quickly and are not manual priority inputs.")
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    dismissKeyboard()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GWTheme.gold)
                .padding(.vertical, 6)
            }
        }
        .task(id: planningDayISO) {
            await runCalendarAutoSyncIfNeeded()
        }
        .onChange(of: store.googleCalendarLastError) { _, newValue in
            if newValue == nil || newValue?.isEmpty == true {
                hideCalendarErrorBannerForSession = false
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Today")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(GWTheme.textMuted)
            Text("Fill It")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(GWTheme.textPrimary)
            Text("Sync your calendar, then assign each task to a time (drag and drop).")
                .font(.system(size: 13))
                .foregroundStyle(GWTheme.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func rowHeader(title: String, trailing: String, helpAction: (() -> Void)? = nil) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(GWTheme.textGhost)
                .textCase(.uppercase)
            if let helpAction {
                Button(action: helpAction) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(GWTheme.gold.opacity(0.85))
                }
                .buttonStyle(.plain)
            }
            Spacer()
            Text(trailing)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(GWTheme.gold)
        }
        .padding(.top, 4)
    }

    private var dragHandle: some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(GWTheme.textMuted)
            .frame(width: 40, height: 40)
            .contentShape(Rectangle())
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var dualExecutionProgressBar: some View {
        GeometryReader { geo in
            let halfWidth = geo.size.width / 2

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))

                HStack(spacing: 0) {
                    Capsule()
                        .fill(GWTheme.gold)
                        .frame(width: halfWidth * big3CompletionRatio)

                    Capsule()
                        .fill(Color(hex: "5ca06d"))
                        .frame(width: halfWidth * scheduledTaskCompletionRatio)

                    Spacer(minLength: 0)
                }
            }
        }
        .frame(height: 12)
        .overlay(alignment: .bottomLeading) {
            HStack(spacing: 12) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(GWTheme.gold)
                        .frame(width: 6, height: 6)
                    Text("Big 3")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(GWTheme.textMuted)
                }

                HStack(spacing: 5) {
                    Circle()
                        .fill(Color(hex: "5ca06d"))
                        .frame(width: 6, height: 6)
                    Text("Tasks")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(GWTheme.textMuted)
                }
            }
            .padding(.top, 16)
        }
        .padding(.bottom, 14)
    }

    private func taskRow(task: TaskItem, codeColor: Color) -> some View {
        HStack(spacing: 10) {
            Button {
                store.toggleTaskCompleted(task.id)
            } label: {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.completed ? GWTheme.gold : GWTheme.textGhost)
            }
            .buttonStyle(.plain)

            Text(task.code)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(codeColor)
                .frame(width: 28, alignment: .leading)

            Text(task.text)
                .font(.system(size: 13))
                .foregroundStyle(task.completed ? GWTheme.textGhost : GWTheme.textMuted)
                .strikethrough(task.completed)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            if task.carriedOver {
                Text("Carried")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color(hex: "1a1208"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(GWTheme.gold.opacity(0.85))
                    .clipShape(Capsule())
            }
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
        .padding(.horizontal, 8)
        .background(task.completed ? GWTheme.gold.opacity(0.12) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func timelineSlotRow(slot: String) -> some View {
        let scheduled = store.tasksScheduled(for: planningDay, at: slot)
        let syncedEvents = syncedEventsForSlot(slot)

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text(slot)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(GWTheme.gold)
                    .frame(width: 58, alignment: .leading)

                Text((scheduled.isEmpty && syncedEvents.isEmpty)
                     ? "Drop task here"
                     : "\(scheduled.count) task\(scheduled.count == 1 ? "" : "s") · \(syncedEvents.count) event\(syncedEvents.count == 1 ? "" : "s")")
                    .font(.system(size: 11))
                    .foregroundStyle((scheduled.isEmpty && syncedEvents.isEmpty) ? GWTheme.textGhost : GWTheme.textMuted)

                Spacer()
            }

            if !scheduled.isEmpty {
                ForEach(Array(scheduled.enumerated()), id: \.element.id) { index, task in
                    HStack(spacing: 8) {
                        Button {
                            store.toggleTaskCompleted(task.id)
                        } label: {
                            Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(task.completed ? GWTheme.gold : GWTheme.textGhost)
                        }
                        .buttonStyle(.plain)

                        Text(task.code)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(GWTheme.gold)
                            .frame(width: 28, alignment: .leading)

                        Text(task.text)
                            .font(.system(size: 11))
                            .foregroundStyle(task.completed ? GWTheme.textGhost : GWTheme.textMuted)
                            .strikethrough(task.completed)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()

                        HStack(spacing: 3) {
                            Button {
                                store.moveScheduledTaskWithinSlot(task.id, day: planningDay, time: slot, direction: -1)
                            } label: {
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(index == 0 ? GWTheme.textGhost.opacity(0.45) : GWTheme.textGhost)
                            .disabled(index == 0)

                            Button {
                                store.moveScheduledTaskWithinSlot(task.id, day: planningDay, time: slot, direction: 1)
                            } label: {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(index == scheduled.count - 1 ? GWTheme.textGhost.opacity(0.45) : GWTheme.textGhost)
                            .disabled(index == scheduled.count - 1)
                        }
                        .padding(.trailing, 3)

                        Button("Clear") {
                            store.unscheduleTask(task.id)
                        }
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(GWTheme.textGhost)
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 4)
                    .background(task.completed ? GWTheme.gold.opacity(0.13) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            if !syncedEvents.isEmpty {
                ForEach(syncedEvents) { event in
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color(hex: "5ca06d"))

                        Text(event.title)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: "9bc4a6"))
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()

                        Text(event.allDay ? "All day" : "Google")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(hex: "5ca06d"))
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 4)
                    .background(Color(hex: "5ca06d").opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(GWTheme.gold.opacity(targetedDropSlot == slot ? 0.9 : 0), lineWidth: 1.5)
        }
        .onDrop(of: [UTType.plainText.identifier], isTargeted: Binding(
            get: { targetedDropSlot == slot },
            set: { isTargeted in
                targetedDropSlot = isTargeted ? slot : (targetedDropSlot == slot ? nil : targetedDropSlot)
            }
        )) { providers in
            guard let provider = providers.first else { return false }

            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                guard let payload = droppedPayloadString(item) else { return }

                DispatchQueue.main.async {
                    if applyDroppedPayload(payload, slot: slot) {
                        GWHaptics.medium()
                    }
                }
            }

            return true
        }
    }

    // Parses ISO 8601 strings including those with fractional seconds (e.g. .000Z)
    // returned by the Vercel sync endpoint.
    private func parseISO(_ iso: String) -> Date? {
        let plain = ISO8601DateFormatter()
        if let d = plain.date(from: iso) { return d }
        let frac = ISO8601DateFormatter()
        frac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return frac.date(from: iso)
    }

    private func syncedEventsForSlot(_ slot: String) -> [SyncedCalendarEvent] {
        let plannedDayISO = planningDayISO
        return store.syncedCalendarEvents
            .filter { event in
                if event.allDay {
                    // All-day events: use raw date prefix to avoid timezone day shifts.
                    let rawDate = String((event.startAtISO ?? "").prefix(10))
                    return slot == "All Day" && rawDate == plannedDayISO
                }

                guard let startISO = event.startAtISO,
                      let date = parseISO(startISO) else {
                    return false
                }

                return dayISO(from: startISO) == plannedDayISO && hourLabel(Calendar.current.component(.hour, from: date)) == slot
            }
            .sorted { lhs, rhs in
                (lhs.startAtISO ?? "") < (rhs.startAtISO ?? "")
            }
    }

    private func dayISO(from iso: String?) -> String? {
        guard let iso, let date = parseISO(iso) else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func runCalendarAutoSyncIfNeeded() async {
        // Only skip if not connected or already syncing.
        // Do NOT gate on hasGoogleCalendarAccessToken — syncGoogleCalendarNow calls
        // validGoogleCalendarAccessToken which silently refreshes using the refresh token
        // when the access token is expired or missing. Short-circuiting here would block
        // that silent refresh path and force the user to reconnect unnecessarily.
        guard store.googleCalendarConnected,
              !isAutoSyncingCalendar else { return }

        let shouldSync: Bool
        if let lastSyncISO = store.lastCalendarSyncISO,
           let lastSync = ISO8601DateFormatter().date(from: lastSyncISO) {
            shouldSync = Date().timeIntervalSince(lastSync) > (15 * 60)
        } else {
            shouldSync = true
        }

        guard shouldSync else { return }

        await MainActor.run {
            isAutoSyncingCalendar = true
        }
        _ = await store.syncGoogleCalendarNow()
        await MainActor.run {
            isAutoSyncingCalendar = false
        }
    }

    private var shouldShowCalendarErrorBanner: Bool {
        guard !hideCalendarErrorBannerForSession,
              let calendarError = store.googleCalendarLastError,
              !calendarError.isEmpty else {
            return false
        }
        return true
    }

    private var calendarBannerMessage: String {
        let lowercasedError = (store.googleCalendarLastError ?? "").lowercased()
        // "Reconnect" language should only appear when BOTH tokens are gone (error 1007)
        // or when the refresh token itself has been revoked. Token refresh failures due to
        // expiry are handled silently by validGoogleCalendarAccessToken before we reach here.
        let needsFullReconnect = lowercasedError.contains("no refresh token") ||
            lowercasedError.contains("reconnect your calendar") ||
            (lowercasedError.contains("401") && lowercasedError.contains("refresh"))
        if needsFullReconnect {
            return "Calendar connection needs renewal. Open Calendar Settings to reconnect."
        }

        if !store.syncedCalendarEvents.isEmpty {
            return "Calendar sync unavailable. Showing cached events. Tap Retry Sync to refresh."
        }

        return "Calendar sync unavailable. You can keep planning and retry when ready."
    }

    private var formattedLastCalendarSync: String? {
        guard let iso = store.lastCalendarSyncISO,
              let date = ISO8601DateFormatter().date(from: iso) else {
            return nil
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func retryCalendarSyncFromBanner() async {
        guard !isRetryingCalendarSync else { return }

        await MainActor.run {
            isRetryingCalendarSync = true
        }
        _ = await store.syncGoogleCalendarNow()
        await MainActor.run {
            isRetryingCalendarSync = false
        }
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

    private func formatAppointmentTime(_ iso: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        guard let date = isoFormatter.date(from: iso) else { return "Scheduled" }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func assignTask(_ task: TaskItem, toBig3Slot slot: Int) {
        guard store.big3.indices.contains(slot) else { return }
        store.setBig3FromTask(id: store.big3[slot].id, taskId: task.id)
    }

    private func applyBig3PoolChoice(_ choice: Big3PoolChoice, big3Id: UUID) {
        if let taskId = choice.taskId {
            store.setBig3FromTask(id: big3Id, taskId: taskId)
        } else if let dumpId = choice.dumpItemId,
                  let dumpItem = unfilteredPileItems.first(where: { $0.id == dumpId }) {
            store.setBig3Text(id: big3Id, text: dumpItem.text)
        }
        dismissKeyboard()
    }

    private func dismissKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func droppedPayloadString(_ item: NSSecureCoding?) -> String? {
        if let text = item as? String {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let data = item as? Data,
           let text = String(data: data, encoding: .utf8) {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return nil
    }

    private func applyDroppedPayload(_ payload: String, slot: String) -> Bool {
        guard !payload.isEmpty else { return false }

        if payload.hasPrefix("dump:") {
            let raw = String(payload.dropFirst(5))
            guard let dumpId = UUID(uuidString: raw) else { return false }
            store.scheduleDumpItemOnTimeline(dumpId, day: planningDay, time: slot)
            return true
        }

        if payload.hasPrefix("task:") {
            let raw = String(payload.dropFirst(5))
            guard let taskId = UUID(uuidString: raw) else { return false }
            store.scheduleTaskOnTimeline(taskId, day: planningDay, time: slot)
            return true
        }

        guard let taskId = UUID(uuidString: payload) else { return false }
        store.scheduleTaskOnTimeline(taskId, day: planningDay, time: slot)
        return true
    }

    private func formattedPlanningDay() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d"
        return formatter.string(from: planningDay)
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
}
