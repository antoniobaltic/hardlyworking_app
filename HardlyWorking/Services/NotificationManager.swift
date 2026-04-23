import Foundation
import UserNotifications

@Observable @MainActor
final class NotificationManager {
    private(set) var isAuthorized = false
    private var permissionTask: Task<Void, Never>?

    private static let hasRequestedKey = "hasRequestedNotificationPermission"
    nonisolated static let timerCategoryId = "timerReminder"
    nonisolated static let stopActionId = "stopTimer"

    // MARK: - Permission

    /// Request notification permission on first-ever timer start.
    /// Delay avoids interrupting the user right when they tap a category.
    func requestPermissionIfNeeded(delay: TimeInterval = 0) {
        guard !UserDefaults.standard.bool(forKey: Self.hasRequestedKey) else {
            // Already asked — just refresh authorization status
            Task { await refreshAuthorizationStatus() }
            return
        }

        UserDefaults.standard.set(true, forKey: Self.hasRequestedKey)

        permissionTask?.cancel()
        permissionTask = Task {
            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { return }
            }

            let center = UNUserNotificationCenter.current()
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound])
                isAuthorized = granted
            } catch {
                print("[Notifications] Permission request failed: \(error)")
            }
        }
    }

    private func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Timer Reminders

    /// Schedule local notifications for a running timer (1h and 2h marks).
    /// Pass the category name for contextual notification copy.
    func scheduleTimerReminder(category: String, startTime: Date) {
        Self.scheduleTimerReminderDirect(category: category, startTime: startTime)
    }

    /// Cancel all pending timer reminders (called when timer stops).
    func cancelTimerReminder() {
        Self.cancelTimerReminderDirect()
    }

    // MARK: - Process-agnostic helpers

    /// Static version usable from `LiveActivityIntent.perform()` or any context without
    /// access to the `NotificationManager` instance. Touches only `UNUserNotificationCenter.current()`.
    nonisolated static func scheduleTimerReminderDirect(category: String, startTime: Date) {
        let center = UNUserNotificationCenter.current()

        cancelTimerReminderDirect()

        let interval2h = startTime.addingTimeInterval(7200).timeIntervalSinceNow
        if interval2h > 1 {
            let content2h = UNMutableNotificationContent()
            content2h.title = "ACTIVITY REPORT"
            content2h.body = "Your \(category) timer has been running for 2 hours. Still reclaiming, or did you accidentally become productive?"
            content2h.sound = .default
            content2h.categoryIdentifier = timerCategoryId

            let trigger2h = UNTimeIntervalNotificationTrigger(timeInterval: interval2h, repeats: false)
            center.add(UNNotificationRequest(identifier: "timer-reminder-2h", content: content2h, trigger: trigger2h))
        }

        let interval3h = startTime.addingTimeInterval(10800).timeIntervalSinceNow
        if interval3h > 1 {
            let content3h = UNMutableNotificationContent()
            content3h.title = "ACTIVITY AUDIT"
            content3h.body = "Session exceeds 3 hours. HR has been notified. (Just kidding. But your timer is still going.)"
            content3h.sound = .default
            content3h.categoryIdentifier = timerCategoryId

            let trigger3h = UNTimeIntervalNotificationTrigger(timeInterval: interval3h, repeats: false)
            center.add(UNNotificationRequest(identifier: "timer-reminder-3h", content: content3h, trigger: trigger3h))
        }
    }

    nonisolated static func cancelTimerReminderDirect() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["timer-reminder-2h", "timer-reminder-3h"]
        )
    }

    // MARK: - Category Registration

    /// Register notification categories with actions. Call once at app launch.
    nonisolated static func registerCategories() {
        let stopAction = UNNotificationAction(
            identifier: stopActionId,
            title: "Stop Timer",
            options: [.destructive]
        )

        let timerCategory = UNNotificationCategory(
            identifier: timerCategoryId,
            actions: [stopAction],
            intentIdentifiers: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([timerCategory])
    }
}
