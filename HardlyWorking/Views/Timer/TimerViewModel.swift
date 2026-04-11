import Foundation
import SwiftData
import SwiftUI

@Observable @MainActor
final class TimerViewModel {
    var modelContext: ModelContext?
    var achievementManager: AchievementManager?
    var ratingManager: RatingManager?
    var notificationManager: NotificationManager?
    var isProUser: Bool = false
    var customCategories: [CustomCategory] = []
    var syncError: String?
    @ObservationIgnored private var hourlyRate: Double = 15.0

    func startSlacking(category: SlackCategory, entries: [TimeEntry]) {
        guard let modelContext else { return }

        // Stop any running entry first and cancel its notifications
        if let running = entries.first(where: \.isRunning) {
            running.endTime = .now
            notificationManager?.cancelTimerReminder()
        }

        let entry = TimeEntry(category: category.name)
        modelContext.insert(entry)
        try? modelContext.save()

        // Schedule background timer reminders
        notificationManager?.scheduleTimerReminder(category: category.name, startTime: entry.startTime)

        // Request notification permission on first-ever timer start (2s delay so user sees timer first)
        notificationManager?.requestPermissionIfNeeded(delay: 2.0)
    }

    func stopSlacking(entries: [TimeEntry]) {
        guard let running = entries.first(where: \.isRunning) else { return }
        running.endTime = .now
        try? modelContext?.save()

        // Cancel pending timer reminders
        notificationManager?.cancelTimerReminder()

        // Sync today's aggregated stats to Supabase
        Task { await syncDailyStats(entries: entries) }

        // Check achievements
        achievementManager?.checkAll(entries: entries, hourlyRate: hourlyRate, isProUser: isProUser)

        // Track for rating prompt
        ratingManager?.recordSessionCompleted()
    }

    func updateHourlyRate(_ rate: Double) {
        hourlyRate = rate
    }

    func todayTotal(entries: [TimeEntry]) -> TimeInterval {
        entries.reduce(0) { $0 + $1.duration }
    }

    func todayMoney(entries: [TimeEntry], hourlyRate: Double) -> Double {
        todayTotal(entries: entries) / 3600.0 * hourlyRate
    }

    // MARK: - Supabase Sync

    func syncDailyStats(entries: [TimeEntry]) async {
        guard SupabaseManager.shared.isAuthenticated else { return }

        let today = Calendar.current.startOfDay(for: .now)
        let todayEntries = entries.filter { !$0.isRunning && $0.startTime >= today }

        guard !todayEntries.isEmpty else { return }

        let rawTotal = todayEntries.reduce(0.0) { $0 + $1.duration }
        // Cap at workHoursPerDay to prevent inflated benchmark data
        let workHoursPerDay = UserDefaults.standard.double(forKey: "workHoursPerDay")
        let dailyCap = RecordingLimits.dailyCapSeconds(workHoursPerDay: workHoursPerDay > 0 ? workHoursPerDay : 8)
        let totalSeconds = Int(min(rawTotal, dailyCap))
        let sessionCount = todayEntries.count

        // Find most used category today
        var categoryCounts: [String: Int] = [:]
        for entry in todayEntries {
            categoryCounts[entry.category, default: 0] += 1
        }
        let topCategoryRaw = categoryCounts.max(by: { $0.value < $1.value })?.key
        // Map custom categories to their parent for benchmark data quality
        let topCategory = topCategoryRaw.map { SlackCategory.parentName(for: $0, custom: customCategories) }

        do {
            try await SupabaseManager.shared.syncDailyStats(
                date: today,
                totalSeconds: totalSeconds,
                sessionCount: sessionCount,
                topCategory: topCategory
            )
            syncError = nil
        } catch {
            print("[Sync] Daily stats sync failed: \(error)")
            syncError = "Sync pending — data saved locally."
            // Auto-dismiss after 5 seconds
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(5))
                if syncError != nil { syncError = nil }
            }
        }
    }
}
