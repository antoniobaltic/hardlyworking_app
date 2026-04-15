import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Environment(AchievementManager.self) private var achievementManager
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(RatingManager.self) private var ratingManager
    @AppStorage("workHoursPerDay") private var workHoursPerDay: Double = 8.0

    var body: some View {
        ZStack(alignment: .top) {
            TabView {
                Tab("Time Sheet", systemImage: "clock.fill") {
                    TimerView()
                }
                Tab("Reports", systemImage: "chart.bar.fill") {
                    DashboardView()
                }
                Tab("Intel", systemImage: "eye.fill") {
                    WallOfShameView()
                }
                Tab("Units", systemImage: "person.3.fill") {
                    GroupsView()
                }
                Tab("Dossier", systemImage: "doc.text.fill") {
                    RapSheetView()
                }
            }
            .tint(Theme.accent)

            // Banner overlays — only one at a time, achievements take priority
            if let unlock = achievementManager.recentUnlock {
                AchievementUnlockBanner(event: unlock) {
                    achievementManager.dismissUnlock()
                }
                .padding(.top, 50)
                .zIndex(100)
            } else if subscriptionManager.showProUpgradeBanner {
                ProUpgradeBanner {
                    subscriptionManager.showProUpgradeBanner = false
                }
                .padding(.top, 50)
                .zIndex(100)
            }
        }
        .onChange(of: subscriptionManager.showProUpgradeBanner) { _, isShowing in
            // The Pro celebration banner just appeared — fire the rating
            // prompt. RatingManager applies its own 3s delay so the prompt
            // lands after the banner has had a moment to register, plus
            // a once-per-user gate so this only fires for the first upgrade.
            if isShowing {
                ratingManager.recordProPurchased()
            }
        }
        .onChange(of: achievementManager.recentUnlock?.id) { _, newId in
            // An achievement unlock banner just appeared. Only the elite /
            // legendary tiers are emotionally weighty enough to warrant
            // burning one of our 3 annual rating slots — RatingManager
            // filters out lower rarities internally.
            guard newId != nil, let unlock = achievementManager.recentUnlock else { return }
            ratingManager.recordAchievementUnlocked(rarity: unlock.rarity)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                achievementManager.resetForNewSession()
                enforceTimerLimits()
            }
        }
    }

    // MARK: - Timer Limit Enforcement

    /// Called every time the app returns to foreground.
    /// Enforces hard cap and daily cap on any running timer.
    /// Overnight detection is left to TimerView's sheet (requires user decision).
    private func enforceTimerLimits() {
        // Hard cap first (most urgent — timer exceeded max session)
        if RecordingLimits.enforceHardCapIfNeeded(context: modelContext) {
            Haptics.warning()
            return // already stopped, no need to check daily cap
        }

        // Daily cap (total today exceeds work hours)
        if RecordingLimits.enforceDailyCapIfNeeded(context: modelContext, workHoursPerDay: workHoursPerDay) {
            Haptics.warning()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TimeEntry.self, inMemory: true)
}
