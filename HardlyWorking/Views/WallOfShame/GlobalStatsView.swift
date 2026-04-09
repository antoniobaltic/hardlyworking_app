import SwiftUI

struct GlobalStatsView: View {
    let stats: GlobalBenchmark

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("GLOBAL STATS")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(1.5)

            LazyVGrid(columns: columns, spacing: 12) {
                statCard(
                    value: formatLargeMoney(stats.totalWagesReclaimed),
                    label: "Wages Reclaimed\nby All Users",
                    color: Theme.money
                )
                statCard(
                    value: stats.totalUsersThisWeek.formatted(),
                    label: "Active Reclaimers\nThis Week",
                    color: Theme.textPrimary
                )
                statCard(
                    value: "\(stats.mostPopularCategoryEmoji) \(stats.mostPopularCategory)",
                    label: "Most Popular\nActivity",
                    color: Theme.textPrimary
                )
                statCard(
                    value: Theme.formatDuration(stats.globalAvgSecondsPerDay) + "/day",
                    label: "Global\nAverage",
                    color: Theme.accent
                )
            }
        }
    }

    private func statCard(value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.35))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.cardBackground.opacity(0.6))
                .stroke(Theme.textPrimary.opacity(0.06), lineWidth: 1)
        )
    }

    private func formatLargeMoney(_ amount: Double) -> String {
        if amount >= 1_000_000 {
            return String(format: "$%.1fM", amount / 1_000_000)
        }
        if amount >= 1_000 {
            return String(format: "$%.0fK", amount / 1_000)
        }
        return Theme.formatMoney(amount)
    }
}
