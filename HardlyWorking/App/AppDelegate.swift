import AppsFlyerLib
import AppTrackingTransparency
import RevenueCat
import SwiftData
import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, PurchasesDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        configureRevenueCat()
        configureAppsFlyer()
        // Device identifiers can be collected immediately
        Purchases.shared.attribution.collectDeviceIdentifiers()
        // Listen for real-time subscription changes
        Purchases.shared.delegate = self
        // Register notification categories + set delegate
        NotificationManager.registerCategories()
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // MARK: - RevenueCat Delegate

    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        let isPro = customerInfo.entitlements["pro"]?.isActive == true
        UserDefaults.standard.set(isPro, forKey: "cachedProStatus")
        Task { @MainActor in
            SubscriptionManager.handleCustomerInfoUpdate(isPro: isPro)
        }
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        .portrait
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        AppsFlyerLib.shared().start()
        // Wire AppsFlyer ID to RevenueCat AFTER start() so the UID is initialized
        Purchases.shared.attribution.setAppsflyerID(
            AppsFlyerLib.shared().getAppsFlyerUID()
        )
    }

    // MARK: - Notification Handling

    /// Show notifications even when app is in foreground (suppressed by default on iOS).
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Don't show timer reminders if app is in foreground — the UI already handles it
        let categoryId = notification.request.content.categoryIdentifier
        if categoryId == NotificationManager.timerCategoryId {
            return []
        }
        return [.banner, .sound]
    }

    /// Handle notification action (e.g. "Stop Timer" button).
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let actionId = response.actionIdentifier
        if actionId == NotificationManager.stopActionId {
            await MainActor.run { stopRunningTimer() }
        }
    }

    @MainActor
    private func stopRunningTimer() {
        let container: ModelContainer
        do {
            container = try ModelContainer(
                for: TimeEntry.self, UnlockedAchievement.self, CustomCategory.self
            )
        } catch {
            print("[AppDelegate] Failed to create ModelContainer for notification action: \(error)")
            // Best effort: still clear pending reminders
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: ["timer-reminder-2h", "timer-reminder-3h"]
            )
            return
        }

        let context = container.mainContext
        let descriptor = FetchDescriptor<TimeEntry>(
            predicate: #Predicate { $0.endTime == nil }
        )

        guard let running = (try? context.fetch(descriptor))?.first else {
            print("[AppDelegate] No running timer found for notification action")
            return
        }

        running.endTime = .now
        try? context.save()

        // Clear pending reminders
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["timer-reminder-2h", "timer-reminder-3h"]
        )
    }
}

// MARK: - SDK Configuration

private extension AppDelegate {
    func configureRevenueCat() {
        Purchases.configure(withAPIKey: "appl_knNMlBgWKDwKzuSRCPOPFJZMZZI")
    }

    func configureAppsFlyer() {
        AppsFlyerLib.shared().appsFlyerDevKey = "mDAyAgYQxtGgiVHDoHttoi"
        AppsFlyerLib.shared().appleAppID = "6761917321"

        // Wait for ATT response before sending first launch (up to 60s)
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)

        #if DEBUG
        AppsFlyerLib.shared().isDebug = true
        #endif
    }
}
