import ActivityKit
import AppIntents
import SwiftData
import UserNotifications

/// Fired by a "Substitute code" chip in the expanded Dynamic Island / Lock Screen card.
/// Stops the current running entry and starts a fresh one under the new category,
/// then updates the Live Activity in place so the island doesn't flash.
struct SwitchActivityIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Substitute Code"
    static let description = IntentDescription("Stops the current activity and starts a new one.")

    @Parameter(title: "Category Name")
    var categoryName: String

    @Parameter(title: "Category Emoji")
    var categoryEmoji: String

    init() {
        self.categoryName = ""
        self.categoryEmoji = ""
    }

    init(categoryName: String, categoryEmoji: String) {
        self.categoryName = categoryName
        self.categoryEmoji = categoryEmoji
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard !categoryName.isEmpty else { return .result() }

        let newStart = Date.now
        var substitutes: [SubstituteCode] = []

        if let container = try? ModelContainer(
            for: TimeEntry.self, UnlockedAchievement.self, CustomCategory.self
        ) {
            let context = container.mainContext

            let runningDescriptor = FetchDescriptor<TimeEntry>(
                predicate: #Predicate { $0.endTime == nil }
            )
            if let running = (try? context.fetch(runningDescriptor))?.first {
                running.endTime = newStart
            }

            let newEntry = TimeEntry(category: categoryName, startTime: newStart)
            context.insert(newEntry)
            try? context.save()

            // After save: fetch fresh historical state and resolve the 3 MRU codes,
            // so the updated Live Activity shows substitute chips that reflect the
            // user's actual recent behaviour (minus the one we just switched to).
            let allDescriptor = FetchDescriptor<TimeEntry>()
            let historical = (try? context.fetch(allDescriptor)) ?? []
            let customDescriptor = FetchDescriptor<CustomCategory>()
            let customs = (try? context.fetch(customDescriptor)) ?? []
            substitutes = SubstituteResolver.compute(
                excluding: categoryName,
                historicalEntries: historical,
                customCategories: customs
            )

            // Upsert today's aggregate so the stopped-on-switch session shows
            // up in the company-wide Intel page. `MAIN_APP` is a custom
            // compilation condition set only on the main app target (widget
            // extension doesn't link Supabase). This intent's body runs in the
            // app process only, so the widget-target compile just needs the
            // block skipped, not executed.
            #if MAIN_APP
            await SupabaseSync.syncTodayStats(context: context)
            #endif
        }

        NotificationManager.cancelTimerReminderDirect()
        NotificationManager.scheduleTimerReminderDirect(category: categoryName, startTime: newStart)

        await LiveActivityService.update(
            categoryName: categoryName,
            categoryEmoji: categoryEmoji,
            substitutes: substitutes,
            startDate: newStart
        )

        return .result()
    }
}
