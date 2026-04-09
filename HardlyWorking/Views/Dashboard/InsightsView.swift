import SwiftUI

struct InsightsView: View {
    let insights: [Insight]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AUDIT FINDINGS")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(1.5)

            if insights.isEmpty {
                emptyState
            } else {
                ForEach(insights) { insight in
                    insightCard(insight.text)
                }
            }
        }
    }

    private func insightCard(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(.subheadline))
                .foregroundStyle(Theme.cautionYellow)
                .frame(width: 20)
            Text(text)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.cautionYellow.opacity(0.06))
                .stroke(Theme.cautionYellow.opacity(0.15), lineWidth: 1)
        )
    }

    private var emptyState: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle")
                .font(.system(.subheadline))
                .foregroundStyle(Theme.textPrimary.opacity(0.25))
                .frame(width: 20)
            Text("Insufficient data for analysis. Get back to not working.")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.cardBackground)
                .stroke(Theme.textPrimary.opacity(0.06), lineWidth: 1)
        )
    }
}
