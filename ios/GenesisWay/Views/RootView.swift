import SwiftUI

#if DEBUG
private let isDebug = true
#else
private let isDebug = false
#endif

private let screenNumbers: [AppScreen: Int] = [
    .onboarding: 1,
    .dump: 2,
    .shape: 3,
    .fill: 4,
    .park: 5,
]

struct RootView: View {
    @EnvironmentObject private var store: GenesisStore

    private var buildLabel: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "v\(version) b\(build)"
    }

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

            if isDebug, let num = screenNumbers[store.screen] {
                VStack {
                    HStack {
                        Spacer()
                        Text("Screen \(num)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .allowsHitTesting(false)
                            .padding(.trailing, 12)
                            .padding(.top, 56)
                    }
                    Spacer()
                }
            }

            VStack {
                Spacer()
                Text(buildLabel)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(GWTheme.textGhost.opacity(0.65))
                    .padding(.bottom, 4)
            }
            .allowsHitTesting(false)
        }
    }
}

private struct MainTabShell: View {
    @EnvironmentObject private var store: GenesisStore
    @State private var showAppSettings = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: Binding(
                get: { store.screen },
                set: { store.navigate($0) }
            )) {
                DumpScreen()
                    .tabItem { Label("Dump", systemImage: "square.and.pencil") }
                    .tag(AppScreen.dump)

                ShapeScreen()
                    .tabItem { Label("Shape", systemImage: "circle.grid.cross") }
                    .tag(AppScreen.shape)

                FillScreen()
                    .tabItem { Label("Fill", systemImage: "checklist") }
                    .tag(AppScreen.fill)

                ParkScreen()
                    .tabItem { Label("Park", systemImage: "tray.and.arrow.down") }
                    .tag(AppScreen.park)
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
            }
            .buttonStyle(.plain)
            .padding(.trailing, 14)
            .padding(.top, 8)
        }
        .tint(GWTheme.gold)
        .sheet(isPresented: $showAppSettings) {
            AppSettingsScreen()
                .environmentObject(store)
        }
    }
}
