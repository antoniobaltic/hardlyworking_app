import ActivityKit
import Foundation

/// Thin wrapper over ActivityKit for starting/updating/ending the session Live Activity.
/// Invariant: at most one live activity at a time, mirroring the "at most one running TimeEntry"
/// invariant enforced throughout the rest of the codebase.
@MainActor
enum LiveActivityService {
    typealias ActivityType = Activity<HardlyWorkingActivityAttributes>

    // MARK: - Start

    /// Begin a new Live Activity for the given category. Ends any existing activity first.
    static func start(
        categoryName: String,
        categoryEmoji: String,
        substitutes: [SubstituteCode],
        startDate: Date = .now
    ) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        await endAll()

        let state = makeState(
            categoryName: categoryName,
            categoryEmoji: categoryEmoji,
            startDate: startDate,
            substitutes: substitutes
        )
        do {
            _ = try ActivityType.request(
                attributes: HardlyWorkingActivityAttributes(),
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("[LiveActivity] Failed to start: \(error)")
        }
    }

    // MARK: - Update

    /// Update the running activity in place — used for seamless category switches.
    static func update(
        categoryName: String,
        categoryEmoji: String,
        substitutes: [SubstituteCode],
        startDate: Date
    ) async {
        let state = makeState(
            categoryName: categoryName,
            categoryEmoji: categoryEmoji,
            startDate: startDate,
            substitutes: substitutes
        )
        for activity in ActivityType.activities {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    // MARK: - End

    /// Dismiss the current Live Activity immediately.
    static func end() async {
        await endAll()
    }

    private static func endAll() async {
        for activity in ActivityType.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    // MARK: - Reconcile

    /// Reconciles the live activity with SwiftData state. Call on app launch / first foreground.
    ///
    /// Four cases:
    /// - Neither running entry nor activity → no-op.
    /// - Activity without entry → end orphan.
    /// - Entry without activity → start a new one (e.g. after reboot wiped activities).
    /// - Both present → refresh state in case category/rate drifted.
    static func reattach(
        runningCategory: String?,
        runningEmoji: String?,
        runningStart: Date?,
        substitutes: [SubstituteCode]
    ) async {
        let hasActivity = !ActivityType.activities.isEmpty

        guard let category = runningCategory, let startDate = runningStart else {
            if hasActivity { await endAll() }
            return
        }

        let emoji = runningEmoji ?? ""
        if hasActivity {
            await update(
                categoryName: category,
                categoryEmoji: emoji,
                substitutes: substitutes,
                startDate: startDate
            )
        } else {
            await start(
                categoryName: category,
                categoryEmoji: emoji,
                substitutes: substitutes,
                startDate: startDate
            )
        }
    }

    // MARK: - State construction

    private static func makeState(
        categoryName: String,
        categoryEmoji: String,
        startDate: Date,
        substitutes: [SubstituteCode]
    ) -> HardlyWorkingActivityAttributes.ContentState {
        let rawRate = UserDefaults.standard.double(forKey: "hourlyRate")
        let rate = rawRate > 0 ? rawRate : 15.0
        let code = UserDefaults.standard.string(forKey: "currency") ?? "USD"
        return HardlyWorkingActivityAttributes.ContentState(
            categoryName: categoryName,
            categoryEmoji: categoryEmoji,
            startDate: startDate,
            hourlyRate: rate,
            currencySymbol: Theme.currencySymbol(for: code),
            substitutes: substitutes
        )
    }
}
