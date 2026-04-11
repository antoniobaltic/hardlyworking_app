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

            Text("One last thing.")
                .font(.system(size: 24, weight: .light, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)

            Spacer().frame(height: 8)

            Text("To complete your orientation, please\nacknowledge the following statement:")
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .multilineTextAlignment(.center)

            Spacer().frame(height: 24)

            pledgeCard

            Spacer().frame(height: 20)

            checkboxRow

            Spacer().frame(height: 12)

            Text("This pledge is non-binding and carries\nno legal or moral weight whatsoever.")
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

            Text("I, the undersigned, am committed\nto reclaiming my time and tracking\nmy true workplace productivity.")
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

                Text("I acknowledge this pledge.")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .buttonStyle(.plain)
    }
}
