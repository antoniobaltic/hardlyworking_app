import SwiftUI

struct IndustryRankingsView: View {
    let industries: [BenchmarkIndustry]
    let userIndustry: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("INDUSTRY RANKINGS")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(1.5)

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
                            .foregroundStyle(Theme.textPrimary.opacity(0.5))

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
        default: Theme.textPrimary.opacity(0.2)
        }
    }
}
