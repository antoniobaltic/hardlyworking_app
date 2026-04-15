import SwiftUI

/// A single 4:3 share card (1080 × 1440 final, 360 × 480 logical). Layout
/// is tuned so every card type sits comfortably inside the frame with
/// room above the hero, generous margins around the stamp+signature,
/// and a footer strip that doesn't crowd the bottom edge.
struct ShareCardView: View {
    let data: ShareCardData
    let type: ShareCardType
    let isProUser: Bool

    private var size: CGSize { ShareCardCanvas.logicalSize }

    var body: some View {
        ZStack {
            // Paper background + inner frame
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)

            documentFrame

            VStack(spacing: 0) {
                memoHeader
                metadataStrip

                Spacer().frame(height: 24)

                Text(type.sectionHeader)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    .tracking(2.5)
                    .padding(.horizontal, 24)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 18)

                heroContent
                    .padding(.horizontal, 24)

                // Flexible spacer absorbs the slack between hero and stamp
                // so cards with shorter hero blocks don't feel top-heavy.
                Spacer(minLength: 12)

                stampAndSignature

                footerStrip
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .frame(width: size.width, height: size.height)
    }

    // MARK: - Chrome

    private var memoHeader: some View {
        HStack {
            Text("HARDLY WORKING CORP.")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(.white)

            Spacer()

            Text("FILE #\(fileNumber)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.textPrimary)
    }

    private var metadataStrip: some View {
        HStack(spacing: 12) {
            metadataItem(label: "FY", value: fiscalPeriod)
            Divider().frame(height: 18).overlay(Theme.textPrimary.opacity(0.1))
            metadataItem(label: "EMP", value: "\u{2593}\u{2593}\u{2593}\u{2593}\u{2593}\u{2593}\u{2593}")
            Divider().frame(height: 18).overlay(Theme.textPrimary.opacity(0.1))
            metadataItem(label: "CLRN", value: isProUser ? "EXEC" : "STD")
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Theme.cardBackground.opacity(0.6))
        .overlay(
            Rectangle().fill(Theme.textPrimary.opacity(0.1)).frame(height: 1),
            alignment: .bottom
        )
    }

    private func metadataItem(label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .tracking(1)
                .foregroundStyle(Theme.textPrimary.opacity(0.4))
            Text(value)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.75))
        }
    }

    private var documentFrame: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(Theme.textPrimary.opacity(0.12), lineWidth: 1)
    }

    private var footerStrip: some View {
        VStack(spacing: 2) {
            Rectangle()
                .fill(Theme.textPrimary.opacity(0.08))
                .frame(height: 1)

            HStack {
                Text("ISSUED BY RECORDS DIVISION")
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .tracking(1)
                    .foregroundStyle(Theme.textPrimary.opacity(0.45))

                Spacer()

                Text("NO. \(serialNumber)")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.35))
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 8)

            if !isProUser {
                Text("hardlyworking.app")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.3))
                    .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Hero content

    @ViewBuilder
    private var heroContent: some View {
        switch type {
        case .money: moneyContent
        case .category: categoryContent
        case .record: recordContent
        case .achievement: achievementContent
        case .laziestDay: laziestDayContent
        case .streak: streakContent
        }
    }

    private var moneyContent: some View {
        VStack(spacing: 10) {
            Text(formatLargeMoney(data.totalMoney))
                .font(.system(size: 60, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.money)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text("TOTAL UNBILLED COMPENSATION")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(Theme.textPrimary.opacity(0.7))
                .multilineTextAlignment(.center)

            Text("Accrued across \(Int(data.totalHours)) hours of documented self-care.")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.45))
                .multilineTextAlignment(.center)
        }
    }

    private var categoryContent: some View {
        VStack(spacing: 10) {
            if let cat = data.topCategory {
                Text(cat.emoji)
                    .font(.system(size: 50))

                Text(cat.name.uppercased())
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .tracking(1)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .lineLimit(2)

                Text("PRIMARY ACTIVITY DESIGNATION")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(Theme.textPrimary.opacity(0.65))

                Text("\(Int(cat.percentage * 100))% of reclaimed time.")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.45))

                Text("\(data.totalSessions) events on file.")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.35))
            }
        }
    }

    private var recordContent: some View {
        VStack(spacing: 10) {
            if let session = data.longestSession {
                Text(Theme.formatDuration(session.duration))
                    .font(.system(size: 52, weight: .light, design: .monospaced))
                    .foregroundStyle(Theme.accent)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text("LONGEST UNINTERRUPTED EPISODE")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(Theme.textPrimary.opacity(0.7))
                    .multilineTextAlignment(.center)

                HStack(spacing: 6) {
                    Text(session.emoji)
                    Text("\(session.category.uppercased()) \u{00B7} \(session.date.formatted(date: .numeric, time: .omitted))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.5))
                }
            }
        }
    }

    private var achievementContent: some View {
        VStack(spacing: 10) {
            if let achievement = data.recentAchievement {
                Text(achievement.emoji)
                    .font(.system(size: 50))

                Text(achievement.name.uppercased())
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .tracking(1)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .lineLimit(2)

                Text(achievement.rarity.label)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(achievement.rarity.color)

                Text("\(achievement.detail) recognition \u{2014} presented this fiscal quarter.")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.45))
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var laziestDayContent: some View {
        VStack(spacing: 10) {
            if let day = data.laziestDay {
                Text(Theme.formatDuration(day.duration))
                    .font(.system(size: 52, weight: .light, design: .monospaced))
                    .foregroundStyle(Theme.accent)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text("RECORDED IN A SINGLE WORKDAY")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(Theme.textPrimary.opacity(0.7))

                Text(day.date.formatted(date: .long, time: .omitted).uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.55))
                    .tracking(1)

                Text("Peak documented inactivity on file.")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.45))
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var streakContent: some View {
        VStack(spacing: 10) {
            Text("\(data.currentStreak)")
                .font(.system(size: 76, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.accent)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text("CONSECUTIVE WORKDAYS")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(Theme.textPrimary.opacity(0.7))

            Text("Of documented non-compliance. Weekends excluded.")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.45))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Stamp + Signature

    private var stampAndSignature: some View {
        VStack(spacing: 18) {
            stampBlock

            signatureBlock
        }
        .padding(.bottom, 14)
    }

    private var stampBlock: some View {
        Text(stampText)
            .font(.system(size: 13, weight: .heavy, design: .monospaced))
            .tracking(2)
            .foregroundStyle(Theme.bloodRed.opacity(0.75))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Theme.bloodRed.opacity(0.7), lineWidth: 2.5)
            )
            .rotationEffect(.degrees(-5))
    }

    private var signatureBlock: some View {
        VStack(spacing: 4) {
            Rectangle()
                .fill(Theme.textPrimary.opacity(0.3))
                .frame(width: 160, height: 1)

            Text("CERTIFIED BY: J. PEMBERTON, CSO")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(1)
                .foregroundStyle(Theme.textPrimary.opacity(0.55))
        }
    }

    private var stampText: String {
        switch type {
        case .money: "REVIEWED"
        case .category: "FILED"
        case .record: "RECORD"
        case .achievement: "CERTIFIED"
        case .laziestDay: "NOTABLE"
        case .streak: "VERIFIED"
        }
    }

    // MARK: - Derived metadata

    /// Document-style file number: HW-YYYYMMDD-####
    /// Suffix is a deterministic derivation from the data so the same user
    /// sees the same number across previews and exports on the same day.
    private var fileNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateStr = formatter.string(from: Date())
        let seed = abs(data.totalSessions * 7 + Int(data.totalHours * 3)) % 10000
        return "\(dateStr)-\(String(format: "%04d", seed))"
    }

    /// Serial number for the footer — longer pseudo-serial for records division feel.
    private var serialNumber: String {
        let seed = abs(data.totalSessions * 31 + Int(data.totalMoney * 7) + Int(data.totalHours * 13)) % 10_000_000
        return String(format: "%07d", seed)
    }

    private var fiscalPeriod: String {
        let year = Calendar.current.component(.year, from: Date())
        let month = Calendar.current.component(.month, from: Date())
        let quarter = (month - 1) / 3 + 1
        return "\(year)-Q\(quarter)"
    }

    private func formatLargeMoney(_ amount: Double) -> String {
        let sym = Theme.currencySymbol(for: UserDefaults.standard.string(forKey: "currency") ?? "USD")
        if amount >= 10000 { return String(format: "%@%.0fK", sym, amount / 1000) }
        if amount >= 1000 { return String(format: "%@%.1fK", sym, amount / 1000) }
        return Theme.formatMoney(amount)
    }
}

