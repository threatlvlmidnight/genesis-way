import SwiftUI
import EventKit
import EventKitUI
#if canImport(UIKit)
import UIKit
#endif

private enum ScheduleMoveMode: String, Hashable { case appointment, day }
private enum AutomateMode: String, Hashable { case custom, loop }

struct ShapeScreen: View {
    @EnvironmentObject private var store: GenesisStore
    @State private var scheduleOrMoveTargetItem: DumpItem?
    @State private var scheduleOrMoveMode: ScheduleMoveMode = .appointment
    @State private var scheduleOrMoveDateTime = Date()
    @State private var scheduleOrMoveDayDate = Date()
    @State private var automateTargetItem: DumpItem?
    @State private var automateMode: AutomateMode = .loop
    @State private var automateNote = ""
    @State private var automateLoopText = ""
    @State private var automateLoopLane = "unassigned"
    @State private var automateLoopRecurrenceType: LoopRecurrenceType = .daily
    @State private var automateLoopWeekdays: Set<Int> = []
    @State private var automateLoopDurationType: LoopDurationType = .forever
    @State private var automateLoopFixedCount = 4
    @State private var delegateTargetItem: DumpItem?
    @State private var lastActionItemId: UUID?
    @State private var jamTargetItem: DumpItem?
    @State private var calendarExportDraft: CalendarExportDraft?
    @State private var calendarHandoffStatus = ""

    private var pendingItems: [DumpItem] {
        store.pendingPileItems
    }

    private var activePlanningDay: Date {
        store.activePlanningDay
    }

    private var activeDayDumpItemCount: Int {
        store.dumpItems(for: activePlanningDay).count
    }

