import SwiftUI

struct OnboardingHonestyView: View {
    @Binding var estimatedProductivity: Int

    private var commentary: String {
        switch estimatedProductivity {
        case 0...20: "Bold. We respect the honesty."
        case 21...40: "Below the national average of 38%."
        case 41...60: "You're in the sweet spot."
        case 61...80: "Overachiever detected. We can help."
        default: "Sure you are. We'll revisit this."
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 16)

                Image("mascot_honest")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)

                Spacer().frame(height: 24)

                Text("Be honest.")
                    .font(.system(size: 24, weight: .light, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)

                Spacer().frame(height: 8)

                Text("What percentage of your workday\ndo you estimate you actually work?")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 32)

                Text("\(estimatedProductivity)%")
                    .font(.system(size: 56, weight: .ultraLight, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.15), value: estimatedProductivity)

                Spacer().frame(height: 20)

                Slider(
                    value: Binding(
                        get: { Double(estimatedProductivity) },
                        set: { estimatedProductivity = Int($0) }
                    ),
                    in: 0...100,
                    step: 5
                )
                .tint(Theme.accent)
                .padding(.horizontal, 32)
                .onChange(of: estimatedProductivity) {
                    Haptics.selection()
                }

                HStack {
                    Text("0%")
                    Spacer()
                    Text("100%")
                }
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.35))
                .padding(.horizontal, 32)

                Spacer().frame(height: 20)

                Text(commentary)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.2), value: commentary)
            }
            .padding(.horizontal, 24)
        }
        .scrollIndicators(.hidden)
    }
}
