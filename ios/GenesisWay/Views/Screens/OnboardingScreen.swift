import SwiftUI

struct OnboardingScreen: View {
    @EnvironmentObject private var store: GenesisStore
    let onBegin: () -> Void
    let onSkip: () -> Void

    @State private var selectedStep: IntroStep = .dump
    @State private var showCalendarSettings = false

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

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Genesis Pattern")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(GWTheme.textGhost)
                            .textCase(.uppercase)

                        Text("Form -> Fill -> Finish -> Rest")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(GWTheme.textPrimary)

                        Text("The three-step flow gets you moving now. The six-week path deepens rhythm, boundaries, and completion.")
                            .font(.system(size: 12))
                            .foregroundStyle(GWTheme.textMuted)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                PrimaryButton(title: "Begin the Journey", action: onBegin)

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
        .sheet(isPresented: $showCalendarSettings) {
            CalendarSettingsScreen()
                .environmentObject(store)
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

                if selectedStep == .sync {
                    HStack(spacing: 10) {
                        Button {
                            store.setGoogleCalendarConnected(true)
                            store.markCalendarSyncedNow()
                        } label: {
                            Text(store.googleCalendarConnected ? "Google Connected" : "Quick Connect Google")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "1a1208"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(GWTheme.gold)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button {
                            showCalendarSettings = true
                        } label: {
                            Text("Open Calendar Settings")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(GWTheme.gold)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 2)
                }
            }
        }
    }
}

private enum IntroStep: CaseIterable {
    case dump
    case shape
    case fill
    case sync

    var badge: String {
        switch self {
        case .dump: return "1"
        case .shape: return "2"
        case .fill: return "3"
        case .sync: return "4"
        }
    }

    var title: String {
        switch self {
        case .dump: return "Dump It"
        case .shape: return "Shape It"
        case .fill: return "Fill It"
        case .sync: return "Sync"
        }
    }

    var kicker: String {
        switch self {
        case .dump: return "Expose everything before you organize anything."
        case .shape: return "Assign each item to one spoke. Structure creates clarity."
        case .fill: return "Choose intentional actions and place them on your calendar."
        case .sync: return "Connect your primary calendar so your plan has a home."
        }
    }

    var summary: String {
        switch self {
        case .dump:
            return "Capture your time, energy, attention, and emotional load without editing. The goal is awareness, not fixing."
        case .shape:
            return "Move each item into one of the seven spokes. This reveals what is crowded, neglected, and misaligned."
        case .fill:
            return "Pick one specific action per spoke and assign timing. Small focused action beats vague intention."
        case .sync:
            return "Start with Google Calendar sync so your Daily Big 3 and spoke actions can move from intention to scheduled reality. Additional providers can be added later."
        }
    }

    var practicePoints: [String] {
        switch self {
        case .dump:
            return [
                "List items fast. Do not prioritize yet.",
                "Notice what explains your exhaustion.",
                "Keep all raw input in one trusted place."
            ]
        case .shape:
            return [
                "Use seven spokes as the primary lens.",
                "Place each item in one category only.",
                "Look for imbalance before making plans."
            ]
        case .fill:
            return [
                "Set one action with a clear time.",
                "Map action to your Daily Big 3.",
                "Protect margin so the plan survives real life."
            ]
        case .sync:
            return [
                "Connect Google first for the fastest setup.",
                "Use Calendar Settings for provider options.",
                "Treat calendar as your execution surface."
            ]
        }
    }
}

private struct StepAnimationView: View {
    let step: IntroStep

    private var caption: String {
        switch step {
        case .dump:
            return "Capture everything without editing"
        case .shape:
            return "Assign each item to one spoke"
        case .fill:
            return "Turn priorities into scheduled action"
        case .sync:
            return "Connect your calendar to execute in real time"
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
                case .dump:
                    dumpAnimation(t: t)
                case .shape:
                    shapeAnimation(t: t)
                case .fill:
                    fillAnimation(t: t)
                case .sync:
                    syncAnimation(t: t)
                }

                VStack {
                    Spacer()
                    Text(caption)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(GWTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .frame(maxWidth: 236)
                        .padding(.bottom, 10)
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
        ZStack {
            let rotation = Angle.degrees((t.truncatingRemainder(dividingBy: 6)) * 60)
            ForEach(0..<7, id: \.self) { i in
                let angle = (Double(i) / 7.0) * 360.0
                Circle()
                    .fill(GWTheme.gold.opacity(0.35))
                    .frame(width: 20, height: 20)
                    .offset(y: -52)
                    .rotationEffect(.degrees(angle))
                    .rotationEffect(rotation)
            }

            Circle()
                .stroke(GWTheme.gold.opacity(0.4), lineWidth: 2)
                .frame(width: 130, height: 130)

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 52, height: 52)

            Text("7")
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(GWTheme.textPrimary)
                .offset(y: -1)
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
