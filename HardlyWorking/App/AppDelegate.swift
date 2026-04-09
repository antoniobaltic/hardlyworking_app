import AppsFlyerLib
import RevenueCat
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        configureRevenueCat()
        configureAppsFlyer()
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        AppsFlyerLib.shared().start()
    }
}

// MARK: - SDK Configuration

private extension AppDelegate {
    func configureRevenueCat() {
        // TODO: Replace with your RevenueCat API key from https://app.revenuecat.com
        Purchases.configure(withAPIKey: "your_revenuecat_api_key")
    }

    func configureAppsFlyer() {
        // TODO: Replace with your AppsFlyer dev key and Apple App ID
        AppsFlyerLib.shared().appsFlyerDevKey = "your_appsflyer_dev_key"
        AppsFlyerLib.shared().appleAppID = "your_apple_app_id"
        #if DEBUG
        AppsFlyerLib.shared().isDebug = true
        #endif
    }
}
