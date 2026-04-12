import SwiftUI

struct OnboardingInsightView: View {
    let hourlyRate: Double
    let workHoursPerDay: Double
    let workDaysPerWeek: Int
    let estimatedProductivity: Int
    let userIndustry: String
    let userCountry: String

    @State private var visibleRows: Int = 0

    private var dailyPotential: Double {
        hourlyRate * workHoursPerDay
    }

    private var weeklyUnreclaimed: Double {
        let weeklyTotal = hourlyRate * workHoursPerDay * Double(workDaysPerWeek)
        return weeklyTotal * (1.0 - Double(estimatedProductivity) / 100.0)
    }

    private var industryAvgHours: String {
        if let industry = MockBenchmarkData.industries.first(where: { $0.industry.rawValue == userIndustry }) {
            return Theme.formatDuration(industry.avgSecondsPerDay)
        }
        return Theme.formatDuration(MockBenchmarkData.global.globalAvgSecondsPerDay)
    }

    private var locationLabel: String {
        if !userIndustry.isEmpty && !userCountry.isEmpty {
            return "\(userIndustry) professionals in \(userCountry)"
        } else if !userIndustry.isEmpty {
            return "\(userIndustry) professionals"
        } else {
            return "Professionals globally"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 16)

                Image("mascot_aha")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)

                Spacer().frame(height: 24)

                Text("Preliminary findings from your\nintake assessment follow.")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 24)

                VStack(spacing: 0) {
                    if visibleRows >= 1 {
                        insightRow(
                            text: "At \(Theme.formatMoney(hourlyRate))/hr, daily reclamation ceiling: ",
                            highlight: Theme.formatMoney(dailyPotential),
                            suffix: "."
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if visibleRows >= 2 {
                        Divider().opacity(0.06).padding(.vertical, 4)
                        insightRow(
                            text: "Sector average (\(locationLabel)): ",
                            highlight: industryAvgHours,
                            suffix: " reclaimed per day."
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if visibleRows >= 3 {
                        Divider().opacity(0.06).padding(.vertical, 4)
                        insightRow(
                            text: "At \(estimatedProductivity)% declared productivity, weekly unreclaimed wages: ",
                            highlight: Theme.formatMoney(weeklyUnreclaimed),
                            suffix: "."
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.cardBackground.opacity(0.5))
                        .stroke(Theme.textPrimary.opacity(0.06), lineWidth: 1)
                )
                .padding(.horizontal, 24)
            }
        }
        .scrollIndicators(.hidden)
        .onAppear { animateRows() }
    }

    private func insightRow(text: String, highlight: String, suffix: String) -> some View {
        Text("\(Text(text).foregroundStyle(Theme.textPrimary.opacity(0.6)))\(Text(highlight).foregroundStyle(Theme.money).fontWeight(.semibold))\(Text(suffix).foregroundStyle(Theme.textPrimary.opacity(0.6)))")
            .font(.system(.caption, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }

    private func animateRows() {
        for i in 1...3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5) {
                withAnimation(.easeOut(duration: 0.4)) {
                    visibleRows = i
                }
                Haptics.light()
            }
        }
    }
}
