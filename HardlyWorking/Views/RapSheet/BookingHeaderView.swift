import SwiftUI

struct BookingHeaderView: View {
    let hourlyRate: Double
    let userCountry: String
    let userIndustry: String
    let firstEntryDate: Date?
    let isActive: Bool
    let isProUser: Bool

    /// Server-assigned globally-unique Employee ID, cached from
    /// `profiles.employee_id`. 0 means "not yet fetched from Supabase" —
    /// the view's `.task` refreshes it on appear if needed.
    @AppStorage("employeeId") private var employeeId: Int = 0

    /// Renders the cached Employee ID as "#HW-XXXXX". Pads to 5 digits for
    /// IDs < 100,000 so the format stays tight, but `%05d` gracefully falls
    /// back to the natural digit count once we cross that threshold.
    private var caseNumber: String {
        guard employeeId > 0 else { return "#HW-—————" }
        return String(format: "#HW-%05d", employeeId)
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
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
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
                    HStack {
                        Text(industryDisplay.label)
                            .font(.system(.subheadline, design: .monospaced, weight: .medium))
                            .foregroundStyle(userIndustry.isEmpty ? Theme.textPrimary.opacity(0.5) : Theme.textPrimary)
                        Spacer()
                    }
                }

                rowDivider

                fieldRow(label: "REGION") {
                    HStack(spacing: 6) {
                        Text(userCountry.isEmpty ? "Unspecified" : userCountry)
                            .font(.system(.subheadline, design: .monospaced, weight: .medium))
                            .foregroundStyle(userCountry.isEmpty ? Theme.textPrimary.opacity(0.5) : Theme.textPrimary)
                        Spacer()
                    }
                }

                rowDivider

                fieldRow(label: "COMPENSATION") {
                    HStack {
                        Text(Theme.formatMoney(hourlyRate) + "/hr")
                            .font(.system(.subheadline, design: .monospaced, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                    }
                }

                rowDivider

                fieldRow(label: "START DATE") {
                    HStack {
                        Text(startDateLabel)
                            .font(.system(.subheadline, design: .monospaced, weight: .medium))
                            .foregroundStyle(firstEntryDate == nil ? Theme.textPrimary.opacity(0.5) : Theme.textPrimary)
                        Spacer()
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.cardBackground.opacity(0.5))
                    .stroke(Theme.textPrimary.opacity(0.06), lineWidth: 1)
            )
        }
        .task {
            // Lazy backfill for users who signed in before this feature existed
            // (or whose local cache was cleared). If we already have a cached
            // ID, skip the network call.
            if employeeId == 0 {
                if let fetched = try? await SupabaseManager.shared.fetchMyEmployeeId(),
                   fetched > 0 {
                    employeeId = fetched
                }
            }
        }
    }

    // MARK: - Components

    private var statusBadge: some View {
        Text(isProUser ? "EXECUTIVE" : "INTERN")
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                isProUser ? Theme.money : Theme.accent,
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
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
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
            isActive: true,
            isProUser: true
        )

        BookingHeaderView(
            hourlyRate: 15.0,
            userCountry: "",
            userIndustry: "",
            firstEntryDate: nil,
            isActive: false,
            isProUser: false
        )
    }
    .padding(24)
}
