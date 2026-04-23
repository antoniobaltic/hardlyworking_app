#if DEBUG
import Foundation
import SwiftData

/// Populates the app with a known, reproducible "screenshot persona" so we
/// can capture App Store screenshots with on-brand, consistent data.
///
/// Activated by the `-SCREENSHOT_MODE` launch argument in the Xcode scheme.
/// When active, on every launch this seeder:
///   1. Wipes all local SwiftData records (TimeEntry, UnlockedAchievement, CustomCategory).
///   2. Writes the persona profile to UserDefaults (rate, industry, employee ID, onboarding flags).
///   3. Generates 283 historical TimeEntry records across 127 weekdays — totalling ~94h 18m,
///      with category distribution matching MEMO-2026-007 canon (Doom Scrolling 28.4%, etc.).
///   4. Inserts one RUNNING TimeEntry (Doom Scrolling) backdated 170 minutes so the Timer
///      view immediately shows ~2:50:00 on launch (Shot 2).
///   5. Forces `isProUser = true` and injects mock data into the Groups + Benchmark view
///      models — bypassing Supabase entirely. Nothing writes to the backend.
///
/// All mocks are static. All state is local. Removing the launch argument restores
/// normal app behaviour (though a simulator wipe is recommended to clear the seeded data).
enum ScreenshotSeeder {

