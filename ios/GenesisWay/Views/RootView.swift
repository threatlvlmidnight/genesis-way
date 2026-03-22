import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: GenesisStore

    var body: some View {
        ZStack {
            GWTheme.background.ignoresSafeArea()

            if store.screen == .onboarding {
                OnboardingScreen(
                    onBegin: { store.beginJourney() },
                    onSkip: { store.skipToPlanner() }
                )
            } else {
                MainTabShell()
            }
        }
    }
}

private struct MainTabShell: View {
    @EnvironmentObject private var store: GenesisStore
    @State private var showAppSettings = false
    @State private var showCalendarSettings = false
    @State private var showScreenGuide = false
    @State private var showGuidedSetup = false
    @State private var guidedStepIndex = 0

    private let guidedSteps: [GuidedSetupStep] = [
        GuidedSetupStep(
            screen: .dump,
            title: "Link your calendar",
            details: "Tap the gear icon, then open Calendar Settings and connect Google or enable Apple ICS.",
            emphasis: .settings
        ),
        GuidedSetupStep(
            screen: .dump,
            title: "Add items to Dump",
            details: "Capture every open loop. Press Enter to keep adding without leaving the field.",
            emphasis: .dump
        ),
        GuidedSetupStep(
            screen: .shape,
            title: "Filter and lane tasks",
            details: "Run each item through Shape and choose Work or Personal so it becomes ready for Fill.",
            emphasis: .shape
        ),
        GuidedSetupStep(
            screen: .fill,
            title: "Drag tasks onto timeline",
            details: "Drag from Task Pool to All Day or a time slot. Place every task before Start Day.",
            emphasis: .fill
        )
    ]

    private var activeGuidedStep: GuidedSetupStep? {
        guard showGuidedSetup, guidedSteps.indices.contains(guidedStepIndex) else { return nil }
        return guidedSteps[guidedStepIndex]
    }

    private var showsGuideButton: Bool {
        switch store.screen {
        case .dump, .shape, .fill:
            return true
        default:
            return false
        }
    }

    private var showsHomeButton: Bool {
        store.screen != .onboarding
    }

    var body: some View {
        TabView(selection: Binding(
            get: { store.screen },
            set: { store.navigate($0) }
        )) {
            DumpScreen()
            .padding(.top, 42)
            .tabItem { Label("Dump", systemImage: "square.and.pencil") }
            .tag(AppScreen.dump)

            ShapeScreen()
            .padding(.top, 42)
            .tabItem { Label("Shape", systemImage: "circle.grid.cross") }
            .tag(AppScreen.shape)

            FillScreen()
            .padding(.top, 42)
            .tabItem { Label("Fill", systemImage: "checklist") }
            .tag(AppScreen.fill)

            ParkScreen()
            .padding(.top, 42)
            .tabItem { Label("Park", systemImage: "tray.and.arrow.down") }
            .tag(AppScreen.park)
        }
        .safeAreaInset(edge: .top) {
            Color.clear
                .frame(height: 92)
        }
        .overlay(alignment: .top) {
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.36), Color.black.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(GWTheme.gold.opacity(0.08))
                            .frame(height: 1)
                    }
                    .allowsHitTesting(false)

