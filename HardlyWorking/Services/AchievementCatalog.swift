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
        case .common: Theme.textPrimary.opacity(0.5)
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

// MARK: - Unit (for formatting thresholds in descriptions)

enum AchievementUnit: Sendable {
    case count          // "5 categories"
    case hours          // "10 hours"
    case minutes        // "30 minutes"
    case money          // "$500"
    case days           // "7 days"
    case weeks          // "4 weeks"
    case sessions       // "10 sessions"
}

// MARK: - Achievement Definition

struct AchievementDefinition: Identifiable, Sendable {
    let id: String
    let name: String
    /// Short flavor text without thresholds, always safe to show
    let flavor: String
    /// How to format the threshold number in descriptions
    let unit: AchievementUnit
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

    /// Human-readable next-goal description — what you need to do next.
    /// Returns nil if all levels are complete.
    func nextGoalDescription(currentProgress: Double, currency: String = "USD") -> String? {
        guard let next = nextThreshold(after: currentProgress) else { return nil }
        let formatted = format(threshold: next, currency: currency)
        return "Next: \(formatted)"
    }

    /// Description with the *current goal* threshold filled in.
    func dynamicDescription(currentProgress: Double, currency: String = "USD") -> String {
        if let next = nextThreshold(after: currentProgress) {
            let formatted = format(threshold: next, currency: currency)
            return "\(flavor) (Next: \(formatted))"
        }
        return "\(flavor) (All levels complete.)"
    }

