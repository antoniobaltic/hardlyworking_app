import Charts
import SwiftUI

struct PeriodChartView: View {
    let header: String
    let data: [ChartBar]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(header)
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(1.5)

            if data.isEmpty || data.allSatisfy({ $0.totalDuration == 0 }) {
                emptyChart
            } else {
                chart
            }
        }
    }

    private var chart: some View {
        Chart(data) { bar in
            BarMark(
                x: .value("Hours", bar.totalDuration / 3600),
                y: .value("Period", bar.label)
            )
            .foregroundStyle(bar.isCurrent ? Theme.timer : Theme.accent)
            .cornerRadius(3)
            .annotation(position: .trailing, spacing: 8) {
                if bar.totalDuration > 0 {
                    Text(Theme.formatDuration(bar.totalDuration))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.5))
                }
            }
        }
        .chartXAxis {
            AxisMarks(position: .bottom) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
                    .foregroundStyle(Theme.textPrimary.opacity(0.08))
                AxisValueLabel {
                    if let hours = value.as(Double.self) {
                        Text("\(Int(hours))h")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Theme.textPrimary.opacity(0.3))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let label = value.as(String.self) {
                        Text(label)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    }
                }
            }
        }
        .frame(height: max(140, CGFloat(data.count) * 38))
    }

    private var emptyChart: some View {
        VStack(spacing: 4) {
            Text("####")
                .font(.system(.title3, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.08))
            Text("Column too narrow to display")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.2))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
    }
}
