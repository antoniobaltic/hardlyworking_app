import SwiftUI

struct PersonalRecordsView: View {
    let stats: DashboardViewModel.CareerStats

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PERSONAL RECORDS")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(1.5)

            let records = buildRecords()

            if records.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(records.enumerated()), id: \.offset) { index, record in
                        recordRow(record, isEven: index.isMultiple(of: 2))
                    }
                }
            }
        }
    }

    private func recordRow(_ record: Record, isEven: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(record.icon)
                .font(.title3)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(record.title)
                    .font(.system(.subheadline, design: .monospaced, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(record.detail)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.4))
            }

            Spacer()

            Text(record.value)
                .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                .foregroundStyle(Theme.accent)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 10)
        .background(isEven ? Theme.cardBackground.opacity(0.4) : Color.clear)
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Text("#N/A")
                .font(.system(.title3, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.08))
            Text("Not enough data for records yet.")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Build Records

    private struct Record {
        let icon: String
        let title: String
        let value: String
        let detail: String
    }

    private func buildRecords() -> [Record] {
        var records: [Record] = []

        if let longest = stats.longestSession {
            let emoji = SlackCategory.defaults.first { $0.name == longest.category }?.emoji ?? "\u{23F1}"
            records.append(Record(
                icon: emoji,
                title: "Longest Session",
                value: Theme.formatDuration(longest.duration),
                detail: "\(longest.category) \u{00B7} \(dateFormatter.string(from: longest.date))"
            ))
        }

        if let laziest = stats.laziestDay {
            records.append(Record(
                icon: "\u{1F3C6}",
                title: "Laziest Single Day",
                value: Theme.formatDuration(laziest.duration),
                detail: dateFormatter.string(from: laziest.date)
            ))
        }

        if let most = stats.mostSessionsDay, most.count >= 3 {
            records.append(Record(
                icon: "\u{1F4CA}",
                title: "Most Sessions (1 Day)",
                value: "\(most.count)",
                detail: dateFormatter.string(from: most.date)
            ))
        }

        if let payday = stats.biggestPayday, payday.money > 0 {
            records.append(Record(
                icon: "\u{1F4B5}",
                title: "Biggest Payday",
                value: Theme.formatMoney(payday.money),
                detail: dateFormatter.string(from: payday.date)
            ))
        }

        if let variety = stats.mostCategoriesDay, variety.count >= 3 {
            records.append(Record(
                icon: "\u{1F500}",
                title: "Most Activity Codes (1 Day)",
                value: "\(variety.count)",
                detail: dateFormatter.string(from: variety.date)
            ))
        }

        if stats.daysActive > 0 {
            records.append(Record(
                icon: "\u{1F4C5}",
                title: "Days Active",
                value: "\(stats.daysActive)",
                detail: stats.daysActive == 1 ? "Just getting started" : "A seasoned professional"
            ))
        }

        return records
    }
}
