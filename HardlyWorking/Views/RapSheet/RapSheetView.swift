import SwiftData
import SwiftUI
import UIKit
import UserNotifications

struct RapSheetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TimeEntry.startTime, order: .forward)
    private var allEntries: [TimeEntry]
    @AppStorage("hourlyRate") private var hourlyRate: Double = 15.0
    @AppStorage("workHoursPerDay") private var workHoursPerDay: Double = 8.0
    @AppStorage("workDaysPerWeek") private var workDaysPerWeek: Int = 5
    @AppStorage("userCountry") private var userCountry: String = ""
    @AppStorage("userIndustry") private var userIndustry: String = ""
    @AppStorage("reclaimerLevel") private var reclaimerLevel: Int = 0

    @State private var viewModel = DashboardViewModel()
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(AchievementManager.self) private var achievementManager
    @Query(sort: \CustomCategory.createdAt)
    private var customCategories: [CustomCategory]
    @State private var showPaywall = false
    @State private var showShareSheet = false
    @State private var showSettings = false

    private var completedEntries: [TimeEntry] {
        allEntries.filter { !$0.isRunning }
    }

    /// Career-lifetime stats for this screen. Explicitly sets the view
    /// model's period so callers aren't relying on a computed-property
    /// side effect to produce correct data.
    private var careerStats: DashboardViewModel.CareerStats {
        let lifetimeVM = DashboardViewModel()
        lifetimeVM.selectedPeriod = .lifetime
        return lifetimeVM.careerStats(allEntries, hourlyRate: hourlyRate)
    }

    private var careerMoney: Double {
        let completed = completedEntries
        let total = completed.reduce(0.0) { $0 + $1.duration }
        return total / 3600.0 * hourlyRate
    }

    private var isActive: Bool {
        guard let latest = completedEntries.last else { return false }
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return latest.startTime >= weekAgo
    }

    var body: some View {
        VStack(spacing: 0) {
            formulaBar
            ScrollView {
                VStack(spacing: 0) {
                    // Settings gear
                    HStack {
                        Spacer()
                        HStack(spacing: 0) {
                            Button {
                                Haptics.medium()
                                showShareSheet = true
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(.body, weight: .medium))
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 46, height: 40)
                            }

                            Divider()
                                .frame(height: 20)
                                .opacity(0.3)

                            Button {
                                Haptics.light()
                                showSettings = true
                            } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(.body, weight: .medium))
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 46, height: 40)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.accent.opacity(0.1))
                                .stroke(Theme.textPrimary.opacity(0.06), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                    VStack(spacing: 28) {
                        BookingHeaderView(
                            hourlyRate: hourlyRate,
                            userCountry: userCountry,
                            userIndustry: userIndustry,
                            firstEntryDate: completedEntries.first?.startTime,
                            isActive: isActive,
                            isProUser: subscriptionManager.isProUser
                        )
                        .padding(.horizontal, 24)

                        Divider().padding(.horizontal, 24)

                        clearanceBadge
                            .padding(.horizontal, 24)

                        Divider().padding(.horizontal, 24)

                        achievementsSection
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 60)
                }
            }
        }
        .background(Color.white)
        .fullScreenCover(isPresented: $showPaywall, onDismiss: {
            subscriptionManager.showProBannerIfPending()
        }) {
            PaywallView()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(
                data: buildShareCardData(),
                isProUser: subscriptionManager.isProUser
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSettings, onDismiss: {
            // Fires after a successful restore-from-Settings: surfaces the
            // PROMOTION GRANTED banner over the tab root.
            subscriptionManager.showProBannerIfPending()
        }) {
            SettingsView()
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            achievementManager.modelContext = modelContext
        }
    }

    // MARK: - Formula Bar

    private var formulaBar: some View {
        HStack(spacing: 0) {
            Text("E1")
                .font(.system(.caption2, design: .monospaced, weight: .medium))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .frame(width: 28)
                .padding(.vertical, 8)
                .background(Theme.cardBackground)
                .overlay(alignment: .trailing) {
                    Rectangle()
                        .fill(Theme.textPrimary.opacity(0.1))
                        .frame(width: 1)
                }

            HStack {
                Text("fx")
                    .font(.system(.caption2, design: .serif, weight: .bold))
                    .italic()
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))

                Text("=IF(working, FALSE, TRUE)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.65))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                Text("TRUE")
                    .font(.system(.callout, design: .monospaced, weight: .bold))
                    .foregroundStyle(Theme.money)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(Theme.cardBackground.ignoresSafeArea(.all, edges: .top))
        .overlay(
            Rectangle().fill(Theme.textPrimary.opacity(0.08)).frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Achievements

    // MARK: - Share

    private var shareSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("DISTRIBUTE")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .tracking(1.5)

            Button {
                Haptics.medium()
                showShareSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(.caption, weight: .medium))
                    Text("Generate Share Card")
                        .font(.system(.caption, design: .monospaced, weight: .medium))
                }
                .foregroundStyle(Theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.accent, lineWidth: 1)
                )
            }

            Text("Share your performance review.\nFree cards include attribution.")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
        }
    }

    private func buildShareCardData() -> ShareCardData {
        // Use a dedicated view model for sharing so we don't mutate the
        // instance held by the rest of the screen.
        let lifetimeVM = DashboardViewModel()
        lifetimeVM.selectedPeriod = .lifetime
        lifetimeVM.customCategories = customCategories

        let stats = lifetimeVM.careerStats(allEntries, hourlyRate: hourlyRate)
        let rankings = lifetimeVM.categoryRankings(allEntries, hourlyRate: hourlyRate)
        let streak = AchievementCatalog.calculateStreak(entries: allEntries)
        let recent = latestAchievementUnlock()

        return ShareCardData.build(
            stats: stats,
            rankings: rankings,
            industry: userIndustry.isEmpty ? nil : userIndustry,
            country: userCountry.isEmpty ? nil : userCountry,
            hourlyRate: hourlyRate,
            customCategories: customCategories,
            currentStreak: streak,
            recentAchievement: recent
        )
    }

    /// Most recently unlocked achievement, as an `AchievementUnlockEvent`
    /// suitable for the Commendation share card. Returns nil if the user
    /// has no unlocks yet or the catalog definition can't be resolved.
    private func latestAchievementUnlock() -> AchievementUnlockEvent? {
        var descriptor = FetchDescriptor<UnlockedAchievement>(
            sortBy: [SortDescriptor(\.unlockedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        guard let record = try? modelContext.fetch(descriptor).first,
              let definition = AchievementCatalog.all.first(where: { $0.id == record.achievementId })
        else { return nil }

        let rarity = definition.rarityForLevel(record.level)
        return AchievementUnlockEvent(
            definition: definition,
            level: record.level,
            rarity: rarity
        )
    }

    private var achievementsSection: some View {
        AchievementsView(achievementManager: achievementManager)
    }


    // MARK: - Clearance Level

    private var clearanceBadge: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("CLEARANCE LEVEL (UNCHANGEABLE)")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .tracking(1.5)

            if reclaimerLevel > 0 {
                ClearanceBadgeView(
                    level: ClearanceLevel.from(level: reclaimerLevel),
                    size: .large,
                    showDescription: true
                )
            } else {
                HStack {
                    Text("Classification")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.65))
                    Spacer()
                    Text("Unassigned")
                        .font(.system(.subheadline, design: .monospaced, weight: .medium))
                        .foregroundStyle(Theme.textPrimary.opacity(0.5))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.cardBackground.opacity(0.5))
                        .stroke(Theme.textPrimary.opacity(0.06), lineWidth: 1)
                )
            }
        }
    }

}

#Preview {
    let container = try! ModelContainer(for: TimeEntry.self, configurations: .init(isStoredInMemoryOnly: true))
    let context = container.mainContext
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)

    for daysAgo in 0..<5 {
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
        let start = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: day) ?? day
        let end = start.addingTimeInterval(Double.random(in: 900...3600))
        let entry = TimeEntry(
            category: SlackCategory.defaults.randomElement()!.name,
            startTime: start,
            endTime: end
        )
        context.insert(entry)
    }

    return RapSheetView()
        .modelContainer(container)
}
