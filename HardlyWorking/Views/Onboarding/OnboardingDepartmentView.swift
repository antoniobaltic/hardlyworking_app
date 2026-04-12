import SwiftUI

struct OnboardingDepartmentView: View {
    @Binding var userIndustry: String
    @Binding var userCountry: String

    var isComplete: Bool {
        !userIndustry.isEmpty && !userCountry.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 16)

                Image("mascot_department")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)

                Spacer().frame(height: 24)

                Text("Indicate your sector and operating region.\nRequired for interdepartmental benchmarking.")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 28)

                VStack(alignment: .leading, spacing: 20) {
                    // Industry
                    VStack(alignment: .leading, spacing: 10) {
                        Text("SECTOR")
                            .font(.system(.caption2, design: .monospaced, weight: .bold))
                            .foregroundStyle(Theme.textPrimary.opacity(0.3))
                            .tracking(1.5)

                        industryPills
                    }

                    // Country
                    VStack(alignment: .leading, spacing: 10) {
                        Text("OPERATING REGION")
                            .font(.system(.caption2, design: .monospaced, weight: .bold))
                            .foregroundStyle(Theme.textPrimary.opacity(0.3))
                            .tracking(1.5)

                        countryPicker
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Industry Pills

    private var industryPills: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(Industry.allCases) { industry in
                    Button {
                        Haptics.light()
                        userIndustry = industry.rawValue
                    } label: {
                        HStack(spacing: 4) {
                            Text(industry.emoji)
                                .font(.caption)
                            Text(industry.rawValue)
                                .font(.system(
                                    size: 11,
                                    weight: userIndustry == industry.rawValue ? .semibold : .regular,
                                    design: .monospaced
                                ))
                                .foregroundStyle(userIndustry == industry.rawValue ? .white : Theme.textPrimary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(userIndustry == industry.rawValue ? Theme.accent : Theme.cardBackground)
                                .stroke(
                                    userIndustry == industry.rawValue ? Color.clear : Theme.textPrimary.opacity(0.1),
                                    lineWidth: 1
                                )
                        )
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Country Picker

    private var countryPicker: some View {
        Menu {
            ForEach(Self.countryList, id: \.self) { country in
                Button(country) {
                    Haptics.light()
                    userCountry = country
                }
            }
        } label: {
            HStack {
                Text(userCountry.isEmpty ? "Select operating region" : userCountry)
                    .font(.system(.subheadline, design: .monospaced, weight: .medium))
                    .foregroundStyle(userCountry.isEmpty ? Theme.textPrimary.opacity(0.3) : Theme.textPrimary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(Theme.textPrimary.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.cardBackground.opacity(0.5))
                    .stroke(Theme.textPrimary.opacity(0.06), lineWidth: 1)
            )
        }
    }

    static let countryList: [String] = {
        Locale.Region.isoRegions.compactMap { region in
            Locale.current.localizedString(forRegionCode: region.identifier)
        }
        .sorted()
    }()
}
