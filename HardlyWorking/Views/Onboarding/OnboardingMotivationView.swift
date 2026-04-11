import SwiftUI

struct OnboardingMotivationView: View {
    @Binding var userMotivation: String

    private let options: [(emoji: String, label: String)] = [
        ("\u{1F4B0}", "I want to know how much I'm \"earning\""),
        ("\u{1F50D}", "Curiosity. How much do I actually slack?"),
        ("\u{1F4C4}", "My job is pointless and I need proof"),
        ("\u{1F4F1}", "I saw it on TikTok"),
        ("\u{1F465}", "A friend made me download this"),
        ("\u{1F441}", "I'm a manager spying on trends"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 16)

                Image("mascot_thinking")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)

                Spacer().frame(height: 24)

                Text("Why are you here?")
                    .font(.system(size: 24, weight: .light, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)

                Spacer().frame(height: 8)

                Text("Select the primary reason for your\ntime reclamation enrollment.")
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
        let isSelected = userMotivation == label
        return Button {
            Haptics.light()
            userMotivation = label
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
