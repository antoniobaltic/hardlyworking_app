import SwiftUI

struct RapSheetStatsView: View {
    let stats: DashboardViewModel.CareerStats

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PERFORMANCE REVIEW")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .tracking(1.5)

            if stats.totalSessions == 0 {
                emptyState
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    statCard(
                        value: Theme.formatDuration(stats.totalTime),
                        label: "Total Reclaimed",
                        color: Theme.textPrimary
                    )
                    statCard(
                        value: Theme.formatMoney(stats.totalMoney),
                        label: "Career Wages",
                        color: Theme.money
                    )
                    statCard(
                        value: "\(stats.totalSessions)",
                        label: "Total Sessions",
                        color: Theme.textPrimary
                    )
                    statCard(
                        value: "\(stats.daysActive)",
                        label: "Days Active",
                        color: Theme.textPrimary
                    )
                    statCard(
                        value: Theme.formatDuration(stats.avgPerWorkDay),
                        label: "Avg / Work Day",
                        color: Theme.accent
                    )
                    statCard(
                        value: stats.totalSessions > 0
                            ? Theme.formatDuration(stats.totalTime / Double(stats.totalSessions))
                            : "0m",
                        label: "Avg Session",
                        color: Theme.accent
                    )
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Text("#N/A")
                .font(.system(.title3, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.25))
            Text("No activity on record.")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func statCard(value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.system(.title3, design: .monospaced, weight: .semibold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
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
