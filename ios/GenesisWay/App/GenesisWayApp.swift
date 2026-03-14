import SwiftUI

@main
struct GenesisWayApp: App {
    @StateObject private var store = GenesisStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
