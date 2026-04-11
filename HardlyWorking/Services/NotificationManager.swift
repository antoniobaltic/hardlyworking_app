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
        let center = UNUserNotificationCenter.current()

        // Cancel any existing reminders first (safety for rapid category switches)
        cancelTimerReminder()

        // 1-hour reminder
        let interval1h = startTime.addingTimeInterval(3600).timeIntervalSinceNow
        if interval1h > 1 {
            let content1h = UNMutableNotificationContent()
            content1h.title = "ACTIVITY REPORT"
            content1h.body = "Your \(category) timer has been running for 1 hour. Still reclaiming, or did you accidentally become productive?"
            content1h.sound = .default
            content1h.categoryIdentifier = Self.timerCategoryId

            let trigger1h = UNTimeIntervalNotificationTrigger(timeInterval: interval1h, repeats: false)
            center.add(UNNotificationRequest(identifier: "timer-reminder-1h", content: content1h, trigger: trigger1h))
        }

        // 2-hour reminder (soft cap)
        let interval2h = startTime.addingTimeInterval(7200).timeIntervalSinceNow
        if interval2h > 1 {
            let content2h = UNMutableNotificationContent()
            content2h.title = "ACTIVITY AUDIT"
            content2h.body = "Session exceeds 2 hours. HR has been notified. (Just kidding. But your timer is still going.)"
            content2h.sound = .default
            content2h.categoryIdentifier = Self.timerCategoryId

            let trigger2h = UNTimeIntervalNotificationTrigger(timeInterval: interval2h, repeats: false)
            center.add(UNNotificationRequest(identifier: "timer-reminder-2h", content: content2h, trigger: trigger2h))
        }
    }

    /// Cancel all pending timer reminders (called when timer stops).
    func cancelTimerReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["timer-reminder-1h", "timer-reminder-2h"]
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
