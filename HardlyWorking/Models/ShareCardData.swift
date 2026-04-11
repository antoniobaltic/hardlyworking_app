import Foundation

struct ShareCardData {
    let totalMoney: Double
    let totalHours: Double
    let totalSessions: Int
    let daysActive: Int
    let topCategory: TopCategoryInfo?
    let longestSession: SessionRecord?
    let laziestDay: DayRecord?
    let percentile: Int?
    let industry: String?
    let country: String?
    let hourlyRate: Double
    let recentAchievement: AchievementInfo?

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
        percentile: Int?,
        industry: String?,
        country: String?,
        hourlyRate: Double,
        customCategories: [CustomCategory],
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
            AchievementInfo(name: event.definition.name, emoji: event.definition.emoji, rarity: event.rarity, detail: "Level \(event.level)")
        }

        return ShareCardData(
            totalMoney: stats.totalMoney,
            totalHours: stats.totalTime / 3600.0,
            totalSessions: stats.totalSessions,
            daysActive: stats.daysActive,
            topCategory: topCategory,
            longestSession: longestSession,
            laziestDay: laziestDay,
            percentile: percentile,
            industry: industry,
            country: country,
            hourlyRate: hourlyRate,
            recentAchievement: achievementInfo
        )
    }
}

enum ShareCardType: String, CaseIterable, Identifiable {
    case money = "Performance Review"
    case percentile = "Benchmark Report"
    case category = "Incident Report"
    case record = "Personal Best"
    case achievement = "Commendation"

    var id: String { rawValue }

    var sectionHeader: String {
        switch self {
        case .money: "ANNUAL PERFORMANCE REVIEW"
        case .percentile: "BENCHMARK REPORT"
        case .category: "INCIDENT REPORT"
        case .record: "PERSONAL BEST"
        case .achievement: "COMMENDATION ISSUED"
        }
    }
}

enum ShareCardFormat: String, CaseIterable, Identifiable {
    case stories = "Stories"
    case square = "Square"

    var id: String { rawValue }

    var logicalSize: CGSize {
        switch self {
        case .stories: CGSize(width: 360, height: 640)
        case .square: CGSize(width: 360, height: 360)
        }
    }
}