    private func format(threshold: Double, currency: String) -> String {
        switch unit {
        case .count:
            return "\(Int(threshold))"
        case .hours:
            return threshold == 1 ? "1 hour" : "\(Int(threshold)) hours"
        case .minutes:
            return threshold == 1 ? "1 minute" : "\(Int(threshold)) minutes"
        case .money:
            let sym = Theme.currencySymbol(for: UserDefaults.standard.string(forKey: "currency") ?? "USD")
            return "\(sym)\(Int(threshold))"
        case .days:
            return threshold == 1 ? "1 day" : "\(Int(threshold)) days"
        case .weeks:
            return threshold == 1 ? "1 week" : "\(Int(threshold)) weeks"
        case .sessions:
            return threshold == 1 ? "1 session" : "\(Int(threshold)) sessions"
        }
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
    /// Ordered by difficulty gradient: easy onboarding wins at top, grinds in the middle,
    /// Pro and secret at the bottom. Users see a motivating ladder of first unlocks.
    static let all: [AchievementDefinition] = {
        let byId = Dictionary(
            uniqueKeysWithValues: (streaks + milestones + discoveries + records + secrets).map { ($0.id, $0) }
        )
        let order = [
            "welcome_aboard",          // free gift on onboarding complete
            "orientation_complete",    // first timer stop ("First Offense")
            "process_improvement",     // edit any entry
            "retroactive_filing",      // add manual entry
            "early_bird_deviation",    // one pre-9am session
            "cross_functional",        // try 3+ categories
            "perfect_attendance",      // daily streak
            "consistent_contributor",  // weekly streak
            "repeat_offender",         // session count grind
            "lifetime_hours",          // hours grind ("Time Well Not-Spent")
            "budget_variance",         // money grind
            "deep_focus",              // Pro
            "maximum_throughput",      // Pro
            "meeting_email",           // Pro
            "after_hours",             // secret
            "overtime",                // secret
        ]
        return order.compactMap { byId[$0] }
    }()
    static let totalUnlockMoments: Int = all.reduce(0) { $0 + $1.totalLevels }
    static let totalAchievements: Int = all.count

    static let streaks: [AchievementDefinition] = [
        AchievementDefinition(
            id: "perfect_attendance",
            name: "Perfect Attendance",
            flavor: "Consecutive workdays with recorded slacking. Weekends don't count.",
            unit: .days,
            emoji: "\u{1F4C5}",
            category: .streak,
            levels: [
                AchievementLevel(threshold: 3, rarity: .common),
                AchievementLevel(threshold: 7, rarity: .common),
                AchievementLevel(threshold: 14, rarity: .uncommon),
                AchievementLevel(threshold: 30, rarity: .rare),
                AchievementLevel(threshold: 100, rarity: .elite),
                AchievementLevel(threshold: 365, rarity: .legendary),
            ],
            isSecret: false, isProOnly: false,
            checker: { entries, _ in Double(Self.calculateStreak(entries: entries)) }
        ),
        AchievementDefinition(
            id: "consistent_contributor",
            name: "Consistent Contributor",
            flavor: "Consecutive weeks with at least one session. Consistency is a core competency.",
            unit: .weeks,
            emoji: "\u{1F504}",
            category: .streak,
            levels: [
                AchievementLevel(threshold: 4, rarity: .common),
                AchievementLevel(threshold: 8, rarity: .uncommon),
                AchievementLevel(threshold: 12, rarity: .rare),
                AchievementLevel(threshold: 26, rarity: .elite),
            ],
            isSecret: false, isProOnly: false,
            checker: { entries, _ in Double(Self.calculateWeeklyStreak(entries: entries)) }
        ),
        AchievementDefinition(
            id: "early_bird_deviation",
            name: "Early Bird Deviation",
            flavor: "Days with a session before 9 AM. The early bird gets to slack first.",
            unit: .days,
            emoji: "\u{1F305}",
            category: .streak,
            levels: [
                AchievementLevel(threshold: 1, rarity: .common),
                AchievementLevel(threshold: 5, rarity: .uncommon),
                AchievementLevel(threshold: 20, rarity: .rare),
            ],
            isSecret: false, isProOnly: false,
            checker: { entries, _ in
                Double(Set(entries.filter { !$0.isRunning && Calendar.current.component(.hour, from: $0.startTime) < 9 }.map { Calendar.current.startOfDay(for: $0.startTime) }).count)
            }
        ),
    ]

    static let milestones: [AchievementDefinition] = [
        AchievementDefinition(
            id: "welcome_aboard",
            name: "Welcome Aboard",
            flavor: "Complete orientation. You're officially on the payroll. Sort of.",
            unit: .count,
            emoji: "\u{1F4BC}",
            category: .milestone,
            levels: [AchievementLevel(threshold: 1, rarity: .common)],
            isSecret: false, isProOnly: false,
            checker: { _, _ in UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") ? 1.0 : 0.0 }
        ),
        AchievementDefinition(
            id: "orientation_complete",
            name: "First Offense",
            flavor: "Log your first session. The paper trail begins.",
            unit: .sessions,
            emoji: "\u{1F393}",
            category: .milestone,
            levels: [AchievementLevel(threshold: 1, rarity: .common)],
            isSecret: false, isProOnly: false,
            checker: { entries, _ in Double(entries.filter { !$0.isRunning }.count > 0 ? 1 : 0) }
        ),
        AchievementDefinition(
            id: "lifetime_hours",
            name: "Time Well Not-Spent",
            flavor: "Total hours reclaimed across your career.",
            unit: .hours,
            emoji: "\u{23F1}",
            category: .milestone,
            levels: [
                AchievementLevel(threshold: 10, rarity: .common),
                AchievementLevel(threshold: 50, rarity: .uncommon),
                AchievementLevel(threshold: 100, rarity: .rare),
                AchievementLevel(threshold: 500, rarity: .elite),
                AchievementLevel(threshold: 1000, rarity: .legendary),
            ],
            isSecret: false, isProOnly: false,
            checker: { entries, _ in entries.filter { !$0.isRunning }.reduce(0) { $0 + $1.duration } / 3600.0 }
        ),
        AchievementDefinition(
            id: "budget_variance",
            name: "Budget Variance",
            flavor: "Wages reclaimed from your employer. The accounting department has questions.",
            unit: .money,
            emoji: "\u{1F4B0}",
            category: .milestone,
            levels: [
                AchievementLevel(threshold: 100, rarity: .common),
                AchievementLevel(threshold: 500, rarity: .uncommon),
                AchievementLevel(threshold: 1000, rarity: .rare),
                AchievementLevel(threshold: 5000, rarity: .elite),
                AchievementLevel(threshold: 10000, rarity: .legendary),
            ],
            isSecret: false, isProOnly: false,
            // Uses ratchet: only ever grows, ignoring hourly rate changes
            checker: { entries, hourlyRate in Self.budgetVarianceProgress(entries: entries, hourlyRate: hourlyRate) }
        ),
        AchievementDefinition(
            id: "repeat_offender",
            name: "Repeat Offender",
            flavor: "Total sessions logged. At this point it's a pattern, not an incident.",
            unit: .sessions,
            emoji: "\u{1F4CA}",
            category: .milestone,
            levels: [
                AchievementLevel(threshold: 10, rarity: .common),
                AchievementLevel(threshold: 50, rarity: .uncommon),
                AchievementLevel(threshold: 100, rarity: .rare),
                AchievementLevel(threshold: 500, rarity: .elite),
                AchievementLevel(threshold: 1000, rarity: .legendary),
            ],
            isSecret: false, isProOnly: false,
            checker: { entries, _ in Double(entries.filter { !$0.isRunning }.count) }
        ),
    ]

    static let discoveries: [AchievementDefinition] = [
        AchievementDefinition(
            id: "cross_functional",
            name: "Cross-Functional Experience",
            flavor: "Different categories tried. A well-rounded lack of productivity.",
            unit: .count,
            emoji: "\u{1F500}",
            category: .discovery,
            levels: [
                AchievementLevel(threshold: 3, rarity: .common),
                AchievementLevel(threshold: 5, rarity: .uncommon),
                AchievementLevel(threshold: 7, rarity: .rare),
                AchievementLevel(threshold: 10, rarity: .elite),
            ],
            isSecret: false, isProOnly: false,
            checker: { entries, _ in Double(Set(entries.filter { !$0.isRunning }.map(\.category)).count) }
        ),
        AchievementDefinition(
            id: "process_improvement",
            name: "Process Improvement",
            flavor: "Edit a time entry. Revising history is an underrated skill.",
            unit: .count,
            emoji: "\u{270F}\u{FE0F}",
            category: .discovery,
            levels: [AchievementLevel(threshold: 1, rarity: .common)],
            isSecret: false, isProOnly: false,
            checker: { _, _ in UserDefaults.standard.bool(forKey: "hasEditedEntry") ? 1.0 : 0.0 }
        ),
        AchievementDefinition(
            id: "retroactive_filing",
            name: "Retroactive Filing",
            flavor: "Add a retroactive entry. Amending the record after the fact.",
            unit: .count,
            emoji: "\u{1F4DD}",
            category: .discovery,
            levels: [AchievementLevel(threshold: 1, rarity: .common)],
            isSecret: false, isProOnly: false,
            checker: { entries, _ in entries.filter { $0.isManual }.isEmpty ? 0.0 : 1.0 }
        ),
    ]

    static let records: [AchievementDefinition] = [
        AchievementDefinition(
            id: "deep_focus",
            name: "Deep Focus",
            flavor: "Longest single session on record. That's not slacking, that's an art form.",
            unit: .minutes,
            emoji: "\u{1F9D8}",
            category: .record,
            levels: [
                AchievementLevel(threshold: 30, rarity: .common),
                AchievementLevel(threshold: 60, rarity: .uncommon),
                AchievementLevel(threshold: 120, rarity: .rare),
                AchievementLevel(threshold: 180, rarity: .elite),
            ],
            isSecret: false, isProOnly: true,
            checker: { entries, _ in (entries.filter { !$0.isRunning }.map(\.duration).max() ?? 0) / 60.0 }
        ),
        AchievementDefinition(
            id: "maximum_throughput",
            name: "Maximum Throughput",
            flavor: "Most hours reclaimed in a single day. Peak operational inefficiency.",
            unit: .hours,
            emoji: "\u{1F3C6}",
            category: .record,
            levels: [
                AchievementLevel(threshold: 2, rarity: .common),
                AchievementLevel(threshold: 4, rarity: .rare),
                AchievementLevel(threshold: 6, rarity: .elite),
            ],
            isSecret: false, isProOnly: true,
            checker: { entries, _ in
                let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
                var d: [String: Double] = [:]
                for e in entries.filter({ !$0.isRunning }) { d[fmt.string(from: e.startTime), default: 0] += e.duration }
                return (d.values.max() ?? 0) / 3600.0
            }
        ),
        AchievementDefinition(
            id: "meeting_email",
            name: "Meeting Could Have Been an Email",
            flavor: "Most sessions in a single day. You're really committed to not being committed.",
            unit: .sessions,
            emoji: "\u{1F4E7}",
            category: .record,
            levels: [
                AchievementLevel(threshold: 3, rarity: .common),
                AchievementLevel(threshold: 5, rarity: .uncommon),
                AchievementLevel(threshold: 8, rarity: .rare),
                AchievementLevel(threshold: 10, rarity: .elite),
            ],
            isSecret: false, isProOnly: true,
            checker: { entries, _ in
                let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
                var d: [String: Int] = [:]
                for e in entries.filter({ !$0.isRunning }) { d[fmt.string(from: e.startTime), default: 0] += 1 }
                return Double(d.values.max() ?? 0)
            }
        ),
    ]

    static let secrets: [AchievementDefinition] = [
        AchievementDefinition(
            id: "after_hours",
            name: "After Hours",
            flavor: "Log a session before 6 AM or after 10 PM. The night shift nobody asked for.",
            unit: .count,
            emoji: "\u{1F319}",
            category: .secret,
            levels: [AchievementLevel(threshold: 1, rarity: .rare)],
            isSecret: true, isProOnly: false,
            checker: { entries, _ in
                entries.filter { !$0.isRunning }.contains {
                    let h = Calendar.current.component(.hour, from: $0.startTime)
                    return h < 6 || h >= 22
                } ? 1.0 : 0.0
            }
        ),
        AchievementDefinition(
            id: "overtime",
            name: "Overtime",
            flavor: "Log a session on a weekend. Even your time off isn't really time off.",
            unit: .count,
            emoji: "\u{1F4C6}",
            category: .secret,
            levels: [AchievementLevel(threshold: 1, rarity: .uncommon)],
            isSecret: true, isProOnly: false,
            checker: { entries, _ in
                entries.filter { !$0.isRunning }.contains {
                    let w = Calendar.current.component(.weekday, from: $0.startTime)
                    return w == 1 || w == 7
                } ? 1.0 : 0.0
            }
        ),
    ]

    // MARK: - Streak Helpers

    /// Calculate consecutive-day streak, counting only weekdays (Mon-Fri).
    /// Weekends are skipped entirely — users don't need to slack on days off to keep their streak.
    /// Allows 1 missed weekday as grace before streak resets.
    static func calculateStreak(entries: [TimeEntry]) -> Int {
        let completed = entries.filter { !$0.isRunning }
        guard !completed.isEmpty else { return 0 }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var daysWithEntries = Set<Date>()
        for entry in completed { daysWithEntries.insert(calendar.startOfDay(for: entry.startTime)) }

        // Find the most recent weekday with an entry
        let mostRecentWeekday = daysWithEntries
            .filter { isWeekday($0, calendar: calendar) }
            .max()
        guard let mostRecent = mostRecentWeekday else { return 0 }

        // Streak must be "current" — count weekdays between most recent entry and today
        let weekdaysSinceRecent = countWeekdays(from: mostRecent, to: today, calendar: calendar)
        // Allow up to 1 missed weekday + any weekends in between
        if weekdaysSinceRecent > 1 { return 0 }

        // Count back from most recent weekday, allowing 1 missed weekday as grace
        var streak = 0
        var checkDate = mostRecent
        var missedInRow = 0

        while streak < 10_000 { // safety bound
            // Skip weekends — don't count them toward streak or breakage
            if !isWeekday(checkDate, calendar: calendar) {
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
                continue
            }

            if daysWithEntries.contains(checkDate) {
                streak += 1
                missedInRow = 0
            } else {
                missedInRow += 1
                if missedInRow > 1 { break }
            }

            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }

    /// Longest consecutive-workday streak the user has EVER achieved, not just
    /// their current one. Uses the same 1-weekday grace rule as
    /// `calculateStreak` so the two numbers are comparable.
    static func calculateLongestStreakEver(entries: [TimeEntry]) -> Int {
        let completed = entries.filter { !$0.isRunning }
        guard !completed.isEmpty else { return 0 }
        let calendar = Calendar.current
        var daysWithEntries = Set<Date>()
        for entry in completed { daysWithEntries.insert(calendar.startOfDay(for: entry.startTime)) }

        guard let earliest = daysWithEntries.min() else { return 0 }
        let today = calendar.startOfDay(for: .now)

        var best = 0
        var current = 0
        var missedInRow = 0
        var cursor = earliest

        // Safety bound: longest plausible career (100 years of daily use) is
        // well under this limit; prevents runaway loops on clock skew.
        var iterations = 0
        while cursor <= today, iterations < 50_000 {
            if isWeekday(cursor, calendar: calendar) {
                if daysWithEntries.contains(cursor) {
                    current += 1
                    missedInRow = 0
                    best = max(best, current)
                } else {
                    missedInRow += 1
                    if missedInRow > 1 {
                        current = 0
                        missedInRow = 0
                    }
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
            iterations += 1
        }
        return best
    }

    private static func isWeekday(_ date: Date, calendar: Calendar) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday >= 2 && weekday <= 6 // Mon-Fri (Sunday=1, Saturday=7)
    }

    private static func countWeekdays(from start: Date, to end: Date, calendar: Calendar) -> Int {
        guard start <= end else { return 0 }
        var count = 0
        var current = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        let endDay = calendar.startOfDay(for: end)
        while current <= endDay {
            if isWeekday(current, calendar: calendar) { count += 1 }
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return count
    }

    /// Calculate consecutive-week streak. Uses ISO week-of-year to avoid year-boundary bugs.
    static func calculateWeeklyStreak(entries: [TimeEntry]) -> Int {
        let completed = entries.filter { !$0.isRunning }
        guard !completed.isEmpty else { return 0 }
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current

        // Collect unique weeks (keyed by the start-of-week date for proper chronological comparison)
        var weeksWithEntries = Set<Date>()
        for entry in completed {
            if let weekStart = calendar.dateInterval(of: .weekOfYear, for: entry.startTime)?.start {
                weeksWithEntries.insert(weekStart)
            }
        }

        guard let mostRecentWeek = weeksWithEntries.max() else { return 0 }

        // Streak must include current or previous week
        guard let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: .now)?.start else { return 0 }
        let weeksBetween = calendar.dateComponents([.weekOfYear], from: mostRecentWeek, to: thisWeekStart).weekOfYear ?? 0
        if weeksBetween > 1 { return 0 }

        // Count consecutive weeks back from most recent
        var streak = 0
        var checkWeek = mostRecentWeek
        while weeksWithEntries.contains(checkWeek) {
            streak += 1
            guard let prev = calendar.date(byAdding: .weekOfYear, value: -1, to: checkWeek) else { break }
            checkWeek = prev
        }
        return streak
    }

    // MARK: - Budget Variance Ratchet
    //
    // Budget Variance uses a ratchet to prevent gaming via hourly rate changes.
    // We store the max-ever-seen value in UserDefaults and only return values >= that.
    // Formula: current total always computed from real entries * current rate.
    // The stored ratchet only comes into play IF the user lowered their rate AFTER
    // unlocking a level — then we preserve the unlock by returning the max.

    private static let budgetRatchetKey = "budgetVarianceRatchet"

    static func budgetVarianceProgress(entries: [TimeEntry], hourlyRate: Double) -> Double {
        let raw = entries.filter { !$0.isRunning }.reduce(0) { $0 + $1.duration } / 3600.0 * hourlyRate
        let stored = UserDefaults.standard.double(forKey: budgetRatchetKey)
        let newMax = max(raw, stored)
        if newMax > stored {
            UserDefaults.standard.set(newMax, forKey: budgetRatchetKey)
        }
        // Return raw value for normal case, but never drop below the stored ratchet
        // (protects unlocked levels from hourly rate decreases)
        return max(raw, stored)
    }
}
