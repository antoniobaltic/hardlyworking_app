import Foundation
import StoreKit
import SwiftUI

enum RatingEvent {
    case timerCompleted
    case dashboardViewed
    case achievementUnlocked
    case shareCardCreated
    case subscribedToPro

    var points: Double {
        switch self {
        case .timerCompleted: 3
        case .dashboardViewed: 2
        case .achievementUnlocked: 5
        case .shareCardCreated: 5
        case .subscribedToPro: 8
        }
    }
}

@Observable @MainActor
final class RatingManager {
    var showSatisfactionSurvey = false

    private enum Keys {
        static let installDate = "rating_installDate"
        static let happinessScore = "rating_happinessScore"
        static let lastScoreUpdate = "rating_lastScoreUpdate"
        static let completedSessions = "rating_completedSessions"
        static let lastPromptDate = "rating_lastPromptDate"
        static let lastPromptedVersion = "rating_lastPromptedVersion"
        static let totalPromptsShown = "rating_totalPromptsShown"
    }

    private let minimumDaysSinceInstall = 7
    private let minimumCompletedSessions = 5
    private let happinessThreshold: Double = 12
    private let cooldownDays = 90
    private let lifetimePromptCap = 3

    // MARK: - Record Events

    func recordInstallIfNeeded() {
        if UserDefaults.standard.double(forKey: Keys.installDate) == 0 {
            UserDefaults.standard.set(Date.now.timeIntervalSince1970, forKey: Keys.installDate)
        }
    }

    func recordSessionCompleted() {
        let current = UserDefaults.standard.integer(forKey: Keys.completedSessions)
        UserDefaults.standard.set(current + 1, forKey: Keys.completedSessions)
        recordEvent(.timerCompleted)
    }

    private var isPromptPending = false

    func recordEvent(_ event: RatingEvent) {
        addPoints(event.points)

        // Prevent multiple concurrent prompt Tasks
        guard !isPromptPending && !showSatisfactionSurvey else { return }

        if shouldPrompt() {
            isPromptPending = true
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2.0))
                isPromptPending = false
                showSatisfactionSurvey = true
            }
        }
    }

    // MARK: - Responses

    func recordPositiveResponse() {
        triggerSystemPrompt()
        recordPromptShown()
        Haptics.success()
        showSatisfactionSurvey = false
    }

    func recordNeutralResponse() {
        triggerSystemPrompt()
        recordPromptShown()
        Haptics.light()
        showSatisfactionSurvey = false
    }

    func recordNegativeResponse() {
        UserDefaults.standard.set(0, forKey: Keys.happinessScore)
        UserDefaults.standard.set(Date.now.timeIntervalSince1970, forKey: Keys.lastScoreUpdate)
        Haptics.light()
        showSatisfactionSurvey = false
    }

    func dismissSurvey() {
        showSatisfactionSurvey = false
    }

    // MARK: - Scoring

    private func addPoints(_ points: Double) {
        let current = UserDefaults.standard.double(forKey: Keys.happinessScore)
        UserDefaults.standard.set(current + points, forKey: Keys.happinessScore)
        UserDefaults.standard.set(Date.now.timeIntervalSince1970, forKey: Keys.lastScoreUpdate)
    }

    private var decayedScore: Double {
        let raw = UserDefaults.standard.double(forKey: Keys.happinessScore)
        let lastUpdate = UserDefaults.standard.double(forKey: Keys.lastScoreUpdate)
        guard lastUpdate > 0 else { return raw }
        let decayDays = (Date.now.timeIntervalSince1970 - lastUpdate) / 86400
        return max(0, raw - decayDays)
    }

    // MARK: - Conditions

    private func shouldPrompt() -> Bool {
        let installTimestamp = UserDefaults.standard.double(forKey: Keys.installDate)
        guard installTimestamp > 0 else { return false }
        let daysSinceInstall = Calendar.current.dateComponents([.day], from: Date(timeIntervalSince1970: installTimestamp), to: .now).day ?? 0
        guard daysSinceInstall >= minimumDaysSinceInstall else { return false }

        guard UserDefaults.standard.integer(forKey: Keys.completedSessions) >= minimumCompletedSessions else { return false }
        guard decayedScore >= happinessThreshold else { return false }

        let lastPromptTimestamp = UserDefaults.standard.double(forKey: Keys.lastPromptDate)
        if lastPromptTimestamp > 0 {
            let daysSincePrompt = Calendar.current.dateComponents([.day], from: Date(timeIntervalSince1970: lastPromptTimestamp), to: .now).day ?? 0
            guard daysSincePrompt >= cooldownDays else { return false }
        }

        let lastVersion = UserDefaults.standard.string(forKey: Keys.lastPromptedVersion) ?? ""
        guard lastVersion != currentAppVersion else { return false }
        guard UserDefaults.standard.integer(forKey: Keys.totalPromptsShown) < lifetimePromptCap else { return false }

        return true
    }

    // MARK: - System Prompt

    @MainActor
    private func triggerSystemPrompt() {
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first {
            AppStore.requestReview(in: scene)
        }
    }

    private func recordPromptShown() {
        UserDefaults.standard.set(Date.now.timeIntervalSince1970, forKey: Keys.lastPromptDate)
        UserDefaults.standard.set(currentAppVersion, forKey: Keys.lastPromptedVersion)
        let total = UserDefaults.standard.integer(forKey: Keys.totalPromptsShown)
        UserDefaults.standard.set(total + 1, forKey: Keys.totalPromptsShown)
        UserDefaults.standard.set(0, forKey: Keys.happinessScore)
    }

    private var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
