import SwiftUI

struct OnboardingCommitmentView: View {
    @Binding var hasCommitted: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image("mascot_welcome")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)

            Spacer().frame(height: 24)

            Text("Final clearance required.")
                .font(.system(size: 24, weight: .light, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)

            Spacer().frame(height: 8)

            Text("To complete your enrollment at Hardly\nWorking Corp., acknowledge the following:")
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .multilineTextAlignment(.center)

            Spacer().frame(height: 24)

            pledgeCard

            Spacer().frame(height: 20)

            checkboxRow

            Spacer().frame(height: 12)

            Text("This pledge is non-binding, non-enforceable,\nand carries no weight of any kind.")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var pledgeCard: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Theme.textPrimary.opacity(0.06))
                .frame(height: 2)

            Text("I, the undersigned, hereby commit to\nthe accurate and ongoing reclamation of\nnon-productive time as defined by\nHardly Working Corp. (Ref: MEMO-2026-001)")
                .font(.system(.subheadline, design: .monospaced, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.vertical, 24)
                .padding(.horizontal, 20)

            Rectangle()
                .fill(Theme.textPrimary.opacity(0.06))
                .frame(height: 2)
        }
        .background(Theme.cardBackground.opacity(0.5))
    }

    private var checkboxRow: some View {
        Button {
            Haptics.medium()
            hasCommitted.toggle()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: hasCommitted ? "checkmark.square.fill" : "square")
                    .font(.system(.title3, weight: .medium))
                    .foregroundStyle(hasCommitted ? Theme.accent : Theme.textPrimary.opacity(0.2))

                Text("I have read and accept this pledge.")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .buttonStyle(.plain)
    }
}
