import SwiftUI

enum PreferenceField: String, Identifiable {
    case hourlyRate
    case workSchedule
    case industry
    case country
    case currency

    var id: String { rawValue }
}

struct CoverStoryView: View {
    let hourlyRate: Double
    let workHoursPerDay: Double
    let workDaysPerWeek: Int
    @Binding var includeWeekends: Bool
    let userIndustry: String
    let userCountry: String
    let currency: String
    var onEdit: (PreferenceField) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PREFERENCES")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(1.5)

            Text("Keep your records up to date.")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))

            VStack(spacing: 0) {
                settingRow(
                    label: "Hourly Rate",
                    value: Theme.formatMoney(hourlyRate) + "/hr",
                    isEmpty: false
                ) { onEdit(.hourlyRate) }

                rowDivider

                settingRow(
                    label: "Work Schedule",
                    value: "\(Int(workHoursPerDay))h/day, \(workDaysPerWeek) days/wk",
                    isEmpty: false
                ) { onEdit(.workSchedule) }

                rowDivider

                settingRow(
                    label: "Industry",
                    value: userIndustry.isEmpty ? "Undisclosed" : userIndustry,
                    isEmpty: userIndustry.isEmpty
                ) { onEdit(.industry) }

                rowDivider

                settingRow(
                    label: "Country",
                    value: userCountry.isEmpty ? "Undisclosed" : userCountry,
                    isEmpty: userCountry.isEmpty
                ) { onEdit(.country) }

                rowDivider

                settingRow(
                    label: "Currency",
                    value: currency,
                    isEmpty: false
                ) { onEdit(.currency) }

                rowDivider

                toggleRow
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.cardBackground.opacity(0.5))
                    .stroke(Theme.textPrimary.opacity(0.06), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Rows

    private func settingRow(
        label: String,
        value: String,
        isEmpty: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))

                Spacer()

                Text(value)
                    .font(.system(.subheadline, design: .monospaced, weight: .medium))
                    .foregroundStyle(isEmpty ? Theme.textPrimary.opacity(0.3) : Theme.textPrimary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary.opacity(0.15))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var toggleRow: some View {
        HStack {
            Text("Include Weekends")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))

            Spacer()

            Toggle("", isOn: $includeWeekends)
                .labelsHidden()
                .tint(Theme.accent)
                .onChange(of: includeWeekends) {
                    Haptics.selection()
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var rowDivider: some View {
        Divider()
            .padding(.leading, 16)
            .opacity(0.15)
    }
}
