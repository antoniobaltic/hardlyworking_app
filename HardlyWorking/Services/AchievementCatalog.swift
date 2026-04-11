import SwiftUI

// MARK: - Rarity Tiers

enum AchievementRarity: Int, Comparable {
    case common = 1
    case uncommon = 2
    case rare = 3
    case elite = 4
    case legendary = 5

    static func < (lhs: AchievementRarity, rhs: AchievementRarity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .common: "MEETS EXPECTATIONS"
        case .uncommon: "EXCEEDS EXPECTATIONS"
        case .rare: "DISTINGUISHED PERFORMANCE"
        case .elite: "EXECUTIVE MATERIAL"
        case .legendary: "BOARD-LEVEL CONCERN"
        }
    }

    var color: Color {
        switch self {
        case .common: Theme.textPrimary.opacity(0.4)
        case .uncommon: Theme.accent
        case .rare: Theme.cautionYellow
        case .elite: Theme.money
        case .legendary: Theme.timer
        }
    }
}

// MARK: - Achievement Level

struct AchievementLevel: Sendable {
    let threshold: Double
    let rarity: AchievementRarity
}

// MARK: - Achievement Definition

struct AchievementDefinition: Identifiable, Sendable {
    let id: String
    let name: String
    let description: String
    let emoji: String
    let category: AchievementCategory
    let levels: [AchievementLevel]
    let isSecret: Bool
    let isProOnly: Bool
    let checker: @Sendable ([TimeEntry], Double) -> Double

    var totalLevels: Int { levels.count }

    func currentLevel(for progressValue: Double) -> Int {
        var level = 0
        for (index, achievementLevel) in levels.enumerated() {
            if progressValue >= achievementLevel.threshold {
                level = index + 1
            }
        }
        return level
    }

    func rarityForLevel(_ level: Int) -> AchievementRarity {
        guard level > 0, level <= levels.count else { return .common }
        return levels[level - 1].rarity
    }

    func thresholdForLevel(_ level: Int) -> Double {
        guard level > 0, level <= levels.count else { return 0 }
        return levels[level - 1].threshold
    }

    func nextThreshold(after currentProgress: Double) -> Double? {
        for achievementLevel in levels {
            if currentProgress < achievementLevel.threshold {
                return achievementLevel.threshold
            }
        }
        return nil
    }
}

enum AchievementCategory: String, CaseIterable {
    case streak = "Attendance"
    case milestone = "Tenure"
    case discovery = "Exploration"
    case record = "Distinctions"
    case secret = "Classified"
}

// MARK: - The Catalog

enum AchievementCatalog {
    static let all: [AchievementDefinition] = streaks + milestones + discoveries + records + secrets
    static let totalUnlockMoments: Int = all.reduce(0) { $0 + $1.totalLevels }

    static let streaks: [AchievementDefinition] = [
        AchievementDefinition(id: "perfect_attendance", name: "Perfect Attendance", description: "Record slacking on consecutive work days. HR is impressed by your commitment.", emoji: "\u{1F4C5}", category: .streak, levels: [
            AchievementLevel(threshold: 3, rarity: .common), AchievementLevel(threshold: 7, rarity: .common), AchievementLevel(threshold: 14, rarity: .uncommon), AchievementLevel(threshold: 30, rarity: .rare), AchievementLevel(threshold: 100, rarity: .elite), AchievementLevel(threshold: 365, rarity: .legendary),
        ], isSecret: false, isProOnly: false, checker: { entries, _ in Double(Self.calculateStreak(entries: entries)) }),
        AchievementDefinition(id: "consistent_contributor", name: "Consistent Contributor", description: "Log at least one session every week. Consistency is a core competency.", emoji: "\u{1F504}", category: .streak, levels: [
            AchievementLevel(threshold: 4, rarity: .common), AchievementLevel(threshold: 8, rarity: .uncommon), AchievementLevel(threshold: 12, rarity: .rare), AchievementLevel(threshold: 26, rarity: .elite),
        ], isSecret: false, isProOnly: false, checker: { entries, _ in Double(Self.calculateWeeklyStreak(entries: entries)) }),
        AchievementDefinition(id: "early_bird_deviation", name: "Early Bird Deviation", description: "Track slacking before 9 AM. The early bird gets to slack first.", emoji: "\u{1F305}", category: .streak, levels: [
            AchievementLevel(threshold: 1, rarity: .common), AchievementLevel(threshold: 5, rarity: .uncommon), AchievementLevel(threshold: 20, rarity: .rare),
        ], isSecret: false, isProOnly: false, checker: { entries, _ in
            Double(Set(entries.filter { !$0.isRunning && Calendar.current.component(.hour, from: $0.startTime) < 9 }.map { Calendar.current.startOfDay(for: $0.startTime) }).count)
        }),
    ]

