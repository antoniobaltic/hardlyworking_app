import SwiftUI

struct CountryRankingsView: View {
    let countries: [BenchmarkCountry]
    let userCountry: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("COUNTRY RANKINGS")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .tracking(1.5)

            if countries.isEmpty {
                VStack(spacing: 4) {
                    Text("#N/A")
                        .font(.system(.title3, design: .monospaced, weight: .bold))
                        .foregroundStyle(Theme.textPrimary.opacity(0.3))
                    Text("Insufficient regional data.\nMore employees needed.")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }

            VStack(spacing: 0) {
                ForEach(Array(countries.enumerated()), id: \.element.id) { index, country in
                    let isUser = country.name == userCountry
                    HStack(spacing: 10) {
                        Text("#\(index + 1)")
                            .font(.system(.caption, design: .monospaced, weight: .bold))
                            .foregroundStyle(rankColor(index + 1))
                            .frame(width: 24, alignment: .trailing)

                        Text(country.flag)
                            .font(.subheadline)

                        Text(country.name)
                            .font(.system(.subheadline, design: .monospaced, weight: isUser ? .bold : .regular))
                            .foregroundStyle(isUser ? Theme.accent : Theme.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        Text(Theme.formatDuration(country.avgSecondsPerDay) + "/day")
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

#Preview("Country Rankings — populated") {
    ScrollView {
        CountryRankingsView(
            countries: sampleCountryRankings,
            userCountry: "Austria"
        )
        .padding(24)
    }
    .background(Color.white)
}

private let sampleCountryRankings: [BenchmarkCountry] = [
    BenchmarkCountry(name: "France",        flag: "\u{1F1EB}\u{1F1F7}", avgSecondsPerDay: 9_540, userCount: 12_430),
    BenchmarkCountry(name: "Italy",         flag: "\u{1F1EE}\u{1F1F9}", avgSecondsPerDay: 8_820, userCount: 9_121),
    BenchmarkCountry(name: "Spain",         flag: "\u{1F1EA}\u{1F1F8}", avgSecondsPerDay: 8_460, userCount: 11_204),
    BenchmarkCountry(name: "Greece",        flag: "\u{1F1EC}\u{1F1F7}", avgSecondsPerDay: 7_920, userCount: 3_812),
    BenchmarkCountry(name: "Portugal",      flag: "\u{1F1F5}\u{1F1F9}", avgSecondsPerDay: 7_380, userCount: 2_951),
    BenchmarkCountry(name: "Germany",       flag: "\u{1F1E9}\u{1F1EA}", avgSecondsPerDay: 6_720, userCount: 18_440),
    BenchmarkCountry(name: "Austria",       flag: "\u{1F1E6}\u{1F1F9}", avgSecondsPerDay: 6_240, userCount: 1_872),
    BenchmarkCountry(name: "Netherlands",   flag: "\u{1F1F3}\u{1F1F1}", avgSecondsPerDay: 5_940, userCount: 4_310),
    BenchmarkCountry(name: "United Kingdom",flag: "\u{1F1EC}\u{1F1E7}", avgSecondsPerDay: 5_520, userCount: 22_601),
    BenchmarkCountry(name: "Ireland",       flag: "\u{1F1EE}\u{1F1EA}", avgSecondsPerDay: 5_160, userCount: 1_204),
    BenchmarkCountry(name: "Canada",        flag: "\u{1F1E8}\u{1F1E6}", avgSecondsPerDay: 4_800, userCount: 9_844),
    BenchmarkCountry(name: "United States", flag: "\u{1F1FA}\u{1F1F8}", avgSecondsPerDay: 4_440, userCount: 54_102),
    BenchmarkCountry(name: "Australia",     flag: "\u{1F1E6}\u{1F1FA}", avgSecondsPerDay: 4_080, userCount: 3_910),
    BenchmarkCountry(name: "Japan",         flag: "\u{1F1EF}\u{1F1F5}", avgSecondsPerDay: 3_000, userCount: 6_283),
    BenchmarkCountry(name: "South Korea",   flag: "\u{1F1F0}\u{1F1F7}", avgSecondsPerDay: 2_640, userCount: 2_114),
]
