import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

extension Notification.Name {
    static let genesisOpenFillFromReminder = Notification.Name("genesisOpenFillFromReminder")
}

final class GenesisStore: ObservableObject {
    @Published private(set) var state: GenesisState {
        didSet { persist() }
    }
    @Published private(set) var guidedSetupLaunchToken = UUID()
    private var reminderTapObserver: NSObjectProtocol?

    private let storageKey = "genesis-way-ios-v1"
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
    var remindersEnabled: Bool { state.remindersEnabled }
    var reminderLeadMinutes: Int { state.reminderLeadMinutes }
    var big3: [Big3Item] { state.big3 }
    var shapedDumpItems: [DumpItem] {
        pendingPileItems
    }
    var pendingPileItems: [DumpItem] {
        pendingPileItems(for: Date())
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
    var hasUnreadyShapeItems: Bool {
        let todayISO = Self.todayDayISO()
        return state.dumpItems.contains { item in
            let outcome = item.filterOutcome ?? .pending
            let dayISO = item.planningDayISO ?? todayISO
            return outcome == .pending && dayISO == todayISO && item.lane == nil
        }
    }

    func beginJourney() { state.screen = .dump }
    func skipToPlanner() { state.screen = .fill }

    func setShowIntroOnLaunch(_ enabled: Bool) {
        state.showIntroOnLaunch = enabled
    }

    func setRemindersEnabled(_ enabled: Bool) {
        state.remindersEnabled = enabled
    }

    func setReminderLeadMinutes(_ minutes: Int) {
        state.reminderLeadMinutes = minutes
    }

    func setMorningPlanningReminderEnabled(_ enabled: Bool) {
        state.morningPlanningReminderEnabled = enabled
        state.hasConfiguredDailyFlowReminders = true
        Task { await scheduleDailyFlowRemindersIfNeeded() }
    }

    func setMorningPlanningReminderTime(_ time: String) {
        state.morningPlanningReminderTime = time
        state.hasConfiguredDailyFlowReminders = true
        Task { await scheduleDailyFlowRemindersIfNeeded() }
    }

    func setEveningPlanningReminderEnabled(_ enabled: Bool) {
        state.eveningPlanningReminderEnabled = enabled
        state.hasConfiguredDailyFlowReminders = true
        Task { await scheduleDailyFlowRemindersIfNeeded() }
    }

    func setEveningPlanningReminderTime(_ time: String) {
        state.eveningPlanningReminderTime = time
        state.hasConfiguredDailyFlowReminders = true
        Task { await scheduleDailyFlowRemindersIfNeeded() }
    }

    func markDailyFlowRemindersConfigured() {
        state.hasConfiguredDailyFlowReminders = true
        Task { await scheduleDailyFlowRemindersIfNeeded() }
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
    }

    func setAppleIcsEnabled(_ enabled: Bool) {
        state.appleIcsEnabled = enabled
    }

    func markCalendarSyncedNow() {
        state.lastCalendarSyncISO = ISO8601DateFormatter().string(from: Date())
    }

    func resetAllUserData() {
        state = .initial
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
