import SwiftUI

struct BookingHeaderView: View {
    let hourlyRate: Double
    let userCountry: String
    let userIndustry: String
    let firstEntryDate: Date?
    let isActive: Bool

    private var caseNumber: String {
        guard let date = firstEntryDate else { return "#HW-00000" }
        let hash = abs(date.timeIntervalSince1970.hashValue) % 100000
        return String(format: "#HW-%05d", hash)
    }

    private var industryDisplay: (label: String, emoji: String?) {
        guard !userIndustry.isEmpty,
              let industry = Industry(rawValue: userIndustry)
        else { return ("Unassigned", nil) }
        return (industry.rawValue, industry.emoji)
    }

    private var startDateLabel: String {
        guard let date = firstEntryDate else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PERSONNEL FILE")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(1.5)

            VStack(spacing: 0) {
                fieldRow(label: "EMPLOYEE ID") {
                    HStack {
                        Text(caseNumber)
                            .font(.system(.subheadline, design: .monospaced, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        statusBadge
                    }
                }

                rowDivider

                fieldRow(label: "DEPARTMENT") {
                    HStack(spacing: 6) {
                        Text(industryDisplay.label)
                            .font(.system(.subheadline, design: .monospaced, weight: .medium))
                            .foregroundStyle(userIndustry.isEmpty ? Theme.textPrimary.opacity(0.3) : Theme.textPrimary)
                        if let emoji = industryDisplay.emoji {
                            Text(emoji)
                                .font(.subheadline)
                        }
                        Spacer()
                    }
                }

                rowDivider

                fieldRow(label: "REGION") {
                    HStack(spacing: 6) {
                        Text(userCountry.isEmpty ? "Unspecified" : userCountry)
                            .font(.system(.subheadline, design: .monospaced, weight: .medium))
                            .foregroundStyle(userCountry.isEmpty ? Theme.textPrimary.opacity(0.3) : Theme.textPrimary)
                        Spacer()
                    }
                }

                rowDivider

                fieldRow(label: "COMPENSATION") {
                    Text(Theme.formatMoney(hourlyRate) + "/hr")
                        .font(.system(.subheadline, design: .monospaced, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                }

                rowDivider

                fieldRow(label: "START DATE") {
                    Text(startDateLabel)
                        .font(.system(.subheadline, design: .monospaced, weight: .medium))
                        .foregroundStyle(firstEntryDate == nil ? Theme.textPrimary.opacity(0.3) : Theme.textPrimary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.cardBackground.opacity(0.5))
                    .stroke(Theme.textPrimary.opacity(0.06), lineWidth: 1)
            )
        }
    }

    // MARK: - Components

    private var statusBadge: some View {
        Text(isActive ? "ON THE CLOCK" : "OUT OF OFFICE")
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                isActive ? Theme.timer : Theme.textPrimary.opacity(0.2),
                in: Capsule()
            )
    }

    private var rowDivider: some View {
        Divider().opacity(0.15)
    }

    private func fieldRow(label: String, @ViewBuilder content: () -> some View) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.25))
                .tracking(0.5)
                .frame(width: 90, alignment: .leading)

            content()
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    VStack {
        BookingHeaderView(
            hourlyRate: 45.0,
            userCountry: "United States",
            userIndustry: "Tech Bro",
            firstEntryDate: Calendar.current.date(byAdding: .month, value: -3, to: .now),
            isActive: true
        )

        BookingHeaderView(
            hourlyRate: 15.0,
            userCountry: "",
            userIndustry: "",
            firstEntryDate: nil,
            isActive: false
        )
    }
    .padding(24)
}
