import Foundation
import RevenueCat
import SwiftUI

@Observable @MainActor
final class SubscriptionManager {
    private(set) var isProUser: Bool
    private(set) var offerings: Offerings?
    var showProUpgradeBanner = false
    private(set) var pendingProUpgrade = false

    private static let proStatusKey = "cachedProStatus"
    private static weak var active: SubscriptionManager?

    /// Called by AppDelegate's PurchasesDelegate when subscription status changes in real time.
    static func handleCustomerInfoUpdate(isPro: Bool) {
        guard let manager = active else { return }
        let wasPro = manager.isProUser
        manager.isProUser = isPro
        UserDefaults.standard.set(isPro, forKey: proStatusKey)
        if isPro && !wasPro {
            manager.pendingProUpgrade = true
        }
    }

    var weeklyPackage: Package? {
        offerings?.current?.weekly
    }

    var annualPackage: Package? {
        offerings?.current?.annual
    }

    init() {
        // Start with cached value so Pro users aren't locked out offline
        isProUser = UserDefaults.standard.bool(forKey: Self.proStatusKey)
        Self.active = self
        Task { await loadData() }
    }

    func loadData() async {
        do {
            offerings = try await Purchases.shared.offerings()
            let info = try await Purchases.shared.customerInfo()
            let isPro = info.entitlements["pro"]?.isActive == true
            isProUser = isPro
            UserDefaults.standard.set(isPro, forKey: Self.proStatusKey)
        } catch {
            print("[SubscriptionManager] Failed to load: \(error)")
            // Keep cached value — don't reset to false on network error
        }
    }

    func purchase(_ package: Package) async throws -> Bool {
        let wasPro = isProUser
        let result = try await Purchases.shared.purchase(package: package)
        let isPro = result.customerInfo.entitlements["pro"]?.isActive == true
        isProUser = isPro
        UserDefaults.standard.set(isPro, forKey: Self.proStatusKey)

        // Flag for celebration banner — shown after the paywall sheet dismisses
        if isPro && !wasPro {
            pendingProUpgrade = true
        }
        return isPro
    }

    /// Call after the paywall sheet fully dismisses to show the celebration banner.
    func showProBannerIfPending() {
        guard pendingProUpgrade else { return }
        pendingProUpgrade = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showProUpgradeBanner = true
        }
    }

    func restorePurchases() async throws {
        let info = try await Purchases.shared.restorePurchases()
        let isPro = info.entitlements["pro"]?.isActive == true
        isProUser = isPro
        UserDefaults.standard.set(isPro, forKey: Self.proStatusKey)
    }
}
