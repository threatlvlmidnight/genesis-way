import SwiftUI

struct ShapeScreen: View {
    @EnvironmentObject private var store: GenesisStore
    @State private var scheduleTargetItem: DumpItem?
    @State private var scheduleDateTime = Date()
    @State private var moveTargetItem: DumpItem?
    @State private var moveDate = Date()
    @State private var delegateTargetText = ""
    @State private var lastActionItemId: UUID?
    @State private var jamTargetItem: DumpItem?

    private var todayISO: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private var pendingItems: [DumpItem] {
        let todayPending = store.pendingPileItems
        if !todayPending.isEmpty {
            return todayPending
        }

        let allPending = store.dumpItems.filter { ($0.filterOutcome ?? .pending) == .pending }
        return allPending.sorted {
            ($0.planningDayISO ?? todayISO) > ($1.planningDayISO ?? todayISO)
        }
    }

    private var showingCrossDayFallback: Bool {
        store.pendingPileItems.isEmpty && pendingItems.isEmpty == false
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
                        Text("How Shape Works")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(GWTheme.textPrimary)

                        Text("Run each dump item through one filter: Schedule, Move, Eliminate, Delegate, or Park.")
                            .font(.system(size: 12))
                            .foregroundStyle(GWTheme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Work items are ordered top-down. Personal items are ordered bottom-up.")
                            .font(.system(size: 11))
                            .foregroundStyle(GWTheme.textGhost)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Text("Dump to Process")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(GWTheme.textGhost)
                    .textCase(.uppercase)

                if showingCrossDayFallback {
                    GlassCard {
                        Text("No pending items for today. Showing pending items from other days so you can keep shaping.")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(GWTheme.gold)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if store.pendingPileItems.isEmpty {
                    GlassCard {
                        Text("No pending dump items. Add more in Dump or continue to Fill.")
                            .font(.system(size: 12))
                            .foregroundStyle(GWTheme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    GlassCard {
                        HStack(spacing: 10) {
                            Image(systemName: unreadyPendingCount == 0 ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(unreadyPendingCount == 0 ? GWTheme.gold : Color(hex: "c07060"))

                            Text(unreadyPendingCount == 0
                                 ? "All pending items are ready for Fill."
                                 : "\(unreadyPendingCount) item\(unreadyPendingCount == 1 ? "" : "s") still need Work/Personal lane selection.")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(unreadyPendingCount == 0 ? GWTheme.textMuted : Color(hex: "c07060"))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

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

                                    Button("Clear") {
                                        store.clearDumpItemLane(item.id)
                                        GWHaptics.warning()
                                    }
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(GWTheme.textPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(
                                        RoundedRectangle(cornerRadius: 999)
                                            .fill(Color.white.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 999)
                                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                            )
                                    )
                                    .clipShape(Capsule())
                                    .buttonStyle(.plain)
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
                                    filterButton("Schedule", isActive: lastActionItemId == item.id) {
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                            lastActionItemId = item.id
                                            scheduleDateTime = Date()
                                            scheduleTargetItem = item
                                        }
                                        GWHaptics.medium()
                                    }

                                    filterButton("Move", isActive: false) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                                            lastActionItemId = item.id
                                            moveDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                                            moveTargetItem = item
                                        }
                                        GWHaptics.medium()
                                    }

                                    filterButton("Eliminate", isActive: false, isDestructive: true) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                                            lastActionItemId = item.id
                                            store.applyFilterOutcome(item.id, outcome: .eliminated)
                                        }
                                        GWHaptics.warning()
                                    }

                                    filterButton("Delegate", isActive: false) {
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                            lastActionItemId = item.id
                                            delegateTargetText = item.text
                                            store.applyFilterOutcome(item.id, outcome: .delegated)
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
            .padding(24)
        }
        .background(GWTheme.background.ignoresSafeArea())
        .sheet(item: $scheduleTargetItem) { item in
            NavigationStack {
                Form {
                    Section("Appointment Date & Time") {
                        DatePicker("When", selection: $scheduleDateTime, displayedComponents: [.date, .hourAndMinute])
                    }

                    Section {
                        Text(item.text)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("Schedule Item")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            scheduleTargetItem = nil
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Add Appointment") {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                                store.scheduleDumpItemAsAppointment(item.id, at: scheduleDateTime, lane: item.lane ?? .work)
                            }
                            GWHaptics.success()
                            scheduleTargetItem = nil
                        }
                    }
                }
            }
        }
        .sheet(item: $moveTargetItem) { item in
            NavigationStack {
                Form {
                    Section("Move to Day") {
                        DatePicker("Day", selection: $moveDate, displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                    }

                    Section {
                        Text(item.text)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("Move Item")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            moveTargetItem = nil
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Move") {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                                store.moveDumpItemToDay(item.id, day: moveDate)
                            }
                            GWHaptics.success()
                            moveTargetItem = nil
                        }
                    }
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { !delegateTargetText.isEmpty },
            set: { showing in
                if !showing {
                    delegateTargetText = ""
                }
            }
        )) {
            DelegateScreen(taskText: delegateTargetText)
                .environmentObject(store)
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Step 2 of 3")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(GWTheme.textGhost)
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

private struct FilterActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

private struct DelegateScreen: View {
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
