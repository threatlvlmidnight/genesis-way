import Foundation

enum AppScreen: String, Codable {
    case onboarding
    case dump
    case shape
    case fill
    case park
}

enum TaskLane: String, Codable {
    case work
    case personal
}

enum Spoke: String, CaseIterable, Codable {
    case spiritual
    case family
    case career
    case physical
    case mental
    case social
    case financial

    var title: String {
        switch self {
        case .spiritual: return "Spiritual"
        case .family: return "Family"
        case .career: return "Career"
        case .physical: return "Physical"
        case .mental: return "Mental"
        case .social: return "Social"
        case .financial: return "Financial"
        }
    }

    var icon: String {
        switch self {
        case .spiritual: return "sparkles"
        case .family: return "person.3.fill"
        case .career: return "briefcase.fill"
        case .physical: return "figure.walk"
        case .mental: return "brain.head.profile"
        case .social: return "person.2.fill"
        case .financial: return "dollarsign.circle.fill"
        }
    }
}

struct DumpItem: Identifiable, Codable {
    let id: UUID
    var text: String
    var spoke: Spoke?

    init(id: UUID = UUID(), text: String, spoke: Spoke? = nil) {
        self.id = id
        self.text = text
        self.spoke = spoke
    }
}

struct Big3Item: Identifiable, Codable {
    let id: UUID
    var text: String
    var done: Bool

    init(id: UUID = UUID(), text: String, done: Bool = false) {
        self.id = id
        self.text = text
        self.done = done
    }
}

struct TaskItem: Identifiable, Codable {
    let id: UUID
    var text: String
    var code: String
    var lane: TaskLane
    var time: String?

    init(id: UUID = UUID(), text: String, code: String, lane: TaskLane, time: String? = nil) {
        self.id = id
        self.text = text
        self.code = code
        self.lane = lane
        self.time = time
    }
}

struct ParkItem: Identifiable, Codable {
    let id: UUID
    var text: String

    init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }
}

struct GenesisState: Codable {
    var screen: AppScreen
    var showIntroOnLaunch: Bool
    var remindersEnabled: Bool
    var reminderLeadMinutes: Int
    var dumpItems: [DumpItem]
    var big3: [Big3Item]
    var tasks: [TaskItem]
    var parked: [ParkItem]
    var rhythmAnchors: [String: String]
    var googleCalendarConnected: Bool
    var appleIcsEnabled: Bool
    var lastCalendarSyncISO: String?

    static let initial = GenesisState(
        screen: .onboarding,
        showIntroOnLaunch: true,
        remindersEnabled: true,
        reminderLeadMinutes: 30,
        dumpItems: [],
        big3: [
            Big3Item(text: "Finalize iOS architecture"),
            Big3Item(text: "Port Dump and Fill screens"),
            Big3Item(text: "Set calendar integration strategy")
        ],
        tasks: [
            TaskItem(text: "Review product roadmap", code: "W1", lane: .work, time: "9:00 AM"),
            TaskItem(text: "Design data sync contracts", code: "W2", lane: .work),
            TaskItem(text: "Evening walk", code: "P1", lane: .personal, time: "6:00 PM")
        ],
        parked: [
            ParkItem(text: "Evaluate iOS widget support"),
            ParkItem(text: "Draft Android port checklist")
        ],
        rhythmAnchors: [
            Spoke.spiritual.rawValue: "Morning reflection before phone",
            Spoke.family.rawValue: "One distraction-free dinner each week"
        ],
        googleCalendarConnected: false,
        appleIcsEnabled: true,
        lastCalendarSyncISO: nil
    )
}
