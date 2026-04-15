import Foundation

struct ShareCardData {
    let totalMoney: Double
    let totalHours: Double
    let totalSessions: Int
    let topCategory: TopCategoryInfo?
    let longestSession: SessionRecord?
    let laziestDay: DayRecord?
    let industry: String?
    let country: String?
    let hourlyRate: Double
    let recentAchievement: AchievementInfo?
    /// Current consecutive-workday streak (Mon–Fri, skips weekends). Sourced
    /// from `AchievementCatalog.calculateStreak`.
    let currentStreak: Int

    struct TopCategoryInfo {
        let name: String
        let emoji: String
        let percentage: Double
        let count: Int
    }

    struct SessionRecord {
        let duration: TimeInterval
        let category: String
        let emoji: String
        let date: Date
    }

    struct DayRecord {
        let duration: TimeInterval
        let date: Date
    }

    struct AchievementInfo {
        let name: String
        let emoji: String
        let rarity: AchievementRarity
        let detail: String
    }

    static func build(
        stats: DashboardViewModel.CareerStats,
        rankings: [DashboardViewModel.CategoryRank],
        industry: String?,
        country: String?,
        hourlyRate: Double,
        customCategories: [CustomCategory],
        currentStreak: Int = 0,
        recentAchievement: AchievementUnlockEvent? = nil
    ) -> ShareCardData {
        let topCategory: TopCategoryInfo? = rankings.first.map { rank in
            TopCategoryInfo(name: rank.name, emoji: rank.emoji, percentage: rank.percentage, count: 0)
        }

        let longestSession: SessionRecord? = stats.longestSession.map { session in
            SessionRecord(
                duration: session.duration,
                category: session.category,
                emoji: SlackCategory.emoji(for: session.category, custom: customCategories),
                date: session.date
            )
        }

        let laziestDay: DayRecord? = stats.laziestDay.map { day in
            DayRecord(duration: day.duration, date: day.date)
        }

        let achievementInfo: AchievementInfo? = recentAchievement.map { event in
            AchievementInfo(name: event.definition.name, emoji: event.definition.emoji, rarity: event.rarity, detail: "Tier \(romanNumeral(event.level))")
        }

        // Apply the Budget Variance ratchet to `totalMoney` so the share-card
        // number can't be inflated (or deflated) by hourly-rate changes —
        // matches the Budget Variance achievement's monotonic behaviour.
        let ratchetedMoney = max(
            stats.totalMoney,
            UserDefaults.standard.double(forKey: "budgetVarianceRatchet")
        )

        return ShareCardData(
            totalMoney: ratchetedMoney,
            totalHours: stats.totalTime / 3600.0,
            totalSessions: stats.totalSessions,
            topCategory: topCategory,
            longestSession: longestSession,
            laziestDay: laziestDay,
            industry: industry,
            country: country,
            hourlyRate: hourlyRate,
            recentAchievement: achievementInfo,
            currentStreak: currentStreak
        )
    }

    private static func romanNumeral(_ n: Int) -> String {
        switch n {
        case 1: "I"
        case 2: "II"
        case 3: "III"
        case 4: "IV"
        case 5: "V"
        case 6: "VI"
        case 7: "VII"
        default: "\(n)"
        }
    }
}

enum ShareCardType: String, CaseIterable, Identifiable {
    case money = "Performance Review"
    case category = "Incident Report"
    case record = "Personal Best"
    case achievement = "Commendation"
    case laziestDay = "Peak Inactivity"
    case streak = "Attendance Record"

    var id: String { rawValue }

    var sectionHeader: String {
        switch self {
        case .money: "ANNUAL PERFORMANCE REVIEW"
        case .category: "INCIDENT REPORT"
        case .record: "PERSONAL BEST"
        case .achievement: "COMMENDATION ISSUED"
        case .laziestDay: "PEAK INACTIVITY REPORT"
        case .streak: "ATTENDANCE VERIFICATION"
        }
    }

    /// Small glyph shown on the type-picker pill so users can see intent
    /// before committing to a selection.
    var previewEmoji: String {
        switch self {
        case .money: "\u{1F4B0}"                // 💰
        case .category: "\u{1F4CB}"             // 📋
        case .record: "\u{1F3C6}"               // 🏆
        case .achievement: "\u{1F396}\u{FE0F}"  // 🎖️
        case .laziestDay: "\u{1F6CB}\u{FE0F}"   // 🛋️
        case .streak: "\u{1F4C5}"               // 📅
        }
    }
}

/// Shared logical canvas for every share card. We render at @3x for a
/// final image of 1080 × 1440 (4:3 portrait), which fits Instagram's
/// 4:5 feed crop generously, prints cleanly, and reads well in WhatsApp /
/// Messages previews. Kept as a free-standing constant rather than an
/// enum case because there is only one supported format.
enum ShareCardCanvas {
    static let logicalSize = CGSize(width: 360, height: 480)
}
