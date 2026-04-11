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
        case 1: "The Apprentice"
        case 2: "The Dabbler"
        case 3: "The Professional"
        case 4: "The Veteran"
        default: "The Enlightened"
        }
    }

    private var description: String {
        switch level {
        case 1: "You're just getting started. Every expert\nwas once a beginner. We believe in you."
        case 2: "You've dipped your toes in. There's\nso much more potential to unlock."
        case 3: "A balanced approach to time reclamation.\nConsistent. Reliable. Professional."
        case 4: "An experienced practitioner with a\ndeep understanding of workplace dynamics."
        default: "You have transcended the construct of\nproductivity. Welcome to the other side."
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

            Text("Based on your responses, you are:")
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
            Text("LEVEL \(level)")
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
