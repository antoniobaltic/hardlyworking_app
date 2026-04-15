import SwiftUI

struct OnboardingIntermissionView: View {
    @Binding var isComplete: Bool

    @State private var showMascot = false
    @State private var showBubble = false
    @State private var dialogueStage = 0
    @State private var showReplyButton = false
    @State private var replyPulse = false

    private var bubbleText: String {
        switch dialogueStage {
        case 0: "So, how are you\ndoing so far?"
        case 1: "Yeah, haha.\nWe all had to go through that."
        case 2: "Ohhhh, we got a\nhigh performer here!"
        case 3: "High performer alarm!"
        case 4: "Alright, let's continue."
        default: ""
        }
    }

    private var replyText: String {
        switch dialogueStage {
        case 0: "I just answered\ntwo questions."
        case 1: "It wasn't\nthat hard."
        case 2: "?"
        case 3: "?"
        default: ""
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack(alignment: .top) {
                Image("mascot_welcome")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 320)
                    .padding(.top, 56)
                    .offset(x: -30)

                // John D.'s speech bubble
                if showBubble {
                    speechBubble
                        .offset(x: 30)
                        .transition(.scale(scale: 0, anchor: .bottom).combined(with: .opacity))
                }

                // Reply button
                if showReplyButton {
                    replyButton
                        .scaleEffect(replyPulse ? 1.08 : 1.0)
                        .offset(x: 110, y: 72)
                        .transition(.scale(scale: 0, anchor: .topLeading).combined(with: .opacity))
                }
            }
            .offset(y: showMascot ? 0 : 40)
            .opacity(showMascot ? 1 : 0)

            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear { startSequence() }
    }

    // MARK: - Speech Bubble

    private var speechBubble: some View {
        Text(bubbleText)
            .font(.system(.caption, design: .monospaced, weight: .medium))
            .foregroundStyle(Theme.textPrimary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                IntermissionBubbleShape(tailOffset: -20)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            }
            .background {
                IntermissionBubbleShape(tailOffset: -20)
                    .stroke(Theme.textPrimary.opacity(0.12), lineWidth: 1)
            }
            .animation(.easeInOut(duration: 0.3), value: dialogueStage)
    }

    // MARK: - Reply Button

    private var replyButton: some View {
        Button {
            Haptics.light()
            let nextStage = dialogueStage + 1

            // Hide button
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showReplyButton = false
                replyPulse = false
            }

            // Update John D.'s response
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    dialogueStage = nextStage
                }

                // Show next reply button or mark complete
                if nextStage < 4 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            showReplyButton = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                replyPulse = true
                            }
                        }
                    }
                } else {
                    // Final stage — activate Continue
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isComplete = true
                    }
                }
            }
        } label: {
            Text(replyText)
                .font(.system(.caption, design: .monospaced, weight: .medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
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

    // MARK: - Animation

    private func startSequence() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showMascot = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showBubble = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showReplyButton = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    replyPulse = true
                }
            }
        }
    }
}

// MARK: - Bubble Shape

private struct IntermissionBubbleShape: Shape {
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
