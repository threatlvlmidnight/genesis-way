import SwiftUI

struct OnboardingScreen: View {
    @EnvironmentObject private var store: GenesisStore
    let onBegin: () -> Void
    let onSkip: () -> Void

    @State private var selectedStep: IntroStep = .pile
    @State private var reminderSetupStatus: String?

    private var selectedIndex: Int {
        IntroStep.allCases.firstIndex(of: selectedStep) ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("The\nGenesis\nWay")
                    .font(.system(size: 44, weight: .heavy))
                    .foregroundStyle(GWTheme.textPrimary)
                    .lineSpacing(0)

                Text("Awareness before action. Shape before speed. This is stewardship, not hustle.")
                    .font(.system(size: 14))
                    .foregroundStyle(GWTheme.textMuted)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                stepSelector

                showcaseCard

                dailyFlowReminderSetupCard

                PrimaryButton(title: "Begin the Journey", action: onBegin)
                    .opacity(store.hasConfiguredDailyFlowReminders ? 1.0 : 0.7)
                    .disabled(!store.hasConfiguredDailyFlowReminders)

                Button("Already familiar? Skip to planner") {
                    onSkip()
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(GWTheme.textGhost)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 22)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
        }
        .background(GWTheme.background.ignoresSafeArea())
        .onChange(of: store.morningPlanningReminderEnabled) { _, _ in
            reminderSetupStatus = nil
        }
        .onChange(of: store.morningPlanningReminderTime) { _, _ in
            reminderSetupStatus = nil
        }
        .onChange(of: store.eveningPlanningReminderEnabled) { _, _ in
            reminderSetupStatus = nil
        }
        .onChange(of: store.eveningPlanningReminderTime) { _, _ in
            reminderSetupStatus = nil
        }
    }

    private var dailyFlowReminderSetupCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Daily Flow Setup")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(GWTheme.textGhost)
                    .textCase(.uppercase)

                Text("Set your morning and evening reminders")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(GWTheme.textPrimary)

                Toggle("Morning reminder", isOn: Binding(
                    get: { store.morningPlanningReminderEnabled },
                    set: { store.setMorningPlanningReminderEnabled($0) }
                ))

                if store.morningPlanningReminderEnabled {
                    Picker("Morning time", selection: Binding(
                        get: { store.morningPlanningReminderTime },
                        set: { store.setMorningPlanningReminderTime($0) }
                    )) {
                        Text("Choose time").tag("")
                        Text("6:30 AM").tag("6:30 AM")
                        Text("7:00 AM").tag("7:00 AM")
                        Text("7:30 AM").tag("7:30 AM")
                        Text("8:00 AM").tag("8:00 AM")
                        Text("8:30 AM").tag("8:30 AM")
                        Text("9:00 AM").tag("9:00 AM")
                    }
                }

                Toggle("Evening reminder", isOn: Binding(
                    get: { store.eveningPlanningReminderEnabled },
                    set: { store.setEveningPlanningReminderEnabled($0) }
                ))

                if store.eveningPlanningReminderEnabled {
                    Picker("Evening time", selection: Binding(
                        get: { store.eveningPlanningReminderTime },
                        set: { store.setEveningPlanningReminderTime($0) }
                    )) {
                        Text("Choose time").tag("")
                        Text("7:00 PM").tag("7:00 PM")
                        Text("7:30 PM").tag("7:30 PM")
                        Text("8:00 PM").tag("8:00 PM")
                        Text("8:30 PM").tag("8:30 PM")
                        Text("9:00 PM").tag("9:00 PM")
                    }
                }

                Button("Save Reminder Setup") {
                    let saved = store.markDailyFlowRemindersConfigured()
                    reminderSetupStatus = saved
                        ? "Reminder setup saved. You can adjust this anytime in Settings."
                        : "Pick a time for each reminder you turned on."
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(hex: "1a1208"))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(GWTheme.gold)
                .clipShape(Capsule())
                .buttonStyle(.plain)

                Text(reminderSetupStatus ?? (store.hasConfiguredDailyFlowReminders
                     ? "Reminder setup saved. You can adjust this anytime in Settings."
                     : "You must save reminder setup before starting."))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(store.hasConfiguredDailyFlowReminders ? GWTheme.gold : (store.canMarkDailyFlowRemindersConfigured() ? GWTheme.textMuted : Color(hex: "c07060")))
            }
        }
    }

    private var stepSelector: some View {
        HStack(spacing: 8) {
            ForEach(IntroStep.allCases, id: \.self) { step in
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedStep = step
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(step.badge)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(selectedStep == step ? Color(hex: "1a1208") : GWTheme.gold)
                            .frame(width: 28, height: 20)
                            .background(selectedStep == step ? GWTheme.gold : GWTheme.gold.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        Text(step.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(selectedStep == step ? GWTheme.textPrimary : GWTheme.textGhost)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(selectedStep == step ? 0.06 : 0.02))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var showcaseCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(selectedStep.title)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(GWTheme.textPrimary)

                Text(selectedStep.kicker)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(GWTheme.textMuted)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                StepAnimationView(step: selectedStep)
                    .frame(height: 170)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                Text("Step \(selectedIndex + 1) of \(IntroStep.allCases.count) • \(selectedStep.title)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(GWTheme.gold)
                    .textCase(.uppercase)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                Text(selectedStep.summary)
                    .font(.system(size: 12))
                    .foregroundStyle(GWTheme.textMuted)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 6) {
                    Text("In practice")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(GWTheme.textGhost)
                        .textCase(.uppercase)

                    ForEach(selectedStep.practicePoints, id: \.self) { point in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(GWTheme.gold.opacity(0.55))
                                .frame(width: 5, height: 5)
                                .padding(.top, 5)
                            Text(point)
                                .font(.system(size: 12))
                                .foregroundStyle(GWTheme.textMuted)
                                .multilineTextAlignment(.leading)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

            }
        }
    }
}

private enum IntroStep: CaseIterable {
    case pile
    case shape
    case fill
    case finish

    var badge: String {
        switch self {
        case .pile: return "1"
        case .shape: return "2"
        case .fill: return "3"
        case .finish: return "4"
        }
    }

    var title: String {
        switch self {
        case .pile: return "Dump It"
        case .shape: return "Shape It"
        case .fill: return "Fill It"
        case .finish: return "Finish It"
        }
    }

    var kicker: String {
        switch self {
        case .pile: return "Capture everything before you decide anything."
        case .shape: return "Run each item through the filter: Eliminate, Automate, Delegate, Schedule, Park."
        case .fill: return "Choose intentional actions and place them in your calendar. Decide when you will do the task."
        case .finish: return "Close your day, move what matters, and reset for tomorrow."
        }
    }

    var summary: String {
        switch self {
        case .pile:
            return "Get everything out of your head. List tasks at Work, Home, Hobby, School. Do not filter or worry about order yet."
        case .shape:
            return "Convert raw dump items into decisions. If it belongs today, lane it into Work or Personal so Fill can schedule it."
        case .fill:
            return "Assign each task a place in your calendar and protect margin so your plan survives real life."
        case .finish:
            return "Close your day with intention: complete what you can, move what matters, and reset tomorrow."
        }
    }

    var practicePoints: [String] {
        switch self {
        case .pile:
            return [
                "List items fast. Do not prioritize yet.",
                "Think of Work, Home, Hobby, School.",
                "Keep all raw input in one trusted place."
            ]
        case .shape:
            return [
                "Break oversized items into smaller pieces.",
                "Assign each actionable item to Work or Personal.",
                "Use one filter per item: Eliminate, Automate, Delegate, Schedule, Park."
            ]
        case .fill:
            return [
                "Make sure your digital calendar is synced.",
                "Protect margin so the plan survives real life.",
                "Assign each item a placeholder on your calendar."
            ]
        case .finish:
            return [
                "Finish your task list or consciously move each item forward. Run each incomplete item through the filters.",
                "Carry incomplete items forward with intention.",
                "Use the evening reminder to set up tomorrow."
            ]
        }
    }
}

private struct StepAnimationView: View {
    let step: IntroStep

    private var caption: String {
        switch step {
        case .pile:
            return "Capture everything without editing"
        case .shape:
            return "Filter every dump item into a clear next decision"
        case .fill:
            return "Turn priorities into scheduled action"
        case .finish:
            return "Close today and prepare tomorrow in minutes"
        }
    }

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [GWTheme.gold.opacity(0.18), GWTheme.goldDark.opacity(0.16)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                switch step {
                case .pile:
                    dumpAnimation(t: t)
                case .shape:
                    shapeAnimation(t: t)
                case .fill:
                    fillAnimation(t: t)
                case .finish:
                    syncAnimation(t: t)
                }

                VStack {
                    Spacer()
                    Text(caption)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(GWTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .lineSpacing(1.5)
                        .frame(maxWidth: 250)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
                }
            }
            .padding(1)
        }
    }

    private func dumpAnimation(t: TimeInterval) -> some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                let phase = t + (Double(i) * 0.43)
                let y = CGFloat(sin(phase) * 10)
                let alpha = 0.16 + (abs(sin(phase)) * 0.22)

                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(alpha))
                    .frame(width: CGFloat(110 + (i % 3) * 22), height: 24)
                    .offset(x: CGFloat(-95 + i * 38), y: CGFloat(-45 + i * 16) + y)
            }
        }
    }

    private func shapeAnimation(t: TimeInterval) -> some View {
        // Cards dealt one-by-one from a pile to three destinations, each tagged
        // with a coloured dot — represents routing pile items through 5 filters.
        let cycle = t.truncatingRemainder(dividingBy: 3.0)

        let dealDur = 0.48
        let dealStarts: [Double] = [0.0, 0.78, 1.56]
        let holdUntil = 2.2
        let fadeEnd = 2.7

        let srcX: Double = -60
        let dstX: [Double] = [32, 50, 32]
        let dstY: [Double] = [-40, 0, 40]
        let dstRot: [Double] = [10, 16, -9]
        // Green = Schedule, Blue = Delegate, Gold = Park
        let tagColors: [Color] = [Color(hex: "5ca06d"), Color(hex: "6090c8"), GWTheme.gold]

        let dealFade: Double = cycle > holdUntil
            ? max(0.0, 1.0 - (cycle - holdUntil) / (fadeEnd - holdUntil))
            : 1.0

        return ZStack {
            // Permanent source pile — always visible, gives impression of a full deck
            ForEach(0..<3, id: \.self) { j in
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.06 + Double(j) * 0.025))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.09), lineWidth: 0.8)
                    )
                    .frame(width: 52, height: 34)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 30, height: 4)
                    )
                    .offset(x: srcX + Double(j) * 1.5, y: Double(j) * -2.0)
                    .zIndex(Double(-j))
            }

            // Dealt (flying) cards — one per filter destination
            ForEach(0..<3, id: \.self) { i in
                let rawP = (cycle - dealStarts[i]) / dealDur
                let p = max(0.0, min(1.0, rawP))
                let e = 1.0 - pow(1.0 - p, 3.0)
                let cx = srcX + (dstX[i] - srcX) * e
                let cy = dstY[i] * e

                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.13))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(tagColors[i].opacity(e * 0.6), lineWidth: 1)
                        )
                        .frame(width: 52, height: 34)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 30, height: 4)
                        )

                    // Coloured filter dot appears as the card lands
                    Circle()
                        .fill(tagColors[i])
                        .frame(width: 8, height: 8)
                        .offset(x: 18, y: 10)
                        .scaleEffect(e)
                        .opacity(e)
                }
                .rotationEffect(.degrees(dstRot[i] * e))
                .offset(x: cx, y: cy)
                .opacity(p > 0 ? dealFade : 0.0)
                .zIndex(Double(i + 1))
            }
        }
    }

    private func fillAnimation(t: TimeInterval) -> some View {
        VStack(spacing: 12) {
            ForEach(0..<4, id: \.self) { i in
                let phase = (sin(t * 1.6 + Double(i)) + 1) / 2
                let progress = CGFloat(0.35 + (phase * 0.55))

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 14)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [GWTheme.gold, GWTheme.goldDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 220 * progress, height: 14)
                }
            }
        }
        .padding(.horizontal, 22)
    }

    private func syncAnimation(t: TimeInterval) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .frame(width: 248, height: 128)

            VStack(alignment: .leading, spacing: 9) {
                ForEach(0..<3, id: \.self) { i in
                    let pulse = 0.15 + (abs(sin(t * 1.2 + Double(i))) * 0.18)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(pulse))
                        .frame(width: CGFloat(68 + (i * 8)), height: 12)
                }
            }
            .offset(x: -70, y: -2)

            Path { p in
                p.move(to: CGPoint(x: -18, y: 0))
                p.addLine(to: CGPoint(x: 56, y: 0))
                p.move(to: CGPoint(x: 56, y: 0))
                p.addLine(to: CGPoint(x: 47, y: -6))
                p.move(to: CGPoint(x: 56, y: 0))
                p.addLine(to: CGPoint(x: 47, y: 6))
            }
            .stroke(GWTheme.gold.opacity(0.4), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

            ForEach(0..<5, id: \.self) { i in
                let phase = (t * 0.55 + (Double(i) / 5.0)).truncatingRemainder(dividingBy: 1)
                let x = -18 + (74 * phase)
                let y = sin((phase * .pi * 2) + Double(i)) * 3.5
                let size = 4.0 + (phase * 2.0)

                Circle()
                    .fill(GWTheme.gold.opacity(0.55))
                    .frame(width: size, height: size)
                    .offset(x: x, y: y)
            }

            RoundedRectangle(cornerRadius: 10)
                .fill(GWTheme.gold.opacity(0.16))
                .frame(width: 90, height: 82)
                .offset(x: 84)

            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 27, weight: .bold))
                .foregroundStyle(GWTheme.textPrimary)
                .offset(x: 84, y: -10)

            let ring = 0.9 + (abs(sin(t * 1.8)) * 0.25)
            Circle()
                .stroke(GWTheme.gold.opacity(0.45), lineWidth: 2)
                .frame(width: 22, height: 22)
                .scaleEffect(ring)
                .offset(x: 112, y: 20)

            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(GWTheme.gold)
                .offset(x: 112, y: 20)
        }
    }
}
