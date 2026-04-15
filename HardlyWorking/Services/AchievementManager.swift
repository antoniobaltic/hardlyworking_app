import Foundation
import SwiftData
import SwiftUI

struct AchievementUnlockEvent: Identifiable {
    let id = UUID()
    let definition: AchievementDefinition
    let level: Int
    let rarity: AchievementRarity
}

@Observable @MainActor
final class AchievementManager {
    var modelContext: ModelContext?
    private(set) var recentUnlock: AchievementUnlockEvent?
    private var unlockQueue: [AchievementUnlockEvent] = []
    private var isShowingBanner = false
    private let maxUnlocksPerSession = 3
    private var unlocksShownThisSession = 0
    private var bannerTask: Task<Void, Never>?

    /// Set once the user has become Pro and seen (or been offered) the reveal of
    /// every silently-tracked Pro-only achievement earned during their free era.
    /// Survives across sessions so we only fire the reveal once per user, ever.
    private static let proBacklogAnnouncedKey = "proBacklogAnnounced"

    /// While true, `showNextBanner` bypasses the per-session cap so the full
    /// Pro-upgrade reveal plays regardless of how many banners already shown.
    private var isShowingProBacklog = false

    /// Reset the per-session unlock counter (call on app foreground)
    func resetForNewSession() {
        unlocksShownThisSession = 0
    }

    // MARK: - Check All Achievements

    func checkAll(entries: [TimeEntry], hourlyRate: Double, isProUser: Bool = false) {
        guard let modelContext else { return }

        // Fetch existing unlocks
        let descriptor = FetchDescriptor<UnlockedAchievement>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        let existingMap = Dictionary(
            existing.map { ($0.achievementId, $0.level) },
            uniquingKeysWith: max
        )

        var newUnlocks: [AchievementUnlockEvent] = []

        for definition in AchievementCatalog.all {
            // Track progress for ALL achievements (including Pro-only)
            // so free users get retroactive credit when they upgrade
            let progressValue = definition.checker(entries, hourlyRate)
            let earnedLevel = definition.currentLevel(for: progressValue)
            let previousLevel = existingMap[definition.id] ?? 0

            if earnedLevel > previousLevel {
                // Remove old level record FIRST to prevent duplicates
                if let oldRecord = existing.first(where: { $0.achievementId == definition.id }) {
                    modelContext.delete(oldRecord)
                }

                // Then insert new level — always persist progress
                let unlock = UnlockedAchievement(
                    achievementId: definition.id,
                    level: earnedLevel
                )
                modelContext.insert(unlock)

                // Only show unlock banner if user has access to this achievement
                if !definition.isProOnly || isProUser {
                    let rarity = definition.rarityForLevel(earnedLevel)
                    newUnlocks.append(AchievementUnlockEvent(
                        definition: definition,
                        level: earnedLevel,
                        rarity: rarity
                    ))
                }
            }
        }

        try? modelContext.save()

        // Queue unlocks with drip-feed (max 3 per session)
        if !newUnlocks.isEmpty {
            enqueueUnlocks(newUnlocks)
        }

        // First checkAll after upgrade (or first time a Pro user ever runs this
        // code path) reveals silently-tracked Pro-only achievements as banners.
        // Gated by UserDefaults so it fires at most once per user, ever.
        if isProUser && !UserDefaults.standard.bool(forKey: Self.proBacklogAnnouncedKey) {
            announceProBacklog()
            UserDefaults.standard.set(true, forKey: Self.proBacklogAnnouncedKey)
        }
    }

    /// Reveal all Pro-only achievements the user silently earned while free.
    /// Called when a free→Pro upgrade is detected during the session.
    private func announceProBacklog() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<UnlockedAchievement>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        let map = Dictionary(
            existing.map { ($0.achievementId, $0.level) },
            uniquingKeysWith: max
        )

        var backlog: [AchievementUnlockEvent] = []
        for definition in AchievementCatalog.all where definition.isProOnly {
            guard let level = map[definition.id], level > 0 else { continue }
            let rarity = definition.rarityForLevel(level)
            backlog.append(AchievementUnlockEvent(
                definition: definition,
                level: level,
                rarity: rarity
            ))
        }

        guard !backlog.isEmpty else { return }

        // Show highest rarity first so the reveal crescendos correctly.
        let sorted = backlog.sorted { $0.rarity > $1.rarity }
        isShowingProBacklog = true
        unlockQueue.append(contentsOf: sorted)
        showNextBanner()
    }

    // MARK: - Unlock Queue + Drip Feed

    private func enqueueUnlocks(_ unlocks: [AchievementUnlockEvent]) {
        // Sort by rarity (show most impressive first)
        let sorted = unlocks.sorted { $0.rarity > $1.rarity }

        for unlock in sorted {
            if unlocksShownThisSession < maxUnlocksPerSession {
                unlockQueue.append(unlock)
            }
            // Excess unlocks beyond the session limit are silently recorded
            // (they're already persisted in SwiftData — the user will see them in the grid)
        }

        showNextBanner()
    }

    private func showNextBanner() {
        guard !isShowingBanner, !unlockQueue.isEmpty else { return }
        // Pro-upgrade reveals bypass the 3-per-session cap so the full
        // backlog plays back regardless of how many banners already shown.
        if !isShowingProBacklog {
            guard unlocksShownThisSession < maxUnlocksPerSession else { return }
        }

        isShowingBanner = true
        let event = unlockQueue.removeFirst()
        if !isShowingProBacklog {
            unlocksShownThisSession += 1
        }

        Haptics.success()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            recentUnlock = event
        }

        // Auto-dismiss after 5.5 seconds, then show next
        bannerTask?.cancel()
        bannerTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(5.5))
            guard !Task.isCancelled else { return }

            withAnimation(.easeOut(duration: 0.3)) {
                recentUnlock = nil
            }
            isShowingBanner = false

            // Small gap between banners
            if !unlockQueue.isEmpty {
                try? await Task.sleep(for: .seconds(1.0))
                guard !Task.isCancelled else { return }
                showNextBanner()
            } else {
                // Queue drained — end Pro backlog reveal mode if active
                isShowingProBacklog = false
            }
        }
    }

    func dismissUnlock() {
        bannerTask?.cancel()
        bannerTask = nil
        withAnimation(.easeOut(duration: 0.3)) {
            recentUnlock = nil
        }
        isShowingBanner = false
    }

    // MARK: - Query Helpers

    func unlockedLevel(for achievementId: String) -> Int {
        guard let modelContext else { return 0 }
        let descriptor = FetchDescriptor<UnlockedAchievement>(
            predicate: #Predicate { $0.achievementId == achievementId }
        )
        let results = (try? modelContext.fetch(descriptor)) ?? []
        return results.first?.level ?? 0
    }

    func unlockDate(for achievementId: String) -> Date? {
        guard let modelContext else { return nil }
        let descriptor = FetchDescriptor<UnlockedAchievement>(
            predicate: #Predicate { $0.achievementId == achievementId }
        )
        let results = (try? modelContext.fetch(descriptor)) ?? []
        return results.first?.unlockedAt
    }

    func totalUnlocked() -> Int {
        guard let modelContext else { return 0 }
        let descriptor = FetchDescriptor<UnlockedAchievement>()
        let results = (try? modelContext.fetch(descriptor)) ?? []
        return results.reduce(0) { $0 + $1.level }
    }

    // MARK: - Flag-based Achievement Triggers

    static func markEntryEdited() {
        UserDefaults.standard.set(true, forKey: "hasEditedEntry")
    }
}