    static let milestones: [AchievementDefinition] = [
        AchievementDefinition(id: "orientation_complete", name: "Orientation Complete", description: "Log your first session. Welcome aboard. Or not.", emoji: "\u{1F393}", category: .milestone, levels: [
            AchievementLevel(threshold: 1, rarity: .common),
        ], isSecret: false, isProOnly: false, checker: { entries, _ in Double(entries.filter { !$0.isRunning }.count > 0 ? 1 : 0) }),
        AchievementDefinition(id: "quarterly_review", name: "Quarterly Review", description: "Reclaim X total hours. Time well not-spent.", emoji: "\u{23F1}", category: .milestone, levels: [
            AchievementLevel(threshold: 10, rarity: .common), AchievementLevel(threshold: 50, rarity: .uncommon), AchievementLevel(threshold: 100, rarity: .rare), AchievementLevel(threshold: 500, rarity: .elite), AchievementLevel(threshold: 1000, rarity: .legendary),
        ], isSecret: false, isProOnly: false, checker: { entries, _ in entries.filter { !$0.isRunning }.reduce(0) { $0 + $1.duration } / 3600.0 }),
        AchievementDefinition(id: "budget_variance", name: "Budget Variance", description: "Reclaim $X from your employer. The accounting department has questions.", emoji: "\u{1F4B0}", category: .milestone, levels: [
            AchievementLevel(threshold: 100, rarity: .common), AchievementLevel(threshold: 500, rarity: .uncommon), AchievementLevel(threshold: 1000, rarity: .rare), AchievementLevel(threshold: 5000, rarity: .elite), AchievementLevel(threshold: 10000, rarity: .legendary),
        ], isSecret: false, isProOnly: false, checker: { entries, hourlyRate in entries.filter { !$0.isRunning }.reduce(0) { $0 + $1.duration } / 3600.0 * hourlyRate }),
        AchievementDefinition(id: "repeat_offender", name: "Repeat Offender", description: "Log X total sessions. At this point it's a pattern, not an incident.", emoji: "\u{1F4CA}", category: .milestone, levels: [
            AchievementLevel(threshold: 10, rarity: .common), AchievementLevel(threshold: 50, rarity: .uncommon), AchievementLevel(threshold: 100, rarity: .rare), AchievementLevel(threshold: 500, rarity: .elite), AchievementLevel(threshold: 1000, rarity: .legendary),
        ], isSecret: false, isProOnly: false, checker: { entries, _ in Double(entries.filter { !$0.isRunning }.count) }),
    ]

    static let discoveries: [AchievementDefinition] = [
        AchievementDefinition(id: "cross_functional", name: "Cross-Functional Experience", description: "Try X different categories. A well-rounded lack of productivity.", emoji: "\u{1F500}", category: .discovery, levels: [
            AchievementLevel(threshold: 3, rarity: .common), AchievementLevel(threshold: 5, rarity: .uncommon), AchievementLevel(threshold: 7, rarity: .rare), AchievementLevel(threshold: 10, rarity: .elite),
        ], isSecret: false, isProOnly: false, checker: { entries, _ in Double(Set(entries.filter { !$0.isRunning }.map(\.category)).count) }),
        AchievementDefinition(id: "process_improvement", name: "Process Improvement", description: "Edit a time entry. Revising history is an underrated skill.", emoji: "\u{270F}\u{FE0F}", category: .discovery, levels: [
            AchievementLevel(threshold: 1, rarity: .common),
        ], isSecret: false, isProOnly: false, checker: { _, _ in UserDefaults.standard.bool(forKey: "hasEditedEntry") ? 1.0 : 0.0 }),
        AchievementDefinition(id: "retroactive_filing", name: "Retroactive Filing", description: "Add a retroactive entry. Amending the record after the fact.", emoji: "\u{1F4DD}", category: .discovery, levels: [
            AchievementLevel(threshold: 1, rarity: .common),
        ], isSecret: false, isProOnly: false, checker: { entries, _ in entries.filter { $0.isManual }.isEmpty ? 0.0 : 1.0 }),
    ]

