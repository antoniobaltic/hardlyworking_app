import SwiftUI

struct IndustryRankingsView: View {
    let industries: [BenchmarkIndustry]
    let userIndustry: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("INDUSTRY RANKINGS")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .tracking(1.5)

            if industries.isEmpty {
                VStack(spacing: 4) {
                    Text("#N/A")
                        .font(.system(.title3, design: .monospaced, weight: .bold))
                        .foregroundStyle(Theme.textPrimary.opacity(0.3))
                    Text("Insufficient sector data.\nMore employees needed.")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }

            VStack(spacing: 0) {
                ForEach(Array(industries.enumerated()), id: \.element.id) { index, entry in
                    let isUser = entry.industry.rawValue == userIndustry
                    HStack(spacing: 10) {
                        Text("#\(index + 1)")
                            .font(.system(.caption, design: .monospaced, weight: .bold))
                            .foregroundStyle(rankColor(index + 1))
                            .frame(width: 24, alignment: .trailing)

                        Text(entry.industry.emoji)
                            .font(.subheadline)

                        Text(entry.industry.rawValue)
                            .font(.system(.subheadline, design: .monospaced, weight: isUser ? .bold : .regular))
                            .foregroundStyle(isUser ? Theme.accent : Theme.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Spacer()

                        Text(Theme.formatDuration(entry.avgSecondsPerDay) + "/day")
                            .font(.system(.caption, design: .monospaced, weight: .medium))
                            .foregroundStyle(Theme.textPrimary.opacity(0.65))

                        if isUser {
                            Text("YOU")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.accent, in: Capsule())
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 10)
                    .background(
                        isUser
                            ? Theme.accent.opacity(0.06)
                            : (index.isMultiple(of: 2) ? Theme.cardBackground.opacity(0.4) : Color.clear)
                    )
                }
            }
        }
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: Theme.cautionYellow
        case 2: Theme.textPrimary.opacity(0.4)
        case 3: Theme.cautionYellow.opacity(0.6)
        default: Theme.textPrimary.opacity(0.4)
        }
    }
}

// MARK: - Preview

#Preview("Industry Rankings — populated") {
    ScrollView {
        IndustryRankingsView(
            industries: sampleIndustryRankings,
            userIndustry: Industry.techBro.rawValue
        )
        .padding(24)
    }
    .background(Color.white)
}

private let sampleIndustryRankings: [BenchmarkIndustry] = [
    BenchmarkIndustry(industry: .creative,           avgSecondsPerDay: 10_260, userCount: 8_440),
    BenchmarkIndustry(industry: .bureaucrat,         avgSecondsPerDay: 9_180,  userCount: 5_219),
    BenchmarkIndustry(industry: .officeDrone,        avgSecondsPerDay: 8_640,  userCount: 34_102),
    BenchmarkIndustry(industry: .remoteWorker,       avgSecondsPerDay: 8_400,  userCount: 21_820),
    BenchmarkIndustry(industry: .teachersLounge,     avgSecondsPerDay: 7_680,  userCount: 4_211),
    BenchmarkIndustry(industry: .techBro,            avgSecondsPerDay: 7_140,  userCount: 19_503),
    BenchmarkIndustry(industry: .legal,              avgSecondsPerDay: 6_000,  userCount: 2_814),
    BenchmarkIndustry(industry: .suitAndTie,         avgSecondsPerDay: 5_400,  userCount: 11_204),
    BenchmarkIndustry(industry: .callCenterSurvivor, avgSecondsPerDay: 4_920,  userCount: 6_183),
    BenchmarkIndustry(industry: .scrubs,             avgSecondsPerDay: 3_600,  userCount: 3_044),
    BenchmarkIndustry(industry: .hospitality,        avgSecondsPerDay: 3_120,  userCount: 2_912),
    BenchmarkIndustry(industry: .retailWarrior,      avgSecondsPerDay: 2_640,  userCount: 5_391),
    BenchmarkIndustry(industry: .blueCollar,         avgSecondsPerDay: 2_100,  userCount: 4_118),
    BenchmarkIndustry(industry: .other,              avgSecondsPerDay: 1_800,  userCount: 1_430),
]
