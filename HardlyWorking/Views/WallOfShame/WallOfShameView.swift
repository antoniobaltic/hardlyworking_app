import SwiftData
import SwiftUI

struct WallOfShameView: View {
    @Query(sort: \TimeEntry.startTime, order: .reverse)
    private var allEntries: [TimeEntry]
    @AppStorage("userCountry") private var userCountry: String = ""
    @AppStorage("userIndustry") private var userIndustry: String = ""

    private var userAvgPerDay: TimeInterval {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: .now)!
        let recentEntries = allEntries.filter { !$0.isRunning && $0.startTime >= weekAgo }
        let total = recentEntries.reduce(0.0) { $0 + $1.duration }

        // Count weekdays in the last 7 days
        var weekdays = 0
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: .now) {
                let wd = calendar.component(.weekday, from: date)
                if wd != 1 && wd != 7 { weekdays += 1 }
            }
        }
        return weekdays > 0 ? total / Double(weekdays) : 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                formulaBar

                VStack(spacing: 28) {
                    YourPositionView(
                        userAvgPerDay: userAvgPerDay,
                        globalAvgPerDay: MockBenchmarkData.global.globalAvgSecondsPerDay
                    )
                    .padding(.horizontal, 24)

                    Divider().padding(.horizontal, 24)

                    CountryRankingsView(
                        countries: MockBenchmarkData.countries,
                        userCountry: userCountry
                    )
                    .padding(.horizontal, 24)

                    Divider().padding(.horizontal, 24)

                    IndustryRankingsView(
                        industries: MockBenchmarkData.industries,
                        userIndustry: userIndustry
                    )
                    .padding(.horizontal, 24)

                    Divider().padding(.horizontal, 24)

                    GlobalStatsView(stats: MockBenchmarkData.global)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 20)
                .padding(.bottom, 60)
            }
        }
        .background(Color.white)
    }

    // MARK: - Formula Bar

    private var formulaBar: some View {
        HStack(spacing: 0) {
            Text("C1")
                .font(.system(.caption2, design: .monospaced, weight: .medium))
                .foregroundStyle(Theme.textPrimary.opacity(0.4))
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
                    .foregroundStyle(Theme.textPrimary.opacity(0.3))

                Text("=PERCENTILE(you, everyone)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))

                Spacer()

                Text(userAvgPerDay > 0 ? percentileLabel : "#N/A")
                    .font(.system(.callout, design: .monospaced, weight: .bold))
                    .foregroundStyle(userAvgPerDay > 0 ? Theme.accent : Theme.textPrimary.opacity(0.3))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(Theme.cardBackground)
        .overlay(
            Rectangle().fill(Theme.textPrimary.opacity(0.08)).frame(height: 1),
            alignment: .top
        )
        .overlay(
            Rectangle().fill(Theme.textPrimary.opacity(0.08)).frame(height: 1),
            alignment: .bottom
        )
    }

    private var percentileLabel: String {
        let globalAvg = MockBenchmarkData.global.globalAvgSecondsPerDay
        guard globalAvg > 0 else { return "#N/A" }
        // Simple percentile estimate based on position relative to average
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
