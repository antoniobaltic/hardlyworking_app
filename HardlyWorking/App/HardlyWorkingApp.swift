import SwiftData
import SwiftUI

@Observable
final class DeepLinkHandler {
    var pendingInviteCode: String?
}

@main
struct HardlyWorkingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var subscriptionManager = SubscriptionManager()
    @State private var deepLinkHandler = DeepLinkHandler()
    @State private var achievementManager = AchievementManager()
    @State private var ratingManager = RatingManager()
    @State private var notificationManager = NotificationManager()

    init() {
        #if DEBUG
        // Launched with -SCREENSHOT_MODE? Seed UserDefaults BEFORE @AppStorage
        // reads them, so routing lands on ContentView (skipping onboarding).
        ScreenshotSeeder.prepareUserDefaultsIfNeeded()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                        .environment(subscriptionManager)
                        .environment(deepLinkHandler)
                        .environment(achievementManager)
                        .environment(ratingManager)
                        .environment(notificationManager)
                        .onAppear {
                            ratingManager.recordInstallIfNeeded()
                            // Fire the post-onboarding rating prompt the
                            // first time ContentView appears. Internally
                            // gated to once-per-user so it doesn't refire
                            // on every app launch.
                            ratingManager.recordOnboardingCompleted()
                        }
                        .task {
                            await reattachLiveActivity()
                            // Recover any daily_stats rows that missed their
                            // original sync (app killed mid-session, Dynamic
                            // Island stop before the fix shipped, etc.). A
                            // week's sweep on every cold launch is enough.
                            await backfillOnLaunch()
                        }
                        .onChange(of: scenePhase) { _, newPhase in
                            // Repeat the sweep on every foreground transition so
                            // cross-device edits and earlier missed syncs keep
                            // converging without the user having to do anything.
                            if newPhase == .active {
                                Task { await backfillOnLaunch() }
                            }
                        }
                        .background {
                            #if DEBUG
                            // Invisible trigger — reads modelContext from the
                            // env provided by .modelContainer() below, then
                            // seeds the SwiftData store on first appear.
                            ScreenshotSeederBootstrap()
                            #endif
                        }
                        .transition(.opacity)
                        .onOpenURL { url in
                            handleDeepLink(url)
                        }
                } else {
                    OnboardingContainerView()
                        .environment(subscriptionManager)
                        .transition(.opacity)
                        .task { await checkExistingUser() }
                }
            }
            .preferredColorScheme(.light)
        }
        .modelContainer(for: [TimeEntry.self, UnlockedAchievement.self, CustomCategory.self], isAutosaveEnabled: true)
    }

    /// On a new device, check if the user already has a Supabase session
    /// (signed in via Apple on another device, iCloud syncing data).
    /// If so, skip onboarding and restore their profile settings.
    private func checkExistingUser() async {
        guard !hasCompletedOnboarding else { return }

        // Check if Supabase already has an active session (from a previous device)
        if SupabaseManager.shared.isAuthenticated {
            // Restore profile data from Supabase to local AppStorage
            await restoreProfileFromSupabase()
            hasCompletedOnboarding = true
        }
    }

    /// Pull profile settings from Supabase and write to AppStorage.
    private func restoreProfileFromSupabase() async {
        guard let userId = SupabaseManager.shared.userId else { return }

        do {
            struct ProfileRow: Decodable {
                let industry: String?
                let country: String?
                let hourlyRate: Double?
                let workHoursPerDay: Double?
                let workDaysPerWeek: Int?
                let employeeId: Int?

                enum CodingKeys: String, CodingKey {
                    case industry, country
                    case hourlyRate = "hourly_rate"
                    case workHoursPerDay = "work_hours_per_day"
                    case workDaysPerWeek = "work_days_per_week"
                    case employeeId = "employee_id"
                }
            }

            let profiles: [ProfileRow] = try await SupabaseManager.shared.client
                .from("profiles")
                .select("industry, country, hourly_rate, work_hours_per_day, work_days_per_week, employee_id")
                .eq("id", value: userId.uuidString)
                .execute()
                .value

            if let profile = profiles.first {
                if let industry = profile.industry { UserDefaults.standard.set(industry, forKey: "userIndustry") }
                if let country = profile.country { UserDefaults.standard.set(country, forKey: "userCountry") }
                if let rate = profile.hourlyRate { UserDefaults.standard.set(rate, forKey: "hourlyRate") }
                if let hours = profile.workHoursPerDay { UserDefaults.standard.set(hours, forKey: "workHoursPerDay") }
                if let days = profile.workDaysPerWeek { UserDefaults.standard.set(days, forKey: "workDaysPerWeek") }
                if let empId = profile.employeeId { UserDefaults.standard.set(empId, forKey: "employeeId") }
            }
        } catch {
            print("[Restore] Profile restore failed: \(error)")
        }
    }

    /// Reconciles the Live Activity with SwiftData on app launch / foreground.
    /// Runs once per ContentView appearance via `.task`.
    @MainActor
    private func reattachLiveActivity() async {
        let container: ModelContainer
        do {
            container = try ModelContainer(
                for: TimeEntry.self, UnlockedAchievement.self, CustomCategory.self
            )
        } catch {
            return
        }

        let context = container.mainContext
        let descriptor = FetchDescriptor<TimeEntry>(
            predicate: #Predicate { $0.endTime == nil }
        )

        let customDescriptor = FetchDescriptor<CustomCategory>()
        let customs = (try? context.fetch(customDescriptor)) ?? []

        if let running = (try? context.fetch(descriptor))?.first {
            let emoji = SlackCategory.emoji(for: running.category, custom: customs)
            let allDescriptor = FetchDescriptor<TimeEntry>()
            let historical = (try? context.fetch(allDescriptor)) ?? []
            let substitutes = SubstituteResolver.compute(
                excluding: running.category,
                historicalEntries: historical,
                customCategories: customs
            )
            await LiveActivityService.reattach(
                runningCategory: running.category,
                runningEmoji: emoji,
                runningStart: running.startTime,
                substitutes: substitutes
            )
        } else {
            await LiveActivityService.reattach(
                runningCategory: nil,
                runningEmoji: nil,
                runningStart: nil,
                substitutes: []
            )
        }
    }

    /// Back-fills `daily_stats` for the last 7 days so the server's company-wide
    /// view catches up on anything that missed its original sync (most commonly:
    /// sessions ended via the Dynamic Island END button before this helper
    /// existed). Safe to call repeatedly — upserts on (user_id, date).
    @MainActor
    private func backfillOnLaunch() async {
        guard let container = try? ModelContainer(
            for: TimeEntry.self, UnlockedAchievement.self, CustomCategory.self
        ) else { return }
        await SupabaseSync.backfillRecentDays(context: container.mainContext)
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "hardlyworking",
              url.host == "join"
        else { return }

        // Extract invite code from path: hardlyworking://join/INVITE_CODE
        let rawCode = url.pathComponents.dropFirst().first
        let code = rawCode?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let code, !code.isEmpty {
            deepLinkHandler.pendingInviteCode = code
        }
    }
}
