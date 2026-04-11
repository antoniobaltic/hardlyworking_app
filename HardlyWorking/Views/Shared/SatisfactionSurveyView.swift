import SwiftUI

struct SatisfactionSurveyView: View {
    @Environment(RatingManager.self) private var ratingManager

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("EMPLOYEE SATISFACTION SURVEY")
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundStyle(Theme.textPrimary.opacity(0.3))
                    .tracking(1.5)
                Text("FORM ES-4782 | REV. 3.1")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.15))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Theme.cardBackground)
            .overlay(
                Rectangle().fill(Theme.textPrimary.opacity(0.08)).frame(height: 1),
                alignment: .bottom
            )

            Spacer().frame(height: 24)

            Image("mascot_welcome")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)

            Spacer().frame(height: 24)

            Text("Your quarterly satisfaction assessment\nis due. The Department of Employee\nMorale requires your input.")
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .multilineTextAlignment(.center)

            Spacer().frame(height: 12)

            Text("All responses are anonymous and will\ndefinitely not affect your performance\nreview.")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.4))
                .multilineTextAlignment(.center)

            Spacer().frame(height: 20)

            VStack(spacing: 8) {
                Rectangle().fill(Theme.textPrimary.opacity(0.06)).frame(height: 1)
                Text("Participation is mandatory. Resistance has been noted.")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.3))
                Rectangle().fill(Theme.textPrimary.opacity(0.06)).frame(height: 1)
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 24)

            VStack(spacing: 12) {
                Button {
                    ratingManager.recordPositiveResponse()
                } label: {
                    VStack(spacing: 4) {
                        Text("Exceeds Expectations")
                            .font(.system(.subheadline, design: .monospaced, weight: .medium))
                        Text("I find this tool adequate for my needs")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    ratingManager.recordNeutralResponse()
                } label: {
                    VStack(spacing: 4) {
                        Text("Meets Expectations")
                            .font(.system(.subheadline, design: .monospaced, weight: .medium))
                        Text("It's fine. Everything is fine.")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(Theme.accent.opacity(0.6))
                    }
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Theme.accent, lineWidth: 1)
                    )
                }

                Button {
                    ratingManager.recordNegativeResponse()
                } label: {
                    VStack(spacing: 4) {
                        Text("File a Grievance")
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(Theme.timer)
                        Text("I need to speak with a manager")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(Theme.timer.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Text("REF: FORM-ES-4782-R3.1 | DEPT. OF MORALE | DO NOT DISCARD")
                .font(.system(size: 7, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.1))
                .padding(.bottom, 16)
        }
        .background(Color.white)
    }
}
