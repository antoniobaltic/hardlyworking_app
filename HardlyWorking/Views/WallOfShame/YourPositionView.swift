import SwiftUI

struct YourPositionView: View {
    let userAvgPerDay: TimeInterval
    let globalAvgPerDay: TimeInterval

    private var percentageDiff: Int {
        guard globalAvgPerDay > 0 else { return 0 }
        return Int(((userAvgPerDay - globalAvgPerDay) / globalAvgPerDay) * 100)
    }

    private var comment: String {
        if userAvgPerDay == 0 {
            return "No data yet. Get to work. Or don't."
        }
        let diff = percentageDiff
        if diff > 50 { return "A prodigy. HR is watching." }
        if diff > 20 { return "Overachiever." }
        if diff > 0 { return "Above average. Not bad." }
        if diff > -20 { return "Below average. Room for improvement." }
        return "Suspiciously productive. Are you okay?"
    }

    private var maxValue: TimeInterval {
        max(userAvgPerDay, globalAvgPerDay, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("YOUR POSITION")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(1.5)

            VStack(alignment: .leading, spacing: 12) {
                barRow(
                    label: "You",
                    value: userAvgPerDay,
                    color: Theme.timer,
                    isBold: true
                )
                barRow(
                    label: "Global Avg",
                    value: globalAvgPerDay,
                    color: Theme.textPrimary.opacity(0.2),
                    isBold: false
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.cardBackground.opacity(0.5))
                    .stroke(Theme.textPrimary.opacity(0.06), lineWidth: 1)
            )

            HStack(spacing: 6) {
                if percentageDiff != 0 {
                    Text(percentageDiff > 0 ? "+\(percentageDiff)%" : "\(percentageDiff)%")
                        .font(.system(.caption, design: .monospaced, weight: .bold))
                        .foregroundStyle(percentageDiff > 0 ? Theme.timer : Theme.accent)
                }
                Text(comment)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.4))
            }
        }
    }

    private func barRow(label: String, value: TimeInterval, color: Color, isBold: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(.caption, design: .monospaced, weight: isBold ? .bold : .regular))
                    .foregroundStyle(Theme.textPrimary.opacity(isBold ? 0.7 : 0.4))
                Spacer()
                Text(Theme.formatDuration(value) + "/day")
                    .font(.system(.caption, design: .monospaced, weight: .semibold))
                    .foregroundStyle(isBold ? Theme.textPrimary : Theme.textPrimary.opacity(0.4))
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
