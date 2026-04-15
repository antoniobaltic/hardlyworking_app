import SwiftUI

struct CareerStatsView: View {
    let stats: DashboardViewModel.CareerStats
    @AppStorage("workHoursPerDay") private var workHoursPerDay: Double = 8.0

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    /// Share of a scheduled workday that the user reclaims on average.
    /// 0.0–∞ range (can exceed 1.0 if the user logs more than their nominal
    /// workday on average — leave uncapped so that reads as the flex it is).
    private var reclamationRate: Double {
        let workSeconds = workHoursPerDay * 3600
        guard workSeconds > 0 else { return 0 }
        return stats.avgPerWorkDay / workSeconds
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("EMPLOYMENT SUMMARY")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .tracking(1.5)

            LazyVGrid(columns: columns, spacing: 12) {
                // Money first — it's the headline stat for the tab.
                // It's also the only one in green; everything else reads in
                // neutral black so it doesn't compete with the money figure.
                statCard(
                    icon: "\u{1F4B0}", // 💰
                    value: Theme.formatMoney(stats.totalMoney),
                    label: "Total Wages Reclaimed",
                    color: Theme.money
                )
                statCard(
                    icon: "\u{23F1}\u{FE0F}", // ⏱️
                    value: Theme.formatDuration(stats.totalTime),
                    label: "Total Hours Reclaimed",
                    color: Theme.textPrimary
                )
                statCard(
                    icon: "\u{1F4CB}", // 📋
                    value: "\(stats.totalSessions)",
                    label: "Logged Sessions",
                    color: Theme.textPrimary
                )
                statCard(
                    icon: "\u{1F4C5}", // 📅
                    value: "\(stats.daysActive)",
                    label: "Workdays Slacked",
                    color: Theme.textPrimary
                )
                statCard(
                    icon: "\u{1F4CA}", // 📊
                    value: Theme.formatDuration(stats.avgPerWorkDay),
                    label: "Avg / Work Day",
                    color: Theme.textPrimary
                )
                statCard(
                    icon: "\u{1F3AF}", // 🎯
                    value: "\(Int((reclamationRate * 100).rounded()))%",
                    label: "Reclamation Rate",
                    color: Theme.textPrimary
                )
            }
        }
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.system(.title3, design: .monospaced, weight: .semibold))
                .foregroundStyle(color)
            HStack(spacing: 5) {
                Text(icon)
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.cardBackground.opacity(0.6))
                .stroke(Theme.textPrimary.opacity(0.06), lineWidth: 1)
        )
    }
}
