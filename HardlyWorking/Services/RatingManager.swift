import Foundation
import StoreKit
import SwiftUI
import UIKit

/// Distinct in-app moments worth asking for a rating. The trigger is just a
/// label — every trigger calls `AppStore.requestReview` the same way; the
/// label exists for telemetry / debugging so we can see which moments
/// actually convert when reviewing logs.
enum RatingTrigger: String {
    case onboardingComplete
    case shareDistributed
    case proPurchased
    case achievementUnlocked
    case thirdSessionCompleted
    case userInitiated  // tapped "Rate Hardly Working" in Settings
}

/// Volume-first rating gate. Every meaningful positive moment in the app
/// calls `requestReview(trigger:)`. iOS hard-caps the system prompt at
/// 3 per 365 days per user, so we don't worry about over-firing — we layer
/// a small same-session + 3-day debounce on top to prevent two prompts
/// from stacking when (e.g.) the user finishes a session AND unlocks an
/// achievement in the same minute.
///
/// Compliance:
/// - Uses only `AppStore.requestReview(in:)`. No bribing, no gating, no
///   write-review URL routing on automated triggers.
/// - User-initiated path (Settings) uses the same API, plus an explicit
///   App Store fallback URL for users who've already burned their 3
///   annual prompts and still want to leave a review.
@Observable @MainActor
final class RatingManager {
    // MARK: - Persistence keys

    private enum Keys {
        static let installDate = "rating_installDate"
        static let completedSessions = "rating_completedSessions"
        static let lastPromptDate = "rating_lastPromptDate"
        static let hasFiredOnboarding = "rating_firedOnboarding"
        static let hasFiredFirstShare = "rating_firedFirstShare"
        static let hasFiredProPurchase = "rating_firedProPurchase"
        static let hasFiredThirdSession = "rating_firedThirdSession"
    }

    // MARK: - Tunables

    /// Don't ask in the user's first hour — even at the end of onboarding.
    /// Onboarding completion bypasses install-age (see trigger logic) but
    /// every other automated trigger respects this floor.
    private let minimumHoursSinceInstall: Double = 1

    /// How many calendar days between automated prompts. iOS already caps
    /// at 3 per 365 days; this prevents two of those 3 firing in the same
    /// week if the user trips multiple triggers in quick succession.
    private let cooldownDays = 3

    /// True once we've called `requestReview` in this session. Prevents
    /// back-to-back firings if e.g. a session completion AND an achievement
    /// unlock land seconds apart.
    private var hasPromptedThisSession = false

    // MARK: - Lifecycle bookkeeping

    func recordInstallIfNeeded() {
        if UserDefaults.standard.double(forKey: Keys.installDate) == 0 {
            UserDefaults.standard.set(Date.now.timeIntervalSince1970, forKey: Keys.installDate)
        }
    }

    /// Increments the lifetime session counter; if we're at or past the 3rd
    /// completed session AND we haven't already fired the session trigger,
    /// fires the prompt. Called from the timer view-model on every stop.
    ///
    /// Three sessions is the earliest point we can credibly call the user
    /// a "habitual user" — late enough that it's not a first lucky tap,
    /// early enough to catch them before they churn.
    ///
    /// Uses `>= 3` rather than `== 3` so:
    ///   1. Existing users updating from a version without this code (whose
    ///      tracked counter starts at 0) still get the prompt after 3
    ///      sessions on the new version.
    ///   2. If the prompt at session 3 was debounced (cooldown / same
    ///      session as another trigger), session 4+ retries until it
    ///      actually fires. The `hasFiredThirdSession` flag is only set
    ///      once `requestReview` confirms a real fire.
    func recordSessionCompleted() {
        let next = UserDefaults.standard.integer(forKey: Keys.completedSessions) + 1
        UserDefaults.standard.set(next, forKey: Keys.completedSessions)

        guard next >= 3,
              !UserDefaults.standard.bool(forKey: Keys.hasFiredThirdSession)
        else { return }

        let didFire = requestReview(trigger: .thirdSessionCompleted)
        if didFire {
            UserDefaults.standard.set(true, forKey: Keys.hasFiredThirdSession)
        }
    }

