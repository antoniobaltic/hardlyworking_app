import SwiftUI

struct OnboardingFrustrationView: View {
    @Binding var userFrustration: String

    @State private var showMascot = false
    @State private var showBubble = false
    @State private var dialogueStage = 0
    @State private var showReplyButton = false
    @State private var replyPulse = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var visibleOptions = 0

    private let options: [(emoji: String, label: String)] = [
        ("\u{1F56F}", "The boredom is slowly extinguishing my soul."),
        ("\u{1F4CB}", "Too many meetings that should have been memos."),
        ("\u{1F937}", "My manager doesn't even know what I do."),
        ("\u{1F41F}", "Someone keeps microwaving fish."),
        ("\u{1F3AD}", "Pretending to have a lot to do is hard."),
        ("\u{1F6F8}", "I just feel... nothing. Nothing at all."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Mascot + speech bubble
            ZStack(alignment: .top) {
                Image("mascot_frustrated")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .padding(.top, 48)

                if showBubble {
                    speechBubble
                        .offset(x: 60)
                        .transition(.scale(scale: 0, anchor: .bottom).combined(with: .opacity))
                }

                if showReplyButton {
                    replyButton
                        .scaleEffect(replyPulse ? 1.08 : 1.0)
                        .offset(x: 110, y: 72)
                        .transition(.scale(scale: 0, anchor: .topLeading).combined(with: .opacity))
                }
            }
            .padding(.top, 12)
            .offset(y: showMascot ? 0 : 30)
            .opacity(showMascot ? 1 : 0)

            Text("State your grievance!")
                .font(.system(size: 24, weight: .light, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, 16)
                .opacity(showTitle ? 1 : 0)
                .offset(y: showTitle ? 0 : 10)

            Text("All new hires must declare their main\ngrievance at their former/concurrent\nemployer.")
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

    private var bubbleText: String {
        dialogueStage == 0
            ? "Whoops, I stood up\ntoo fast and fell over!"
            : "Maybe.\nI'm thinking about it."
    }

    private var speechBubble: some View {
        Text(bubbleText)
            .font(.system(.caption, design: .monospaced, weight: .medium))
            .foregroundStyle(Theme.textPrimary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                FrustrationBubbleShape(tailOffset: -20)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            }
            .background {
                FrustrationBubbleShape(tailOffset: -20)
                    .stroke(Theme.textPrimary.opacity(0.12), lineWidth: 1)
            }
            .animation(.easeInOut(duration: 0.3), value: dialogueStage)
    }

    private var replyButton: some View {
        Button {
            Haptics.light()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showReplyButton = false
                replyPulse = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    dialogueStage = 1
                }
            }
        } label: {
            Text("You okay?")
                .font(.system(.caption, design: .monospaced, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.accent)
                        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                }
        }
        .buttonStyle(.plain)
    }

    private func startSequence() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showMascot = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { showBubble = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { showReplyButton = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    replyPulse = true
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeOut(duration: 0.4)) { showTitle = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.easeOut(duration: 0.3)) { showSubtitle = true }
        }
        for i in 0..<options.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3 + Double(i) * 0.1) {
                withAnimation(.easeOut(duration: 0.3)) { visibleOptions = i + 1 }
            }
        }
    }

    private func optionButton(emoji: String, label: String) -> some View {
        let isSelected = userFrustration == label
        return Button {
            Haptics.light()
            withAnimation(.easeInOut(duration: 0.2)) {
                userFrustration = label
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

private struct FrustrationBubbleShape: Shape {
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
