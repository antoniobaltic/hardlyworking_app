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
    @ObservationIgnored private var hourlyRate: Double = 15.0

    func startSlacking(category: SlackCategory, entries: [TimeEntry]) {
        guard let modelContext else { return }

        let wasRunning = entries.contains(where: \.isRunning)

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

        // Compute the 3 most-recently-used categories (excluding the one we just started)
        // for the Dynamic Island / Lock Screen substitute chips.
        let allDescriptor = FetchDescriptor<TimeEntry>()
        let historical = (try? modelContext.fetch(allDescriptor)) ?? []
        let substitutes = SubstituteResolver.compute(
            excluding: category.name,
            historicalEntries: historical,
            customCategories: customCategories
        )

        // If we just stopped a previous entry as part of this switch, its
        // duration needs to hit Supabase — otherwise the server under-reports.
        // Capture the context weakly (it's a value-ish reference, MainActor-isolated).
        if wasRunning {
            let ctx = modelContext
            Task { await SupabaseSync.syncTodayStats(context: ctx) }
        }

        // Live Activity: seamless update when switching categories, fresh start otherwise.
        let startDate = entry.startTime
        let emoji = category.emoji
        let name = category.name
        Task {
            if wasRunning {
                await LiveActivityService.update(categoryName: name, categoryEmoji: emoji, substitutes: substitutes, startDate: startDate)
            } else {
                await LiveActivityService.start(categoryName: name, categoryEmoji: emoji, substitutes: substitutes, startDate: startDate)
            }
        }
    }

    func stopSlacking(entries: [TimeEntry]) {
        guard let running = entries.first(where: \.isRunning) else { return }
        running.endTime = .now
        try? modelContext?.save()

        // Cancel pending timer reminders
        notificationManager?.cancelTimerReminder()

        // Dismiss the Live Activity
        Task { await LiveActivityService.end() }

        // Sync today's aggregated stats to Supabase (via the shared helper so
        // every stop-path — in-app, Dynamic Island, notification, caps —
        // converges on one upsert routine).
        if let ctx = modelContext {
            Task { await SupabaseSync.syncTodayStats(context: ctx) }
        }

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
}
