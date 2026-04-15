import SwiftUI

struct YourPositionView: View {
    let userAvgPerDay: TimeInterval
    let countryAvgPerDay: TimeInterval
    let countryName: String
    let globalAvgPerDay: TimeInterval

    private var maxValue: TimeInterval {
        max(userAvgPerDay, countryAvgPerDay, globalAvgPerDay, 1)
    }

    private var countryLabel: String {
        countryName.isEmpty ? "Region Avg." : "\(countryName) Avg."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("HOW YOU COMPARE (LAST 30 DAYS)")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .tracking(1.5)

            VStack(alignment: .leading, spacing: 12) {
                barRow(
                    label: "Your Avg.",
                    value: userAvgPerDay,
                    color: Theme.timer
                )
                barRow(
                    label: countryLabel,
                    value: countryAvgPerDay,
                    color: Theme.cautionYellow
                )
                barRow(
                    label: "Global Avg.",
                    value: globalAvgPerDay,
                    color: Theme.accent
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.cardBackground.opacity(0.5))
                    .stroke(Theme.textPrimary.opacity(0.06), lineWidth: 1)
            )
        }
    }

    private func barRow(label: String, value: TimeInterval, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(Theme.textPrimary.opacity(0.7))
                Spacer()
                Text(Theme.formatDuration(value) + "/day")
                    .font(.system(.caption, design: .monospaced, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }

            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: max(4, geo.size.width * (value / maxValue)))
            }
            .frame(height: 10)
        }
    }
}