    /// True when the app was launched with `-SCREENSHOT_MODE` in the scheme args.
    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains("-SCREENSHOT_MODE")
    }

    // MARK: - Persona

    static let hourlyRate: Double = 45.0
    static let employeeIdInt: Int = 47210
    static let country = "United States"
    static let industry = "Tech Bro"
    static let currency = "USD"

    // MARK: - Entry Points

    /// Call synchronously from `HardlyWorkingApp.init()`. Sets UserDefaults so the
    /// @AppStorage-driven routing (onboarding / ATT / main) lands on the main UI.
    static func prepareUserDefaultsIfNeeded() {
        guard isActive else { return }
        let d = UserDefaults.standard
        d.set(hourlyRate, forKey: "hourlyRate")
        d.set(8.0, forKey: "workHoursPerDay")
        d.set(5, forKey: "workDaysPerWeek")
        d.set(false, forKey: "includeWeekends")
        d.set(currency, forKey: "currency")
        d.set(country, forKey: "userCountry")
        d.set(industry, forKey: "userIndustry")
        d.set(employeeIdInt, forKey: "employeeId")
        d.set(true, forKey: "hasCompletedOnboarding")
        d.set(true, forKey: "cachedProStatus")
        print("[ScreenshotSeeder] Prepared UserDefaults for persona #HW-\(employeeIdInt).")
    }

    /// Call from a `.onAppear` on the first view that has `@Environment(\.modelContext)`.
    /// Wipes and re-seeds the SwiftData store. Idempotent — safe to call on every launch.
    @MainActor
    static func seedSwiftDataIfNeeded(modelContext: ModelContext) {
        guard isActive else { return }

        // --- 1. Wipe existing local data
        try? modelContext.delete(model: TimeEntry.self)
        try? modelContext.delete(model: UnlockedAchievement.self)
        try? modelContext.delete(model: CustomCategory.self)
        try? modelContext.save()

        // --- 2. Generate historical entries
        var rng = SeededRNG(seed: 47210)
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        var weekdays: [Date] = []
        var offset = 1
        while weekdays.count < 127 {
            if let d = cal.date(byAdding: .day, value: -offset, to: today) {
                let wd = cal.component(.weekday, from: d)
                if wd != 1 && wd != 7 { weekdays.append(d) }
            }
            offset += 1
        }

        // Distribution in minutes — totals ~5658 (= 94h 18m) at the target percentages.
        let minutesPerCategory: [(String, Int)] = [
            ("Doom Scrolling",   1607),  // 28.4%
            ("Coffee Run",       1188),  // 21.0%
            ("\"Thinking\"",      849),  // 15.0%
            ("Bathroom Break",    639),  // 11.3%
            ("Chatting",          453),  //  8.0%
            ("Looking Busy",      396),  //  7.0%
            ("Online Shopping",   226),  //  4.0%
            ("Long Lunch",        170),  //  3.0%
            ("Into the Void",     113),  //  2.0%
            ("Errands",            17),  //  0.3%
        ]

        var inserted = 0
        for (category, totalMin) in minutesPerCategory {
            var left = totalMin
            while left > 0 {
                let sessionLen = min(left, Int.random(in: 10...45, using: &rng))
                let day = weekdays.randomElement(using: &rng) ?? today
                let startHour = Int.random(in: 9...16, using: &rng)
                let startMin = Int.random(in: 0...59, using: &rng)
                guard let start = cal.date(
                    bySettingHour: startHour, minute: startMin, second: 0, of: day
                ) else {
                    left -= sessionLen
                    continue
                }
                let end = start.addingTimeInterval(TimeInterval(sessionLen * 60))
                modelContext.insert(TimeEntry(
                    category: category,
                    startTime: start,
                    endTime: end,
                    isManual: false
                ))
                inserted += 1
                left -= sessionLen
            }
        }

        // --- 3. Running entry for Shot 2: Doom Scrolling, backdated 170 minutes
        let running = TimeEntry(
            category: "Doom Scrolling",
            startTime: Date().addingTimeInterval(-170 * 60),
            endTime: nil,
            isManual: false
        )
        modelContext.insert(running)

        try? modelContext.save()
        print("[ScreenshotSeeder] Seeded SwiftData: \(inserted) historical entries + 1 running.")
    }

    // MARK: - Mocks for ViewModels

    static let mockGroupId = UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF0123456789")!
    private static let mockCreatorId = UUID(uuidString: "B2C3D4E5-F6A7-8901-BCDE-F01234567890")!
    private static let fallbackUserId = UUID(uuidString: "47210000-0000-0000-0000-000000047210")!

    static var mockGroups: [FriendGroupRecord] {
        [
            FriendGroupRecord(
                id: mockGroupId,
                name: "Q1 Cost Center",
                emoji: "🏢",
                description: "Private. No managerial oversight.",
                createdBy: mockCreatorId,
                inviteCode: "COSTCTR",
                createdAt: "2026-01-06T09:14:00Z",
                memberCount: 7
            )
        ]
    }

    /// Leaderboard for the mock group.
    ///
    /// The rank-2 entry uses the caller-provided `currentUserId` (if signed in,
    /// that's `SupabaseManager.shared.userId`) so the "YOU" highlight renders
    /// correctly in `GroupDetailSheet`. Falls back to a stable UUID if nil.
    ///
    /// Weekly seconds calibrated at $45/hr to produce the planned leaderboard amounts:
    ///   #1 → $1,247.50 · #2 → $1,189.25 (YOU) · #3 → $982.00 · …
    static func mockLeaderboard(currentUserId: UUID?) -> [GroupLeaderboardEntry] {
        let you = currentUserId ?? fallbackUserId
        return [
            GroupLeaderboardEntry(
                userId: UUID(), industry: "Tech Bro", reclaimerTitle: nil,
                employeeId: 31829, displayName: nil,
                totalSecondsThisWeek: 99_800, sessionCountThisWeek: 34
            ),
            GroupLeaderboardEntry(
                userId: you, industry: "Tech Bro", reclaimerTitle: nil,
                employeeId: 47210, displayName: nil,
                totalSecondsThisWeek: 95_140, sessionCountThisWeek: 31
            ),
            GroupLeaderboardEntry(
                userId: UUID(), industry: "Tech Bro", reclaimerTitle: nil,
                employeeId: 58104, displayName: nil,
                totalSecondsThisWeek: 78_560, sessionCountThisWeek: 28
            ),
            GroupLeaderboardEntry(
                userId: UUID(), industry: "Office Drone", reclaimerTitle: nil,
                employeeId: 22476, displayName: nil,
                totalSecondsThisWeek: 67_200, sessionCountThisWeek: 22
            ),
            GroupLeaderboardEntry(
                userId: UUID(), industry: "Creative", reclaimerTitle: nil,
                employeeId: 89312, displayName: nil,
                totalSecondsThisWeek: 54_300, sessionCountThisWeek: 19
            ),
            GroupLeaderboardEntry(
                userId: UUID(), industry: "Suit & Tie", reclaimerTitle: nil,
                employeeId: 11045, displayName: nil,
                totalSecondsThisWeek: 42_800, sessionCountThisWeek: 15
            ),
            GroupLeaderboardEntry(
                userId: UUID(), industry: "Tech Bro", reclaimerTitle: nil,
                employeeId: 66891, displayName: nil,
                totalSecondsThisWeek: 31_900, sessionCountThisWeek: 12
            ),
        ]
    }

    // MARK: Benchmarks

    static var mockGlobalBenchmark: GlobalBenchmark {
        GlobalBenchmark(
            totalUsers: 12_847,
            totalWagesReclaimed: 2_143_890.52,
            totalHoursReclaimed: 47_642.8,
            globalAvgSecondsPerDay: 47 * 60,
            mostPopularCategory: "Doom Scrolling",
            mostPopularCategoryEmoji: "💀"
        )
    }

    static var mockCountries: [BenchmarkCountry] {
        [
            BenchmarkCountry(name: "Brazil",         flag: "🇧🇷", avgSecondsPerDay: 72 * 60, userCount: 812),
            BenchmarkCountry(name: "United States",  flag: "🇺🇸", avgSecondsPerDay: 52 * 60, userCount: 4128),
            BenchmarkCountry(name: "United Kingdom", flag: "🇬🇧", avgSecondsPerDay: 51 * 60, userCount: 1204),
            BenchmarkCountry(name: "Canada",         flag: "🇨🇦", avgSecondsPerDay: 49 * 60, userCount: 687),
            BenchmarkCountry(name: "Australia",      flag: "🇦🇺", avgSecondsPerDay: 48 * 60, userCount: 502),
            BenchmarkCountry(name: "Germany",        flag: "🇩🇪", avgSecondsPerDay: 44 * 60, userCount: 967),
            BenchmarkCountry(name: "France",         flag: "🇫🇷", avgSecondsPerDay: 42 * 60, userCount: 731),
            BenchmarkCountry(name: "Japan",          flag: "🇯🇵", avgSecondsPerDay: 28 * 60, userCount: 543),
        ]
    }

    static var mockIndustries: [BenchmarkIndustry] {
        [
            BenchmarkIndustry(industry: .techBro,            avgSecondsPerDay: 67 * 60, userCount: 2341),
            BenchmarkIndustry(industry: .creative,           avgSecondsPerDay: 61 * 60, userCount: 1204),
            BenchmarkIndustry(industry: .officeDrone,        avgSecondsPerDay: 54 * 60, userCount: 3812),
            BenchmarkIndustry(industry: .bureaucrat,         avgSecondsPerDay: 52 * 60, userCount: 428),
            BenchmarkIndustry(industry: .callCenterSurvivor, avgSecondsPerDay: 49 * 60, userCount: 612),
            BenchmarkIndustry(industry: .suitAndTie,         avgSecondsPerDay: 38 * 60, userCount: 1087),
            BenchmarkIndustry(industry: .scrubs,             avgSecondsPerDay: 24 * 60, userCount: 531),
        ]
    }

    /// Percentile value used directly by `WallOfShameView.percentileLabel`.
    /// 83 → renders as "Top 17%" (the view computes `100 - percentile`).
    static let mockPercentile: Int = 83
}

// MARK: - Deterministic RNG

/// Xorshift64. Same seed → same sequence → same seeded history every run.
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 1 : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

// MARK: - Bootstrap View

import SwiftUI

/// Invisible helper that reads `modelContext` from the environment (provided
/// by `.modelContainer()` on the WindowGroup) and kicks the seeder on first
/// appear. Attached via `.background()` so it lives inside the container's
/// scope without affecting layout. No-op if `-SCREENSHOT_MODE` isn't set.
struct ScreenshotSeederBootstrap: View {
    @Environment(\.modelContext) private var modelContext
    @State private var didSeed = false

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear {
                guard !didSeed else { return }
                didSeed = true
                ScreenshotSeeder.seedSwiftDataIfNeeded(modelContext: modelContext)
            }
    }
}
#endif