    private var activePlanningDayLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateStyle = .medium
        return formatter.string(from: activePlanningDay)
    }

    private var readyPendingCount: Int {
        pendingItems.filter { $0.lane != nil }.count
    }

    private var unreadyPendingCount: Int {
        pendingItems.count - readyPendingCount
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How Shape It Works")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(GWTheme.textPrimary)

                        Text("Finish your day on paper before the day begins. Quickly tag each item as Work or Personal, then run each item through one filter: Eliminate, Automate, Delegate, Schedule, or Park.")
                            .font(.system(size: 13))
                            .foregroundStyle(GWTheme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Choose Work for output, deadlines, and obligations. Choose Personal for home, health, and relationship tasks.")
                            .font(.system(size: 12))
                            .foregroundStyle(GWTheme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Two lanes are intentionally enough: they keep Fill fast and force a clear decision instead of endless categorizing.")
                            .font(.system(size: 12))
                            .foregroundStyle(GWTheme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Text("Dump to Process")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(GWTheme.textMuted)
                    .textCase(.uppercase)

                Text("Viewing \(activePlanningDayLabel)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(GWTheme.gold)

                if pendingItems.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No pending dump items for this day.")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(GWTheme.textPrimary)

                            if activeDayDumpItemCount > 0 {
                                Text("Dump has \(activeDayDumpItemCount) item\(activeDayDumpItemCount == 1 ? "" : "s") for \(activePlanningDayLabel), but none are pending for Shape. They may already be scheduled, delegated, parked, eliminated, or promoted into Fill tasks.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(GWTheme.textMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                            } else {
                                Text("Add items in Dump for \(activePlanningDayLabel), then return here to shape them.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(GWTheme.textMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                } else {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                Image(systemName: unreadyPendingCount == 0 ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                    .foregroundStyle(unreadyPendingCount == 0 ? GWTheme.gold : Color(hex: "c07060"))

                                Text(unreadyPendingCount == 0
                                      ? "All pending items are ready, click Fill below."
                                     : "\(unreadyPendingCount) item\(unreadyPendingCount == 1 ? "" : "s") still need Work/Personal lane selection.")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(unreadyPendingCount == 0 ? GWTheme.textMuted : Color(hex: "c07060"))
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            ProgressView(value: Double(readyPendingCount), total: Double(max(pendingItems.count, 1)))
                                .tint(unreadyPendingCount == 0 ? GWTheme.gold : Color(hex: "c07060"))

                            Text("Ready: \(readyPendingCount)/\(pendingItems.count)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(unreadyPendingCount == 0 ? GWTheme.gold : GWTheme.textMuted)
                        }
                    }

                    VStack(spacing: 14) {
                        ForEach(pendingItems) { item in
                            GlassCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(item.text)
                                        .font(.system(size: 13))
                                        .foregroundStyle(GWTheme.textPrimary)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)

                                    if store.isLikelyOversizedDumpItem(item.id) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "scissors")
                                                .foregroundStyle(GWTheme.gold)
                                            Text("Likely oversized. Split into thin 15-30 min slices.")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundStyle(GWTheme.textGhost)
                                            Spacer()
                                            Button("Jam") {
                                                jamTargetItem = item
                                            }
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(Color(hex: "1a1208"))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 6)
                                            .background(GWTheme.gold)
                                            .clipShape(Capsule())
                                            .buttonStyle(.plain)
                                        }
                                        .padding(8)
                                        .background(GWTheme.gold.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }

                                    HStack(spacing: 8) {
                                        laneButton("Work", lane: .work, selectedLane: item.lane) {
                                            store.assignDumpItemLane(item.id, lane: .work)
                                            GWHaptics.light()
                                        }

                                        laneButton("Personal", lane: .personal, selectedLane: item.lane) {
                                            store.assignDumpItemLane(item.id, lane: .personal)
                                            GWHaptics.light()
                                        }
                                    }

                                    LazyVGrid(
                                        columns: [
                                            GridItem(.flexible(minimum: 88), spacing: 8),
                                            GridItem(.flexible(minimum: 88), spacing: 8),
                                            GridItem(.flexible(minimum: 88), spacing: 8)
                                        ],
                                        alignment: .leading,
                                        spacing: 8
                                    ) {
                                        filterButton("Eliminate", isActive: false, isDestructive: true) {
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                                lastActionItemId = item.id
                                                store.applyFilterOutcome(item.id, outcome: .eliminated)
                                            }
                                            GWHaptics.warning()
                                        }

                                        filterButton("Automate", isActive: lastActionItemId == item.id && automateTargetItem?.id == item.id) {
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                                lastActionItemId = item.id
                                                automateMode = .loop
                                                automateNote = ""
                                                automateLoopText = item.text
                                                automateLoopLane = item.lane?.rawValue ?? "unassigned"
                                                let weekday = Calendar.current.component(.weekday, from: Date())
                                                automateLoopWeekdays = [weekday]
                                                automateLoopRecurrenceType = .daily
                                                automateLoopDurationType = .forever
                                                automateLoopFixedCount = 4
                                                automateTargetItem = item
                                            }
                                            GWHaptics.medium()
                                        }

                                        filterButton("Delegate", isActive: false) {
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                                lastActionItemId = item.id
                                                delegateTargetItem = item
                                            }
                                            GWHaptics.medium()
                                        }

                                        filterButton("Schedule", isActive: lastActionItemId == item.id && scheduleOrMoveTargetItem?.id == item.id) {
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                                lastActionItemId = item.id
                                                scheduleOrMoveMode = .day
                                                scheduleOrMoveDateTime = Date()
                                                scheduleOrMoveDayDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                                                scheduleOrMoveTargetItem = item
                                            }
                                            GWHaptics.medium()
                                        }

                                        filterButton("Park", isActive: false, isDestructive: true) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                                                lastActionItemId = item.id
                                                store.applyFilterOutcome(item.id, outcome: .parked)
                                            }
                                            GWHaptics.warning()
                                        }
                                    }
                                }
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(item.lane == nil ? Color(hex: "c07060") : Color(hex: "5ca06d"), lineWidth: 1.5)
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(GWTheme.background.ignoresSafeArea())
        .sheet(item: $scheduleOrMoveTargetItem) { item in
            scheduleOrMoveSheet(item: item)
        }
        .sheet(item: $automateTargetItem) { item in
            automateSheet(item: item)
        }
        .sheet(isPresented: Binding(
            get: { delegateTargetItem != nil },
            set: { showing in
                if !showing {
                    delegateTargetItem = nil
                }
            }
        )) {
            if let delegateTargetItem {
                DelegateScreen(dumpItemId: delegateTargetItem.id, taskText: delegateTargetItem.text)
                .environmentObject(store)
            }
        }
        .sheet(item: $calendarExportDraft) { draft in
            CalendarEventComposerSheet(draft: draft) { message in
                calendarHandoffStatus = message
            }
        }
        .alert("Create Jam Session?", isPresented: Binding(
            get: { jamTargetItem != nil },
            set: { showing in
                if !showing {
                    jamTargetItem = nil
                }
            }
        )) {
            Button("Cancel", role: .cancel) {}
            Button("Create", role: .none) {
                if let target = jamTargetItem {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                        store.createJamSessionForDumpItem(target.id)
                    }
                    GWHaptics.success()
                }
                jamTargetItem = nil
            }
        } message: {
            Text("This will move the current item forward and create a 'Jam Session' refinement item in tomorrow's dump.")
        }
    }

    private func scheduleOrMoveSheet(item: DumpItem) -> some View {
        NavigationStack {
            Form {
                Section {
                    Picker("", selection: $scheduleOrMoveMode) {
                        Text("Move").tag(ScheduleMoveMode.day)
                        Text("Schedule").tag(ScheduleMoveMode.appointment)
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                }
                if scheduleOrMoveMode == .appointment {
                    Section("Appointment Date & Time") {
                        DatePicker("When", selection: $scheduleOrMoveDateTime, displayedComponents: [.date, .hourAndMinute])
                    }
                    previewSection(for: scheduleOrMoveDateTime, includeTimeBlocks: true)
                } else {
                    Section("Move to Day") {
                        DatePicker("Day", selection: $scheduleOrMoveDayDate, displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                    }
                    previewSection(for: scheduleOrMoveDayDate, includeTimeBlocks: false)
                }
                Section {
                    Text(item.text)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if scheduleOrMoveMode == .appointment {
                    Section("Calendar Handoff") {
                        Button("Export to Calendar") {
                            scheduleItemAndPrepareCalendarExport(item)
                        }
                        .foregroundStyle(GWTheme.gold)

                        Button("Open Calendar") {
                            scheduleItemAndOpenCalendar(item)
                        }
                        .foregroundStyle(GWTheme.textMuted)

                        Text("Export opens a prefilled Apple Calendar event composer. If export fails, your item stays scheduled in Genesis.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if !calendarHandoffStatus.isEmpty {
                    Section("Status") {
                        Text(calendarHandoffStatus)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(scheduleOrMoveMode == .appointment ? "Schedule Item" : "Move Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { scheduleOrMoveTargetItem = nil }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(scheduleOrMoveMode == .appointment ? "Add Appointment" : "Move") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                            if scheduleOrMoveMode == .appointment {
                                store.scheduleDumpItemAsAppointment(item.id, at: scheduleOrMoveDateTime, lane: item.lane ?? .work)
                                calendarHandoffStatus = "Scheduled in Genesis. Use Calendar Handoff to export or open calendar."
                                return
                            } else {
                                store.moveDumpItemToDay(item.id, day: scheduleOrMoveDayDate)
                            }
                        }
                        GWHaptics.success()
                        scheduleOrMoveTargetItem = nil
                    }
                    .foregroundStyle(GWTheme.gold)
                }
            }
        }
    }

    private func scheduleItemAndPrepareCalendarExport(_ item: DumpItem) {
        let start = scheduleOrMoveDateTime
        let end = Calendar.current.date(byAdding: .minute, value: 45, to: start) ?? start.addingTimeInterval(45 * 60)

        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
            store.scheduleDumpItemAsAppointment(item.id, at: start, lane: item.lane ?? .work)
        }
        GWHaptics.success()

        let draft = CalendarExportDraft(
            title: item.text,
            startDate: start,
            endDate: end,
            notes: "Created from Genesis Way Shape."
        )

        scheduleOrMoveTargetItem = nil
        DispatchQueue.main.async {
            calendarExportDraft = draft
        }
    }

    private func scheduleItemAndOpenCalendar(_ item: DumpItem) {
        let date = scheduleOrMoveDateTime

        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
            store.scheduleDumpItemAsAppointment(item.id, at: date, lane: item.lane ?? .work)
        }

        let timestamp = date.timeIntervalSinceReferenceDate
        if let url = URL(string: "calshow:\(timestamp)") {
            #if canImport(UIKit)
            UIApplication.shared.open(url)
            #endif
            calendarHandoffStatus = "Scheduled in Genesis and opened Calendar."
        } else {
            calendarHandoffStatus = "Scheduled in Genesis. Could not open Calendar app."
        }

        GWHaptics.success()
        scheduleOrMoveTargetItem = nil
    }

    private func automateSheet(item: DumpItem) -> some View {
        NavigationStack {
            Form {
                Section {
                    Picker("", selection: $automateMode) {
                        Text("Loop").tag(AutomateMode.loop)
                        Text("Custom").tag(AutomateMode.custom)
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                }
                if automateMode == .custom {
                    Section("How will you automate this?") {
                        TextField("Describe the automation...", text: $automateNote, axis: .vertical)
                            .lineLimit(3...6)
                    }
                    Section {
                        Text(item.text)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Section {
                        Text("The item stays pending. Add a note describing your automation plan: a tool, a process, or a system you'll set up.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("Loop") {
                        TextField("Task", text: $automateLoopText)
                        Picker("Default lane", selection: $automateLoopLane) {
                            Text("Unassigned").tag("unassigned")
                            Text("Work").tag(TaskLane.work.rawValue)
                            Text("Personal").tag(TaskLane.personal.rawValue)
                        }
                    }
                    Section("Recurrence") {
                        Picker("Type", selection: $automateLoopRecurrenceType) {
                            ForEach(LoopRecurrenceType.allCases) { type in
                                Text(type.title).tag(type)
                            }
                        }
                        if automateLoopRecurrenceType == .weekdays {
                            automateWeekdayChips
                        }
                    }
                    Section("Duration") {
                        Picker("Length", selection: $automateLoopDurationType) {
                            ForEach(LoopDurationType.allCases) { type in
                                Text(type.title).tag(type)
                            }
                        }
                        if automateLoopDurationType == .fixedCount {
                            Stepper("Occurrences: \(automateLoopFixedCount)", value: $automateLoopFixedCount, in: 1...60)
                        }
                    }
                    Section {
                        Text("Saving a Loop keeps this item pending. At most one Loop item is generated per day; missed runs roll into one carried-over item.")
                        Text("Existing loops: \(store.loopRules.count)")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Automate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { automateTargetItem = nil }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(automateMode == .custom ? "Save Note" : "Save Loop") {
                        if automateMode == .custom {
                            let trimmed = automateNote.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                store.setAutomationNote(item.id, note: trimmed)
                            }
                        } else {
                            let weekdays = automateLoopWeekdays.sorted()
                            store.addLoopRule(
                                text: automateLoopText.trimmingCharacters(in: .whitespacesAndNewlines),
                                lane: TaskLane(rawValue: automateLoopLane),
                                recurrenceType: automateLoopRecurrenceType,
                                weekdayNumbers: weekdays,
                                durationType: automateLoopDurationType,
                                fixedCount: automateLoopDurationType == .fixedCount ? automateLoopFixedCount : nil
                            )
                        }
                        GWHaptics.success()
                        automateTargetItem = nil
                    }
                    .disabled(automateMode == .loop && (
                        automateLoopText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        (automateLoopRecurrenceType == .weekdays && automateLoopWeekdays.isEmpty)
                    ))
                    .foregroundStyle(GWTheme.gold)
                }
            }
        }
    }

    private func laneButton(_ title: String, lane: TaskLane, selectedLane: TaskLane?, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(selectedLane == lane ? Color(hex: "1a1208") : GWTheme.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 999)
                    .fill(selectedLane == lane ? GWTheme.gold.opacity(0.95) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 999)
                            .stroke(selectedLane == lane ? GWTheme.gold.opacity(0.9) : Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
            .clipShape(Capsule())
            .buttonStyle(.plain)
    }

    private func filterButton(_ title: String, isActive: Bool, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        let fillColor: Color = {
            if isDestructive {
                return isActive ? Color(hex: "d96d5f") : Color(hex: "b14b44").opacity(0.28)
            }
            return isActive ? GWTheme.gold.opacity(0.95) : Color.white.opacity(0.1)
        }()

        let strokeColor: Color = {
            if isDestructive {
                return isActive ? Color(hex: "d96d5f") : Color(hex: "c07060").opacity(0.65)
            }
            return isActive ? GWTheme.gold.opacity(0.9) : Color.white.opacity(0.18)
        }()

        let textColor: Color = {
            if isDestructive {
                return isActive ? Color(hex: "1a1208") : Color(hex: "f2b0a8")
            }
            return isActive ? Color(hex: "1a1208") : GWTheme.textPrimary
        }()

        return Button(title, action: action)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(textColor)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 999)
                    .fill(fillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 999)
                            .stroke(strokeColor, lineWidth: 1)
                    )
            )
            .clipShape(Capsule())
            .buttonStyle(FilterActionButtonStyle())
    }

    @ViewBuilder
    private func previewSection(for day: Date, includeTimeBlocks: Bool) -> some View {
        let appointments = store.appointments(for: day)
        let scheduledTasks = store.scheduledTasks(for: day)
        let taskPool = store.taskPool(for: day)
        let pendingPile = store.pendingPileItems(for: day)

        Section("Day Preview") {
            VStack(alignment: .leading, spacing: 8) {
                Text(formattedPreviewDay(day))
                    .font(.system(size: 13, weight: .semibold))

                Text("\(appointments.count) appointment\(appointments.count == 1 ? "" : "s") • \(scheduledTasks.count) timed task\(scheduledTasks.count == 1 ? "" : "s") • \(taskPool.count) pool item\(taskPool.count == 1 ? "" : "s") • \(pendingPile.count) pending pile item\(pendingPile.count == 1 ? "" : "s")")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                if appointments.isEmpty && scheduledTasks.isEmpty && taskPool.isEmpty && pendingPile.isEmpty {
                    Text("Nothing is scheduled for this day yet.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                } else {
                    if !appointments.isEmpty {
                        previewGroup(title: "Appointments", lines: appointments.prefix(3).map { "\(formatAppointmentTime($0.scheduledAtISO)) • \($0.text)" })
                    }

                    if includeTimeBlocks && !scheduledTasks.isEmpty {
                        previewGroup(title: "Timed Tasks", lines: scheduledTasks.prefix(3).map { "\($0.time ?? "Time") • \($0.code) \($0.text)" })
                    }

                    if !taskPool.isEmpty {
                        previewGroup(title: "Task Pool", lines: taskPool.prefix(3).map { "\($0.code) \($0.text)" })
                    }

                    if !pendingPile.isEmpty {
                        previewGroup(title: "Pending Pile", lines: pendingPile.prefix(3).map(\.text))
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func previewGroup(title: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(GWTheme.textGhost)
                .textCase(.uppercase)

            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text("• \(line)")
                    .font(.system(size: 11))
                    .foregroundStyle(GWTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func formattedPreviewDay(_ day: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: day)
    }

    private func formatAppointmentTime(_ iso: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        guard let date = isoFormatter.date(from: iso) else { return "Scheduled" }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private var automateWeekdayChips: some View {
        let options: [(Int, String)] = [(2,"Mon"),(3,"Tue"),(4,"Wed"),(5,"Thu"),(6,"Fri"),(7,"Sat"),(1,"Sun")]
        return HStack(spacing: 8) {
            ForEach(options, id: \.0) { weekday, label in
                let selected = automateLoopWeekdays.contains(weekday)
                Button(label) {
                    if selected { automateLoopWeekdays.remove(weekday) }
                    else { automateLoopWeekdays.insert(weekday) }
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(selected ? Color(hex: "1a1208") : GWTheme.textGhost)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(selected ? GWTheme.gold : Color.white.opacity(0.08))
                .clipShape(Capsule())
                .buttonStyle(.plain)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Step 2 of 3")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(GWTheme.textMuted)
            Text("Shape It")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(GWTheme.textPrimary)
            Text("Filter the dump into actions, then order Work and Personal before Fill.")
                .font(.system(size: 13))
                .foregroundStyle(GWTheme.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct CalendarExportDraft: Identifiable {
    let id = UUID()
    let title: String
    let startDate: Date
    let endDate: Date
    let notes: String
}

private struct CalendarEventComposerSheet: UIViewControllerRepresentable {
    let draft: CalendarExportDraft
    let onCompletionMessage: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCompletionMessage: onCompletionMessage)
    }

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let controller = EKEventEditViewController()
        let eventStore = EKEventStore()
        controller.eventStore = eventStore
        controller.editViewDelegate = context.coordinator
        controller.event = buildEvent(in: eventStore)
        context.coordinator.requestCalendarAccessIfNeeded(eventStore: eventStore)
        return controller
    }

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}

    private func buildEvent(in store: EKEventStore) -> EKEvent {
        let event = EKEvent(eventStore: store)
        event.title = draft.title
        event.startDate = draft.startDate
        event.endDate = draft.endDate
        event.notes = draft.notes
        event.calendar = store.defaultCalendarForNewEvents
        return event
    }

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        let onCompletionMessage: (String) -> Void

        init(onCompletionMessage: @escaping (String) -> Void) {
            self.onCompletionMessage = onCompletionMessage
        }

        func requestCalendarAccessIfNeeded(eventStore: EKEventStore) {
            eventStore.requestFullAccessToEvents { granted, _ in
                if !granted {
                    DispatchQueue.main.async {
                        self.onCompletionMessage("Calendar permission is needed to export events. The item is still scheduled in Genesis.")
                    }
                }
            }
        }

        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            switch action {
            case .saved:
                onCompletionMessage("Event exported to Calendar.")
            case .deleted:
                onCompletionMessage("Calendar event was removed from composer.")
            case .canceled:
                onCompletionMessage("Calendar export canceled. The item remains scheduled in Genesis.")
            @unknown default:
                onCompletionMessage("Calendar handoff finished.")
            }

            controller.dismiss(animated: true)
        }
    }
}

private struct FilterActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

private struct DelegateScreen: View {
    let dumpItemId: UUID
    let taskText: String
    @EnvironmentObject private var store: GenesisStore
    @Environment(\.dismiss) private var dismiss
    @State private var assignee = ""
    @State private var followUpDate = Date()
    @State private var completionTarget: DelegateFollowUpItem?
    @State private var completionReminderDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var completionReminderStatus = ""
    @FocusState private var isAssigneeFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    Text(taskText)
                        .font(.body)
                }

                Section("Delegate To") {
                    TextField("Person responsible", text: $assignee)
                        .focused($isAssigneeFocused)
                        .textInputAutocapitalization(.words)
                }

                Section("Follow-Up") {
                    DatePicker("Follow-up date", selection: $followUpDate, displayedComponents: [.date])
                    Text("Use this to track when you need to check back in.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if !store.delegatedFollowUps.isEmpty {
                    Section("Open Follow-Ups") {
                        ForEach(store.delegatedFollowUps.filter { !$0.completed }) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.taskText)
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("\(item.assignee) • \(item.followUpISODate)")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Done") {
                                    completionTarget = item
                                    completionReminderDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
                                }
                                .font(.system(size: 10, weight: .bold))
                            }
                        }
                    }
                }

                if !completionReminderStatus.isEmpty {
                    Section("Status") {
                        Text(completionReminderStatus)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Delegate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        store.applyFilterOutcome(dumpItemId, outcome: .delegated)
                        store.addDelegateFollowUp(taskText: taskText, assignee: assignee, followUpDate: followUpDate)
                        dismiss()
                    }
                    .disabled(assignee.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isAssigneeFocused = false
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GWTheme.gold)
                    .padding(.vertical, 6)
                }
            }
            .sheet(item: $completionTarget) { item in
                NavigationStack {
                    Form {
                        Section("Set Follow-Up Reminder") {
                            DatePicker("Reminder", selection: $completionReminderDate, displayedComponents: [.date, .hourAndMinute])
                            Text("Default is 7 days. Change it if this handoff needs a different cadence.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .navigationTitle("Complete Delegate")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Skip Reminder") {
                                store.toggleDelegateFollowUpCompleted(item.id)
                                completionReminderStatus = "Marked complete without reminder."
                                completionTarget = nil
                            }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Save Reminder") {
                                Task {
                                    let scheduled = await store.scheduleDelegateReminder(
                                        taskText: item.taskText,
                                        assignee: item.assignee,
                                        on: completionReminderDate
                                    )

                                    await MainActor.run {
                                        store.toggleDelegateFollowUpCompleted(item.id)
                                        completionReminderStatus = scheduled
                                            ? "Marked complete and reminder scheduled."
                                            : "Marked complete, but reminder could not be scheduled."
                                        completionTarget = nil
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