    static let records: [AchievementDefinition] = [
        AchievementDefinition(id: "deep_focus", name: "Deep Focus", description: "A single session longer than X. That's not slacking, that's an art form.", emoji: "\u{1F9D8}", category: .record, levels: [
            AchievementLevel(threshold: 30, rarity: .common), AchievementLevel(threshold: 60, rarity: .uncommon), AchievementLevel(threshold: 120, rarity: .rare), AchievementLevel(threshold: 240, rarity: .elite),
        ], isSecret: false, isProOnly: true, checker: { entries, _ in (entries.filter { !$0.isRunning }.map(\.duration).max() ?? 0) / 60.0 }),
        AchievementDefinition(id: "maximum_throughput", name: "Maximum Throughput", description: "Reclaim X+ hours in a single day. Peak operational inefficiency.", emoji: "\u{1F3C6}", category: .record, levels: [
            AchievementLevel(threshold: 2, rarity: .common), AchievementLevel(threshold: 4, rarity: .rare), AchievementLevel(threshold: 6, rarity: .elite), AchievementLevel(threshold: 8, rarity: .legendary),
        ], isSecret: false, isProOnly: true, checker: { entries, _ in
            let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
            var d: [String: Double] = [:]; for e in entries.filter({ !$0.isRunning }) { d[fmt.string(from: e.startTime), default: 0] += e.duration }
            return (d.values.max() ?? 0) / 3600.0
        }),
        AchievementDefinition(id: "meeting_email", name: "Meeting Could Have Been an Email", description: "Log X+ sessions in one day. You're really committed to not being committed.", emoji: "\u{1F4E7}", category: .record, levels: [
            AchievementLevel(threshold: 3, rarity: .common), AchievementLevel(threshold: 5, rarity: .uncommon), AchievementLevel(threshold: 8, rarity: .rare), AchievementLevel(threshold: 10, rarity: .elite),
        ], isSecret: false, isProOnly: true, checker: { entries, _ in
            let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
            var d: [String: Int] = [:]; for e in entries.filter({ !$0.isRunning }) { d[fmt.string(from: e.startTime), default: 0] += 1 }
            return Double(d.values.max() ?? 0)
        }),
    ]

    static let secrets: [AchievementDefinition] = [
        AchievementDefinition(id: "after_hours", name: "After Hours", description: "Track slacking before 6 AM or after 10 PM. The night shift nobody asked for.", emoji: "\u{1F319}", category: .secret, levels: [
            AchievementLevel(threshold: 1, rarity: .rare),
        ], isSecret: true, isProOnly: true, checker: { entries, _ in
            entries.filter { !$0.isRunning }.contains { let h = Calendar.current.component(.hour, from: $0.startTime); return h < 6 || h >= 22 } ? 1.0 : 0.0
        }),
        AchievementDefinition(id: "overtime", name: "Overtime", description: "Track slacking on a weekend. Even your time off isn't really time off.", emoji: "\u{1F4C6}", category: .secret, levels: [
            AchievementLevel(threshold: 1, rarity: .uncommon),
        ], isSecret: true, isProOnly: true, checker: { entries, _ in
            entries.filter { !$0.isRunning }.contains { let w = Calendar.current.component(.weekday, from: $0.startTime); return w == 1 || w == 7 } ? 1.0 : 0.0
        }),
    ]

    // MARK: - Streak Helpers

    static func calculateStreak(entries: [TimeEntry]) -> Int {
        let completed = entries.filter { !$0.isRunning }
        guard !completed.isEmpty else { return 0 }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var daysWithEntries = Set<Date>()
        for entry in completed { daysWithEntries.insert(calendar.startOfDay(for: entry.startTime)) }
        var streak = 0
        var checkDate = today
        while daysWithEntries.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }

    static func calculateWeeklyStreak(entries: [TimeEntry]) -> Int {
        let completed = entries.filter { !$0.isRunning }
        guard !completed.isEmpty else { return 0 }
        let calendar = Calendar.current
        var weeksWithEntries = Set<String>()
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-ww"
        for entry in completed { weeksWithEntries.insert(fmt.string(from: entry.startTime)) }
        var streak = 0
        var checkDate = Date.now
        while true {
            let weekKey = fmt.string(from: checkDate)
            if weeksWithEntries.contains(weekKey) {
                streak += 1
                guard let prev = calendar.date(byAdding: .weekOfYear, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else { break }
        }
        return streak
    }
}
