import ActivityKit
import AppIntents
import SwiftData
import UserNotifications

/// Fired by the END ACTIVITY button on the Live Activity / Dynamic Island.
/// `LiveActivityIntent`'s `perform()` runs in the host app's process, so we can touch the
/// main SwiftData container directly — the same trick used by the notification-action handler
/// in `AppDelegate.stopRunningTimer()`.
struct EndSessionIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "End Activity"
    static let description = IntentDescription("Concludes the current reclamation session.")

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        if let container = try? ModelContainer(
            for: TimeEntry.self, UnlockedAchievement.self, CustomCategory.self
        ) {
            let context = container.mainContext
            let descriptor = FetchDescriptor<TimeEntry>(
                predicate: #Predicate { $0.endTime == nil }
            )
            if let running = (try? context.fetch(descriptor))?.first {
                running.endTime = .now
                try? context.save()
            }

            // Upsert today's aggregate so the company-wide Intel page reflects
            // sessions ended from the Dynamic Island, not just the in-app stop.
            // `MAIN_APP` is a custom compilation condition set only on the main
            // app target (not the widget extension, which doesn't link Supabase).
            // This intent's `perform()` runs in the app process only, so the
            // widget-target compiled copy never executes anyway — we just need
            // it to compile, which gating the Supabase call here achieves.
            #if MAIN_APP
            await SupabaseSync.syncTodayStats(context: context)
            #endif
        }

        NotificationManager.cancelTimerReminderDirect()
        await LiveActivityService.end()

        return .result()
    }
}
