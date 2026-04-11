import SwiftUI

struct ShareCardView: View {
    let data: ShareCardData
    let type: ShareCardType
    let format: ShareCardFormat
    let isProUser: Bool

    private var size: CGSize { format.logicalSize }
    private var isStories: Bool { format == .stories }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Theme.textPrimary.opacity(0.06), lineWidth: 1)
                )

            VStack(spacing: 0) {
                Spacer().frame(height: isStories ? 60 : 32)

                Text(type.sectionHeader)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.25))
                    .tracking(2)

                Spacer().frame(height: isStories ? 40 : 20)

                cardContent

                Spacer()

                Image("mascot_welcome")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: isStories ? 100 : 70)
                    .opacity(0.75)

                Spacer().frame(height: isStories ? 24 : 16)

                if !isProUser {
                    watermark
                }

                Spacer().frame(height: isStories ? 40 : 24)
            }
            .padding(.horizontal, 32)
        }
        .frame(width: size.width, height: size.height)
    }

    @ViewBuilder
    private var cardContent: some View {
        switch type {
        case .money: moneyContent
        case .percentile: percentileContent
        case .category: categoryContent
        case .record: recordContent
        case .achievement: achievementContent
        }
    }

    private var moneyContent: some View {
        VStack(spacing: isStories ? 16 : 10) {
            Text(formatLargeMoney(data.totalMoney))
                .font(.system(size: isStories ? 72 : 52, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.money)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text("reclaimed from employer")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.6))

            Text("in \(Int(data.totalHours)) hours of dedication")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
        }
    }

    private var percentileContent: some View {
        VStack(spacing: isStories ? 16 : 10) {
            if let percentile = data.percentile {
                Text("Top \(100 - percentile)%")
                    .font(.system(size: isStories ? 64 : 48, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.accent)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                if let industry = data.industry, !industry.isEmpty {
                    Text("of \(industry) professionals")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.6))
                        .multilineTextAlignment(.center)
                } else {
                    Text("of all professionals")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.6))
                }
            } else {
                Text("#N/A")
                    .font(.system(size: isStories ? 64 : 48, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.1))
                Text("Insufficient data for ranking.")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.3))
            }
        }
    }

    private var categoryContent: some View {
        VStack(spacing: isStories ? 16 : 10) {
            if let cat = data.topCategory {
                Text(cat.emoji)
                    .font(.system(size: isStories ? 56 : 40))

                Text(cat.name)
                    .font(.system(size: isStories ? 28 : 22, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("\(Int(cat.percentage * 100))% of all reclaimed time")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))

                Text("\(data.totalSessions) documented incidents")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.3))
            }
        }
    }

    private var recordContent: some View {
        VStack(spacing: isStories ? 16 : 10) {
            if let session = data.longestSession {
                Text(Theme.formatDuration(session.duration))
                    .font(.system(size: isStories ? 64 : 48, weight: .light, design: .monospaced))
                    .foregroundStyle(Theme.accent)

                Text("single session")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))

                HStack(spacing: 6) {
                    Text(session.emoji)
                    Text(session.category)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.6))
                }

                Text(session.date, format: .dateTime.month(.wide).day().year())
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.25))
            }
        }
    }

    private var achievementContent: some View {
        VStack(spacing: isStories ? 16 : 10) {
            if let achievement = data.recentAchievement {
                Text(achievement.emoji)
                    .font(.system(size: isStories ? 56 : 40))

                Text(achievement.name)
                    .font(.system(size: isStories ? 24 : 20, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(achievement.rarity.label)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(achievement.rarity.color)
                    .tracking(1)

                Text(achievement.detail)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.4))
            }
        }
    }

    private var watermark: some View {
        VStack(spacing: 6) {
            Rectangle()
                .fill(Theme.textPrimary.opacity(0.06))
                .frame(height: 1)

            Text("=SOURCE(hardlyworking.app)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.2))
        }
    }

    private func formatLargeMoney(_ amount: Double) -> String {
        if amount >= 10000 { return String(format: "$%.0fK", amount / 1000) }
        if amount >= 1000 { return String(format: "$%.1fK", amount / 1000) }
        return Theme.formatMoney(amount)
    }
}