// MARK: - Preview

private func sampleData() -> ShareCardData {
    ShareCardData(
        totalMoney: 4237.50,
        totalHours: 142,
        totalSessions: 87,
        topCategory: ShareCardData.TopCategoryInfo(
            name: "Doom Scrolling",
            emoji: "\u{1F4F1}",
            percentage: 0.42,
            count: 36
        ),
        longestSession: ShareCardData.SessionRecord(
            duration: 4140,
            category: "Coffee Run",
            emoji: "\u{2615}",
            date: Date()
        ),
        laziestDay: ShareCardData.DayRecord(
            duration: 22_800,
            date: Date().addingTimeInterval(-86_400 * 30)
        ),
        industry: "Tech Bro",
        country: "Germany",
        hourlyRate: 30,
        recentAchievement: ShareCardData.AchievementInfo(
            name: "Budget Variance",
            emoji: "\u{1F4B0}",
            rarity: .rare,
            detail: "Tier III"
        ),
        currentStreak: 47
    )
}

#Preview("Performance Review") {
    ShareCardView(data: sampleData(), type: .money, isProUser: false)
        .padding(40)
        .background(Theme.cardBackground.opacity(0.5))
}

#Preview("Incident Report") {
    ShareCardView(data: sampleData(), type: .category, isProUser: false)
        .padding(40)
        .background(Theme.cardBackground.opacity(0.5))
}

#Preview("Personal Best") {
    ShareCardView(data: sampleData(), type: .record, isProUser: true)
        .padding(40)
        .background(Theme.cardBackground.opacity(0.5))
}

#Preview("Commendation") {
    ShareCardView(data: sampleData(), type: .achievement, isProUser: false)
        .padding(40)
        .background(Theme.cardBackground.opacity(0.5))
}

#Preview("Peak Inactivity") {
    ShareCardView(data: sampleData(), type: .laziestDay, isProUser: true)
        .padding(40)
        .background(Theme.cardBackground.opacity(0.5))
}

#Preview("Attendance Streak") {
    ShareCardView(data: sampleData(), type: .streak, isProUser: false)
        .padding(40)
        .background(Theme.cardBackground.opacity(0.5))
}
