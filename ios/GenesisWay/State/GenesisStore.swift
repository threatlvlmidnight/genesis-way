import Foundation

final class GenesisStore: ObservableObject {
    @Published private(set) var state: GenesisState {
        didSet { persist() }
    }

    private let storageKey = "genesis-way-ios-v1"

    init() {
        if let saved = Self.load(storageKey: storageKey) {
            state = saved
            if state.showIntroOnLaunch {
                state.screen = .onboarding
            }
        } else {
            state = .initial
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
    var workTasks: [TaskItem] { state.tasks.filter { $0.lane == .work } }
    var personalTasks: [TaskItem] { state.tasks.filter { $0.lane == .personal } }
    var parked: [ParkItem] { state.parked }
    var googleCalendarConnected: Bool { state.googleCalendarConnected }
    var appleIcsEnabled: Bool { state.appleIcsEnabled }
    var lastCalendarSyncISO: String? { state.lastCalendarSyncISO }

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

    func addDumpItem(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        state.dumpItems.append(DumpItem(text: trimmed))
    }

    func removeDumpItem(id: UUID) {
        state.dumpItems.removeAll { $0.id == id }
    }

    func assignDumpItem(_ id: UUID, to spoke: Spoke?) {
        guard let idx = state.dumpItems.firstIndex(where: { $0.id == id }) else { return }
        state.dumpItems[idx].spoke = spoke
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

    func addParkItem(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        state.parked.append(ParkItem(text: trimmed))
    }

    func removeParkItem(id: UUID) {
        state.parked.removeAll { $0.id == id }
    }

    func navigate(_ screen: AppScreen) {
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

    private func persist() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private static func load(storageKey: String) -> GenesisState? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(GenesisState.self, from: data)
    }
}
