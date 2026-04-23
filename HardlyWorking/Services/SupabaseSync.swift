import Foundation
import SwiftData

/// Aggregates locally-completed TimeEntry rows and upserts them into Supabase's
/// `daily_stats`, the table the benchmarks RPC reads from.
///
/// Before this helper existed, `syncDailyStats` was called from exactly one
/// place (`TimerViewModel.stopSlacking` — the in-app stop button). Any session
/// finalized via the Dynamic Island END button, a Live Activity substitute chip,
/// the notification "Stop Timer" action, hard/daily cap enforcement, or the
/// overnight sheet handlers silently bypassed the upsert — leaving the server's
/// company-wide metrics permanently under-reporting until the next in-app stop.
///
/// All end-paths now call `syncTodayStats(context:)`. As belt-and-suspenders,
/// `backfillRecentDays(context:days:)` runs on every foreground transition to
/// catch anything that slipped through (crashes, terminated background, offline
/// syncs that never flushed).
enum SupabaseSync {
    /// Upsert the aggregate for *today* to `daily_stats`. Idempotent.
    @MainActor
    static func syncTodayStats(context: ModelContext) async {
        await syncStats(for: Calendar.current.startOfDay(for: .now), context: context)
    }

    /// Back-fill the last `days` worth of daily aggregates. Safe to call on
    /// every foreground transition — each day's row is upserted on
    /// `(user_id, date)` so repeats are no-ops if nothing changed locally.
    ///
    /// Default spans 8 days (today + 7 past) to fully cover the retroactive
    /// entry window enforced by `RecordingLimits.retroactiveLookbackDays = 7`.
    /// Bumping to 8 is cheap (8 small upserts max) and protects against a user
    /// filing a retroactive entry on their oldest allowed day and it not being
    /// picked up by the sweep.
    @MainActor
    static func backfillRecentDays(context: ModelContext, days: Int = 8) async {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        for offset in 0..<days {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            await syncStats(for: day, context: context)
        }
    }

    // MARK: - Internal

    @MainActor
    private static func syncStats(for day: Date, context: ModelContext) async {
        guard SupabaseManager.shared.isAuthenticated else { return }

        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: day)
        guard let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) else { return }

        // Completed entries that started on this calendar day. Running entries
        // (endTime == nil) are excluded until they finalize.
        let descriptor = FetchDescriptor<TimeEntry>(
            predicate: #Predicate {
                $0.startTime >= dayStart && $0.startTime < dayEnd && $0.endTime != nil
            }
        )
        guard let completed = try? context.fetch(descriptor), !completed.isEmpty else {
            return
        }

        let rawTotal = completed.reduce(0.0) { $0 + $1.duration }
        // Cap at the user's configured workday length so one outlier-long
        // session can't inflate the company-wide averages.
        let workHoursPerDay = UserDefaults.standard.double(forKey: "workHoursPerDay")
        let dailyCap = RecordingLimits.dailyCapSeconds(
            workHoursPerDay: workHoursPerDay > 0 ? workHoursPerDay : 8
        )
        let totalSeconds = Int(min(rawTotal, dailyCap))
        let sessionCount = completed.count

        var categoryCounts: [String: Int] = [:]
        for entry in completed {
            categoryCounts[entry.category, default: 0] += 1
        }
        let topCategoryRaw = categoryCounts.max(by: { $0.value < $1.value })?.key

        // Resolve custom categories to their parent default so benchmark
        // aggregates don't fragment on user-specific names.
        let customDescriptor = FetchDescriptor<CustomCategory>()
        let customs = (try? context.fetch(customDescriptor)) ?? []
        let topCategory = topCategoryRaw.map {
            SlackCategory.parentName(for: $0, custom: customs)
        }

        do {
            try await SupabaseManager.shared.syncDailyStats(
                date: dayStart,
                totalSeconds: totalSeconds,
                sessionCount: sessionCount,
                topCategory: topCategory
            )
        } catch {
            print("[SupabaseSync] daily_stats upsert failed for \(dayStart): \(error)")
        }
    }
}
