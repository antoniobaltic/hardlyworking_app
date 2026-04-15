import SwiftUI

struct GlobalStatsView: View {
    let stats: GlobalBenchmark

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    private var hasData: Bool {
        stats.totalUsers > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("COMPANY-WIDE METRICS (ALL-TIME)")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .tracking(1.5)

            if hasData {
                LazyVGrid(columns: columns, spacing: 12) {
                    statCard(
                        value: formatLargeMoney(stats.totalWagesReclaimed),
                        label: "Total Wages\nReclaimed",
                        color: Theme.money
                    )
                    statCard(
                        value: formatLargeHours(stats.totalHoursReclaimed),
                        label: "Total Hours\nReclaimed",
                        color: Theme.timer
                    )
                    statCard(
                        value: stats.totalUsers.formatted(),
                        label: "Global Non-\nWorking Force",
                        color: Theme.textPrimary
                    )
                    statCard(
                        value: stats.mostPopularCategory.isEmpty
                            ? "#N/A"
                            : "\(stats.mostPopularCategoryEmoji) \(stats.mostPopularCategory)",
                        label: "Most Popular\nTask",
                        color: Theme.textPrimary
                    )
                }
            } else {
                VStack(spacing: 4) {
                    Text("#N/A")
                        .font(.system(.title3, design: .monospaced, weight: .bold))
                        .foregroundStyle(Theme.textPrimary.opacity(0.3))
                    Text("Awaiting global employee data.\nBe the first to file a report.")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
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
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
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

    private func formatLargeHours(_ hours: Double) -> String {
        let years = hours / 8760
        let months = hours / 730
        let days = hours / 24

        if years >= 1 {
            return String(format: "%.1f years", years)
        }
        if months >= 1 {
            return String(format: "%.0f months", months)
        }
        if days >= 2 {
            return String(format: "%.0f days", days)
        }
        if hours >= 1 {
            return String(format: "%.0f hrs", hours)
        }
        return String(format: "%.1f hrs", hours)
    }

    private func formatLargeMoney(_ amount: Double) -> String {
        let sym = Theme.currencySymbol(for: UserDefaults.standard.string(forKey: "currency") ?? "USD")
        if amount >= 1_000_000 {
            return String(format: "%@%.1fM", sym, amount / 1_000_000)
        }
        if amount >= 1_000 {
            return String(format: "%@%.0fK", sym, amount / 1_000)
        }
        return Theme.formatMoney(amount)
    }
}
