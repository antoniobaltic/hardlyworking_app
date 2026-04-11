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
        guard unlocksShownThisSession < maxUnlocksPerSession else { return }

        isShowingBanner = true
        let event = unlockQueue.removeFirst()
        unlocksShownThisSession += 1

        Haptics.success()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            recentUnlock = event
        }

        // Auto-dismiss after 4 seconds, then show next
        bannerTask?.cancel()
        bannerTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(4.0))
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
