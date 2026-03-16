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

enum AppThemeStyle: String, Codable, CaseIterable, Identifiable {
    case brown
    case oledBlack
    case lightSunrise
    case darkNightfall
    case oceanGlass
    case emberGlass

    var id: String { rawValue }

    var title: String {
        switch self {
        case .brown: return "Brown Glass"
        case .oledBlack: return "OLED Black"
        case .lightSunrise: return "Light Gradient"
        case .darkNightfall: return "Dark Gradient"
        case .oceanGlass: return "Ocean Glass"
        case .emberGlass: return "Ember Glass"
        }
    }
}

enum AppIconStyle: String, Codable, CaseIterable, Identifiable {
    case chrome
    case textile
    case stone
    case molten
    case obsidianGlass
    case monochrome

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chrome: return "Chrome"
        case .textile: return "Textile"
        case .stone: return "Stone"
        case .molten: return "Molten"
        case .obsidianGlass: return "Obsidian Glass"
        case .monochrome: return "Monochrome"
        }
    }

    var alternateIconName: String? {
        switch self {
        case .chrome: return nil
        case .textile: return "Textile"
        case .stone: return "Stone"
        case .molten: return "Molten"
        case .obsidianGlass: return "ObsidianGlass"
        case .monochrome: return "Monochrome"
        }
    }
}

enum PileFilterOutcome: String, Codable, CaseIterable {
    case pending
    case scheduled
    case movedForward
    case eliminated
    case delegated
    case parked
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
    var lane: TaskLane?
    var filterOutcome: PileFilterOutcome?
    var planningDayISO: String?
    var carriedOver: Bool?

    init(
        id: UUID = UUID(),
        text: String,
        spoke: Spoke? = nil,
        lane: TaskLane? = nil,
        filterOutcome: PileFilterOutcome? = nil,
        planningDayISO: String? = nil,
        carriedOver: Bool? = nil
    ) {
        self.id = id
        self.text = text
        self.spoke = spoke
        self.lane = lane
        self.filterOutcome = filterOutcome
        self.planningDayISO = planningDayISO
        self.carriedOver = carriedOver
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
    var plannedDayISO: String?
    var completed: Bool
    var carriedOver: Bool
    var sourceDumpItemId: UUID?

    init(
        id: UUID = UUID(),
        text: String,
        code: String,
        lane: TaskLane,
        time: String? = nil,
        plannedDayISO: String? = nil,
        completed: Bool = false,
        carriedOver: Bool = false,
        sourceDumpItemId: UUID? = nil
    ) {
        self.id = id
        self.text = text
        self.code = code
        self.lane = lane
        self.time = time
        self.plannedDayISO = plannedDayISO
        self.completed = completed
        self.carriedOver = carriedOver
        self.sourceDumpItemId = sourceDumpItemId
    }
}

struct RepeatingTaskRule: Identifiable, Codable {
    let id: UUID
    var text: String
    var everyDays: Int
    var lane: TaskLane
    var lastGeneratedDayISO: String?

    init(
        id: UUID = UUID(),
        text: String,
        everyDays: Int,
        lane: TaskLane,
        lastGeneratedDayISO: String? = nil
    ) {
        self.id = id
        self.text = text
        self.everyDays = max(1, everyDays)
        self.lane = lane
        self.lastGeneratedDayISO = lastGeneratedDayISO
    }
}

struct DelegateFollowUpItem: Identifiable, Codable {
    let id: UUID
    var taskText: String
    var assignee: String
    var followUpISODate: String
    var completed: Bool

    init(
        id: UUID = UUID(),
        taskText: String,
        assignee: String,
        followUpISODate: String,
        completed: Bool = false
    ) {
        self.id = id
        self.taskText = taskText
        self.assignee = assignee
        self.followUpISODate = followUpISODate
        self.completed = completed
    }
}

struct ScheduledAppointment: Identifiable, Codable {
    let id: UUID
    var text: String
    var code: String
    var lane: TaskLane
    var sourceDumpItemId: UUID?
    var scheduledAtISO: String
    var completed: Bool

    init(
        id: UUID = UUID(),
        text: String,
        code: String,
        lane: TaskLane,
        sourceDumpItemId: UUID? = nil,
        scheduledAtISO: String,
        completed: Bool = false
    ) {
        self.id = id
        self.text = text
        self.code = code
        self.lane = lane
        self.sourceDumpItemId = sourceDumpItemId
        self.scheduledAtISO = scheduledAtISO
        self.completed = completed
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
    var appointments: [ScheduledAppointment]
    var delegatedFollowUps: [DelegateFollowUpItem]
    var parked: [ParkItem]
    var archivedSpokeAssignments: [String: String]?
    var archivedRhythmAnchors: [String: String]?
    var rhythmAnchors: [String: String]
    var eveningPlanningReminderEnabled: Bool
    var eveningPlanningReminderTime: String
    var lastRolloverDayISO: String?
    var googleCalendarConnected: Bool
    var appleIcsEnabled: Bool
    var lastCalendarSyncISO: String?
    var themeStyle: AppThemeStyle?
    var hasCompletedGuidedSetup: Bool?
    var repeatingTaskRules: [RepeatingTaskRule]
    var weeklyTopGoals: [String]
    var weeklyMacroDump: String
    var appIconStyle: AppIconStyle?

    static let initial = GenesisState(
        screen: .onboarding,
        showIntroOnLaunch: true,
        remindersEnabled: true,
        reminderLeadMinutes: 30,
        dumpItems: [],
        big3: [
            Big3Item(text: ""),
            Big3Item(text: ""),
            Big3Item(text: "")
        ],
        tasks: [],
        appointments: [],
        delegatedFollowUps: [],
        parked: [
            ParkItem(text: "Evaluate iOS widget support"),
            ParkItem(text: "Draft Android port checklist")
        ],
        archivedSpokeAssignments: nil,
        archivedRhythmAnchors: nil,
        rhythmAnchors: [
            Spoke.spiritual.rawValue: "Morning reflection before phone",
            Spoke.family.rawValue: "One distraction-free dinner each week"
        ],
        eveningPlanningReminderEnabled: false,
        eveningPlanningReminderTime: "8:30 PM",
        lastRolloverDayISO: nil,
        googleCalendarConnected: false,
        appleIcsEnabled: true,
        lastCalendarSyncISO: nil,
        themeStyle: .brown,
        hasCompletedGuidedSetup: false,
        repeatingTaskRules: [],
        weeklyTopGoals: ["", "", ""],
        weeklyMacroDump: "",
        appIconStyle: .chrome
    )
}
