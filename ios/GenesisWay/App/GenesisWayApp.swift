import SwiftUI
import UserNotifications

final class GenesisNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let target = response.notification.request.content.userInfo["targetScreen"] as? String
        if target == "fill" {
            NotificationCenter.default.post(name: .genesisOpenFillFromReminder, object: nil)
        }
        completionHandler()
    }
}

@main
struct GenesisWayApp: App {
    @UIApplicationDelegateAdaptor(GenesisNotificationDelegate.self) var appDelegate
    @StateObject private var store = GenesisStore()

    private var colorScheme: ColorScheme {
        switch store.appThemeStyle {
        case .lightSunrise: return .light
        default: return .dark
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(colorScheme)
        }
    }
}