                HStack(spacing: 8) {
                    if showsHomeButton {
                        Button {
                            store.navigate(.onboarding)
                            GWHaptics.light()
                        } label: {
                            Label("Tour", systemImage: "house.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(GWTheme.gold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: 0)

                    HStack(spacing: 8) {
                        if showsGuideButton {
                            Button {
                                showScreenGuide = true
                            } label: {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(GWTheme.gold)
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }

                        Button {
                            showAppSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(GWTheme.gold)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(GWTheme.gold, lineWidth: 2)
                                        .opacity(activeGuidedStep?.emphasis == .settings ? 0.95 : 0)
                                }
                                .shadow(color: GWTheme.gold.opacity(activeGuidedStep?.emphasis == .settings ? 0.55 : 0), radius: 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 6)
                .padding(.bottom, 18)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 66)
        }
        .overlay(alignment: .bottom) {
            if let emphasis = activeGuidedStep?.emphasis,
               let tabIndex = guidedTabIndex(for: emphasis) {
                GeometryReader { geo in
                    let tabCount = 4.0
                    let tabWidth = geo.size.width / tabCount
                    let centerX = (tabWidth * (Double(tabIndex) + 0.5))

                    Circle()
                        .stroke(GWTheme.gold.opacity(0.92), lineWidth: 2.5)
                        .frame(width: 42, height: 42)
                        .shadow(color: GWTheme.gold.opacity(0.5), radius: 8)
                        .scaleEffect(1.0 + (0.08 * abs(sin(Date().timeIntervalSinceReferenceDate * 3.2))))
                        .position(x: centerX, y: geo.size.height - 25)
                        .allowsHitTesting(false)
                }
            }
        }
        .tint(GWTheme.gold)
        .onAppear {
            if store.shouldShowGuidedSetup {
                showGuidedSetup = true
                guidedStepIndex = 0
                applyGuidedStepNavigation()
            }
        }
        .onChange(of: guidedStepIndex) { _, _ in
            applyGuidedStepNavigation()
        }
        .onChange(of: store.guidedSetupLaunchToken) { _, _ in
            showGuidedSetup = true
            guidedStepIndex = 0
            applyGuidedStepNavigation()
        }
        .sheet(isPresented: $showAppSettings) {
            AppSettingsScreen()
                .environmentObject(store)
        }
        .sheet(isPresented: $showCalendarSettings) {
            CalendarSettingsScreen()
                .environmentObject(store)
        }
        .sheet(isPresented: $showScreenGuide) {
            NavigationStack {
                ScrollView {
                    guideContent(for: store.screen)
                        .padding(16)
                }
                .background(GWTheme.background.ignoresSafeArea())
                .navigationTitle(guideTitle(for: store.screen))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            showScreenGuide = false
                        }
                        .foregroundStyle(GWTheme.gold)
                    }
                }
            }
        }
        .sheet(isPresented: $showGuidedSetup) {
            if guidedSteps.indices.contains(guidedStepIndex) {
                NavigationStack {
                    VStack {
                        guidedSetupCard(step: guidedSteps[guidedStepIndex])
                            .padding(16)
                        Spacer()
                    }
                    .background(GWTheme.background.ignoresSafeArea())
                    .navigationTitle("Guided Setup")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.fraction(0.38), .medium])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private func guidedSetupCard(step: GuidedSetupStep) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Guided Setup")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(GWTheme.textGhost)
                        .textCase(.uppercase)
                    Spacer()
                    Text("\(guidedStepIndex + 1)/\(guidedSteps.count)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(GWTheme.gold)
                }

                Text(step.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(GWTheme.textPrimary)

                Text(step.details)
                    .font(.system(size: 12))
                    .foregroundStyle(GWTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Image(systemName: emphasisIcon(for: step.emphasis))
                        .font(.system(size: 11, weight: .bold))
                    Text("Tap: \(emphasisLabel(for: step.emphasis))")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(GWTheme.gold)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.05))
                .clipShape(Capsule())

                if step.emphasis == .settings {
                    Button("Link Calendar Now") {
                        showCalendarSettings = true
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: "1a1208"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(GWTheme.gold)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
                }

                HStack {
                    Button("Skip") {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showGuidedSetup = false
                        }
                        store.navigate(.dump)
                        store.completeGuidedSetup()
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(GWTheme.textGhost)

                    Spacer()

                    Button(guidedStepIndex == guidedSteps.count - 1 ? "Done" : "Next") {
                        if guidedStepIndex >= guidedSteps.count - 1 {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showGuidedSetup = false
                            }
                            store.navigate(.dump)
                            store.completeGuidedSetup()
                        } else {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                guidedStepIndex += 1
                            }
                        }
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: "1a1208"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(GWTheme.gold)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func applyGuidedStepNavigation() {
        guard showGuidedSetup, guidedSteps.indices.contains(guidedStepIndex) else { return }
        store.navigate(guidedSteps[guidedStepIndex].screen)
    }

    private func emphasisIcon(for emphasis: GuidedSetupStep.Emphasis) -> String {
        switch emphasis {
        case .settings: return "gearshape.fill"
        case .dump: return "square.and.pencil"
        case .shape: return "circle.grid.cross"
        case .fill: return "checklist"
        }
    }

    private func emphasisLabel(for emphasis: GuidedSetupStep.Emphasis) -> String {
        switch emphasis {
        case .settings: return "Settings gear"
        case .dump: return "Dump tab"
        case .shape: return "Shape tab"
        case .fill: return "Fill tab"
        }
    }

    private func guidedTabIndex(for emphasis: GuidedSetupStep.Emphasis) -> Int? {
        switch emphasis {
        case .settings:
            return nil
        case .dump:
            return 0
        case .shape:
            return 1
        case .fill:
            return 2
        }
    }

    private func guideTitle(for screen: AppScreen) -> String {
        switch screen {
        case .dump: return "Dump Guide"
        case .shape: return "Shape Guide"
        case .fill: return "Fill Guide"
        default: return "Guide"
        }
    }

    @ViewBuilder
    private func guideContent(for screen: AppScreen) -> some View {
        switch screen {
        case .dump:
            ScreenGuideCard(
                title: "Dump",
                summary: "Capture reality first, then make decisions in Shape. Dump is for fast trust-building, not sorting.",
                steps: [
                    "Step 1: Empty your head fully: tasks, ideas, worries, follow-ups, and loose commitments.",
                    "Step 2: Keep entries short and concrete so they can be processed quickly later.",
                    "Step 3: Do not prioritize or judge here; speed and completeness are the goal.",
                    "Step 4: Use voice capture when your thoughts are faster than typing.",
                    "Step 5: Press Enter to keep flow and avoid stopping between captures.",
                    "Step 6: Stop only when your mental loop feels quiet, then switch to Shape."
                ]
            )
        case .shape:
            VStack(spacing: 12) {
                ScreenGuideCard(
                    title: "Shape",
                    summary: "Shape converts raw items into decisions that can actually be executed today.",
                    steps: [
                        "Step 1: Assign every item to a lane: Work or Personal.",
                        "Step 2: Apply one filter outcome per item: Schedule, Move, Eliminate, Delegate, or Park.",
                        "Step 3: If a task is too big, split it into smaller slices before planning your day.",
                        "Step 4: Delegate with a follow-up date so ownership is clear and traceable.",
                        "Step 5: Park intentionally: not today does not mean never.",
                        "Step 6: Leave Shape with only actionable, lane-assigned work for Fill."
                    ]
                )

                ShapeFiltersGuideCard()
            }
        case .fill:
            ScreenGuideCard(
                title: "Fill",
                summary: "Fill protects focus by turning decisions into a realistic, time-aware daily plan.",
                steps: [
                    "Step 1: Pick a focused Big 3 that defines what a good day actually means.",
                    "Step 2: Drag tasks into All Day or time slots to create an executable plan.",
                    "Step 3: Avoid overloading and schedule margin so interruptions do not collapse the day.",
                    "Step 4: Move non-critical tasks to another day instead of forcing everything today.",
                    "Step 5: Set alerts to protect key commitments when context switches happen.",
                    "Step 6: Start Day only after every open item has a disposition."
                ]
            )
        default:
            EmptyView()
        }
    }
}

private struct ScreenGuideCard: View {
    let title: String
    let summary: String
    let steps: [String]

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(GWTheme.textPrimary)

                Text(summary)
                    .font(.system(size: 12))
                    .foregroundStyle(GWTheme.textMuted)

                ForEach(steps, id: \.self) { step in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(GWTheme.gold.opacity(0.65))
                            .frame(width: 5, height: 5)
                            .padding(.top, 5)

                        Text(step)
                            .font(.system(size: 12))
                            .foregroundStyle(GWTheme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

private struct ShapeFiltersGuideCard: View {
    private struct FilterDetail: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let tint: Color
        let icon: String
    }

    private let filters: [FilterDetail] = [
        FilterDetail(title: "Schedule", description: "Assign a real day/time and place it into the planner.", tint: Color(hex: "5ca06d"), icon: "calendar.badge.plus"),
        FilterDetail(title: "Move", description: "Not today, but still active. Move it to a different day.", tint: Color(hex: "d2a85a"), icon: "arrow.right.circle"),
        FilterDetail(title: "Eliminate", description: "Remove work that does not need action anymore.", tint: Color(hex: "c07060"), icon: "xmark.circle"),
        FilterDetail(title: "Delegate", description: "Assign ownership to someone else with follow-up.", tint: Color(hex: "6090c8"), icon: "person.2"),
        FilterDetail(title: "Park", description: "Keep it for later without forcing it into today.", tint: Color(hex: "8f7ea8"), icon: "tray.and.arrow.down")
    ]

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("5 Filters")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(GWTheme.textPrimary)

                Text("Use one filter per item. Shape is a routing decision, not a priority debate.")
                    .font(.system(size: 12))
                    .foregroundStyle(GWTheme.textMuted)

                TimelineView(.animation) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    HStack(spacing: 9) {
                        ForEach(Array(filters.enumerated()), id: \.offset) { index, filter in
                            let pulse = 0.82 + (0.18 * abs(sin(t * 2.2 + Double(index) * 0.55)))

                            VStack(spacing: 5) {
                                Image(systemName: filter.icon)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color(hex: "1a1208"))
                                    .frame(width: 22, height: 22)
                                    .background(filter.tint.opacity(0.9))
                                    .clipShape(Circle())
                                    .scaleEffect(pulse)

                                Text(filter.title)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(GWTheme.textGhost)
                            }

                            if index < filters.count - 1 {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(GWTheme.gold.opacity(0.7))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .frame(height: 50)

                ForEach(filters) { filter in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(filter.tint.opacity(0.9))
                            .frame(width: 6, height: 6)
                            .padding(.top, 5)

                        Text("\(filter.title): \(filter.description)")
                            .font(.system(size: 12))
                            .foregroundStyle(GWTheme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

private struct GuidedSetupStep {
    enum Emphasis {
        case settings
        case dump
        case shape
        case fill
    }

    let screen: AppScreen
    let title: String
    let details: String
    let emphasis: Emphasis
}
