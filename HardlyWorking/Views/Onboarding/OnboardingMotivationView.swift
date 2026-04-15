import SwiftUI

struct OnboardingMotivationView: View {
    @Binding var userMotivation: String

    @State private var showMascot = false
    @State private var showBubble = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var visibleOptions = 0

    private let options: [(emoji: String, label: String)] = [
        ("\u{23F3}", "I want to know what my wasted lifetime is worth."),
        ("\u{1F4CA}", "I need to quantify my non-productive output."),
        ("\u{1F916}", "My job could be done by a chatbot. A bad one from like 2023."),
        ("\u{1F440}", "I saw a coworker using this. She looked less dead inside."),
        ("\u{2728}", "I like the... eh... vibes here."),
        ("\u{2753}", "I am just very confused."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Mascot + speech bubble
            ZStack(alignment: .top) {
                Image("mascot_thinking")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .padding(.top, 48)

                if showBubble {
                    speechBubble
                        .offset(x: 60)
                        .transition(.scale(scale: 0, anchor: .bottom).combined(with: .opacity))
                }
            }
            .padding(.top, 12)
            .offset(y: showMascot ? 0 : 30)
            .opacity(showMascot ? 1 : 0)

            Text("State your purpose!")
                .font(.system(size: 24, weight: .light, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, 16)
                .opacity(showTitle ? 1 : 0)
                .offset(y: showTitle ? 0 : 10)

            Text("All new hires must declare their reason\nfor joining Hardly Working Corp.")
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.top, 10)
                .opacity(showSubtitle ? 1 : 0)

            // Scrollable options with fade
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(options.enumerated()), id: \.element.label) { index, option in
                        if index < visibleOptions {
                            optionButton(emoji: option.emoji, label: option.label)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .mask(
                VStack(spacing: 0) {
                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                        .frame(height: 32)
                    Color.black
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 32)
                }
            )
        }
        .onAppear { startSequence() }
    }

    private var speechBubble: some View {
        Text("Take your time.\nI'll just be staring a while.")
            .font(.system(.caption, design: .monospaced, weight: .medium))
            .foregroundStyle(Theme.textPrimary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                MotivationBubbleShape(tailOffset: -20)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            }
            .background {
                MotivationBubbleShape(tailOffset: -20)
                    .stroke(Theme.textPrimary.opacity(0.12), lineWidth: 1)
            }
    }

    private func startSequence() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showMascot = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { showBubble = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.4)) { showTitle = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.3)) { showSubtitle = true }
        }
        for i in 0..<options.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 + Double(i) * 0.1) {
                withAnimation(.easeOut(duration: 0.3)) { visibleOptions = i + 1 }
            }
        }
    }

    private func optionButton(emoji: String, label: String) -> some View {
        let isSelected = userMotivation == label
        return Button {
            Haptics.light()
            withAnimation(.easeInOut(duration: 0.2)) {
                userMotivation = label
            }
        } label: {
            HStack(spacing: 12) {
                Text(emoji)
                    .font(.title3)

                Text(label)
                    .font(.system(.caption, design: .monospaced, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .white : Theme.textPrimary)
                    .multilineTextAlignment(.leading)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(.subheadline, weight: .bold))
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Theme.money : Theme.cardBackground.opacity(0.5))
                    .stroke(isSelected ? Color.clear : Theme.textPrimary.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct MotivationBubbleShape: Shape {
    var tailOffset: CGFloat = 0
    var cornerRadius: CGFloat = 10
    var tailWidth: CGFloat = 12
    var tailHeight: CGFloat = 8

    func path(in rect: CGRect) -> Path {
        let r = cornerRadius
        let tailCenterX = rect.midX + tailOffset
        let tailLeft = tailCenterX - tailWidth / 2
        let tailRight = tailCenterX + tailWidth / 2

        var p = Path()
        p.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
                 radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
                 radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: tailRight, y: rect.maxY))
        p.addLine(to: CGPoint(x: tailCenterX, y: rect.maxY + tailHeight))
        p.addLine(to: CGPoint(x: tailLeft, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        p.addArc(center: CGPoint(x: rect.minX + r, y: rect.maxY - r),
                 radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r),
                 radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.closeSubpath()
        return p
    }
}
