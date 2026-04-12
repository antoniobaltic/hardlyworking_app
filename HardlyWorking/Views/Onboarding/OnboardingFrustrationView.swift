import SwiftUI

struct OnboardingFrustrationView: View {
    @Binding var userFrustration: String

    private let options: [(emoji: String, label: String)] = [
        ("\u{1F4E7}", "Meetings that should have been memos"),
        ("\u{1F50E}", "Mandatory justification of non-productive intervals"),
        ("\u{1F4E2}", "Open-plan acoustic disturbance"),
        ("\u{1F3AD}", "Sustained performance of visible productivity"),
        ("\u{1F4DA}", "Headcount consolidation without title adjustment"),
        ("\u{1F30C}", "Chronic awareness of the arrangement"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 16)

                Image("mascot_frustrated")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)

                Spacer().frame(height: 24)

                Text("Primary workplace grievance.")
                    .font(.system(size: 24, weight: .light, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)

                Spacer().frame(height: 8)

                Text("Per company policy, all employees must\nidentify their principal source of drain.")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 24)

                VStack(spacing: 10) {
                    ForEach(options, id: \.label) { option in
                        optionButton(emoji: option.emoji, label: option.label)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .scrollIndicators(.hidden)
    }

    private func optionButton(emoji: String, label: String) -> some View {
        let isSelected = userFrustration == label
        return Button {
            Haptics.light()
            userFrustration = label
        } label: {
            HStack(spacing: 12) {
                Text(emoji)
                    .font(.title3)
                Text(label)
                    .font(.system(.subheadline, design: .monospaced, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .white : Theme.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Theme.accent : Theme.cardBackground.opacity(0.5))
                    .stroke(isSelected ? Color.clear : Theme.textPrimary.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
