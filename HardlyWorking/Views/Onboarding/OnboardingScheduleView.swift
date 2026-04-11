import SwiftUI

struct OnboardingScheduleView: View {
    @Binding var workHoursPerDay: Double
    @Binding var workDaysPerWeek: Int

    private var weeklyHours: Double {
        workHoursPerDay * Double(workDaysPerWeek)
    }

    private var formattedHours: String {
        workHoursPerDay.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(workHoursPerDay))h"
            : String(format: "%.1fh", workHoursPerDay)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 16)

                Image("mascot_schedule")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)

                Spacer().frame(height: 24)

                Text("Register your official work schedule.\nThis helps us measure your inefficiency.")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 28)

                VStack(spacing: 0) {
                    formSection("HOURS PER DAY") {
                        HStack {
                            Text(formattedHours)
                                .font(.system(.title3, design: .monospaced, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                                .frame(width: 60, alignment: .leading)
                            Spacer()
                            Stepper("", value: $workHoursPerDay, in: 1...24, step: 0.5)
                                .labelsHidden()
                                .onChange(of: workHoursPerDay) { Haptics.selection() }
                        }
                    }

                    Divider().padding(.horizontal, 16).opacity(0.06)

                    formSection("DAYS PER WEEK") {
                        HStack {
                            Text("\(workDaysPerWeek)")
                                .font(.system(.title3, design: .monospaced, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                                .frame(width: 60, alignment: .leading)
                            Spacer()
                            Stepper("", value: $workDaysPerWeek, in: 1...7)
                                .labelsHidden()
                                .onChange(of: workDaysPerWeek) { Haptics.selection() }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.cardBackground.opacity(0.5))
                        .stroke(Theme.textPrimary.opacity(0.06), lineWidth: 1)
                )

                Spacer().frame(height: 20)

                Text("That's \(Text("\(Int(weeklyHours))h/week").foregroundStyle(Theme.money)) of potential reclamation.")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
            }
            .padding(.horizontal, 24)
        }
        .scrollIndicators(.hidden)
    }

    private func formSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(1.5)
            content()
        }
        .padding(.vertical, 16)
    }
}
