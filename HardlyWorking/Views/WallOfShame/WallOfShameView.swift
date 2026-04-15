import SwiftData
import SwiftUI

struct WallOfShameView: View {
    @Query(sort: \TimeEntry.startTime, order: .reverse)
    private var allEntries: [TimeEntry]
    @AppStorage("userCountry") private var userCountry: String = ""
    @AppStorage("userIndustry") private var userIndustry: String = ""

    @State private var viewModel = BenchmarkViewModel()
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var showPaywall = false

    private var isProUser: Bool { subscriptionManager.isProUser }

    private var userAvgPerDay: TimeInterval {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: .now) ?? .now

        // Only count entries on weekdays within the last 30 days
        let recentEntries = allEntries.filter { entry in
            guard !entry.isRunning && entry.startTime >= thirtyDaysAgo else { return false }
            let wd = calendar.component(.weekday, from: entry.startTime)
            return wd != 1 && wd != 7 // exclude Sat (7) and Sun (1)
        }
        let total = recentEntries.reduce(0.0) { $0 + $1.duration }

        // Count weekdays in the last 30 days
        var weekdays = 0
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: .now) {
                let wd = calendar.component(.weekday, from: date)
                if wd != 1 && wd != 7 { weekdays += 1 }
            }
        }
        return weekdays > 0 ? total / Double(weekdays) : 0
    }

    var body: some View {
        VStack(spacing: 0) {
            formulaBar
            ScrollView {
                VStack(spacing: 0) {
                    if viewModel.isLoading && !viewModel.isLiveData {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Compiling benchmark data...")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(Theme.textPrimary.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    } else {
                    VStack(spacing: 28) {
                        YourPositionView(
                            userAvgPerDay: userAvgPerDay,
                            countryAvgPerDay: viewModel.countries.first(where: { $0.name == userCountry })?.avgSecondsPerDay ?? 0,
                            countryName: userCountry,
                            globalAvgPerDay: viewModel.globalStats.globalAvgSecondsPerDay
                        )
                        .padding(.horizontal, 24)

                        Divider().padding(.horizontal, 24)

                        GlobalStatsView(stats: viewModel.globalStats)
                            .padding(.horizontal, 24)

                        Divider().padding(.horizontal, 24)

                        if isProUser {
                            CountryRankingsView(
                                countries: viewModel.countries,
                                userCountry: userCountry
                            )
                            .padding(.horizontal, 24)
                        } else {
                            lockedSection(
                                title: "Country Rankings",
                                description: "International slacking data is\nclassified. Executive clearance required.",
                                icon: "globe"
                            )
                            .padding(.horizontal, 24)
                        }

                        Divider().padding(.horizontal, 24)

                        if isProUser {
                            IndustryRankingsView(
                                industries: viewModel.industries,
                                userIndustry: userIndustry
                            )
                            .padding(.horizontal, 24)
                        } else {
                            lockedSection(
                                title: "Industry Rankings",
                                description: "Sector-level intelligence is classified.\nExecutive clearance required.",
                                icon: "building.2.fill"
                            )
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 60)
                    }
                }
            }
        }
        .background(Color.white)
        .refreshable { await viewModel.loadBenchmarks(forceRefresh: true) }
        .task { await viewModel.loadBenchmarks() }
        .fullScreenCover(isPresented: $showPaywall, onDismiss: {
            subscriptionManager.showProBannerIfPending()
        }) {
            PaywallView()
        }
    }

    private func lockedSection(title: String, description: String, icon: String) -> some View {
        ProLockedView(
            title: title,
            description: description,
            icon: icon
        ) { showPaywall = true }
    }

    // MARK: - Formula Bar

    private var formulaBar: some View {
        HStack(spacing: 0) {
            Text("C1")
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

                Text("=PERCENTILE(you, everyone)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.65))

                Spacer()

                Text(percentileLabel)
                    .font(.system(.callout, design: .monospaced, weight: .bold))
                    .foregroundStyle(userAvgPerDay > 0 ? Theme.accent : Theme.textPrimary.opacity(0.3))
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

    private var percentileLabel: String {
        guard userAvgPerDay > 0 else { return "#N/A" }

        // Use live percentile from Supabase if available
        if let percentile = viewModel.userPercentile {
            return "Top \(100 - percentile)%"
        }

        // Fallback: estimate from global average
        let globalAvg = viewModel.globalStats.globalAvgSecondsPerDay
        guard globalAvg > 0 else { return "#N/A" }
        let ratio = userAvgPerDay / globalAvg
        let percentile: Int
        if ratio > 2.0 { percentile = 1 }
        else if ratio > 1.5 { percentile = 5 }
        else if ratio > 1.2 { percentile = 15 }
        else if ratio > 1.0 { percentile = 30 }
        else if ratio > 0.8 { percentile = 50 }
        else if ratio > 0.5 { percentile = 70 }
        else { percentile = 85 }
        return "Top \(percentile)%"
    }
}

#Preview {
    WallOfShameView()
        .modelContainer(for: TimeEntry.self, inMemory: true)
}
