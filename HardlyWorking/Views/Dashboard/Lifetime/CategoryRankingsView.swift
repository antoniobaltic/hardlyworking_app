import SwiftUI

struct CategoryRankingsView: View {
    let rankings: [DashboardViewModel.CategoryRank]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ACTIVITY ALLOCATION")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .tracking(1.5)

            if rankings.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(rankings) { rank in
                        rankRow(rank)
                    }
                }
            }
        }
    }

    private func rankRow(_ rank: DashboardViewModel.CategoryRank) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                // Rank number
                Text("#\(rank.rank)")
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(rankColor(rank.rank))
                    .frame(width: 24, alignment: .trailing)

                // Emoji
                Text(rank.emoji)
                    .font(.subheadline)

                // Name
                Text(rank.name)
                    .font(.system(.subheadline, design: .monospaced, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                Spacer()

                // Duration
                Text(Theme.formatDuration(rank.totalDuration))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.65))

                // Money
                Text(Theme.formatMoney(rank.totalMoney))
                    .font(.system(.caption, design: .monospaced, weight: .semibold))
                    .foregroundStyle(Theme.money)
                    .frame(width: 60, alignment: .trailing)
            }

            // Share-of-total bar — reads instantly without the user doing math.
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.textPrimary.opacity(0.06))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(rankColor(rank.rank))
                        .frame(width: max(2, geo.size.width * rank.percentage))
                }
            }
            .frame(height: 4)
            .padding(.leading, 40) // align under the name, not the rank number
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 10)
        .background(rank.rank.isMultiple(of: 2) ? Color.clear : Theme.cardBackground.opacity(0.4))
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: Theme.cautionYellow
        case 2: Theme.textPrimary.opacity(0.5)
        case 3: Theme.cautionYellow.opacity(0.6)
        default: Theme.textPrimary.opacity(0.4)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Text("#N/A")
                .font(.system(.title3, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
            Text("No activity codes tracked yet.")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}
