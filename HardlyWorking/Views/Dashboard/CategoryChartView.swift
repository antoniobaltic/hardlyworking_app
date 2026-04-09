import Charts
import SwiftUI

struct CategoryChartView: View {
    let data: [CategorySlack]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ASSET ALLOCATION")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(1.5)

            if data.isEmpty {
                emptyState
            } else {
                donut
                    .frame(maxWidth: .infinity)
                legend
            }
        }
    }

    private var donut: some View {
        Chart(Array(data.enumerated()), id: \.element.id) { index, category in
            SectorMark(
                angle: .value("Time", category.totalDuration),
                innerRadius: .ratio(0.55),
                angularInset: 1.5
            )
            .foregroundStyle(Theme.chartPalette[index % Theme.chartPalette.count])
            .cornerRadius(3)
        }
        .frame(height: 160)
    }

    private var legend: some View {
        VStack(spacing: 0) {
            ForEach(Array(data.prefix(6).enumerated()), id: \.element.id) { index, category in
                HStack(spacing: 10) {
                    Circle()
                        .fill(Theme.chartPalette[index % Theme.chartPalette.count])
                        .frame(width: 8, height: 8)
                    Text(category.emoji)
                        .font(.caption2)
                    Text(category.name)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text(Theme.formatDuration(category.totalDuration))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.4))
                    Text("\(Int(category.percentage * 100))%")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.6))
                        .frame(width: 32, alignment: .trailing)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .background(
                    index.isMultiple(of: 2)
                        ? Theme.cardBackground.opacity(0.4)
                        : Color.clear
                )
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Text("#DIV/0!")
                .font(.system(.title3, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.08))
            Text("Cannot divide by zero categories")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.2))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
    }
}
