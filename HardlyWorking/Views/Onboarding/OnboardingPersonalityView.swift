import SwiftUI

struct OnboardingPersonalityView: View {
    let estimatedProductivity: Int
    @Binding var reclaimerLevel: Int
    @Binding var reclaimerTitle: String

    @State private var hasAppeared = false

    private var level: Int {
        switch estimatedProductivity {
        case 81...100: 1
        case 61...80: 2
        case 41...60: 3
        case 21...40: 4
        default: 5
        }
    }

    private var title: String {
        switch level {
        case 1: "Probationary Intern"
        case 2: "Junior Reclaimer"
        case 3: "Certified Reclaimer"
        case 4: "Senior Reclaimer"
        default: "Executive Reclaimer"
        }
    }

    private var description: String {
        switch level {
        case 1: "Your file indicates limited reclamation\nexperience. A training period applies."
        case 2: "Some evidence of non-productive activity.\nFurther observation recommended."
        case 3: "Consistent and unremarkable. You have\nbeen placed in the general population."
        case 4: "Your dossier indicates sustained\nnon-productive output. Well documented."
        default: "You have transcended the productivity\ncontract. The department has taken note."
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image("mascot_badge")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)

            Spacer().frame(height: 24)

            Text("Based on your intake assessment:")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.4))

            Spacer().frame(height: 16)

            resultCard
                .scaleEffect(hasAppeared ? 1 : 0.9)
                .opacity(hasAppeared ? 1 : 0)

            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            reclaimerLevel = level
            reclaimerTitle = title
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) {
                hasAppeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                Haptics.success()
            }
        }
    }

    private var resultCard: some View {
        VStack(spacing: 12) {
            Text("CLEARANCE LEVEL \(level)")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(2)

            Text(title)
                .font(.system(size: 28, weight: .light, design: .monospaced))
                .foregroundStyle(Theme.accent)

            Text(description)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.cardBackground.opacity(0.5))
                .stroke(Theme.accent.opacity(0.15), lineWidth: 2)
        )
    }
}
