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

    /// Called by AppDelegate's PurchasesDelegate when subscription status
    /// changes in real time.
    ///
    /// Intentionally does NOT set `pendingProUpgrade` on a false → true
    /// transition. The celebration banner should only surface when the user
    /// *just* completed an active upgrade via `purchase()` or
    /// `restorePurchases()` — both of which set the flag themselves. This
    /// callback also fires on passive transitions we don't want to
    /// celebrate:
    ///   - App launch / reinstall where RC restores a pre-existing
    ///     entitlement via keychain or receipt sync.
    ///   - Cross-device sign-in where `logIn(userId)` pulls entitlement
    ///     state from the server for an already-subscribed user.
    ///   - Deferred / Family-Sharing grants arriving silently.
    /// Before this fix, a returning user signing in or reinstalling would
    /// see "PROMOTION GRANTED" pop up for no apparent reason.
    static func handleCustomerInfoUpdate(isPro: Bool) {
        guard let manager = active else { return }
        manager.isProUser = isPro
        UserDefaults.standard.set(isPro, forKey: proStatusKey)
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
        let wasPro = isProUser
        let info = try await Purchases.shared.restorePurchases()
        let isPro = info.entitlements["pro"]?.isActive == true
        isProUser = isPro
        UserDefaults.standard.set(isPro, forKey: Self.proStatusKey)

        // Flag for celebration banner if this restore genuinely upgraded the user.
        if isPro && !wasPro {
            pendingProUpgrade = true
        }
    }
}