    // MARK: - Triggers

    /// Fire after the user finishes onboarding. Skips the install-age floor
    /// because onboarding IS the user's first minutes — but only fires once,
    /// ever, per user.
    ///
    /// Delay tuned to clear the "Welcome Aboard" achievement banner: the
    /// banner shows for ~5.5s plus a 1s tail, so 7s lets it fully dismiss
    /// before the system rating sheet appears. Without this gap the two
    /// would visually stack on top of each other on first launch.
    ///
    /// The "fired" flag is only persisted if `requestReview` actually
    /// showed the prompt — otherwise the user gets a retry on next launch.
    func recordOnboardingCompleted() {
        guard !UserDefaults.standard.bool(forKey: Keys.hasFiredOnboarding) else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(7))
            let didFire = requestReview(trigger: .onboardingComplete, bypassInstallFloor: true)
            if didFire {
                UserDefaults.standard.set(true, forKey: Keys.hasFiredOnboarding)
            }
        }
    }

    /// Fire the FIRST time a share card gets distributed. Subsequent shares
    /// don't fire — they'd compete with other higher-emotion triggers.
    func recordShareDistributed() {
        guard !UserDefaults.standard.bool(forKey: Keys.hasFiredFirstShare) else { return }
        Task { @MainActor in
            // Brief delay so the iOS share sheet has fully dismissed before our
            // prompt fires; otherwise both sheets can race.
            try? await Task.sleep(for: .seconds(2.0))
            let didFire = requestReview(trigger: .shareDistributed)
            if didFire {
                UserDefaults.standard.set(true, forKey: Keys.hasFiredFirstShare)
            }
        }
    }

    /// Fire after a successful Pro upgrade. Sunk-cost commitment is at its
    /// peak the moment after they've paid. Once-per-user.
    func recordProPurchased() {
        guard !UserDefaults.standard.bool(forKey: Keys.hasFiredProPurchase) else { return }
        Task { @MainActor in
            // Wait for the paywall sheet AND the celebration banner to fade
            // out before pushing the prompt on top.
            try? await Task.sleep(for: .seconds(3.0))
            let didFire = requestReview(trigger: .proPurchased)
            if didFire {
                UserDefaults.standard.set(true, forKey: Keys.hasFiredProPurchase)
            }
        }
    }

    /// Fire on `.elite` or `.legendary` achievement unlocks only — these are
    /// the "wow" moments. Common/uncommon/rare unlocks are too frequent
    /// and would burn slots on lukewarm reactions.
    ///
    /// No once-per-user gate here — across a user's career they'll unlock
    /// maybe 2-3 elite/legendary achievements, and the system's 3-per-year
    /// ceiling is the real protection.
    func recordAchievementUnlocked(rarity: AchievementRarity) {
        guard rarity >= .elite else { return }
        Task { @MainActor in
            // Let the achievement banner finish showing before competing
            // with the system sheet.
            try? await Task.sleep(for: .seconds(4.0))
            _ = requestReview(trigger: .achievementUnlocked)
        }
    }

    /// User tapped "Rate Hardly Working" in Settings. Fires immediately
    /// with no debounce, no cooldown — they asked for it.
    func recordUserInitiatedRating() {
        triggerSystemPrompt()
        // Mark the session as prompted so an automated trigger doesn't
        // also fire a few minutes later. Apple would silently no-op the
        // second call anyway, but the bookkeeping stays clean.
        hasPromptedThisSession = true
        UserDefaults.standard.set(Date.now.timeIntervalSince1970, forKey: Keys.lastPromptDate)
    }

    /// Fallback for the Settings flow: open the App Store write-review page
    /// directly. Used as the secondary CTA next to "Rate Hardly Working"
    /// for users whose 3-per-year quota is already spent.
    func openAppStoreReviewPage() {
        guard let url = URL(string: "https://apps.apple.com/app/id6761917321?action=write-review") else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Core request flow

    /// Common path for all automated triggers: applies install-age floor +
    /// cooldown + per-session debounce, then calls the system prompt.
    /// Returns `true` if the prompt was actually called, `false` if any
    /// gate skipped it. Callers use this to decide whether to set their
    /// once-per-user flag.
    @discardableResult
    private func requestReview(trigger: RatingTrigger, bypassInstallFloor: Bool = false) -> Bool {
        guard !hasPromptedThisSession else {
            print("[Rating] Skipped \(trigger.rawValue): already prompted this session")
            return false
        }

        let installTimestamp = UserDefaults.standard.double(forKey: Keys.installDate)
        if !bypassInstallFloor, installTimestamp > 0 {
            let hoursSinceInstall = (Date.now.timeIntervalSince1970 - installTimestamp) / 3600
            guard hoursSinceInstall >= minimumHoursSinceInstall else {
                print("[Rating] Skipped \(trigger.rawValue): only \(Int(hoursSinceInstall))h since install")
                return false
            }
        }

        let lastPromptTimestamp = UserDefaults.standard.double(forKey: Keys.lastPromptDate)
        if lastPromptTimestamp > 0 {
            let daysSincePrompt = Calendar.current.dateComponents(
                [.day],
                from: Date(timeIntervalSince1970: lastPromptTimestamp),
                to: .now
            ).day ?? 0
            guard daysSincePrompt >= cooldownDays else {
                print("[Rating] Skipped \(trigger.rawValue): \(daysSincePrompt)d since last prompt")
                return false
            }
        }

        // Need a foreground-active scene to actually show. If the trigger
        // somehow fires while the app is backgrounded (unlikely with our
        // delays, but possible if the user backgrounds during the await),
        // bail without consuming any state — the next trigger will retry.
        guard let scene = activeForegroundScene() else {
            print("[Rating] Skipped \(trigger.rawValue): no foreground scene")
            return false
        }

        print("[Rating] Firing \(trigger.rawValue)")
        AppStore.requestReview(in: scene)
        hasPromptedThisSession = true
        UserDefaults.standard.set(Date.now.timeIntervalSince1970, forKey: Keys.lastPromptDate)
        return true
    }

    /// Direct path used only by the user-initiated "Rate" button in Settings.
    /// Bypasses every gate because the user explicitly asked.
    @MainActor
    private func triggerSystemPrompt() {
        guard let scene = activeForegroundScene() else { return }
        AppStore.requestReview(in: scene)
    }

    /// Picks the currently foreground-active window scene. iPad multitasking
    /// can have multiple scenes attached at once, so we explicitly filter
    /// for the one currently in the foreground — `requestReview(in:)` only
    /// shows on foreground-active scenes.
    private func activeForegroundScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }

    // MARK: - Debug

    #if DEBUG
    /// Reset every persisted gate so the next trigger fires regardless of
    /// history. Useful in TestFlight to verify each trigger point lands at
    /// the right moment without waiting weeks. Not exposed in any UI.
    func debugResetAll() {
        UserDefaults.standard.removeObject(forKey: Keys.installDate)
        UserDefaults.standard.removeObject(forKey: Keys.completedSessions)
        UserDefaults.standard.removeObject(forKey: Keys.lastPromptDate)
        UserDefaults.standard.removeObject(forKey: Keys.hasFiredOnboarding)
        UserDefaults.standard.removeObject(forKey: Keys.hasFiredFirstShare)
        UserDefaults.standard.removeObject(forKey: Keys.hasFiredProPurchase)
        UserDefaults.standard.removeObject(forKey: Keys.hasFiredThirdSession)
        hasPromptedThisSession = false
    }
    #endif
}
