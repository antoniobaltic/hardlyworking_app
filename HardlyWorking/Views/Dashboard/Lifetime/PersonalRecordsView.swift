import SwiftData
import SwiftUI

struct PersonalRecordsView: View {
    let stats: DashboardViewModel.CareerStats
    @Query(sort: \CustomCategory.createdAt)
    private var customCategories: [CustomCategory]

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PERFORMANCE HIGHLIGHTS")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .tracking(1.5)

            let sections = buildSections()
            let nonEmpty = sections.filter { !$0.records.isEmpty }

            if nonEmpty.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(nonEmpty) { section in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(section.title)
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Theme.textPrimary.opacity(0.4))
                                .tracking(1.2)
                                .padding(.leading, 4)

                            VStack(spacing: 0) {
                                ForEach(Array(section.records.enumerated()), id: \.offset) { index, record in
                                    recordRow(record, isEven: index.isMultiple(of: 2))
                                }
                            }
                        }
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
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
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
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
            Text("Not enough data for records yet.")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.45))
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

    private struct Section: Identifiable {
        let id = UUID()
        let title: String
        let records: [Record]
    }

    private func buildSections() -> [Section] {
        [
            Section(title: "TENURE", records: tenureRecords),
            Section(title: "CONSISTENCY", records: consistencyRecords),
            Section(title: "RECORDS", records: notableRecords),
        ]
    }

    private var tenureRecords: [Record] {
        var records: [Record] = []
        if let firstSession = stats.firstSessionDate {
            records.append(Record(
                icon: "\u{1F4BC}", // 💼
                title: "Employment Start",
                value: dateFormatter.string(from: firstSession),
                detail: employmentDetail(from: firstSession)
            ))
        }
        return records
    }

    private var consistencyRecords: [Record] {
        var records: [Record] = []
        if stats.currentStreak > 0 {
            records.append(Record(
                icon: "\u{1F525}", // 🔥
                title: "Current Streak",
                value: "\(stats.currentStreak)",
                detail: stats.currentStreak == 1 ? "workday" : "consecutive workdays"
            ))
        }
        if stats.longestStreakEver > 0 {
            records.append(Record(
                icon: "\u{1F4C5}", // 📅
                title: "Longest Streak",
                value: "\(stats.longestStreakEver)",
                detail: stats.longestStreakEver == 1 ? "workday on record" : "consecutive workdays on record"
            ))
        }
        return records
    }

    private var notableRecords: [Record] {
        var records: [Record] = []

        if let longest = stats.longestSession {
            let emoji = SlackCategory.emoji(for: longest.category, custom: customCategories)
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
                title: "Peak Inactivity",
                value: Theme.formatDuration(laziest.duration),
                detail: dateFormatter.string(from: laziest.date)
            ))
        }

        if let most = stats.mostSessionsDay, most.count >= 3 {
            records.append(Record(
                icon: "\u{1F4CA}",
                title: "\"Busiest\" Workday",
                value: "\(most.count)",
                detail: dateFormatter.string(from: most.date)
            ))
        }

        if let variety = stats.mostCategoriesDay, variety.count >= 3 {
            records.append(Record(
                icon: "\u{1F500}",
                title: "Greatest Variety",
                value: "\(variety.count)",
                detail: dateFormatter.string(from: variety.date)
            ))
        }

        return records
    }

    /// Human-readable tenure descriptor under the Employment Start record.
    /// Shows "Day one" on the first day, otherwise "N days on the books".
    private func employmentDetail(from firstSession: Date) -> String {
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: firstSession),
            to: Calendar.current.startOfDay(for: .now)
        ).day ?? 0
        if days <= 0 { return "Day one" }
        return "\(days) day\(days == 1 ? "" : "s") on the books"
    }
}
